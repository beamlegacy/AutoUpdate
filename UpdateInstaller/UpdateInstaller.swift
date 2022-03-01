//
//  UpdateInstaller.swift
//  UpdateInstaller
//
//  Created by Ludovic Ollagnier on 04/05/2021.
//

import Foundation

class UpdateInstaller: UpdateInstallerProtocol {

    let fileManager = FileManager.default
    private var updatedAppURL: URL?

    func installUpdate(archiveURL: URL, binaryToReplaceURL: URL, appPID: Int32, reply: @escaping (Bool, String?, String?) -> Void) {
        do {
            updatedAppURL = try unarchiveZip(at: archiveURL)
            guard let updatedAppURL = updatedAppURL else {
                return
            }
            try unquarantineApp(at: updatedAppURL)
            guard areAppSignatureIdentical(currentApp: binaryToReplaceURL, update: updatedAppURL) else { throw UpdateInstallerError.signatureFailed }
            guard checkForAppRename(updateURL: updatedAppURL, replacedBinaryURL: binaryToReplaceURL) else {
                fallbackInstallIfPossible(updatedAppURL: updatedAppURL, archiveURL: archiveURL)
                throw UpdateInstallerError.existingAppAtDestination
            }
            guard canWriteAt(installDestination: binaryToReplaceURL.deletingLastPathComponent()) else {
                fallbackInstallIfPossible(updatedAppURL: updatedAppURL, archiveURL: archiveURL)
                throw UpdateInstallerError.diskPermissionError
            }
            let installedAppURL = try install(updatedAppURL, replacedBinaryURL: binaryToReplaceURL, pid: appPID)
            relaunch(pid: appPID, at: installedAppURL)
        } catch {
            if let error = error as? UpdateInstallerError {
                reply(false, error.rawValue, updatedAppURL?.path)
            } else {
                reply(false, error.localizedDescription, nil)
            }
            return
        }

        reply(true, nil, nil)
    }

    private func unarchiveZip(at archiveURL: URL) throws -> URL {

        let enclosingFolderURL = archiveURL.deletingLastPathComponent()

        let unarchiveTask = Process()
        unarchiveTask.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        unarchiveTask.arguments = [archiveURL.path, "-d", enclosingFolderURL.path]

        let errorPipe = Pipe()
        unarchiveTask.standardError = errorPipe

        do {
            try unarchiveTask.run()
            unarchiveTask.waitUntilExit()
        } catch {
            throw UpdateInstallerError.genericUnzipError
        }

        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        guard errorData.isEmpty else { throw UpdateInstallerError.genericUnzipError}

        var unzippepAppsPaths: [String]
        do {
            let contentOfZipPaths = try fileManager.contentsOfDirectory(atPath: enclosingFolderURL.path)
            unzippepAppsPaths = contentOfZipPaths.filter({ $0.hasSuffix(".app") })
        } catch {
            throw UpdateInstallerError.unzippedContentNotFound
        }

        guard unzippepAppsPaths.count == 1, let app = unzippepAppsPaths.first else { throw UpdateInstallerError.archiveContentNotCoherent }

        return enclosingFolderURL.appendingPathComponent(app)
    }

    private func unquarantineApp(at url: URL) throws {

        let unquarantineTask = Process()
        unquarantineTask.executableURL = URL(fileURLWithPath: "/usr/bin/xattr")
        unquarantineTask.arguments = ["-d", "-r", "com.apple.quarantine", url.path]

        let errorPipe = Pipe()
        unquarantineTask.standardError = errorPipe

        do {
            try unquarantineTask.run()
            unquarantineTask.waitUntilExit()
        } catch {
            throw UpdateInstallerError.failedToUnquarantine
        }

        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        guard errorData.isEmpty else { throw UpdateInstallerError.failedToUnquarantine}
    }

    private func areAppSignatureIdentical(currentApp: URL, update: URL) -> Bool {
        do {
            let currentSignature = try codesign(for: currentApp)
            let updateSignature = try codesign(for: update)

            guard let currentTeam = extractTeamIdentifier(from: currentSignature),
                  let updateTeam = extractTeamIdentifier(from: updateSignature) else {
                return false
            }

            return currentTeam == updateTeam
        } catch {
            return false
        }
    }

    private func extractTeamIdentifier(from signature: String) -> String? {
        let patternToFind = "TeamIdentifier="
        let splitted = signature.split(separator: "\n")
        let filtered = splitted.filter({ $0.hasPrefix(patternToFind) })

        guard var teamID = filtered.first else { return nil }
        teamID.removeFirst(patternToFind.count)

        return String(teamID)
    }

