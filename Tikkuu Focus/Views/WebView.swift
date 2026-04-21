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
    @Binding var loadError: Error?
    
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        
        // Load initial URL
        let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 30)
        webView.load(request)
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        // Only reload if URL has changed to avoid -999 cancelled error
        if webView.url != url {
            let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 30)
            webView.load(request)
        }
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
            DispatchQueue.main.async { [self] in
                self.parent.isLoading = true
                self.parent.loadError = nil
            }
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async { [self] in
                self.parent.isLoading = false
                self.parent.loadError = nil
            }
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            // Ignore cancelled error (-999)
            let nsError = error as NSError
            if nsError.code != NSURLErrorCancelled {
                DispatchQueue.main.async { [self] in
                    self.parent.isLoading = false
                    self.parent.loadError = error
                }
            }
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            // Ignore cancelled error (-999)
            let nsError = error as NSError
            if nsError.code != NSURLErrorCancelled {
                DispatchQueue.main.async { [self] in
                    self.parent.isLoading = false
                    self.parent.loadError = error
                }
            }
        }
        
        // Allow all navigation
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            decisionHandler(.allow)
        }
    }
}

/// Privacy Policy View
struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = true
    @State private var loadError: Error?
    @State private var retryTrigger = UUID()
    var onClose: (() -> Void)? = nil
    
    // URL will be configurable
    private var privacyPolicyURL: URL {
        if let url = URL(string: AppConfig.privacyPolicyURL) {
            return url
        }
        return URL(string: "https://cheng-liang1.github.io/App-Support/Roam%20Focus/privacy/index.html")!
    }
    
    private func closePage() {
        if let onClose {
            onClose()
        } else {
            dismiss()
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()

                WebView(url: privacyPolicyURL, isLoading: $isLoading, loadError: $loadError)
                    .id(retryTrigger)

                if isLoading && loadError == nil {
                    loadingOverlay
                        .transition(.opacity)
                }

                if let error = loadError, !isLoading {
                    errorOverlay(error: error)
                        .transition(.opacity.combined(with: .scale))
                }
            }
            .navigationTitle(L("settings.privacy"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L("common.done")) {
                        closePage()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    // MARK: - Loading Overlay
    
    private var loadingOverlay: some View {
        VStack(spacing: 0) {
            Spacer()
            HStack(spacing: 10) {
                ProgressView()
                    .tint(.primary)
                
                Text(L("common.loading"))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            Spacer()
        }
        .allowsHitTesting(false)
    }
    
    // MARK: - Error Overlay
    
    private func errorOverlay(error: Error) -> some View {
        ZStack {
            Rectangle()
                .fill(Color.black.opacity(0.2))
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                Image(systemName: "wifi.exclamationmark")
                    .font(.system(size: 38, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(L("privacy.error.title"))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(error.localizedDescription)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(4)
                
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        loadError = nil
                        isLoading = true
                        retryTrigger = UUID()
                    }
                } label: {
                    Text(L("privacy.error.retry"))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(.thinMaterial)
                        )
                }
            }
            .padding(.horizontal, 26)
            .padding(.vertical, 28)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.primary.opacity(0.1), lineWidth: 0.8)
                    )
            )
            .padding(.horizontal, 24)
        }
    }
}

#Preview {
    PrivacyPolicyView()
}
