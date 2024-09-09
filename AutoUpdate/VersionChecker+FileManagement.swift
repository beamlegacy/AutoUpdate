//
//  VersionChecker+FileManagement.swift
//  AutoUpdate
//
//  Created by Ludovic Ollagnier on 23/06/2022.
//

import Foundation
import Common

// MARK: - File management
extension VersionChecker {

    /// Checks if the folder at the provided URL is existing, and create it if not.
    /// - Parameter folderURL: The URL of the folder to check and create
    /// - Throws: If we can't create the folder, this function throws VersionCheckerError.cantCreateRequiredFolders
    func createAppFolderInAppSupportIfNeeded(_ folderURL: URL) throws {
        self.logMessage?("Creating update folder.")
        let fileManager = FileManager.default
        guard !fileManager.fileExists(atPath: folderURL.path) else { return }

        do {
            try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            self.logMessage?("Can't create update folder \(error).")
            throw VersionCheckerError.cantCreateRequiredFolders
        }
    }

    /// Removes the update directory to let the filesystem clean after success or failure
    func cleanup() {
        guard let appSupport = applicationSupportDirectoryURL else { return }
        self.logMessage?("Cleaning up the update directory.")
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

        self.logMessage?("Saving build \(release.buildNumber) from \(archiveURL.absoluteString) to \(finalArchiveURL.absoluteString).")

        try FileManager.default.moveItem(at: archiveURL, to: finalArchiveURL)
        let downloadRelease = DownloadedAppRelease(appRelease: release, archiveURL: finalArchiveURL)
        let releaseData = try JSONEncoder().encode(downloadRelease)
        try releaseData.write(to: jsonURL)
        return downloadRelease
    }
}
