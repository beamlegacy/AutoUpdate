//
//  DownloadedAppRelease.swift
//  AutoUpdate
//
//  Created by Ludovic Ollagnier on 21/07/2021.
//

import Foundation

public struct DownloadedAppRelease: Codable, Equatable {
    public let appRelease: AppRelease
    public let archiveURL: URL

    static func downloadedAppRelease(with version: String, buildNumber: String, archiveURL: URL) -> DownloadedAppRelease {
        let release = AppRelease.basicAppRelease(with: version, buildNumber: buildNumber)
        return DownloadedAppRelease(appRelease: release, archiveURL: archiveURL)
    }
}

extension DownloadedAppRelease: Comparable {

    public static func == (lhs: DownloadedAppRelease, rhs: DownloadedAppRelease) -> Bool {
        lhs.appRelease.version.versionCompare(rhs.appRelease.version) == .orderedSame && lhs.appRelease.buildNumber == rhs.appRelease.buildNumber
    }

    public static func < (lhs: DownloadedAppRelease, rhs: DownloadedAppRelease) -> Bool {
        lhs.appRelease.version.versionCompare(rhs.appRelease.version) == .orderedAscending || (lhs.appRelease.version.versionCompare(rhs.appRelease.version) == .orderedSame && lhs.appRelease.buildNumber < rhs.appRelease.buildNumber)
    }
}
