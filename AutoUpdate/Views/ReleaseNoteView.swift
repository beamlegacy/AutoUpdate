//
//  ReleaseNoteView.swift
//  AutoUpdate
//
//  Created by Ludovic Ollagnier on 07/05/2021.
//

import SwiftUI
import Parma

public struct ReleaseNoteView: View {

    public struct ReleaseNoteViewStyle {

        public init(titleFont: Font = .headline, titleColor: Color = Color(.labelColor), buttonFont: Font = .headline, buttonColor: Color = Color(.secondaryLabelColor), buttonHoverColor: Color = Color(.labelColor), closeButtonColor: Color = Color(.secondaryLabelColor), closeButtonHoverColor: Color = Color(.labelColor), dateFont: Font = .body, dateColor: Color = Color(.secondaryLabelColor), versionNameFont: Font = .headline, versionNameColor: Color = Color(.labelColor), backgroundColor: Color = Color(.windowBackgroundColor), cellHoverColor: Color = .gray, separatorColor: Color = .gray, separatorView: AnyView? = nil, parmaRenderer: ParmaRenderable? = nil) {
            self.titleFont = titleFont
            self.titleColor = titleColor
            self.buttonFont = buttonFont
            self.actionButtonColor = buttonColor
            self.actionButtonHoverColor = buttonHoverColor
            self.closeButtonColor = closeButtonColor
            self.closeButtonHoverColor = closeButtonHoverColor
            self.dateFont = dateFont
            self.dateColor = dateColor
            self.versionNameFont = versionNameFont
            self.versionNameColor = versionNameColor
            self.parmaRenderer = parmaRenderer
            self.backgroundColor = backgroundColor
            self.cellHoverColor = cellHoverColor
            self.separatorColor = separatorColor
            self.separatorView = separatorView
        }

        public var titleFont: Font
        public var titleColor: Color
        public var buttonFont: Font
        public var actionButtonColor: Color
        public var actionButtonHoverColor: Color
        public var closeButtonColor: Color
        public var closeButtonHoverColor: Color
        public var dateFont: Font
        public var dateColor: Color
        public var versionNameFont: Font
        public var versionNameColor: Color
        public var parmaRenderer: ParmaRenderable?
        public var backgroundColor: Color
        public var cellHoverColor: Color
        public var separatorColor: Color
        public var separatorView: AnyView?

        var noteViewStyle: NoteView.NoteViewStyle {
            return .init(dateFont: dateFont, dateColor: dateColor, versionNameFont: versionNameFont, versionNameColor: versionNameColor, separatorColor: separatorColor, separatorView: separatorView, backgroundColor: backgroundColor, cellHoverColor: cellHoverColor, parmaRenderer: parmaRenderer)
        }
    }

    private let release: AppRelease
    private let history: [AppRelease]?
    private let checker: VersionChecker?
    private let style: ReleaseNoteViewStyle
    private let closeAction: () -> Void
    private let onActionButtonClickAdditionalAction: (() -> Void)?
    private let showMissedReleasesRecap: Bool
    private let showInlineNotes: Bool

    @State private var showsVersionAndBuild = false
    @State private var onHoverCloseButton = false
    @State private var onHoverActionButton = false

    public init(release: AppRelease, closeAction: @escaping () -> Void, beforeInstallAction: (() -> Void)? = nil, history: [AppRelease]? = nil, checker: VersionChecker? = nil, style: ReleaseNoteViewStyle = ReleaseNoteViewStyle(), showMissedReleasesRecap: Bool = false, showInlineNotes: Bool = false) {
        self.release = release
        self.checker = checker
        self.history = history
        self.style = style
        self.closeAction = closeAction
        self.onActionButtonClickAdditionalAction = beforeInstallAction
        self.showMissedReleasesRecap = showMissedReleasesRecap
        self.showInlineNotes = showInlineNotes
    }

    private var separator: some View {
        Group {
            if let separatorView = style.separatorView {
                separatorView
            } else {
                Separator(color: style.separatorColor)
            }
        }
    }

