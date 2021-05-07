//
//  BeamView.swift
//  BeamUpdaterProto
//
//  Created by Ludovic Ollagnier on 07/05/2021.
//

import SwiftUI
import AutoUpdate

struct BeamView: View {

    @StateObject var checker = VersionChecker(feedURL: URL(string: "https://raw.githubusercontent.com/eLud/update-proto/main/feed.json")!)

    var body: some View {
        UpdaterView(checker: checker)
    }
}

struct BeamView_Previews: PreviewProvider {
    static var previews: some View {
        BeamView()
    }
}
