//
//  ContentView.swift
//  BeamUpdaterProto
//
//  Created by Ludovic Ollagnier on 03/05/2021.
//

import SwiftUI

struct ContentView: View {

    @StateObject var checker = VersionChecker(mockData: AppRelease.demoJSON()!)

    var body: some View {
        VStack(alignment: .leading) {
            switch checker.state {
            case .noUpdate:
                if let lastCheck = checker.lastCheck {
                    VStack(alignment: .leading) {
                        Text("You are using \(checker.currentAppName()) \(checker.currentAppVersion())")
                            .font(.headline)
                        Text("Last check \(lastCheck)")
                            .font(.callout)
                    }
                } else {
                    VStack(alignment: .leading) {
                        Text("You are using \(checker.currentAppName()) \(checker.currentAppVersion())")
                            .font(.headline)
                        Text("Updates never checked")
                            .font(.callout)
                    }
                }
            case .checking:
                VStack(alignment: .leading) {
                    Text("You are using \(checker.currentAppName()) \(checker.currentAppVersion())")
                        .font(.headline)
                    Text("Checking for updates…")
                        .font(.callout)
                    ProgressView()
                }
            case .updateAvailable(release: let release):
                VStack(alignment: .leading) {
                    Text("Update available")
                        .font(.headline)
                    Text("\(checker.currentAppName()) v.\(release.version) can be download and installed.")
                        .font(.callout)
                }
            case .error(errorDesc: let errorDesc):
                VStack(alignment: .leading) {
                    Text("An error occured")
                        .font(.headline)
                    Text(errorDesc)
                        .font(.callout)
                }
            case .downloading(progress: let progress):
                VStack(alignment: .leading) {
                    Text("Downloading update")
                        .font(.headline)
                    ProgressView(progress)
                }
            case .installing:
                VStack(alignment: .leading) {
                    Text("Installing update")
                        .font(.headline)
                    ProgressView()
                }
            case .updateInstalled:
                VStack(alignment: .leading) {
                    Text("Update installed")
                        .font(.headline)
                    Text("Quit the app. The new version will automatically be launched.")
                        .font(.callout)
                }
            }
            Spacer()
            HStack {
                Spacer()
                if let release = checker.newRelease {
                    Button("Update to \(release.version)") {
                        checker.downloadNewestRelease()
                    }.disabled(downloadButtonDisabled())
                } else {
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
