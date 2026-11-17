//
//  ArticleView.swift
//  RAU.am
//
//  Created by artak on 7.11.26.
//  Copyright © 2026 Russian-Armenian University. All rights reserved.
//


import SwiftUI
import WebKit
import NetworkLayer

// MARK: - HTML

extension String {
    var htmlEscaped: String {
        replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}

/// Builds a complete, mobile-friendly HTML page from a post (the API's `description` is HTML).
enum ArticleHTML {
    static func make(post: Post, gallery: [GalleryImage], language: AppLanguage) -> String {
        let heroURL = (post.banner ?? post.image)?.absoluteString
        let hero = heroURL.map { "<img class=\"hero\" src=\"\($0.htmlEscaped)\">" } ?? ""
        let lead = post.subtitle.map { "<p class=\"lead\">\($0.htmlEscaped)</p>" } ?? ""
        let photos = gallery.isEmpty ? "" : "<div class=\"gallery\">"
            + gallery.map { "<img src=\"\($0.url.absoluteString.htmlEscaped)\">" }.joined()
            + "</div>"

        return """
        <!DOCTYPE html>
        <html>
        <head>
        <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
        <style>\(css)</style>
        </head>
        <body>
        \(hero)
        <h1>\(post.title.htmlEscaped)</h1>
        <div class="meta">\(language.dateString(post.date).htmlEscaped)</div>
        \(lead)
        <div class="content">\(post.description ?? "")</div>
        \(photos)
        </body>
        </html>
        """
    }

    private static let css = """
    :root { color-scheme: light dark; }
    body { font: -apple-system-body; line-height: 1.55; margin: 0; padding: 0 16px 40px; color: #1b1f24; background: transparent; }
    h1 { font-size: 1.5em; line-height: 1.25; margin: 4px 0 6px; color: #14315C; }
    .meta { color: #B3202A; font-size: 0.85em; font-weight: 600; margin-bottom: 14px; }
    .lead { font-weight: 600; margin: 0 0 14px; }
    a { color: #B3202A; }
    img { max-width: 100% !important; height: auto !important; width: auto !important; float: none !important;
          display: block; margin: 12px auto !important; border-radius: 10px; }
    img.hero { width: calc(100% + 32px) !important; max-width: none !important; margin: 0 -16px 14px !important; border-radius: 0; }
    .gallery img { margin: 10px auto !important; }
    @media (prefers-color-scheme: dark) {
      body { color: #e8eaed; }
      h1 { color: #ffffff; }
      a { color: #ff8a8f; }
    }
    """
}

// MARK: - Web view

struct ArticleWebView: UIViewRepresentable {
    let html: String

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = false   // static content only
        let web = WKWebView(frame: .zero, configuration: configuration)
        web.navigationDelegate = context.coordinator
        web.isOpaque = false
        web.backgroundColor = .clear
        web.scrollView.backgroundColor = .clear
        return web
    }

    func updateUIView(_ web: WKWebView, context: Context) {
        guard context.coordinator.loadedHTML != html else { return }
        context.coordinator.loadedHTML = html
        web.loadHTMLString(html, baseURL: URL(string: "https://rau.am"))
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        var loadedHTML = ""

        /// Links inside the article open in the system browser instead of replacing the article.
        func webView(_ webView: WKWebView,
                     decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if navigationAction.navigationType == .linkActivated, let url = navigationAction.request.url {
                UIApplication.shared.open(url)
                decisionHandler(.cancel)
            } else {
                decisionHandler(.allow)
            }
        }
    }
}

// MARK: - Screen

struct ArticleView: View {
    @EnvironmentObject private var app: AppModel
    let post: Post
    @State private var gallery: [GalleryImage] = []

    var body: some View {
        ArticleWebView(html: ArticleHTML.make(post: post, gallery: gallery, language: app.language))
            .ignoresSafeArea(edges: .bottom)
            .navigationTitle(post.group == "anons" ? L10n.announcements.text(app.language) : L10n.news.text(app.language))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if let url = post.url { ShareLink(item: url) }
                }
            }
            .task(id: post.id) { await loadGallery() }
    }

    /// The list already contains the full text; the detail endpoint only adds the photo gallery.
    private func loadGallery() async {
        guard let permalink = post.permalink, !permalink.hasPrefix("http") else { return }
        do {
            let detail: PostDetail
            if post.group == "anons" {
                detail = try await app.api.announcements.detail(permalink: permalink)
            } else {
                detail = try await app.api.news.detail(permalink: permalink)
            }
            gallery = detail.gallery
        } catch {
            // The gallery is optional – ignore failures and keep showing the article text.
        }
    }
}
