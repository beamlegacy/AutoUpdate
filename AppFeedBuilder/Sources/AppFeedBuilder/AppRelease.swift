//
//  AppRelease.swift
//  BeamUpdaterProto
//
//  Created by Ludovic Ollagnier on 03/05/2021.
//

import Foundation

public struct AppRelease: Codable {

    public let versionName: String
    public let version: String
    public let buildNumber: Int
    public let htmlReleaseNotesURL: URL
    public let publicationDate: Date
    public let downloadURL: URL
}

extension AppRelease {

    static func updateJSON(at feedURL: URL, with release: AppRelease, completion: @escaping (Data?)->()) {
        getReleases(at: feedURL) { feed in
            guard var feed = feed else {
                completion(nil)
                return
            }

            feed.append(release)
            let encoder = JSONEncoder()
            do {
                let updatedFeedJSON = try encoder.encode(feed)
                completion(updatedFeedJSON)
            } catch {
                completion(nil)
            }
        }
    }

    static func getReleases(at feedURL: URL, completion: @escaping ([AppRelease]?) -> () ) {
        let task = URLSession.shared.dataTask(with: feedURL) { data, response, error in
            guard let data = data else {
                completion(nil)
                return
            }

            do {
                let decoder = JSONDecoder()
                let version = try decoder.decode([AppRelease].self, from: data)
                completion(version)
            } catch {
                completion(nil)
            }
        }
        task.resume()
    }

    static public func demoJSON() -> Data {

        let v0_1DateComponents = DateComponents(year: 2020, month: 11, day: 20, hour: 17, minute: 45, second: 00)
        let v0_1 = AppRelease(versionName: "Version 0.1", version: "0.1", buildNumber: 1, htmlReleaseNotesURL: URL(string: "https://github.com/eLud/update-proto/raw/main/release_notes_0_1.html")!, publicationDate: Calendar.current.date(from: v0_1DateComponents)!, downloadURL: URL(string: "https://www.beamapp.co/downloads/someZipv0.1.zip")!)

        let v0_1_1DateComponents = DateComponents(year: 2020, month: 11, day: 20, hour: 17, minute: 45, second: 00)
        let v0_1_1 = AppRelease(versionName: "Version 0.1.1", version: "0.1.1", buildNumber: 2, htmlReleaseNotesURL: URL(string: "https://github.com/eLud/update-proto/raw/main/release_notes_0_1_1.html")!, publicationDate: Calendar.current.date(from: v0_1_1DateComponents)!, downloadURL: URL(string: "https://www.beamapp.co/downloads/someZipv0.1.1.zip")!)

        let v1_1DateComponents = DateComponents(year: 2021, month: 5, day: 3, hour: 14, minute: 35, second: 00)
        let v1_1 = AppRelease(versionName: "Version 1.1", version: "1.1", buildNumber: 5, htmlReleaseNotesURL: URL(string: "https://github.com/eLud/update-proto/raw/main/release_notes_1_1.html")!, publicationDate: Calendar.current.date(from: v1_1DateComponents)!, downloadURL: URL(string: "https://github.com/eLud/update-proto/raw/main/BeamUpdaterProto_v1.1.zip")!)

        let v2_0 = AppRelease(versionName: "Beam 2.0: Collaborate on Cards",
                              version: "2.0", buildNumber: 50,
                              htmlReleaseNotesURL: URL(string: "https://s3.eu-west-3.amazonaws.com/downloads.dev.beamapp.co/ludo/BE-568-auto-update/release_notes.html")!,
                                            publicationDate: Date(),
                                            downloadURL: URL(string: "http://www.mamadouce.fr/download/Beam_v2.0_50.zip")!)

        let versions = [v0_1, v0_1_1, v1_1, v2_0]

        let jsonEncoder = JSONEncoder()
        let data = try? jsonEncoder.encode(versions)

        return data!
    }
}

extension AppRelease: Comparable {

    public static func == (lhs: AppRelease, rhs: AppRelease) -> Bool {
        lhs.version.versionCompare(rhs.version) == .orderedSame && lhs.buildNumber == rhs.buildNumber
    }

    public static func < (lhs: AppRelease, rhs: AppRelease) -> Bool {
        lhs.version.versionCompare(rhs.version) == .orderedAscending || (lhs.version.versionCompare(rhs.version) == .orderedSame && lhs.buildNumber < rhs.buildNumber)
    }
}

extension String {
    func versionCompare(_ otherVersion: String) -> ComparisonResult {

        let versionDelimiter = "."

        var versionComponents = self.components(separatedBy: versionDelimiter)
        var otherVersionComponents = otherVersion.components(separatedBy: versionDelimiter)

        let zeroDiff = versionComponents.count - otherVersionComponents.count

        if zeroDiff == 0 {
            return self.compare(otherVersion, options: .numeric)
        } else {
            let zeros = Array(repeating: "0", count: abs(zeroDiff))
            if zeroDiff > 0 {
                otherVersionComponents.append(contentsOf: zeros)
            } else {
                versionComponents.append(contentsOf: zeros)
            }
            return versionComponents.joined(separator: versionDelimiter)
                .compare(otherVersionComponents.joined(separator: versionDelimiter), options: .numeric)
        }
    }
}
