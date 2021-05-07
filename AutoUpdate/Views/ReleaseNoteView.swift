//
//  ReleaseNoteView.swift
//  AutoUpdate
//
//  Created by Ludovic Ollagnier on 07/05/2021.
//

import SwiftUI

public struct ReleaseNoteView: View {

    let release: AppRelease

    public var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Changelog")
                    .font(.headline)
                Spacer()
                Button(action: {}, label: {
                    Image(systemName: "xmark")
                        .font(.headline)
                })
                .buttonStyle(BorderlessButtonStyle())
            }
            .padding(.leading)
            .padding(.trailing)
            .padding(.top)
            Divider()
                .padding(.horizontal)
            ScrollView {
                VStack(alignment: .leading, spacing: 4.0) {
                    Text(release.publicationDate, style: .date)
                        .foregroundColor(.gray)
                    Text(release.versionName)
                        .font(.headline)
                    Text(release.releaseNotes)
                        .padding(.vertical)
                }.padding()
            }
        }
        .background(Color.white)
        .cornerRadius(6.0)
        .shadow(radius: 10)
    }
}

struct ReleaseNoteView_Previews: PreviewProvider {

    static let notes = """
        • Pharetra, malesuada tellus amet orci iaculis et. In nunc, augue in orci netus maecenas. In eget arcu a augue. Dui pulvinar pellentesque.

        • Tempor sit erat amet parturient pretium nunc.

        • Urna arcu libero, neque, placerat risus porta commodo, nulla. Diam ac aliquam velit ipsum.

        • Et nulla sed justo facilisi. Lobortis ligula a nisl.

        • Nunc, morbi praesent non suscipit. In massa purus quis molestie. Nam lectus massa mattis fringilla quam. Vel tortor quis a sit tellus lorem amet placerat tellus. Semper dui massa phasellus nisl.

        • At amet nibh nibh nibh elementum. In sagittis consectetur ut massa pulvinar.
        """
    static var previews: some View {
        Group {
            ReleaseNoteView(release: AppRelease(versionName: "Beam 2.0: Collaborate on Cards",
                                                version: "2.0",
                                                releaseNotes: notes,
                                                publicationDate: Date(),
                                                downloadURL: URL(string: "http://")!))
                .frame(width: 340.0, height: 370.0)
            ReleaseNoteView(release: AppRelease(versionName: "Beam 2.0: Collaboarte on Cards",
                                                version: "2.0",
                                                releaseNotes: notes,
                                                publicationDate: Date(),
                                                downloadURL: URL(string: "http://")!))
        }
    }
}
