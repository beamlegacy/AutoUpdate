//
//  StatusView.swift
//  BeamUpdaterProto
//
//  Created by Ludovic Ollagnier on 06/05/2021.
//

import SwiftUI

struct StatusView: View {

    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5.0) {
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.callout)
                .foregroundColor(.gray)
        }
    }
}

struct StatusView_Previews: PreviewProvider {
    static var previews: some View {
        StatusView(title: "Installing", subtitle: "Please wait…")
    }
}