    private func codesign(for appURL: URL) throws -> String {
        let codesignURL = URL(fileURLWithPath: "/usr/bin/codesign")

        let codesignTask = Process()
        codesignTask.executableURL = codesignURL
        codesignTask.arguments = ["--display", "--verbose=2", appURL.path]

        //We use standError because this is where codesign prints out the verbose output
        let errorPipe = Pipe()
        codesignTask.standardError = errorPipe

        do {
            try codesignTask.run()
            codesignTask.waitUntilExit()
        } catch {
            throw UpdateInstallerError.signatureFailed
        }

        let errorOutput = errorPipe.fileHandleForReading.readDataToEndOfFile()
        guard !errorOutput.isEmpty else { throw UpdateInstallerError.signatureFailed }

        let standardErrorString = String(data: errorOutput, encoding: .utf8)
        guard let signature = standardErrorString else { throw UpdateInstallerError.signatureFailed }

        return signature
    }

    ///Check is the app have been renamed, and is so, if it can still be installed
    private func checkForAppRename(updateURL: URL, replacedBinaryURL: URL) -> Bool {

        //Get current installed app name (check the replacedBinaryURL)
        let replacedAppName = replacedBinaryURL.lastPathComponent
        //Get the name on new app
        let updatedAppName = updateURL.lastPathComponent
        //Are they identical?
        if replacedAppName == updatedAppName {
            return true
        } else {
            //If not, check if there is not another app at the same location with the new name.
            let installationDirectoryURL = replacedBinaryURL.deletingLastPathComponent()
            let futureAppLocation = installationDirectoryURL.appendingPathComponent(updatedAppName)
            return !fileManager.fileExists(atPath: futureAppLocation.path)
        }
    }

    private func install(_ updateURL: URL, replacedBinaryURL: URL, pid: Int32) throws -> URL {

        let fileExtension = replacedBinaryURL.pathExtension
        let appToReplaceNameWithoutExtension = replacedBinaryURL.deletingPathExtension()
        let appName = appToReplaceNameWithoutExtension.lastPathComponent
        let appToReplaceNewName = appName + " (\(pid))" + "." + fileExtension

        let enclosingFolder = replacedBinaryURL.deletingLastPathComponent()

        //We rename old binary
        let newNameURL = enclosingFolder.appendingPathComponent(appToReplaceNewName)
        try fileManager.moveItem(at: replacedBinaryURL, to: newNameURL)

        //We move the new in place
        let updateDestinationURL = enclosingFolder.appendingPathComponent(updateURL.lastPathComponent)
        try fileManager.moveItem(at: updateURL, to: updateDestinationURL)

        //Cleanup
        guard let trash = fileManager.urls(for: .trashDirectory, in: .userDomainMask).first else { throw UpdateInstallerError.appReplacementFailed }

        do {
            try fileManager.moveItem(at: newNameURL, to: trash.appendingPathComponent(appToReplaceNewName))
        } catch {
            print(error)
        }

        return updateDestinationURL
    }

    private func relaunch(pid: Int32, at url: URL) {

        let sh = URL(fileURLWithPath: "/bin/sh")

        let waitForExitScript = "(while /bin/kill -0 \(pid) >&/dev/null; do /bin/sleep 0.1; done; /usr/bin/open \"\(url.path)\") &"

        let waitForExitTask = Process()
        waitForExitTask.executableURL = sh
        waitForExitTask.arguments =  ["-c", waitForExitScript]

        try? waitForExitTask.run()
    }

    /// Check if we can write at the destination
    /// - Parameter installDestination: The URL we want to check the write permission
    /// - Returns: true if we can write at this URL, fasle otherwise.
    private func canWriteAt(installDestination: URL) -> Bool {
        //Check disk permissions
        return fileManager.isWritableFile(atPath: installDestination.path)
    }

    /// Fallback installation. We try to move the app in the Download folder. If not possible because there is already an app with that name, try to move the archive, and make it's name unique
    /// - Parameters:
    ///   - appUpdateURL: URL of the updated app
    ///   - archiveURL: URL of the zip archive
    private func fallbackInstallIfPossible(updatedAppURL: URL, archiveURL: URL) {
        guard let downloadFolder = fileManager.urls(for: .downloadsDirectory, in: .userDomainMask).first else { return }

        let updateInDownloadFolder = downloadFolder.appendingPathComponent(updatedAppURL.lastPathComponent)
        let archiveInDownloadFolder = downloadFolder.appendingPathComponent(archiveURL.lastPathComponent)

        if move(file: updatedAppURL, to: updateInDownloadFolder) {
            self.updatedAppURL = updateInDownloadFolder
            return
        } else {
            move(file: archiveURL, to: archiveInDownloadFolder)
            self.updatedAppURL = archiveInDownloadFolder
            return
        }
    }

    ///Tries to move the specified file to the destination.
    /// - Parameters:
    ///   - file: URL of the file to move
    ///   - destination: Destination URL including the filename
    /// - Returns: True is move was successful, false otherwise
    @discardableResult private func move(file: URL, to destination: URL) -> Bool {
        do {
            try fileManager.moveItem(at: file, to: destination)
            return true
        } catch {
            NSLog("Can't move file \(file) to \(destination): \(error)")
            return false
        }
    }
}
