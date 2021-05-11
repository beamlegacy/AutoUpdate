//
//  VersionChecker.swift
//  BeamUpdaterProto
//
//  Created by Ludovic Ollagnier on 03/05/2021.
//

import Foundation
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
        case installing
        case updateInstalled
    }

    private var mockData: Data?
    private var feedURL: URL?

    private var autocheckTimer: AnyCancellable?

    @Published public var newRelease: AppRelease?
    @Published public var state: State
    @Published public var lastCheck: Date?

    public init(mockData: Data, autocheckEnabled: Bool = false) {
        self.mockData = mockData
        self.state = .noUpdate
        if autocheckEnabled {
            autocheckTimer = Timer.publish(every: 3600, on: .main, in: .default).autoconnect().sink { [weak self] timer in
                self?.checkForUpdates()
            }
            self.checkForUpdates()
        }
    }

    public init(feedURL: URL, autocheckEnabled: Bool = false) {
        self.feedURL = feedURL
        self.state = .noUpdate
        if autocheckEnabled {
            autocheckTimer = Timer.publish(every: 3600, on: .main, in: .default).autoconnect().sink { [weak self] timer in
                self?.checkForUpdates()
            }
            self.checkForUpdates()
        }
    }

    public func checkForUpdates() {
        state = .checking

        checkRemoteUpdates { result in
            DispatchQueue.main.async {
                self.lastCheck = Date()

                switch result {
                case .success(let latest):
                    self.newRelease = latest
                    self.state = .updateAvailable(release: latest)
                case .failure(let error):
                    self.newRelease = nil
                    if error == .noUpdates {
                        self.state = .noUpdate
                    } else {
                        self.state = .error(errorDesc: "\(error)")
                    }
                }
            }
        }
    }

    public func downloadNewestRelease() {

        guard let release = newRelease else { return }

        let session = URLSession.shared
        let downloadTask = session.downloadTask(with: release.downloadURL) { fileURL, response, error in
            let fileManager = FileManager.default

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
            } catch {
                self.state = .error(errorDesc: error.localizedDescription)
                return
            }

            let finalURL = updateFolder.appendingPathComponent("\(release.downloadURL.lastPathComponent)")

            do {
                try fileManager.moveItem(at: fileURL, to: finalURL)
                DispatchQueue.main.async {
                    self.state = .installing
                    self.processInstallation(archiveURL: finalURL)
                }
            } catch {
                self.cleanup()
                DispatchQueue.main.async {
                    self.state = .error(errorDesc: error.localizedDescription)
                }
            }
        }

        downloadTask.resume()
        self.state = .downloading(progress: downloadTask.progress)
    }

    private func processInstallation(archiveURL: URL) {
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

            DispatchQueue.main.async {
                if !success, let xpcError = error, let updateError = UpdateInstallerError(rawValue: xpcError) {
                    self.state = .error(errorDesc: updateError.rawValue)
                    return
                } else if !success, let xpcError = error {
                    self.state = .error(errorDesc: xpcError)
                } else {
                    self.state = .updateInstalled
                }
                connection.invalidate()
            }
            self.cleanup()
        })
    }

    private func checkRemoteUpdates(completion: @escaping (Result<AppRelease, VersionCheckerError>)->()) {

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
        var version = try? decoder.decode([AppRelease].self, from: data)
        version?.sort(by: >)
        guard let highestVersion = version?.first else { return nil }

        let currentRelease = AppRelease(versionName: self.currentAppName(),
                                        version: self.currentAppVersion(),
                                        buildNumber: self.currentAppBuild(),
                                        releaseNotes: "",
                                        publicationDate: Date(),
                                        downloadURL: URL(string: "http://")!)

        if highestVersion > currentRelease {
            return highestVersion
        } else {
            return nil
        }
    }

    private func fetchServerData(completion: @escaping (Data?)->()) {

        guard let feedURL = feedURL else { fatalError("Trying to get feed data with no url provided" ) }
        let task = URLSession.shared.dataTask(with: feedURL) { data, response, error in
            completion(data)
        }

        task.resume()
    }

    private func cleanup() {
        guard let appSupport = applicationSupportDirectoryURL else { return }
        let fileManager = FileManager.default
        try? fileManager.removeItem(at: updateDirectory(in: appSupport))
    }

    func currentAppVersion() -> String {
        guard let infos = Bundle.main.infoDictionary,
              let version = infos["CFBundleShortVersionString"] as? String else { fatalError("Cant' get app's version from CFBundleShortVersionString key in Info.plist")
        }
        return version
    }

    func currentAppBuild() -> Int {
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

    private func createAppFolderInAppSupportIfNeeded(_ folderURL: URL) throws {
        let fileManager = FileManager.default
        guard !fileManager.fileExists(atPath: folderURL.path) else { return }

        do {
            try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            throw VersionCheckerError.cantCreateRequiredFolders
        }
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