    public var body: some View {
        VStack(alignment: .leading) {
            HStack(spacing: 14) {
                VStack(alignment: .leading) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Changelog")
                            .font(style.titleFont)
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
                    }
                    if let history = history, history.count > 1, showMissedReleasesRecap {
                        Text("\(history.count) updates since you last updated")
                            .foregroundColor(Color(.secondaryLabelColor))
                    }
                }
                Spacer()
                if let checker = checker {
                    if let allNotesURL = checker.allReleaseNotesURL {
                        Button(action: {
                            NSWorkspace.shared.open(allNotesURL)
                        }, label: {
                            Text("View all")
                        })
                        .buttonStyle(BorderlessButtonStyle())
                    }
                    switch checker.state {
                    case .updateAvailable:
                        Button(action: {
                            onActionButtonClickAdditionalAction?()
                            checker.downloadNewestRelease()
                        }, label: {
                            Text("Update now")
                        })
                        .foregroundColor(onHoverActionButton ? style.actionButtonHoverColor : style.actionButtonColor)
                        .buttonStyle(BorderlessButtonStyle())
                        .onHover { h in
                            onHoverActionButton = h
                        }
                    case .downloaded(let release):
                        Button(action: {
                            onActionButtonClickAdditionalAction?()
                            checker.processInstallation(archiveURL: release.archiveURL, autorelaunch: true)
                        }, label: {
                            Text("Update now")
                        })
                        .foregroundColor(onHoverActionButton ? style.actionButtonHoverColor : style.actionButtonColor)
                        .buttonStyle(BorderlessButtonStyle())
                        .onHover { h in
                            onHoverActionButton = h
                        }
                    default:
                        EmptyView()
                    }
                }
                Button(action: {
                    withAnimation {
                        closeAction()
                    }
                }, label: {
                    Image("close", bundle: Bundle(for: VersionChecker.self))
                        .renderingMode(.template)
                        .foregroundColor(onHoverCloseButton ? style.closeButtonHoverColor : style.closeButtonColor)
                        .animation(.easeInOut, value: onHoverCloseButton)
                        .onHover { h in
                            onHoverCloseButton = h
                        }
                })
                .buttonStyle(BorderlessButtonStyle())
            }
            .padding(.leading, 12)
            .padding(.trailing, 12)
            .padding(.top, 12)
            separator
                .padding(.horizontal, 12)
                .padding(.top, 4)
                .padding(.bottom, -6)
            content
        }
        .background(style.backgroundColor)
        .frame(minWidth: 284, maxWidth: 284, maxHeight: 370)
    }

    @ViewBuilder var content: some View {
        let releases = history ?? [release]
        let noteView = NoteView(releases: releases, style: style.noteViewStyle, showInlineNotes: showInlineNotes, showSeparator: releases.count > 1)

        if releases.count == 1 {
            noteView
                .padding(.bottom, 10)
        } else {
            ScrollView {
                noteView
            }.frame(height: min(CGFloat(releases.count) * 65, 260))
        }
    }
}

struct ReleaseNoteView_Previews: PreviewProvider {

    static let v2 = AppRelease(versionName: "Beam 2.0: Collaborate on Cards",
                               version: "2.0",
                               buildNumber: "50",
                               releaseNotesMarkdown: releaseNotes,
                               releaseNoteURL: URL(string: "https://www.test.com"),
                               publicationDate: Date(),
                               downloadURL: URL(string: "http://")!)

    static let v1_5 = AppRelease(versionName: "Beam 1.5: To Infinity, beyond, beyond and beyond",
                                 version: "1.5",
                                 buildNumber: "30",
                                 releaseNotesMarkdown: "This is Beam 1.5. \nMany improvements.",
                                 releaseNoteURL: URL(string: "https://www.test.com"),
                                 publicationDate: Date(),
                                 downloadURL: URL(string: "http://")!)

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
        let checker = VersionChecker(mockedReleases: AppRelease.mockedReleases())
        checker.allReleaseNotesURL = URL(string: "http://")

        return Group {
            ReleaseNoteView(release: v2, closeAction: {}, history: [v2, v1_5])
            ReleaseNoteView(release: v2, closeAction: {}, history: [v2, v1_5], showMissedReleasesRecap: true)
            ReleaseNoteView(release: v2, closeAction: {})
            ReleaseNoteView(release: v2, closeAction: {})
            ReleaseNoteView(release: v2, closeAction: {}, history: nil, checker: checker)
        }
    }
}

struct NoteView: View {

    struct NoteViewStyle {
        var dateFont: Font = .body
        var dateColor: Color = .gray
        var versionNameFont: Font = .headline
        var versionNameColor: Color = Color(.labelColor)
        var separatorColor: Color = .gray
        var separatorView: AnyView?
        var backgroundColor: Color = Color(.windowBackgroundColor)
        var cellHoverColor: Color = .gray

        var parmaRenderer: ParmaRenderable?
    }

    static let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .long

        return df
    }()

    let releases: [AppRelease]
    let style: NoteViewStyle
    let showInlineNotes: Bool
    let showSeparator: Bool

    @State private var releaseHovered: AppRelease?

    private var separator: some View {
        Group {
            if let separatorView = style.separatorView {
                separatorView
            } else {
                Separator(color: style.separatorColor)
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(releases) { release in
                VStack(alignment: .leading, spacing: 6) {
                    dateText(for: release.publicationDate)
                        .font(style.dateFont)
                        .foregroundColor(style.dateColor)
                        .padding(.top, 10)
                    Text(release.versionName)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .font(style.versionNameFont)
                        .foregroundColor(style.versionNameColor)
                        .multilineTextAlignment(.leading)
                    if let notes = release.releaseNotesMarkdown, showInlineNotes {
                        Parma(notes, render: style.parmaRenderer)
                            .padding(.top, 5)
                    }
                    separator
                        .opacity(showSeparator ? 1.0 : 0.0)
                        .padding(.top, 8)
                        .padding(.bottom, 2)
                }
                .padding(.horizontal)
                .onHover(perform: { hovering in
                    guard release.releaseNoteURL != nil else { return }

                    if hovering {
                        releaseHovered = release
                    } else if !hovering && releaseHovered == release {
                        releaseHovered = nil
                    }
                })
                .background(cellBackground(for: release))
                .animation(.easeIn(duration: 0.2), value: releaseHovered)
                .transition(.opacity)
                .onTapGesture {
                    if let releaseURL = release.releaseNoteURL {
                        NSWorkspace.shared.open(releaseURL)
                    }
                }
            }
        }
    }

    private func cellBackground(for release: AppRelease) -> some View {
        let color = release == releaseHovered ? style.cellHoverColor : style.backgroundColor
        return color.offset(y: -2)
    }

    private func dateText(for date: Date) -> Text {
        let formattedDate = Self.dateFormatter.string(from: date)
        return Text(formattedDate)
    }
}
