//
//  GitHubReleaseFeed.swift
//  AutoUpdate
//

import Foundation

struct GitHubAPIRelease: Decodable {
    let tagName: String
    let name: String
    let publishedAt: Date
    let htmlURL: URL
    let assets: [GitHubAsset]
    let prerelease: Bool

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case name
        case publishedAt = "published_at"
        case htmlURL = "html_url"
        case assets
        case prerelease
    }
}

struct GitHubAsset: Decodable {
    let name: String
    let browserDownloadURL: URL

    enum CodingKeys: String, CodingKey {
        case name
        case browserDownloadURL = "browser_download_url"
    }
}

extension GitHubAPIRelease {

    /// Maps this GitHub release to an `AppRelease`, or returns nil if the release is a
    /// prerelease or doesn't contain an asset matching `assetName`.
    func toAppRelease(matchingAsset assetName: String) -> AppRelease? {
        guard !prerelease else { return nil }
        guard let asset = assets.first(where: { $0.name == assetName }) else { return nil }

        let (version, buildNumber) = Self.parseTag(tagName)

        return AppRelease(
            versionName: name.isEmpty ? tagName : name,
            version: version,
            buildNumber: buildNumber,
            releaseNoteURL: htmlURL,
            publicationDate: publishedAt,
            downloadURL: asset.browserDownloadURL
        )
    }

    /// Parses a GitHub tag into a (version, buildNumber) pair.
    ///
    /// Supported formats:
    /// - `v1.2.3`          → ("1.2.3", "0")
    /// - `1.2.3`           → ("1.2.3", "0")
    /// - `v1.2.3+456`      → ("1.2.3", "456")
    /// - `1.2.3-release`   → ("1.2.3", "0")  suffix after `-` is stripped
    /// - `1.2.3-beta`      → ("1.2.3", "0")
    static func parseTag(_ tag: String) -> (version: String, buildNumber: String) {
        var raw = tag
        if raw.hasPrefix("v") || raw.hasPrefix("V") {
            raw = String(raw.dropFirst())
        }
        // Strip trailing label e.g. "-release", "-beta"
        if let dashIdx = raw.firstIndex(of: "-") {
            raw = String(raw[raw.startIndex..<dashIdx])
        }
        if let plusIdx = raw.firstIndex(of: "+") {
            let version = String(raw[raw.startIndex..<plusIdx])
            let build = String(raw[raw.index(after: plusIdx)...])
            return (version, build.isEmpty ? "0" : build)
        }
        return (raw, "0")
    }
}
