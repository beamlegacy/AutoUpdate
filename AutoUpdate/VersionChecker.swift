//
//  VersionChecker.swift
//  AutoUpdate
//
//  Created by Ludovic Ollagnier on 03/05/2021.
//

import AppKit
import Combine

public class VersionChecker: ObservableObject {

    var mockData: Data?
    var feedURL: URL?
    private var autocheckTimer: AnyCancellable?
    var session: URLSession
    private static var sessionConfiguration: URLSessionConfiguration {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        return config
    }

    var releaseHistory: [AppRelease]?
    private(set) var fakeAppVersion: String?
    private(set) var fakeAppBuild: String?

    internal typealias PendingInstall = DownloadedAppRelease

    @Published public internal(set) var newRelease: AppRelease?
    @Published public internal(set) var currentRelease: AppRelease?
    @Published public internal(set) var state: State {
        didSet {
            logMessage?("AutoUpdate state changed: \(state)")
        }
    }
    @Published public private(set) var lastCheck: Date?

    ///Allows AutoUpdater to process to install automatically after an update was downloaded.
    ///false by default
    @Published public var allowAutoInstall = false

    ///Allow AutoUpdate to download to update in background.
    ///true by default
    @Published public var allowAutoDownload = true

    ///Autocheck time interval
    ///Defaults to 3600 seconds
    public var autocheckTimeInterval: TimeInterval = 3600

    ///If set to true, a timer will perform regular checks
    ///See autocheckTimeInterval to set the interval
    ///false by default
    public private(set) var autocheckEnabled: Bool = false

    ///This code is executed before the update installation.
    public var customPreinstall: (() -> Void)?

    ///This code is executed after the update installation.
    public var customPostinstall: ((Bool) -> Void)?

    ///Use this to get log message from AutoUpdate
    public var logMessage: ((String) -> Void)?

    ///If set, this URL is opened when clicked on the "View all" button in the release note view
    public var allReleaseNotesURL: URL?

    public var missedReleases: [AppRelease]? {
        guard let current = currentRelease else { return nil }
        let missedVersions = releases(after: current)
        return missedVersions
    }

    public init(mockedReleases: [AppRelease], autocheckEnabled: Bool = false, fakeAppVersion: String? = nil, fakeAppBuild: String? = nil) {
        let encoder = JSONEncoder()
        self.mockData = try? encoder.encode(mockedReleases)
        self.state = .noUpdate

        self.fakeAppBuild = fakeAppBuild
        self.fakeAppVersion = fakeAppVersion

        self.session = URLSession(configuration: Self.sessionConfiguration)
        self.setAutocheckEnabled(autocheckEnabled)
    }

    public init(feedURL: URL, autocheckEnabled: Bool = false) {
        self.feedURL = feedURL
        self.state = .noUpdate

        self.session = URLSession(configuration: Self.sessionConfiguration)
        self.setAutocheckEnabled(autocheckEnabled)
    }

    /// Checks if an update is available and update the state
    /// - Returns: The latest release found
    @discardableResult
    public func checkForUpdates() async -> AppRelease? {

        guard state.canPerformCheck else {
            logMessage?("Can't perform check. Current state: \(state)")
            return nil
        }

        guard let appSupportDirectory = applicationSupportDirectoryURL else { return nil }
        let pendingInstallation = checkForPendingInstallations(in: updateDirectory(in: appSupportDirectory))

        logMessage?("Checking for updates…")
        await setState(.checking)

        let result = await checkRemoteUpdates()

        Task { @MainActor in
            self.lastCheck = Date()
        }

        switch result {
        case .success(let release):
            await self.handleCheckSuccess(with: release, pendingInstallation: pendingInstallation)
            return release
        case .failure(let error):
            await self.handleCheckFailure(with: error, pendingInstallation: pendingInstallation)
            return nil
        }
    }

    /// Checks if update is available and then downloads it or install depending on the preferences.
    /// If autoDownload and autoInstall are disabled, and you don't force install, nothing will happen
    public func performUpdateIfAvailable(forceInstall: Bool = false) async {

        await checkForUpdates()

        if case .downloaded(let release) = state {
            if self.allowAutoInstall || forceInstall {
                self.logMessage?(self.allowAutoInstall ?
                                 "Auto-install enabled, will process installation."
                                 : "Force-install, will process installation.")
                await self.processInstallation(downloadedRelease: release, autorelaunch: true)
            }
        } else if case .updateAvailable = state {
            if self.allowAutoDownload || forceInstall {
                await self.downloadNewestRelease(forceInstall)
            }
        }
    }

