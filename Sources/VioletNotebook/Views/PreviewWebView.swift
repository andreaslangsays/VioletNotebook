import SwiftUI
import WebKit

struct PreviewWebView: NSViewRepresentable {
    let htmlContent: String
    let onDayLinkClick: (String) -> Void
    
    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        return webView
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
        context.coordinator.parent = self
        
        let styledHtml = """
        <html>
        <head>
        <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
            font-size: 14px;
            line-height: 1.6;
            padding: 16px;
            background-color: #ffffff;
            color: #1c1c1e;
        }
        @media (prefers-color-scheme: dark) {
            body {
                background-color: #1e1e1e;
                color: #f5f5f5;
            }
        }
        h1, h2, h3 { color: #5a2d82; }
        @media (prefers-color-scheme: dark) {
            h1, h2, h3 { color: #b18ce4; }
        }
        a { color: #7f34c2; text-decoration: none; }
        a:hover { text-decoration: underline; }
        .hashtag {
            color: #a855f7;
            font-weight: 500;
        }
        hr { border: 0; border-top: 1px solid #e2e8f0; margin: 16px 0; }
        @media (prefers-color-scheme: dark) {
            hr { border-top: 1px solid #475569; }
        }
        </style>
        </head>
        <body>
        \(htmlContent)
        </body>
        </html>
        """
        nsView.loadHTMLString(styledHtml, baseURL: nil)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: PreviewWebView
        
        init(_ parent: PreviewWebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let url = navigationAction.request.url {
                if url.scheme == "violet" && url.host == "day" {
                    let dateStr = url.lastPathComponent
                    parent.onDayLinkClick(dateStr)
                    decisionHandler(.cancel)
                    return
                } else if url.scheme != "about" {
                    NSWorkspace.shared.open(url)
                    decisionHandler(.cancel)
                    return
                }
            }
            decisionHandler(.allow)
        }
    }
}
