//
//  VersionChecker.swift
//  BeamUpdaterProto
//
//  Created by Ludovic Ollagnier on 03/05/2021.
//

import AppKit
import Combine

public class VersionChecker: ObservableObject {

    enum VersionCheckerError: Error {
        case checkFailed
        case noUpdates
        case cantCreateRequiredFolders
    }

    public enum State: Equatable {
        case noUpdate
        case checking
        case updateAvailable(release: AppRelease)
        case error(errorDesc: String)
        case downloading(progress: Progress)
        case downloaded(release: DownloadedAppRelease)
        case installing
        case updateInstalled

        var canPerformCheck: Bool {
            switch self {
            case .noUpdate, .updateAvailable, .error, .downloaded:
                return true
            default:
            return false
            }

        }
    }

    private var mockData: Data?
    private var feedURL: URL?
    private var autocheckTimer: AnyCancellable?

    private var releaseHistory: [AppRelease]?
    private var fakeAppVersion: String?
    private var fakeAppBuild: Int?

    internal typealias PendingInstall = DownloadedAppRelease

    @Published public private(set) var newRelease: AppRelease?
    @Published public private(set) var currentRelease: AppRelease?
    @Published public private(set) var state: State
    @Published public private(set) var lastCheck: Date?

    ///Allows AutoUpdater to process to install automatically after an update was downloaded.
    ///false by default
    @Published public var allowAutoInstall = false

    ///Allow AutoUpdate to download to update in background.
    ///true by default
    @Published public var allowAutoDownload = true

    public var autocheckTimeInterval: TimeInterval = 60

    ///This code is executed before the the update installation.
    public var customPreinstall: (() -> Void)?

    public var missedReleases: [AppRelease]? {
        guard let current = currentRelease else { return nil }
        let missedVersions = releases(after: current)
        return missedVersions
    }

    public init(mockedReleases: [AppRelease], autocheckEnabled: Bool = false, fakeAppVersion: String? = nil, fakeAppBuild: Int? = nil) {
        let encoder = JSONEncoder()
        self.mockData = try? encoder.encode(mockedReleases)
        self.state = .noUpdate

        self.fakeAppBuild = fakeAppBuild
        self.fakeAppVersion = fakeAppVersion

        if autocheckEnabled {
            enableAutocheck()
        }
    }

    public init(feedURL: URL, autocheckEnabled: Bool = false) {
        self.feedURL = feedURL
        self.state = .noUpdate
        if autocheckEnabled {
            enableAutocheck()
        }
    }

    /// Checks if update is available from the feed or the mock data and updates the state accordingly
    public func checkForUpdates() {

        guard state.canPerformCheck else { return }

        guard let appSupportDirectory = applicationSupportDirectoryURL else { return }
        let pendingInstallation = checkForPendingInstallations(in: updateDirectory(in: appSupportDirectory))

        state = .checking

        checkRemoteUpdates { result in
            DispatchQueue.main.async {
                self.lastCheck = Date()

                switch result {
                case .success(let latest):

                    //If we have a newer version, make sure it's newer than the previously downloaded one
                    //If a new update was found, clean what was previously downloaded before downloading the new archive
                    if let pendingInstallation = pendingInstallation {
                        self.state = .downloaded(release: pendingInstallation)
                        return
                    } else {
                        self.cleanup()
                    }

                    self.newRelease = latest
                    self.state = .updateAvailable(release: latest)

                    if self.allowAutoDownload {
                        self.downloadNewestRelease()
                    }

                case .failure(let error):
                    self.newRelease = nil

                    if let pendingInstallation = pendingInstallation {
                        self.state = .downloaded(release: pendingInstallation)
                    }

                    if error == .noUpdates, let pendingInstallation = pendingInstallation {
                        self.state = .downloaded(release: pendingInstallation)
                    } else if error == .noUpdates {
                        self.state = .noUpdate
                    } else {
                        self.cleanup()
                        self.state = .error(errorDesc: "\(error)")
                    }
                }
            }
        }
    }