    /// Download the newest release and process installation using the XPC service
    @MainActor
    public func downloadNewestRelease(_ forceInstall: Bool = false) {

        guard let release = newRelease else { return }
        let downloadURL = release.downloadURL
        let downloadTask = session.downloadTask(with: downloadURL) { fileURL, _, error in
            guard error == nil,
                  let fileURL = fileURL,
                  let appSupportURL = self.applicationSupportDirectoryURL else {
                      self.logMessage?("Error while downloading new update.")
                      self.state = .error(errorDesc: error?.localizedDescription ?? "An error occured")
                      return
                  }

            let updateFolder = self.updateDirectory(in: appSupportURL)

            self.logMessage?("Update downloaded.")
            do {
                try self.createAppFolderInAppSupportIfNeeded(updateFolder)
                let savedRelease = try self.saveDownloadedAppRelease(release, archiveURL: fileURL, in: updateFolder)

                Task { @MainActor in
                    if self.allowAutoInstall || forceInstall {
                        self.logMessage?(self.allowAutoInstall ?
                                         "Auto-install enabled, will process installation." :
                                            "Force-install, will process installation.")
                        self.processInstallation(downloadedRelease: savedRelease, autorelaunch: false)
                    } else {
                        self.logMessage?("Auto-install disabled, waiting for user to request installation.")
                        self.state = .downloaded(release: savedRelease)
                    }
                }
            } catch {
                Task { @MainActor in
                    self.state = .error(errorDesc: error.localizedDescription)
                }
                self.cleanup()
                return
            }
        }

        downloadTask.resume()
        self.logMessage?("Downloading new update.")
        self.state = .downloading(progress: downloadTask.progress)
    }

    public func setAutocheckEnabled(_ enabled: Bool, checkImmediately: Bool = false) {
        if enabled {
            autocheckEnabled = true
            autocheckTimer = Timer.publish(every: self.autocheckTimeInterval, on: .main, in: .default)
                .autoconnect()
                .sink { _ in
                    Task {
                        await self.performUpdateIfAvailable()
                    }
                }
        } else {
            autocheckEnabled = false
            autocheckTimer = nil
        }

        if checkImmediately {
            Task {
                await self.performUpdateIfAvailable()
            }
        }
    }

    /// Pass the archive URL to the XPC service to extract it, and replace the existing binary
    /// - Parameter archiveURL: The URL of the zip archive
    /// - Parameter autorelaunch: Should AutoUpdate quit and restart the app
    /// - Parameter completion: Code to be executed when the update is finished or failed
    @MainActor
    public func processInstallation(downloadedRelease: DownloadedAppRelease, autorelaunch: Bool, completion: ((Bool) -> Void)? = nil) {

        self.logMessage?("Processing installation…")
        self.state = .installing

        preinstallAction()

        let connection = setUpXPCConnection()
        guard let updateProxy = setUpXPObjectProxy(using: connection) else {
            self.logMessage?("Error getting remote object proxy for UpdateInstaller XPC.")
            customPostinstall?(false)
            completion?(false)
            return
        }

        let pid = ProcessInfo.processInfo.processIdentifier

        let archiveURL = downloadedRelease.archiveURL
        self.logMessage?("Request installation from UpdateInstaller XPC with archive at \(archiveURL.absoluteString). App PID is \(pid).")
        updateProxy.installUpdate(archiveURL: archiveURL, binaryToReplaceURL: Bundle.main.bundleURL, appPID: pid, reply: { success, error, updatedAppPath in

            self.cleanup()

            DispatchQueue.main.async { [weak self] in
                if !success, let xpcError = error, let updateError = UpdateInstallerError(rawValue: xpcError) {
                    self?.logMessage?("UpdateInstaller returned an error: \(updateError).")
                    self?.state = .error(errorDesc: updateError.localizedErrorString)
                    if let path = updatedAppPath {
                        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: path)])
                    }
                } else if !success, let xpcError = error {
                    self?.logMessage?("UpdateInstaller XPC returned a generic error: \(xpcError).")
                    self?.state = .error(errorDesc: xpcError)
                } else {
                    self?.logMessage?("UpdateInstaller a successful install.")
                    self?.state = .updateInstalled
                    if autorelaunch {
                        self?.logMessage?("AutoRelaunch is enabled. Will quit the app in 1 second.")
                        self?.quitApp(after: 1)
                    }
                }
                connection.invalidate()
                self?.customPostinstall?(success)
                completion?(success)
            }
        })
    }
}

// MARK: - Additional types
extension VersionChecker {
    enum VersionCheckerError: Error {
        case checkFailed
        case noUpdates
        case cantCreateRequiredFolders

        var localizedErrorString: String {
            switch self {
            case .checkFailed:
                return NSLocalizedString("Unable to check for updates", comment: "")
            case .noUpdates:
                return NSLocalizedString("No available updates", comment: "")
            case .cantCreateRequiredFolders:
                return NSLocalizedString("Unable to create required folders", comment: "")
            }
        }
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

        public var informativeMessage: String {
            switch self {
            case .noUpdate:
                return NSLocalizedString("Up to date.", comment: "")
            case .checking:
                return NSLocalizedString("Checking for updates…", comment: "")
            case .updateAvailable:
                return NSLocalizedString("Update available.", comment: "")
            case .error(errorDesc: let errorDesc):
                return NSLocalizedString("An error occured: \(errorDesc).", comment: "")
            case .downloading:
                return NSLocalizedString("Downloading update…", comment: "")
            case .downloaded:
                return NSLocalizedString("Update downloaded, ready for install.", comment: "")
            case .installing:
                return NSLocalizedString("Installing update…", comment: "")
            case .updateInstalled:
                return NSLocalizedString("Updated.", comment: "")
            }
        }
    }
}
