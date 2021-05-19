//
//  main.swift
//  AppFeedBuilder
//
//  Created by Ludovic Ollagnier on 11/05/2021.
//

import Foundation
import ArgumentParser


struct AppFeedBuilder: ParsableCommand {

    @Argument(help: "The feed URL")
    var feedURL: String

    @Argument(help: "The new version name")
    var versionName: String

    @Argument(help: "The new version string (like \"2.0\")")
    var version: String

    @Argument(help: "The new version build number (should be an Int)")
    var buildNumber: Int

    @Argument(help: "The release notes URL")
    var releaseNotesURL: String

    @Argument(help: "The new version download URL. Must be an https URL pointing to a .zip file")
    var downloadURL: String

    @Flag(help: "")
    var verbose = false

    @Option(help: "Specifies the path to write the file", completion: CompletionKind.directory)
    var outputPath: String?

    func validate() throws {

        guard let feedURL = URL(string: feedURL),
              feedURL.scheme == "https" else {
            throw ValidationError("Feed URL is not a valid https URL")
        }

        guard let downloadURL = URL(string: downloadURL),
              downloadURL.pathExtension == "zip",
              downloadURL.scheme == "https" else {
            throw ValidationError("Download URL is not a valid URL for a zip file")
        }

        guard let notes = URL(string: releaseNotesURL),
              notes.pathExtension == "html",
              notes.scheme == "https" else {
            throw ValidationError("Release notes URL is not a valid URL for a html file")
        }
    }

    func run() throws {
        guard let feedURL = URL(string: feedURL),
              feedURL.scheme == "https" else {
            throw ValidationError("Feed URL is not a valid https URL")
        }

        guard let downloadURL = URL(string: downloadURL),
              downloadURL.pathExtension == "zip",
              downloadURL.scheme == "https" else {
            throw ValidationError("Download URL is not a valid URL for a zip file")
        }

        guard let notes = URL(string: releaseNotesURL),
              notes.pathExtension == "html",
              notes.scheme == "https" else {
            throw ValidationError("Release notes URL is not a valid URL for a html file")
        }

        let newRelease = AppRelease(versionName: versionName, version: version, buildNumber: buildNumber, htmlReleaseNotesURL: notes, publicationDate: Date(), downloadURL: downloadURL)

        let semaphore = DispatchSemaphore(value: 0)
        AppRelease.updateJSON(at: feedURL, with: newRelease) { feedJSONData in

            if let json = feedJSONData, let jsonString = String(data: json, encoding: .utf8) {
                if verbose {
                    print(jsonString)
                }

                let fileURL: URL
                if let path = outputPath {
                    fileURL = URL(fileURLWithPath: path)
                } else {
                    let currentURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                    fileURL = currentURL.appendingPathComponent("AppFeed.json")
                }
                do {
                    try jsonString.write(to: fileURL, atomically: true, encoding: .utf8)
                    print("App feed written at \(fileURL.path)")
                } catch {
                    print("Error writing file at \(fileURL.path) : \(error.localizedDescription)")
                }
            } else {
                print("Error generating the feed")
            }

            semaphore.signal()
        }
        semaphore.wait()
    }
}

//AppFeedBuilder.main(["https://raw.githubusercontent.com/eLud/update-proto/main/feed.json", "Beam 2.0", "2.0", "51", "This is a release note", "https://github.com/eLud/update-proto/raw/main/BeamUpdaterProto_v1.1.zip"])
AppFeedBuilder.main()