    /// Download the newest release and process installation using the XPC service
    public func downloadNewestRelease() {

        guard let release = newRelease else { return }
        let downloadURL = release.downloadURL

        let session = URLSession.shared
        let downloadTask = session.downloadTask(with: downloadURL) { fileURL, _, error in
            guard error == nil,
                  let fileURL = fileURL,
                  let appSupportURL = self.applicationSupportDirectoryURL else {
                DispatchQueue.main.async {
                    self.state = .error(errorDesc: error?.localizedDescription ?? "An error occured")
                }
                return
            }

            let updateFolder = self.updateDirectory(in: appSupportURL)

            do {
                try self.createAppFolderInAppSupportIfNeeded(updateFolder)
                let savedRelease = try self.saveDownloadedAppRelease(release, archiveURL: fileURL, in: updateFolder)

                DispatchQueue.main.async {
                    if self.allowAutoInstall {
                        self.processInstallation(archiveURL: savedRelease.archiveURL, autorelaunch: false)
                    } else {
                        self.state = .downloaded(release: savedRelease)
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.state = .error(errorDesc: error.localizedDescription)
                }
                self.cleanup()
                return
            }
        }

        downloadTask.resume()
        self.state = .downloading(progress: downloadTask.progress)
    }

    /// Pass the archive URL to the XPC service to extract it, and replace the existing binary
    /// - Parameter archiveURL: The URL of the zip archive
    func processInstallation(archiveURL: URL, autorelaunch: Bool) {

        self.state = .installing

        customPreinstall?()

        let connection = NSXPCConnection(serviceName: "com.tectec.UpdateInstaller")
        connection.remoteObjectInterface = NSXPCInterface(with: UpdateInstallerProtocol.self)
        connection.resume()

        let service = connection.remoteObjectProxyWithErrorHandler { error in
            DispatchQueue.main.async {
                self.state = .error(errorDesc: error.localizedDescription)
                self.cleanup()
            }
        } as? UpdateInstallerProtocol

        let pid = ProcessInfo.processInfo.processIdentifier
        service?.installUpdate(archiveURL: archiveURL, binaryToReplaceURL: Bundle.main.bundleURL, appPID: pid, reply: { success, error in

            self.cleanup()

            DispatchQueue.main.async {
                if !success, let xpcError = error, let updateError = UpdateInstallerError(rawValue: xpcError) {
                    self.state = .error(errorDesc: updateError.rawValue)
                    return
                } else if !success, let xpcError = error {
                    self.state = .error(errorDesc: xpcError)
                } else {
                    self.state = .updateInstalled
                    if autorelaunch {
                        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                            NSApp.terminate(self)
                        }
                    }
                }
                connection.invalidate()
            }
        })
    }

    private func enableAutocheck() {
        autocheckTimer = Timer.publish(every: self.autocheckTimeInterval, on: .main, in: .default).autoconnect().sink { [weak self] _ in
            self?.checkForUpdates()
        }
        self.checkForUpdates()
    }

    private func checkRemoteUpdates(completion: @escaping (Result<AppRelease, VersionCheckerError>) -> Void) {

        if let mock = mockData {
            if let release = findNewestRelease(data: mock) {
                completion(.success(release))
            } else {
                completion(.failure(.noUpdates))
            }
            return
        } else {
            //Get the real data from the real feed
            fetchServerData { data in
                guard let serverData = data else {
                    completion(.failure(.checkFailed))
                    return
                }

                if let release = self.findNewestRelease(data: serverData) {
                    completion(.success(release))
                } else {
                    completion(.failure(.noUpdates))
                }
                return
            }
        }
    }

    private func findNewestRelease(data: Data) -> AppRelease? {

        let decoder = JSONDecoder()
        // Get current app version
        // Compare to the feed's highest version
        var versions = try? decoder.decode([AppRelease].self, from: data)
        versions?.sort(by: >)
        guard let highestVersion = versions?.first else { return nil }

        self.releaseHistory = versions

        let currentVersion = self.currentAppVersion()
        let currentBuild = self.currentAppBuild()

        let currentFromFeed = versions?.filter({ release in
            release.buildNumber == currentBuild && release.version == currentVersion
        }).first

        let currentRelease = AppRelease(versionName: currentFromFeed?.versionName ?? self.currentAppName(),
                                        version: currentVersion,
                                        buildNumber: currentBuild,
                                        mardownReleaseNotes: currentFromFeed?.mardownReleaseNotes ?? "",
                                        publicationDate: currentFromFeed?.publicationDate ?? Date(),
                                        downloadURL: URL(string: "http://")!)
        self.currentRelease = currentRelease

        if highestVersion > currentRelease {
            return highestVersion
        } else {
            return nil
        }
    }

    private func fetchServerData(completion: @escaping (Data?) -> Void) {
        guard let feedURL = feedURL else { fatalError("Trying to get feed data with no url provided" ) }
        let task = URLSession.shared.dataTask(with: feedURL) { data, _, _ in
            completion(data)
        }

        task.resume()
    }

