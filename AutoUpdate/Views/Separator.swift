//
//  Separator.swift
//  AutoUpdate
//
//  Created by Ludovic Ollagnier on 02/08/2021.
//

import SwiftUI

struct Separator: View {

    var color: Color = .gray

    var body: some View {
        Rectangle()
            .fill(color)
            .frame(height: 1)
    }
}

struct Separator_Previews: PreviewProvider {
    static var previews: some View {
        Separator()
    }
}
