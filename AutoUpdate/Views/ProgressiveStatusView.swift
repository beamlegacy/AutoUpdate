//
//  ProgressiveStatusView.swift
//  BeamUpdaterProto
//
//  Created by Ludovic Ollagnier on 06/05/2021.
//

import SwiftUI

struct ProgressiveStatusView: View {

    let title: String
    let subtitle: String
    let progress: Progress?

    var body: some View {
        VStack(alignment: .leading) {
            StatusView(title: title, subtitle: subtitle)
            if #available(macOS 11, *) {
                if let progress = progress {
                    ProgressView(progress)
                        .progressViewStyle(LinearProgressViewStyle())
                } else {
                    ProgressView()
                        .progressViewStyle(LinearProgressViewStyle())
                }
            }
        }
    }
}

struct ProgressiveStatusView_Previews: PreviewProvider {
    static var previews: some View {
        ProgressiveStatusView(title: "Undefined progress status view", subtitle: "This is the subtitle", progress: nil)
    }
}
