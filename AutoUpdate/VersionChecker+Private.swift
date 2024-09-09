//
//  VersionChecker+Private.swift
//  AutoUpdate
//
//  Created by Ludovic Ollagnier on 23/06/2022.
//

import AppKit
import Common

extension VersionChecker {

    /// Execute customPreinstall code if provided
    func preinstallAction() {
        if let customPreinstall = customPreinstall {
            self.logMessage?("Executing the custom pre-install code.")
            customPreinstall()
            self.logMessage?("Custom pre-install code executed.")
        }
    }

    @MainActor
    func setState(_ state: State) {
        self.state = state
    }

    func checkRemoteUpdates() async -> Result<AppRelease, VersionCheckerError> {

        if let mock = mockData {
            if let release = findNewestRelease(data: mock) {
                return .success(release)
            } else {
                return .failure(.noUpdates)
            }
        } else {
            //Get the real data from the real feed
            let data = await fetchServerData()

            guard let serverData = data else {
                return .failure(.checkFailed)
            }

            if let release = self.findNewestRelease(data: serverData) {
                return .success(release)
            } else {
                return .failure(.noUpdates)
            }
        }
    }

    @MainActor
    func handleCheckSuccess(with latest: AppRelease, pendingInstallation: PendingInstall?) {
        self.logMessage?("Check for update: new update found. \(latest)")

        //If we have a new version, make sure it's newer than the previously downloaded one
        //If a new update was found, clean what was previously downloaded before downloading the new archive
        if let pendingInstallation = pendingInstallation, pendingInstallation.appRelease == latest {
            self.logMessage?("New update is already downloaded.")
            self.state = .downloaded(release: pendingInstallation)
            return
        } else {
            self.cleanup()
        }

        self.logMessage?("Update available, ready to download.")
        self.newRelease = latest
        self.state = .updateAvailable(release: latest)
    }

    @MainActor
    func handleCheckFailure(with error: VersionCheckerError, pendingInstallation: PendingInstall?) {
        self.newRelease = nil

        if let pendingInstallation = pendingInstallation {
            self.logMessage?("Check for update: no update, no update but there is a pending installation.")
            self.state = .downloaded(release: pendingInstallation)
        } else if error == .noUpdates {
            self.logMessage?("Check for update: no update.")
            self.state = .noUpdate
        } else {
            self.logMessage?("Check for update: an error occured \(error).")
            self.cleanup()
            self.state = .error(errorDesc: "\(error.localizedErrorString)")
        }
    }

    func findNewestRelease(data: Data) -> AppRelease? {

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
                                        publicationDate: currentFromFeed?.publicationDate ?? Date(),
                                        downloadURL: URL(string: "http://")!)

        DispatchQueue.main.async {
            self.currentRelease = currentRelease
        }

        if highestVersion > currentRelease {
            return highestVersion
        } else {
            return nil
        }
    }

    func fetchServerData() async -> Data? {
        guard let feedURL = feedURL else { fatalError("Trying to get feed data with no url provided" ) }
        self.logMessage?("Fetching data from \(feedURL.absoluteString).")

        let result = await withCheckedContinuation({ (continuation: CheckedContinuation<Data?, Never>) -> Void in
            let task = session.dataTask(with: feedURL) { data, _, _ in
                continuation.resume(returning: data)
            }

            task.resume()
        })

        return result
    }

    func quitApp(after seconds: Int) {
           DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(seconds)) {
               self.logMessage?("Quitting the app.")
               NSApp.terminate(self)
           }
       }

    // MARK: - XPC setup
    func setUpXPCConnection() -> NSXPCConnection {
        let connection = NSXPCConnection(serviceName: "co.beamapp.UpdateInstaller")
        connection.remoteObjectInterface = NSXPCInterface(with: UpdateInstallerProtocol.self)
        connection.resume()
        return connection
    }

    func setUpXPObjectProxy(using connection: NSXPCConnection) -> UpdateInstallerProtocol? {
        let proxy = connection.remoteObjectProxyWithErrorHandler { error in
            DispatchQueue.main.async {
                self.logMessage?("Error communicating with remote object proxy for UpdateInstaller XPC.")
                self.state = .error(errorDesc: error.localizedDescription)
                self.cleanup()
            }
        } as? UpdateInstallerProtocol

        return proxy
    }
}
