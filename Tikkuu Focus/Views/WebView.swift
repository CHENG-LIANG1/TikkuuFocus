//
//  WebView.swift
//  Tikkuu Focus
//
//  Created by Tikkuu on 2026/2/10.
//

import SwiftUI
import WebKit

/// Simple WebView wrapper for displaying web content
struct WebView: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView
        
        init(_ parent: WebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.isLoading = true
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
        }
    }
}

/// Privacy Policy View with WebView
struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = true
    
    // URL will be configurable
    private var privacyPolicyURL: URL {
        // Placeholder URL - will be replaced with actual URL
        if let url = URL(string: AppConfig.privacyPolicyURL) {
            return url
        }
        // Fallback URL
        return URL(string: "https://cheng-liang1.github.io/App-Support/Roam%20Focus/privacy/index.html")!
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // WebView
                WebView(url: privacyPolicyURL, isLoading: $isLoading)
                    .ignoresSafeArea(edges: .bottom)
                
                // Loading indicator
                if isLoading {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(.white)
                            
                            Text(L("common.loading"))
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.ultraThinMaterial)
                        )
                    }
                }
            }
            .navigationTitle(L("settings.privacy"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L("common.done")) {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    PrivacyPolicyView()
}
