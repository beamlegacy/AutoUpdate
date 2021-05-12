//
//  AppView.swift
//  AutoUpdateDemo
//
//  Created by Ludovic Ollagnier on 07/05/2021.
//

import SwiftUI
import AutoUpdate

struct AppView: View {

    @StateObject var checker = VersionChecker(mockData: AppRelease.demoJSON(), autocheckEnabled: true)

    var body: some View {
        UpdaterView(checker: checker)
    }
}

struct AppView_Previews: PreviewProvider {
    static var previews: some View {
        AppView()
    }
}
