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
    public let buildNumber: String
    public let releaseNotesMarkdown: String?
    public var releaseNoteURL: URL?
    public let publicationDate: Date
    public let downloadURL: URL

    public init(versionName: String, version: String, buildNumber: String, releaseNotesMarkdown: String? = nil, releaseNoteURL: URL? = nil, publicationDate: Date, downloadURL: URL) {
        self.versionName = versionName
        self.version = version
        self.buildNumber = buildNumber
        self.releaseNotesMarkdown = releaseNotesMarkdown
        self.releaseNoteURL = releaseNoteURL
        self.publicationDate = publicationDate
        self.downloadURL = downloadURL
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        versionName = try container.decode(String.self, forKey: .versionName)
        version = try container.decode(String.self, forKey: .version)

        //Migration from old Int build numbers
        if let intBuildNumber = try? container.decode(Int.self, forKey: .buildNumber) {
            buildNumber = "\(intBuildNumber)"
        } else {
            buildNumber = try container.decode(String.self, forKey: .buildNumber)
        }

        releaseNotesMarkdown = try container.decodeIfPresent(String.self, forKey: .releaseNotesMarkdown)
        releaseNoteURL = try container.decodeIfPresent(URL.self, forKey: .releaseNoteURL)
        publicationDate = try container.decode(Date.self, forKey: .publicationDate)
        downloadURL = try container.decode(URL.self, forKey: .downloadURL)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(versionName, forKey: .versionName)
        try container.encode(version, forKey: .version)
        try container.encode(buildNumber, forKey: .buildNumber)
        try container.encode(releaseNotesMarkdown, forKey: .releaseNotesMarkdown)
        try container.encode(publicationDate, forKey: .publicationDate)
        try container.encode(downloadURL, forKey: .downloadURL)
        try container.encode(releaseNoteURL, forKey: .releaseNoteURL)
    }

    enum CodingKeys: String, CodingKey {
        case versionName
        case version
        case buildNumber
        case releaseNotesMarkdown
        case releaseNoteURL
        case publicationDate
        case downloadURL
    }
}

extension AppRelease {

    static func updateJSON(at feedURL: URL, with release: AppRelease, completion: @escaping (Data?) -> Void) {
        getReleases(at: feedURL) { feed in

            var initialFeed = feed ?? []

            initialFeed.append(release)
            let encoder = JSONEncoder()
            do {
                let updatedFeedJSON = try encoder.encode(initialFeed)
                completion(updatedFeedJSON)
            } catch {
                completion(nil)
            }
        }
    }

    static func getReleases(at feedURL: URL, completion: @escaping ([AppRelease]?) -> Void ) {
        let task = URLSession.shared.dataTask(with: feedURL) { data, _, _ in
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

    static func basicAppRelease(with version: String, buildNumber: String) -> AppRelease {
        return AppRelease(versionName: "", version: version, buildNumber: buildNumber, releaseNotesMarkdown: "", publicationDate: Date(), downloadURL: URL(string: "http://")!)
    }

    static public func mockedReleases() -> [AppRelease] {

        let releaseNotes = """
        ## Collaboration, collaboration, collaboration

        - Pharetra, malesuada tellus amet orci iaculis et. In nunc, augue in orci netus maecenas. In eget arcu a augue. Dui pulvinar pellentesque.
        - Tempor sit erat amet parturient pretium nunc.
        - Urna arcu libero, neque, placerat risus porta commodo, nulla. Diam ac aliquam velit ipsum.
        - Et nulla sed justo facilisi. Lobortis ligula a nisl.
        - Nunc, morbi praesent non suscipit. In massa purus quis molestie. Nam lectus massa mattis fringilla quam. Vel tortor quis a sit tellus lorem amet placerat tellus. Semper dui massa phasellus nisl.
        - At amet nibh nibh nibh elementum. In sagittis consectetur ut massa pulvinar.
        """

        let v0_1DateComponents = DateComponents(year: 2021, month: 5, day: 24, hour: 17, minute: 45, second: 00)
        let v0_1 = AppRelease(versionName: "Dis maecenas et pretium diam", version: "0.1", buildNumber: "1", releaseNotesMarkdown: nil, publicationDate: Calendar.current.date(from: v0_1DateComponents)!, downloadURL: URL(string: "https://www.beamapp.co/downloads/someZipv0.1.zip")!)

        let v0_1_1DateComponents = DateComponents(year: 2021, month: 6, day: 03, hour: 17, minute: 45, second: 00)
        let v0_1_1 = AppRelease(versionName: "Imperdiet elementum condimentum vel malesuada mollis", version: "0.1.1", buildNumber: "2", releaseNotesMarkdown: nil, releaseNoteURL: URL(string: "http://www.beamapp.co"), publicationDate: Calendar.current.date(from: v0_1_1DateComponents)!, downloadURL: URL(string: "https://www.beamapp.co/downloads/someZipv0.1.1.zip")!)

        let v1_1DateComponents = DateComponents(year: 2021, month: 6, day: 21, hour: 14, minute: 35, second: 00)
        let v1_1 = AppRelease(versionName: "Proin senectus vitae odio gravida massa", version: "1.1", buildNumber: "5", releaseNotesMarkdown: "This is the version 1.1! \n*Lots of new stuff*", publicationDate: Calendar.current.date(from: v1_1DateComponents)!, downloadURL: URL(string: "https://github.com/eLud/update-proto/raw/main/BeamUpdaterProto_v1.1.zip")!)

        let v2_0DateComponents = DateComponents(year: 2021, month: 7, day: 29, hour: 14, minute: 35, second: 00)
        let v2_0 = AppRelease(versionName: "beam beta",
                              version: "2.0", buildNumber: "50",
                              releaseNoteURL: URL(string: "https://public.beamapp.co/beam/note/f7643c95-e6d9-4800-8499-89f900cfc2a8/Changelog"),
                              publicationDate: Calendar.current.date(from: v2_0DateComponents)!,
                              downloadURL: URL(string: "https://s3.eu-west-3.amazonaws.com/downloads.dev.beamapp.co/bluepineapple/0.5.1/20220420.110635/Beam.zip")!)

        let versions = [v0_1, v0_1_1, v1_1, v2_0]
        return versions
    }
}

extension AppRelease: Comparable {

    public static func == (lhs: AppRelease, rhs: AppRelease) -> Bool {
        lhs.version.versionCompare(rhs.version) == .orderedSame && lhs.buildNumber.versionCompare(rhs.buildNumber) == .orderedSame
    }

    public static func < (lhs: AppRelease, rhs: AppRelease) -> Bool {
        lhs.version.versionCompare(rhs.version) == .orderedAscending ||
        (lhs.version.versionCompare(rhs.version) == .orderedSame && lhs.buildNumber.versionCompare(rhs.buildNumber) == .orderedAscending)
    }
}

extension AppRelease: Identifiable {
    public var id: String {
        "\(version)_\(buildNumber)"
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
