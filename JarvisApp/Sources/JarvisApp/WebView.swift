import SwiftUI
import WebKit

struct WebView: NSViewRepresentable {
    let url: URL

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "developerExtrasEnabled")

        // Allow media autoplay
        config.mediaTypesRequiringUserActionForPlayback = []

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true

        // Transparent background to avoid white flash
        webView.setValue(false, forKey: "drawsBackground")

        webView.load(URLRequest(url: url))
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        // Only reload if URL changed
        if webView.url != url {
            webView.load(URLRequest(url: url))
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ webView: WKWebView,
                     decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }

            // Open external links in default browser
            if navigationAction.navigationType == .linkActivated,
               url.host != "localhost" {
                NSWorkspace.shared.open(url)
                decisionHandler(.cancel)
                return
            }

            decisionHandler(.allow)
        }
    }
}

// MARK: - Reload support via NotificationCenter

extension Notification.Name {
    static let reloadWebView = Notification.Name("reloadWebView")
}

struct ReloadableWebView: View {
    let url: URL
    @State private var reloadID = UUID()

    var body: some View {
        WebView(url: url)
            .id(reloadID)
            .onReceive(NotificationCenter.default.publisher(for: .reloadWebView)) { _ in
                reloadID = UUID()
            }
    }
}
