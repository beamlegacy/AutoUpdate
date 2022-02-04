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

    @Argument(help: "The new version build number (should be String, can be \"dotted\")")
    var buildNumber: String

    @Argument(help: "The new version download URL. Must be an https URL pointing to a .zip file")
    var downloadURL: String

    @Option(help: "The release notes in Markdown")
    var releaseNotesMarkdown: String?

    @Option(help: "The release notes URL to open on a tap on the release")
    var releaseNotesURL: String?

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

        let splitted = buildNumber.split(separator: ".")
        _ = try splitted.map { subStr -> Int in
            guard let component = Int(subStr) else {
                throw ValidationError("Build number format is not OK \"\(buildNumber)\". It should be a String, with at most 3 integers separated by dots")
            }
            return component
        }

        if let releaseNotesURL = releaseNotesURL {
            guard let notesURL = URL(string: releaseNotesURL),
                  notesURL.scheme == "https" else {
                throw ValidationError("Release Notes URL is not a valid URL")
            }
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

        var notesURL: URL?
        if let releaseNotesURL = releaseNotesURL {
            notesURL = URL(string: releaseNotesURL)
        }

        let newRelease = AppRelease(versionName: versionName, version: version, buildNumber: buildNumber, releaseNotesMarkdown: releaseNotesMarkdown, releaseNoteURL: notesURL, publicationDate: Date(), downloadURL: downloadURL)

        let semaphore = DispatchSemaphore(value: 0)
        AppRelease.updateJSON(at: feedURL, with: newRelease) { feedJSONData in

            if let json = feedJSONData, let jsonString = String(data: json, encoding: .utf8) {
                if verbose {
                    print(jsonString)
                }

                var fileURL: URL
                if let path = outputPath {
                    fileURL = URL(fileURLWithPath: path)
                } else {
                    fileURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                }
                fileURL = fileURL.appendingPathComponent("AppFeed.json")
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

//AppFeedBuilder.main(["https://raw.githubusercontent.com/eLud/update-proto/main/feed.json", "Beam 2.0", "2.0", "51", "https://github.com/eLud/update-proto/raw/main/BeamUpdaterProto_v1.1.zip", "--release-notes-markdown", "This is a note"])
//AppFeedBuilder.main(["https://raw.githubusercontent.com/eLud/update-proto/main/feed.json", "Beam 2.0", "2.0", "51", "https://github.com/eLud/update-proto/raw/main/BeamUpdaterProto_v1.1.zip", "--release-notes-url", "https://raw.githubusercontent.com/eLud/update-proto/main/feed.json"])
//AppFeedBuilder.main(["https://raw.githubusercontent.com/eLud/update-proto/main/feed.json", "Beam 2.0", "2.0", "20220127.171924", "https://github.com/eLud/update-proto/raw/main/BeamUpdaterProto_v1.1.zip", "--release-notes-url", "https://raw.githubusercontent.com/eLud/update-proto/main/feed.json", "--verbose"])
AppFeedBuilder.main()
