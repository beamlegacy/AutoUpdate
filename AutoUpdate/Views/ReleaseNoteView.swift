//
//  ReleaseNoteView.swift
//  AutoUpdate
//
//  Created by Ludovic Ollagnier on 07/05/2021.
//

import SwiftUI
import Parma

public struct ReleaseNoteView: View {

    static let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium

        return df
    }()

    private let release: AppRelease
    private let checker: VersionChecker?

    @Environment(\.presentationMode) var presentationMode

    @State private var showsVersionAndBuild = false

    public init(release: AppRelease, checker: VersionChecker? = nil) {
        self.release = release
        self.checker = checker
    }

    public var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Changelog")
                    .font(.headline)
                    .onTapGesture {
                        withAnimation {
                            showsVersionAndBuild.toggle()
                        }
                    }
                if showsVersionAndBuild {
                    Text("(v.\(release.version), build \(release.buildNumber))")
                        .font(.subheadline)
                        .foregroundColor(Color(.secondaryLabelColor))
                }
                Spacer()
                if let checker = checker {
                    Button("Update now") {
                        checker.downloadNewestRelease()
                    }
                }
                Button(action: {
                    withAnimation {
                        presentationMode.wrappedValue.dismiss()
                    }
                }, label: {
                    Image("close", bundle: Bundle(for: VersionChecker.self))
                })
                .buttonStyle(BorderlessButtonStyle())
            }
            Divider()
                .padding(.horizontal)
            dateText
                .foregroundColor(.gray)
            Text(release.versionName)
                .font(.headline)
            ScrollView {
                Parma(release.mardownReleaseNotes)
            }
        }
        .padding(.leading)
        .padding(.trailing)
        .padding(.top)
        .background(Color.white)
        .cornerRadius(6.0)
        .shadow(radius: 10)
        .frame(minWidth: 200, idealWidth: 340, maxWidth: 400, minHeight: 200, idealHeight: 370, maxHeight: 400)
    }

    private var dateText: Text {
        let formattedDate = Self.dateFormatter.string(from: release.publicationDate)
        return Text(formattedDate)
            .foregroundColor(.gray)
    }
}

struct ReleaseNoteView_Previews: PreviewProvider {

    static let releaseNotes = """
    # Beam 2.0 : Collaborate on Cards

    - Pharetra, malesuada tellus amet orci iaculis et. In nunc, augue in orci netus maecenas. In eget arcu a augue. Dui pulvinar pellentesque.
    - Tempor sit erat amet parturient pretium nunc.
    - Urna arcu libero, neque, placerat risus porta commodo, nulla. Diam ac aliquam velit ipsum.
    - Et nulla sed justo facilisi. Lobortis ligula a nisl.
    - Nunc, morbi praesent non suscipit. In massa purus quis molestie. Nam lectus massa mattis fringilla quam. Vel tortor quis a sit tellus lorem amet placerat tellus. Semper dui massa phasellus nisl.
    - At amet nibh nibh nibh elementum. In sagittis consectetur ut massa pulvinar.
    """

    static var previews: some View {
        Group {
            ReleaseNoteView(release: AppRelease(versionName: "Beam 2.0: Collaborate on Cards",
                                                version: "2.0",
                                                buildNumber: 50,
                                                mardownReleaseNotes: releaseNotes,
                                                publicationDate: Date(),
                                                downloadURL: URL(string: "http://")!))
                .frame(width: 340.0, height: 370.0)
            ReleaseNoteView(release: AppRelease(versionName: "Beam 2.0: Collaborate on Cards",
                                                version: "2.0",
                                                buildNumber: 50,
                                                mardownReleaseNotes: releaseNotes,
                                                publicationDate: Date(),
                                                downloadURL: URL(string: "http://")!))
        }
    }
}