    /// Checks if the folder at the provided URL is existing, and create it if not.
    /// - Parameter folderURL: The URL of the folder to check and create
    /// - Throws: If we can't create the folder, this function throws VersionCheckerError.cantCreateRequiredFolders
    private func createAppFolderInAppSupportIfNeeded(_ folderURL: URL) throws {
        let fileManager = FileManager.default
        guard !fileManager.fileExists(atPath: folderURL.path) else { return }

        do {
            try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            throw VersionCheckerError.cantCreateRequiredFolders
        }
    }

    /// Removes the update directory to let the filesystem clean after success or failure
    private func cleanup() {
        guard let appSupport = applicationSupportDirectoryURL else { return }
        let fileManager = FileManager.default
        try? fileManager.removeItem(at: updateDirectory(in: appSupport))
    }

    func releases(after release: AppRelease) -> [AppRelease] {
        guard let history = self.releaseHistory else { return [] }
        let older = history.filter {
            $0 > release
        }

        return older
    }

    static func combinedReleaseNotes(for releases: [AppRelease]) -> [String] {
        releases.map({$0.mardownReleaseNotes})
    }

    func checkForPendingInstallations(in directory: URL ) -> PendingInstall? {
        if case State.downloaded(let release) = state {
            return release
        } else {
            let pendingReleases = findPendingReleases(in: directory)
            if let latest = pendingReleases.last,
               latest.appRelease > AppRelease.basicAppRelease(with: currentAppVersion(), buildNumber: currentAppBuild()) {
                return latest
            }
        }
        return nil
    }

    func findPendingReleases(in directory: URL) -> [DownloadedAppRelease] {
        let fileManager = FileManager.default
        let decoder = JSONDecoder()
        do {
            let files = try fileManager.contentsOfDirectory(atPath: directory.path)
            let releases: [DownloadedAppRelease] = try files.compactMap { fileName in
                guard fileName.hasSuffix("json") else { return nil }
                let url = directory.appendingPathComponent(fileName)
                let data = try Data(contentsOf: url)
                let release = try decoder.decode(DownloadedAppRelease.self, from: data)
                return release
            }
            return releases.sorted()
        } catch {
            return []
        }
    }

    func decomposedFilename(from url: URL) -> (fileName: String, fileExtension: String) {
        let fileExtension = url.pathExtension
        let fileName = url.deletingPathExtension().lastPathComponent
        return (fileName, fileExtension)
    }

    func saveDownloadedAppRelease(_ release: AppRelease, archiveURL: URL, in directory: URL) throws -> DownloadedAppRelease {

        let downloadURL = release.downloadURL

        let (fileName, fileExtension) = self.decomposedFilename(from: downloadURL)
        let finalFileName = directory.appendingPathComponent("\(fileName)_\(release.version).\(release.buildNumber)")

        let finalArchiveURL = finalFileName.appendingPathExtension(fileExtension)
        let jsonURL = finalFileName.appendingPathExtension("json")

        try FileManager.default.moveItem(at: archiveURL, to: finalArchiveURL)
        let downloadRelease = DownloadedAppRelease(appRelease: release, archiveURL: finalArchiveURL)
        let releaseData = try JSONEncoder().encode(downloadRelease)
        try releaseData.write(to: jsonURL)
        return downloadRelease
    }
}

// MARK: - Helper functions
extension VersionChecker {

    func currentAppVersion() -> String {
        if let fake = fakeAppVersion {
            return fake
        }

        guard let infos = Bundle.main.infoDictionary,
              let version = infos["CFBundleShortVersionString"] as? String else { fatalError("Cant' get app's version from CFBundleShortVersionString key in Info.plist")
        }
        return version
    }

    func currentAppBuild() -> Int {
        if let fake = fakeAppBuild {
            return fake
        }

        guard let infos = Bundle.main.infoDictionary,
              let version = infos["CFBundleVersion"] as? String,
              let intVersion = Int(version) else { fatalError("Cant' get app's build from CFBundleVersion key in Info.plist, or it's not an Int number. We only support comparing Int build number.")
        }
        return intVersion
    }

    func currentAppName() -> String {
        guard let infos = Bundle.main.infoDictionary,
              let name = infos["CFBundleName"] as? String else { fatalError("Cant' get app's name from CFBundleName key in Info.plist")
        }
        return name
    }

    private var applicationSupportDirectoryURL: URL? {
        let fileManager = FileManager.default
        return fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
    }

    private func applicationDirectory(in applicationSupportURL: URL) -> URL {
        let appDirectory = applicationSupportURL.appendingPathComponent(self.currentAppName())
        return appDirectory
    }

    private func updateDirectory(in applicationSupportURL: URL) -> URL {
        let appDirectory = applicationDirectory(in: applicationSupportURL)
        let updateDirectory = appDirectory.appendingPathComponent("Updates")
        return updateDirectory
    }
}
