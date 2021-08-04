//
//  VersionChecker+Extensions.swift
//  AutoUpdate
//
//  Created by Ludovic Ollagnier on 03/08/2021.
//

import Foundation

// MARK: - Helper functions
extension VersionChecker {

    func currentAppVersion() -> String {
        if let fake = fakeAppVersion {
            return fake
        }

        guard let infos = Bundle.main.infoDictionary,
              let version = infos["CFBundleShortVersionString"] as? String else { fatalError("Cant' get app's version from CFBundleShortVersionString key in Info.plist")
        }
        return version
    }

    func currentAppBuild() -> Int {
        if let fake = fakeAppBuild {
            return fake
        }

        guard let infos = Bundle.main.infoDictionary,
              let version = infos["CFBundleVersion"] as? String,
              let intVersion = Int(version) else { fatalError("Cant' get app's build from CFBundleVersion key in Info.plist, or it's not an Int number. We only support comparing Int build number.")
        }
        return intVersion
    }

    func currentAppName() -> String {
        guard let infos = Bundle.main.infoDictionary,
              let name = infos["CFBundleName"] as? String else { fatalError("Cant' get app's name from CFBundleName key in Info.plist")
        }
        return name
    }

    var applicationSupportDirectoryURL: URL? {
        let fileManager = FileManager.default
        return fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
    }

    func applicationDirectory(in applicationSupportURL: URL) -> URL {
        let appDirectory = applicationSupportURL.appendingPathComponent(self.currentAppName())
        return appDirectory
    }

    func updateDirectory(in applicationSupportURL: URL) -> URL {
        let appDirectory = applicationDirectory(in: applicationSupportURL)
        let updateDirectory = appDirectory.appendingPathComponent("Updates")
        return updateDirectory
    }
}
