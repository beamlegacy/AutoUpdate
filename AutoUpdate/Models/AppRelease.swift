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
    public let releaseNotes: String
    public let publicationDate: Date
    public let downloadURL: URL

    static public func demoJSON() -> Data {

        let v0_1DateComponents = DateComponents(year: 2020, month: 11, day: 20, hour: 17, minute: 45, second: 00)
        let v0_1 = AppRelease(versionName: "Version 0.1", version: "0.1", releaseNotes: "This is release notes from Beam 0.1", publicationDate: Calendar.current.date(from: v0_1DateComponents)!, downloadURL: URL(string: "https://www.beamapp.co/downloads/someZipv0.1.zip")!)

        let v0_1_1DateComponents = DateComponents(year: 2020, month: 11, day: 20, hour: 17, minute: 45, second: 00)
        let v0_1_1 = AppRelease(versionName: "Version 0.1.1", version: "0.1.1", releaseNotes: "This is release notes from Beam 0.1.1", publicationDate: Calendar.current.date(from: v0_1_1DateComponents)!, downloadURL: URL(string: "https://www.beamapp.co/downloads/someZipv0.1.1.zip")!)

        let v1_1DateComponents = DateComponents(year: 2021, month: 5, day: 3, hour: 14, minute: 35, second: 00)
        let v1_1 = AppRelease(versionName: "Version 1.1", version: "1.1", releaseNotes: "This is release notes from Beam 1.1", publicationDate: Calendar.current.date(from: v1_1DateComponents)!, downloadURL: URL(string: "https://github.com/eLud/update-proto/raw/main/BeamUpdaterProto_v1.1.zip")!)

        let notes = """
            • Pharetra, malesuada tellus amet orci iaculis et. In nunc, augue in orci netus maecenas. In eget arcu a augue. Dui pulvinar pellentesque.

            • Tempor sit erat amet parturient pretium nunc.

            • Urna arcu libero, neque, placerat risus porta commodo, nulla. Diam ac aliquam velit ipsum.

            • Et nulla sed justo facilisi. Lobortis ligula a nisl.

            • Nunc, morbi praesent non suscipit. In massa purus quis molestie. Nam lectus massa mattis fringilla quam. Vel tortor quis a sit tellus lorem amet placerat tellus. Semper dui massa phasellus nisl.

            • At amet nibh nibh nibh elementum. In sagittis consectetur ut massa pulvinar.
            """
        let v2_0 = AppRelease(versionName: "Beam 2.0: Collaborate on Cards",
                                            version: "2.0",
                                            releaseNotes: notes,
                                            publicationDate: Date(),
                                            downloadURL: URL(string: "https://github.com/eLud/update-proto/raw/main/BeamUpdaterProto_v1.1.zip")!)

        let versions = [v0_1, v0_1_1, v1_1, v2_0]

        let jsonEncoder = JSONEncoder()
        let data = try? jsonEncoder.encode(versions)

        return data!
    }
}

extension AppRelease: Comparable {

    public static func == (lhs: AppRelease, rhs: AppRelease) -> Bool {
        lhs.version.versionCompare(rhs.version) == .orderedSame
    }

    public static func < (lhs: AppRelease, rhs: AppRelease) -> Bool {
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
