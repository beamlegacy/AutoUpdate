//
//  ContentView.swift
//  BeamUpdaterProto
//
//  Created by Ludovic Ollagnier on 03/05/2021.
//

import SwiftUI

struct ContentView: View {

    @StateObject var checker = VersionChecker(feedURL: URL(string: "https://raw.githubusercontent.com/eLud/update-proto/main/feed.json")!)

    var body: some View {
        VStack(alignment: .leading) {
            switch checker.state {
            case .noUpdate:
                if let lastCheck = checker.lastCheck {
                    StatusView(title: "You are using \(checker.currentAppName()) \(checker.currentAppVersion())",
                               subtitle: "Last check \(lastCheck)")
                } else {
                    StatusView(title: "You are using \(checker.currentAppName()) \(checker.currentAppVersion())",
                               subtitle: "Updates never checked")
                }
            case .checking:
                ProgressiveStatusView(title: "You are using \(checker.currentAppName()) \(checker.currentAppVersion())",
                                      subtitle: "Checking for updates…", progress: nil)

            case .updateAvailable(release: let release):
                StatusView(title: "Update available",
                           subtitle: "\(checker.currentAppName()) v.\(release.version) can be download and installed.")

            case .error(errorDesc: let errorDesc):
                StatusView(title: "An error occured",
                           subtitle: errorDesc)

            case .downloading(progress: let progress):
                ProgressiveStatusView(title: "Downloading update",
                                      subtitle: "",
                                      progress: progress)

            case .installing:
                ProgressiveStatusView(title: "Installing update…",
                                      subtitle: "",
                                      progress: nil)
            case .updateInstalled:
                StatusView(title: "Update installed.",
                           subtitle: "Quit the app. The new version will automatically be launched.")
            }
            Spacer()
            HStack {
                Spacer()
                switch checker.state {
                case .updateAvailable(release: let release):
                    Button("Update to \(release.version)") {
                        checker.downloadNewestRelease()
                    }.disabled(downloadButtonDisabled())
                case .updateInstalled:
                    Button("Relaunch") {
                        NSApp.terminate(self)
                    }
                default:
                    Button("Check for updates") {
                        checker.checkForUpdates()
                    }.disabled(checker.state == .checking)
                }
            }
        }
        .padding()
        .frame(minWidth: 200, idealWidth: 200, maxWidth: .infinity, minHeight: 100, idealHeight: 100, maxHeight: .infinity, alignment: .center)
        .onChange(of: checker.state, perform: { value in
            print(value)
        })
    }

    private func downloadButtonDisabled() -> Bool {
        switch checker.state {
        case .downloading, .installing:
            return true
        default:
            return false
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
