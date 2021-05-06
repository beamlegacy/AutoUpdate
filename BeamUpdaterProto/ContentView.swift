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
            Group {
                if let release = checker.newRelease {
                    Text("Your app version is \(checker.currentAppVersion()). New update available : \(release.version)")
                } else {
                    Text("Your app version is \(checker.currentAppVersion())")
                }
            }
            .font(.headline)
            Group {
                switch checker.state {
                case .neverChecked:
                    Text("You can check for updates")
                case .checking:
                    VStack(alignment: .leading) {
                        Text("Checking for updates…")
                        ProgressView()
                            .progressViewStyle(LinearProgressViewStyle())
                    }
                case .checked(let date):
                    HStack {
                        Text("Checked : ")
                        Text(date, style: .date)
                    }
                case .error(let error):
                    Text(error)
                case .downloading(let progress):
                    VStack(alignment: .leading) {
                        Text("Downloading updates…")
                        ProgressView(progress)
                    }
                case .installing:
                    VStack(alignment: .leading) {
                        Text("Installing updates…")
                        ProgressView()
                            .progressViewStyle(LinearProgressViewStyle())
                    }
                case .updateInstalled:
                    Text("App updated. Waiting for relaunch")
                }
            }
            .font(.callout)
            .foregroundColor(.gray)
            .padding(.top, 4)
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
        .frame(minWidth: 200, idealWidth: 200, maxWidth: .infinity, minHeight: 100, idealHeight: /*@START_MENU_TOKEN@*/100/*@END_MENU_TOKEN@*/, maxHeight: .infinity, alignment: .center)
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
