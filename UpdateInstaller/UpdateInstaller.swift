//
//  UpdateInstaller.swift
//  UpdateInstaller
//
//  Created by Ludovic Ollagnier on 04/05/2021.
//

import Foundation

class UpdateInstaller: UpdateInstallerProtocol {

    let fileManager = FileManager.default

    func installUpdate(archiveURL: URL, binaryToReplace: URL, reply: @escaping (String) -> Void) {

        do {
            let appURL = try unarchiveZip(at: archiveURL)
            print(appURL)
            try unquarantineApp(at: appURL)
        } catch {
            reply(error.localizedDescription)
        }
    }

    private func unarchiveZip(at archiveURL: URL) throws -> URL {

        let enclosingFolderURL = archiveURL.deletingLastPathComponent()

        let unarchiveTask = Process()
        unarchiveTask.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        unarchiveTask.arguments = [archiveURL.path, "-d", enclosingFolderURL.path]

        do {
            try unarchiveTask.run()
            unarchiveTask.waitUntilExit()
        } catch {
            throw UpdateInstallerError.genericUnzipError
        }

        var unzippepAppsPaths: [String]
        do {
            let contentOfZipPaths = try fileManager.contentsOfDirectory(atPath: enclosingFolderURL.path)
            unzippepAppsPaths = contentOfZipPaths.filter( {$0.hasSuffix(".app") })
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

        do {
            try unquarantineTask.run()
            unquarantineTask.waitUntilExit()
        } catch {
            throw UpdateInstallerError.failedToUnquarantine
        }
    }

}
