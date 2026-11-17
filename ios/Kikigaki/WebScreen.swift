import SwiftUI
import WebKit

/// アプリに同梱した画面を表示する。画面からの AI の依頼は AIBridge が受ける。
struct WebScreen: UIViewRepresentable {
    func makeCoordinator() -> AIBridge { AIBridge() }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.userContentController.addScriptMessageHandler(context.coordinator, contentWorld: .page, name: "kikigaki")

        let web = WKWebView(frame: .zero, configuration: config)
        web.isOpaque = false
        web.backgroundColor = UIColor(red: 0.984, green: 0.973, blue: 0.933, alpha: 1)
        web.scrollView.bounces = false
        web.allowsLinkPreview = false
        if #available(iOS 16.4, *) { web.isInspectable = true }

        if let url = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "Web") {
            web.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }
        return web
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
