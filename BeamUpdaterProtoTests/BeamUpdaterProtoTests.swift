//
//  BeamUpdaterProtoTests.swift
//  BeamUpdaterProtoTests
//
//  Created by Ludovic Ollagnier on 03/05/2021.
//

import XCTest
@testable import AutoUpdate

class BeamUpdaterProtoTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testVersionEqualitySameFormat() {
        let v0_1DateComponents = DateComponents(year: 2020, month: 11, day: 20, hour: 17, minute: 45, second: 00)
        let v0_1 = AppRelease(versionName: "Version 0.1", version: "0.1", buildNumber: 1, releaseNotes: "This is release notes from Beam 0.1", publicationDate: Calendar.current.date(from: v0_1DateComponents)!, downloadURL: URL(string: "https://www.beamapp.co/downloads/someZipv0.1.zip")!)

        let v0_1bis = AppRelease(versionName: "Version 0.1", version: "0.1", buildNumber: 1, releaseNotes: "This is release notes from Beam 0.1", publicationDate: Calendar.current.date(from: v0_1DateComponents)!, downloadURL: URL(string: "https://www.beamapp.co/downloads/someZipv0.1.zip")!)

        let v0_2 = AppRelease(versionName: "Version 0.2", version: "0.2", buildNumber: 1, releaseNotes: "This is release notes from Beam 0.2", publicationDate: Calendar.current.date(from: v0_1DateComponents)!, downloadURL: URL(string: "https://www.beamapp.co/downloads/someZipv0.2.zip")!)

        XCTAssertEqual(v0_1, v0_1bis)
        XCTAssertNotEqual(v0_1, v0_2)
    }

    func testVersionEqualityDifferentFormat() {
        let v0_1DateComponents = DateComponents(year: 2020, month: 11, day: 20, hour: 17, minute: 45, second: 00)
        let v0_1 = AppRelease(versionName: "Version 0.1", version: "0.1.0", buildNumber: 1, releaseNotes: "This is release notes from Beam 0.1", publicationDate: Calendar.current.date(from: v0_1DateComponents)!, downloadURL: URL(string: "https://www.beamapp.co/downloads/someZipv0.1.zip")!)

        let v0_1bis = AppRelease(versionName: "Version 0.1", version: "0.1", buildNumber: 1, releaseNotes: "This is release notes from Beam 0.1", publicationDate: Calendar.current.date(from: v0_1DateComponents)!, downloadURL: URL(string: "https://www.beamapp.co/downloads/someZipv0.1.zip")!)

        XCTAssertEqual(v0_1, v0_1bis)
    }

    func testVersionComparisonSameFormat() {
        let v0_1DateComponents = DateComponents(year: 2020, month: 11, day: 20, hour: 17, minute: 45, second: 00)
        let v0_1 = AppRelease(versionName: "Version 0.1", version: "0.1", buildNumber: 1, releaseNotes: "This is release notes from Beam 0.1", publicationDate: Calendar.current.date(from: v0_1DateComponents)!, downloadURL: URL(string: "https://www.beamapp.co/downloads/someZipv0.1.zip")!)

        let v0_2 = AppRelease(versionName: "Version 0.2", version: "0.2", buildNumber: 1, releaseNotes: "This is release notes from Beam 0.2", publicationDate: Calendar.current.date(from: v0_1DateComponents)!, downloadURL: URL(string: "https://www.beamapp.co/downloads/someZipv0.2.zip")!)

        XCTAssertTrue(v0_2 > v0_1, "")
        XCTAssertTrue(v0_1 < v0_2, "")
    }

    func testVersionComparisonDifferentFormat() {
        let v0_1DateComponents = DateComponents(year: 2020, month: 11, day: 20, hour: 17, minute: 45, second: 00)
        let v0_1 = AppRelease(versionName: "Version 0.1", version: "0.1.0", buildNumber: 1, releaseNotes: "This is release notes from Beam 0.1", publicationDate: Calendar.current.date(from: v0_1DateComponents)!, downloadURL: URL(string: "https://www.beamapp.co/downloads/someZipv0.1.zip")!)

        let v0_2 = AppRelease(versionName: "Version 0.2", version: "0.2", buildNumber: 1, releaseNotes: "This is release notes from Beam 0.2", publicationDate: Calendar.current.date(from: v0_1DateComponents)!, downloadURL: URL(string: "https://www.beamapp.co/downloads/someZipv0.2.zip")!)

        XCTAssertTrue(v0_2 > v0_1, "")
        XCTAssertTrue(v0_1 < v0_2, "")
    }

    func testVersionComparisonBuildDifferentDifferentFormat() {
        let v0_1DateComponents = DateComponents(year: 2020, month: 11, day: 20, hour: 17, minute: 45, second: 00)
        let v0_1 = AppRelease(versionName: "Version 0.1", version: "0.1.0", buildNumber: 1, releaseNotes: "This is release notes from Beam 0.1", publicationDate: Calendar.current.date(from: v0_1DateComponents)!, downloadURL: URL(string: "https://www.beamapp.co/downloads/someZipv0.1.zip")!)

        let v0_1b = AppRelease(versionName: "Version 0.1", version: "0.1", buildNumber: 2, releaseNotes: "This is release notes from Beam 0.1", publicationDate: Calendar.current.date(from: v0_1DateComponents)!, downloadURL: URL(string: "https://www.beamapp.co/downloads/someZipv0.2.zip")!)

        XCTAssertTrue(v0_1b > v0_1, "")
        XCTAssertTrue(v0_1 < v0_1b, "")
    }

    func testVersionEqualBuildDifferentDifferentFormat() {
        let v0_1DateComponents = DateComponents(year: 2020, month: 11, day: 20, hour: 17, minute: 45, second: 00)
        let v0_1 = AppRelease(versionName: "Version 0.1", version: "0.1.0", buildNumber: 1, releaseNotes: "This is release notes from Beam 0.1", publicationDate: Calendar.current.date(from: v0_1DateComponents)!, downloadURL: URL(string: "https://www.beamapp.co/downloads/someZipv0.1.zip")!)

        let v0_1bis = AppRelease(versionName: "Version 0.1", version: "0.1", buildNumber: 2, releaseNotes: "This is release notes from Beam 0.1", publicationDate: Calendar.current.date(from: v0_1DateComponents)!, downloadURL: URL(string: "https://www.beamapp.co/downloads/someZipv0.1.zip")!)

        let v0_1ter = AppRelease(versionName: "Version 0.1", version: "0.1", buildNumber: 2, releaseNotes: "This is release notes from Beam 0.1", publicationDate: Calendar.current.date(from: v0_1DateComponents)!, downloadURL: URL(string: "https://www.beamapp.co/downloads/someZipv0.1.zip")!)

        XCTAssertNotEqual(v0_1, v0_1bis)
        XCTAssertEqual(v0_1ter, v0_1bis)
    }

}
