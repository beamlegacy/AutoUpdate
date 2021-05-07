//
//  AppRelease.swift
//  BeamUpdaterProto
//
//  Created by Ludovic Ollagnier on 03/05/2021.
//

import Foundation

struct AppRelease: Codable {

    let versionName: String
    let version: String
    let releaseNotes: String
    let publicationDate: Date
    let downloadURL: URL

    static func demoJSON() -> Data {

        let v0_1DateComponents = DateComponents(year: 2020, month: 11, day: 20, hour: 17, minute: 45, second: 00)
        let v0_1 = AppRelease(versionName: "Version 0.1", version: "0.1", releaseNotes: "This is release notes from Beam 0.1", publicationDate: Calendar.current.date(from: v0_1DateComponents)!, downloadURL: URL(string: "https://www.beamapp.co/downloads/someZipv0.1.zip")!)

        let v0_1_1DateComponents = DateComponents(year: 2020, month: 11, day: 20, hour: 17, minute: 45, second: 00)
        let v0_1_1 = AppRelease(versionName: "Version 0.1.1", version: "0.1.1", releaseNotes: "This is release notes from Beam 0.1.1", publicationDate: Calendar.current.date(from: v0_1_1DateComponents)!, downloadURL: URL(string: "https://www.beamapp.co/downloads/someZipv0.1.1.zip")!)

        let v1_1DateComponents = DateComponents(year: 2021, month: 5, day: 3, hour: 14, minute: 35, second: 00)
        let v1_1 = AppRelease(versionName: "Version 1.1", version: "1.1", releaseNotes: "This is release notes from Beam 1.1", publicationDate: Calendar.current.date(from: v1_1DateComponents)!, downloadURL: URL(string: "https://github.com/eLud/update-proto/raw/main/BeamUpdaterProto_v1.1.zip")!)

        let versions = [v0_1, v0_1_1, v1_1]

        let jsonEncoder = JSONEncoder()
        let data = try? jsonEncoder.encode(versions)

        return data!
    }
}

extension AppRelease: Comparable {

    static func == (lhs: AppRelease, rhs: AppRelease) -> Bool {
        lhs.version.versionCompare(rhs.version) == .orderedSame
    }

    static func < (lhs: AppRelease, rhs: AppRelease) -> Bool {
        lhs.version.versionCompare(rhs.version) == .orderedAscending
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