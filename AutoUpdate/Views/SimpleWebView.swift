//
//  SimpleWebView.swift
//  AutoUpdate
//
//  Created by Ludovic Ollagnier on 19/05/2021.
//

import SwiftUI
import Combine
import WebKit
import AppKit

/// A container for using a WKWebView in SwiftUI
public struct WebView: View {
    /// The WKWebView to display
    public let webView: WKWebView

    public init(webView: WKWebView = .init()) {
        self.webView = webView
    }
}

extension WebView: NSViewRepresentable {
    public typealias NSViewType = NSViewContainerView<WKWebView>

    public func makeNSView(context: Context) -> WebView.NSViewType {
        return NSViewContainerView()
    }

    public func updateNSView(_ view: WebView.NSViewType, context: Context) {
        if view.contentView !== webView {
            view.contentView = webView
        }
    }
}

public class NSViewContainerView<ContentView: NSView>: NSView {
    var contentView: ContentView? {
        willSet {
            contentView?.removeFromSuperview()
        }

        didSet {
            if let contentView = contentView {
                addSubview(contentView)
                contentView.translatesAutoresizingMaskIntoConstraints = false

                NSLayoutConstraint.activate([
                    contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
                    contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
                    contentView.topAnchor.constraint(equalTo: topAnchor),
                    contentView.bottomAnchor.constraint(equalTo: bottomAnchor)
                ])
            }
        }
    }
}
