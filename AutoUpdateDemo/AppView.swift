//
//  AppView.swift
//  AutoUpdateDemo
//
//  Created by Ludovic Ollagnier on 07/05/2021.
//

import SwiftUI
import AutoUpdate

struct AppView: View {

    @StateObject var checker = VersionChecker(mockedReleases: AppRelease.mockedReleases(), autocheckEnabled: false)

    var body: some View {
        VStack {
            HStack {
                Toggle(isOn: $checker.allowAutoDownload, label: {
                    Text("Auto Download")
                })
                Toggle(isOn: $checker.allowAutoInstall, label: {
                    Text("Auto Install")
                })
            }
            UpdaterView(checker: checker)
        }.onAppear(perform: {
        })
    }
}

struct AppView_Previews: PreviewProvider {
    static var previews: some View {
        AppView()
    }
}
