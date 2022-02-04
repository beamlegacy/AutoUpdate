//
//  AutoUpdateTests.swift
//  AutoUpdateTests
//
//  Created by Ludovic Ollagnier on 03/05/2021.
//

import XCTest
import Combine

@testable import AutoUpdate

class AutoUpdateFrameworkTests: XCTestCase {

    var cancellable: AnyCancellable?

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.

        cancellable = nil
        cleanupTestFolderIfNeeded()
    }

    func testVersionEqualitySameFormat() {
        let v0_1DateComponents = DateComponents(year: 2020, month: 11, day: 20, hour: 17, minute: 45, second: 00)
        let v0_1 = AppRelease(versionName: "Version 0.1", version: "0.1", buildNumber: "1", releaseNotesMarkdown: "This is release notes from Beam 0.1", publicationDate: Calendar.current.date(from: v0_1DateComponents)!, downloadURL: URL(string: "https://www.beamapp.co/downloads/someZipv0.1.zip")!)

        let v0_1bis = AppRelease(versionName: "Version 0.1", version: "0.1", buildNumber: "1", releaseNotesMarkdown: "This is release notes from Beam 0.1", publicationDate: Calendar.current.date(from: v0_1DateComponents)!, downloadURL: URL(string: "https://www.beamapp.co/downloads/someZipv0.1.zip")!)

        let v0_2 = AppRelease(versionName: "Version 0.2", version: "0.2", buildNumber: "1", releaseNotesMarkdown: "This is release notes from Beam 0.2", publicationDate: Calendar.current.date(from: v0_1DateComponents)!, downloadURL: URL(string: "https://www.beamapp.co/downloads/someZipv0.2.zip")!)

        XCTAssertEqual(v0_1, v0_1bis)
        XCTAssertNotEqual(v0_1, v0_2)
    }

    func testVersionEqualityDifferentFormat() {
        let v0_1DateComponents = DateComponents(year: 2020, month: 11, day: 20, hour: 17, minute: 45, second: 00)
        let v0_1 = AppRelease(versionName: "Version 0.1", version: "0.1.0", buildNumber: "1", releaseNotesMarkdown: "This is release notes from Beam 0.1", publicationDate: Calendar.current.date(from: v0_1DateComponents)!, downloadURL: URL(string: "https://www.beamapp.co/downloads/someZipv0.1.zip")!)

        let v0_1bis = AppRelease(versionName: "Version 0.1", version: "0.1", buildNumber: "1", releaseNotesMarkdown: "This is release notes from Beam 0.1", publicationDate: Calendar.current.date(from: v0_1DateComponents)!, downloadURL: URL(string: "https://www.beamapp.co/downloads/someZipv0.1.zip")!)

        XCTAssertEqual(v0_1, v0_1bis)
    }

    func testVersionComparisonSameFormat() {
        let v0_1DateComponents = DateComponents(year: 2020, month: 11, day: 20, hour: 17, minute: 45, second: 00)
        let v0_1 = AppRelease(versionName: "Version 0.1", version: "0.1", buildNumber: "1", releaseNotesMarkdown: "This is release notes from Beam 0.1", publicationDate: Calendar.current.date(from: v0_1DateComponents)!, downloadURL: URL(string: "https://www.beamapp.co/downloads/someZipv0.1.zip")!)

        let v0_2 = AppRelease(versionName: "Version 0.2", version: "0.2", buildNumber: "1", releaseNotesMarkdown: "This is release notes from Beam 0.2", publicationDate: Calendar.current.date(from: v0_1DateComponents)!, downloadURL: URL(string: "https://www.beamapp.co/downloads/someZipv0.2.zip")!)

        XCTAssertTrue(v0_2 > v0_1, "")
        XCTAssertTrue(v0_1 < v0_2, "")
    }

    func testVersionComparisonDifferentFormat() {
        let v0_1DateComponents = DateComponents(year: 2020, month: 11, day: 20, hour: 17, minute: 45, second: 00)
        let v0_1 = AppRelease(versionName: "Version 0.1", version: "0.1.0", buildNumber: "1", releaseNotesMarkdown: "This is release notes from Beam 0.1", publicationDate: Calendar.current.date(from: v0_1DateComponents)!, downloadURL: URL(string: "https://www.beamapp.co/downloads/someZipv0.1.zip")!)

        let v0_2 = AppRelease(versionName: "Version 0.2", version: "0.2", buildNumber: "1", releaseNotesMarkdown: "This is release notes from Beam 0.2", publicationDate: Calendar.current.date(from: v0_1DateComponents)!, downloadURL: URL(string: "https://www.beamapp.co/downloads/someZipv0.2.zip")!)

        XCTAssertTrue(v0_2 > v0_1, "")
        XCTAssertTrue(v0_1 < v0_2, "")
    }

    func testVersionComparisonBuildDifferentDifferentFormat() {
        let v0_1DateComponents = DateComponents(year: 2020, month: 11, day: 20, hour: 17, minute: 45, second: 00)
        let v0_1 = AppRelease(versionName: "Version 0.1", version: "0.1.0", buildNumber: "1", releaseNotesMarkdown: "This is release notes from Beam 0.1", publicationDate: Calendar.current.date(from: v0_1DateComponents)!, downloadURL: URL(string: "https://www.beamapp.co/downloads/someZipv0.1.zip")!)

        let v0_1b = AppRelease(versionName: "Version 0.1", version: "0.1", buildNumber: "2", releaseNotesMarkdown: "This is release notes from Beam 0.1", publicationDate: Calendar.current.date(from: v0_1DateComponents)!, downloadURL: URL(string: "https://www.beamapp.co/downloads/someZipv0.2.zip")!)

        XCTAssertTrue(v0_1b > v0_1, "")
        XCTAssertTrue(v0_1 < v0_1b, "")
    }

    func testVersionComparisonBuildDottedDifferentDifferentFormat() {
        let v0_1DateComponents = DateComponents(year: 2020, month: 11, day: 20, hour: 17, minute: 45, second: 00)
        let v0_1 = AppRelease(versionName: "Version 0.1", version: "0.1.0", buildNumber: "20220126.164156", releaseNotesMarkdown: "This is release notes from Beam 0.1", publicationDate: Calendar.current.date(from: v0_1DateComponents)!, downloadURL: URL(string: "https://www.beamapp.co/downloads/someZipv0.1.zip")!)

        let v0_1b = AppRelease(versionName: "Version 0.1", version: "0.1", buildNumber: "20220127.164156", releaseNotesMarkdown: "This is release notes from Beam 0.1", publicationDate: Calendar.current.date(from: v0_1DateComponents)!, downloadURL: URL(string: "https://www.beamapp.co/downloads/someZipv0.2.zip")!)

        XCTAssertTrue(v0_1b > v0_1, "")
        XCTAssertTrue(v0_1 < v0_1b, "")
    }

    func testVersionEqualBuildDifferentDifferentFormat() {
        let v0_1DateComponents = DateComponents(year: 2020, month: 11, day: 20, hour: 17, minute: 45, second: 00)
        let v0_1 = AppRelease(versionName: "Version 0.1", version: "0.1.0", buildNumber: "1", releaseNotesMarkdown: "This is release notes from Beam 0.1", publicationDate: Calendar.current.date(from: v0_1DateComponents)!, downloadURL: URL(string: "https://www.beamapp.co/downloads/someZipv0.1.zip")!)

        let v0_1bis = AppRelease(versionName: "Version 0.1", version: "0.1", buildNumber: "2", releaseNotesMarkdown: "This is release notes from Beam 0.1", publicationDate: Calendar.current.date(from: v0_1DateComponents)!, downloadURL: URL(string: "https://www.beamapp.co/downloads/someZipv0.1.zip")!)

        let v0_1ter = AppRelease(versionName: "Version 0.1", version: "0.1", buildNumber: "2", releaseNotesMarkdown: "This is release notes from Beam 0.1", publicationDate: Calendar.current.date(from: v0_1DateComponents)!, downloadURL: URL(string: "https://www.beamapp.co/downloads/someZipv0.1.zip")!)

        XCTAssertNotEqual(v0_1, v0_1bis)
        XCTAssertEqual(v0_1ter, v0_1bis)
    }

    func testVersionEqualBuildDottedDifferentDifferentFormat() {
        let v0_1DateComponents = DateComponents(year: 2020, month: 11, day: 20, hour: 17, minute: 45, second: 00)
        let v0_1 = AppRelease(versionName: "Version 0.1", version: "0.1.0", buildNumber: "20220127.164155", releaseNotesMarkdown: "This is release notes from Beam 0.1", publicationDate: Calendar.current.date(from: v0_1DateComponents)!, downloadURL: URL(string: "https://www.beamapp.co/downloads/someZipv0.1.zip")!)

        let v0_1bis = AppRelease(versionName: "Version 0.1", version: "0.1", buildNumber: "20220127.164156", releaseNotesMarkdown: "This is release notes from Beam 0.1", publicationDate: Calendar.current.date(from: v0_1DateComponents)!, downloadURL: URL(string: "https://www.beamapp.co/downloads/someZipv0.1.zip")!)

        let v0_1ter = AppRelease(versionName: "Version 0.1", version: "0.1", buildNumber: "20220127.164156", releaseNotesMarkdown: "This is release notes from Beam 0.1", publicationDate: Calendar.current.date(from: v0_1DateComponents)!, downloadURL: URL(string: "https://www.beamapp.co/downloads/someZipv0.1.zip")!)

        XCTAssertNotEqual(v0_1, v0_1bis)
        XCTAssertEqual(v0_1ter, v0_1bis)
    }

    func testReleaseHistory() {

        let v0_1DateComponents = DateComponents(year: 2020, month: 11, day: 20, hour: 17, minute: 45, second: 00)
        let v0_1 = AppRelease(versionName: "Version 0.1", version: "0.1", buildNumber: "1", releaseNotesMarkdown: "This is release notes from Beam 0.1", publicationDate: Calendar.current.date(from: v0_1DateComponents)!, downloadURL: URL(string: "https://www.beamapp.co/downloads/someZipv0.1.zip")!)
        let v0_2 = AppRelease(versionName: "Version 0.2", version: "0.2", buildNumber: "1", releaseNotesMarkdown: "This is release notes from Beam 0.2", publicationDate: Calendar.current.date(from: v0_1DateComponents)!, downloadURL: URL(string: "https://www.beamapp.co/downloads/someZipv0.2.zip")!)
        let v0_3 = AppRelease(versionName: "Version 0.3", version: "0.3", buildNumber: "1", releaseNotesMarkdown: "This is release notes from Beam 0.3", publicationDate: Calendar.current.date(from: v0_1DateComponents)!, downloadURL: URL(string: "https://www.beamapp.co/downloads/someZipv0.2.zip")!)
        let v0_4 = AppRelease(versionName: "Version 0.4", version: "0.4", buildNumber: "1", releaseNotesMarkdown: "This is release notes from Beam 0.4", publicationDate: Calendar.current.date(from: v0_1DateComponents)!, downloadURL: URL(string: "https://www.beamapp.co/downloads/someZipv0.2.zip")!)

        let feed = [v0_1, v0_2, v0_3, v0_4]
        let checker = VersionChecker(mockedReleases: feed, fakeAppVersion: "0.2")

        let e = expectation(description: "check")

        checker.checkForUpdates()
        cancellable = checker.$state.sink { state in
            switch state {
            case .updateAvailable:
                let after0_2 = checker.releases(after: v0_2)
                XCTAssertTrue(after0_2.count == 2)

                let after0_3 = checker.releases(after: v0_3)
                XCTAssertTrue(after0_3.count == 1)

                let after0_4 = checker.releases(after: v0_4)
                XCTAssertTrue(after0_4.isEmpty)

                e.fulfill()
            default:
                break
            }
            print(state)
        }

        waitForExpectations(timeout: 5, handler: nil)
    }

    func testFileNameDecomposition() {
        let checker = VersionChecker(mockedReleases: sampleFeed, fakeAppVersion: "0.2")
        let url = URL(string: "https://www.beamapp.co/downloads/someZipv0.1.zip")!
        let (filename, ext) = checker.decomposedFilename(from: url)
        XCTAssertEqual(filename, "someZipv0.1")
        XCTAssertEqual(ext, "zip")
    }

    func testFileNameDecompositionNoExtension() {
        let checker = VersionChecker(mockedReleases: sampleFeed, fakeAppVersion: "0.2")
        let url = URL(string: "https://www.beamapp.co/downloads/someZip")!
        let (filename, ext) = checker.decomposedFilename(from: url)
        XCTAssertEqual(filename, "someZip")
        XCTAssertEqual(ext, "")
    }

    func testFindPendingReleasesOnDisk() {
        let tempFolder = createTempTestFolderIfNeeded()

        let checker = VersionChecker(mockedReleases: sampleFeed, fakeAppVersion: "0.2")
        let v0_1DateComponents = DateComponents(year: 2020, month: 11, day: 20, hour: 17, minute: 45, second: 00)

        let onDiskRelease0_5 = AppRelease(versionName: "Version 0.5", version: "0.5", buildNumber: "1", releaseNotesMarkdown: "This is release notes from Beam 0.4", publicationDate: Calendar.current.date(from: v0_1DateComponents)!, downloadURL: URL(string: "https://www.beamapp.co/downloads/someZip.zip")!)
        guard let fakeDownloadURL0_5 = generateFakeDownloadFile() else {
            XCTFail("Failed to generate download file")
            return
        }

        let onDiskRelease0_4 = AppRelease(versionName: "Version 0.4", version: "0.4", buildNumber: "1", releaseNotesMarkdown: "This is release notes from Beam 0.4", publicationDate: Calendar.current.date(from: v0_1DateComponents)!, downloadURL: URL(string: "https://www.beamapp.co/downloads/someZip.zip")!)
        guard let fakeDownloadURL0_4 = generateFakeDownloadFile() else {
            XCTFail("Failed to generate download file")
            return
        }

        _ = try? checker.saveDownloadedAppRelease(onDiskRelease0_4, archiveURL: fakeDownloadURL0_4, in: tempFolder)
        let onDiskSavedRelease0_5 = try? checker.saveDownloadedAppRelease(onDiskRelease0_5, archiveURL: fakeDownloadURL0_5, in: tempFolder)

        let pending = checker.findPendingReleases(in: tempFolder)
        XCTAssertTrue(pending.count == 2)

        guard let latest = pending.last else {
            XCTFail("No pending release found")
            return
        }
        XCTAssertEqual(latest, onDiskSavedRelease0_5)

        let installation = checker.checkForPendingInstallations(in: tempFolder)
        XCTAssertNotNil(installation)
        XCTAssertEqual(installation?.appRelease, onDiskRelease0_5)
    }

    func testJSONUpdate() {
        let feedURL = URL(string: "https://s3.eu-west-3.amazonaws.com/downloads.dev.beamapp.co/develop/AppFeed.json")!
        let newRelease = AppRelease(versionName: "Newest release", version: "3.0", buildNumber: "5", publicationDate: Date(), downloadURL: URL(string: "https://www.beamapp.co/downloads/someZipv0.1.zip")!)

        let e = expectation(description: "updateJSON")
        AppRelease.updateJSON(at: feedURL, with: newRelease) { data in
            guard let data = data else {
                XCTFail("Data should be returned")
                return
            }

            let decoder = JSONDecoder()
            let newFeed = try? decoder.decode([AppRelease].self, from: data)
            XCTAssertNotNil(newFeed)

            if let latest = newFeed?.last {
                XCTAssertEqual(latest, newRelease)
            } else {
                XCTFail("Feed not containing elements")
            }
            e.fulfill()
        }
        waitForExpectations(timeout: 30, handler: nil)
    }

    var sampleFeed: [AppRelease] {
        let v0_1DateComponents = DateComponents(year: 2020, month: 11, day: 20, hour: 17, minute: 45, second: 00)
        let v0_1 = AppRelease(versionName: "Version 0.1", version: "0.1", buildNumber: "1", releaseNotesMarkdown: "This is release notes from Beam 0.1", publicationDate: Calendar.current.date(from: v0_1DateComponents)!, downloadURL: URL(string: "https://www.beamapp.co/downloads/someZipv0.1.zip")!)
        let v0_2 = AppRelease(versionName: "Version 0.2", version: "0.2", buildNumber: "1", releaseNotesMarkdown: "This is release notes from Beam 0.2", publicationDate: Calendar.current.date(from: v0_1DateComponents)!, downloadURL: URL(string: "https://www.beamapp.co/downloads/someZipv0.2.zip")!)
        let v0_3 = AppRelease(versionName: "Version 0.3", version: "0.3", buildNumber: "1", releaseNotesMarkdown: "This is release notes from Beam 0.3", publicationDate: Calendar.current.date(from: v0_1DateComponents)!, downloadURL: URL(string: "https://www.beamapp.co/downloads/someZipv0.2.zip")!)
        let v0_4 = AppRelease(versionName: "Version 0.4", version: "0.4", buildNumber: "1", releaseNotesMarkdown: "This is release notes from Beam 0.4", publicationDate: Calendar.current.date(from: v0_1DateComponents)!, downloadURL: URL(string: "https://www.beamapp.co/downloads/someZipv0.2.zip")!)

        let feed = [v0_1, v0_2, v0_3, v0_4]
        return feed
    }

    private func createTempTestFolderIfNeeded() -> URL {
        let fileManager = FileManager.default
        let tempFolder = testTempFolderURL
        if !fileManager.fileExists(atPath: tempFolder.path) {
            try? fileManager.createDirectory(at: tempFolder, withIntermediateDirectories: true, attributes: nil)
        }
        return tempFolder
    }

    private func createTempDownloadFolderIfNeeded() -> URL {
        let fileManager = FileManager.default
        let tempFolder = testTempFolderURL.appendingPathComponent("downloads")
        if !fileManager.fileExists(atPath: tempFolder.path) {
            try? fileManager.createDirectory(at: tempFolder, withIntermediateDirectories: true, attributes: nil)
        }
        return tempFolder
    }

    private func cleanupTestFolderIfNeeded() {
        let fileManager = FileManager.default
        let tempFolder = testTempFolderURL
        if fileManager.fileExists(atPath: tempFolder.path) {
            try? fileManager.removeItem(at: tempFolder)
        }
    }

    private var testTempFolderURL: URL {
        let fileManager = FileManager.default
        let tempFolder = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("AutoUpdateTests")
        return URL(fileURLWithPath: tempFolder.path)
    }

    private func generateFakeDownloadFile() -> URL? {
        let downloadFolderURL = createTempDownloadFolderIfNeeded()
        let fakeData = Data()
        do {
            let writeURL = downloadFolderURL.appendingPathComponent(UUID().uuidString)
            try fakeData.write(to: writeURL)
            return writeURL
        } catch {
            return nil
        }
    }
}
