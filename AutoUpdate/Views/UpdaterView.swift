//
//  ContentView.swift
//  BeamUpdaterProto
//
//  Created by Ludovic Ollagnier on 03/05/2021.
//

import SwiftUI

public struct UpdaterView: View {

    @ObservedObject var checker: VersionChecker
    @State var showsReleaseNotes = false

    public init(checker: VersionChecker) {
        self.checker = checker
    }

    public var body: some View {
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
                VStack(alignment: .leading) {
                    StatusView(title: "Update available",
                               subtitle: "\(checker.currentAppName()) v.\(release.version) can be download and installed.")
                    Button("Release notes") {
                        showsReleaseNotes.toggle()
                    }
                    .sheet(isPresented: $showsReleaseNotes, content: {
                        ReleaseNoteView(release: release)
                            .frame(minWidth: 200, idealWidth: 340, maxWidth: 400, minHeight: 200, idealHeight: 370, maxHeight: 400)
                    })
                }

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

struct UpdaterView_Previews: PreviewProvider {

    static var checker = VersionChecker(mockData: AppRelease.demoJSON())

    static var previews: some View {
        UpdaterView(checker: checker)
    }
}
