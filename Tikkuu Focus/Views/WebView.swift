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

/// Privacy Policy View with Immersive WebView
struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = true
    @State private var loadError: Error?
    @State private var retryTrigger = UUID()
    @State private var dragOffset: CGFloat = 0
    @State private var contentVisible = false
    
    // URL will be configurable
    private var privacyPolicyURL: URL {
        if let url = URL(string: AppConfig.privacyPolicyURL) {
            return url
        }
        return URL(string: "https://cheng-liang1.github.io/App-Support/Roam%20Focus/privacy/index.html")!
    }
    
    private var dragThreshold: CGFloat { UIScreen.main.bounds.height * 0.25 }
    
    var body: some View {
        ZStack {
            immersiveBackground
            
            // Full screen WebView
            WebView(url: privacyPolicyURL, isLoading: $isLoading, loadError: $loadError)
                .id(retryTrigger)
                .ignoresSafeArea()
                .offset(y: dragOffset)
                .scaleEffect(contentVisible ? 1.0 : 0.985)
                .opacity(contentVisible ? 1.0 : 0.25)
                .animation(.easeOut(duration: 0.28), value: contentVisible)
                .overlay(alignment: .top) {
                    topEdgeFade
                }
            
            // Loading overlay
            if isLoading && loadError == nil {
                loadingOverlay
                    .transition(.opacity)
            }
            
            // Error overlay
            if let error = loadError, !isLoading {
                errorOverlay(error: error)
                    .transition(.opacity.combined(with: .scale))
            }
            
            floatingControls
            bottomDismissHint
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture()
                .onChanged { value in
                    if value.translation.height > 0 {
                        dragOffset = value.translation.height * 0.45
                    }
                }
                .onEnded { value in
                    if value.translation.height > dragThreshold || value.velocity.height > 500 {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            dragOffset = UIScreen.main.bounds.height
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            dismiss()
                        }
                    } else {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            dragOffset = 0
                        }
                    }
                }
        )
        .onAppear {
            withAnimation {
                contentVisible = true
            }
        }
    }
    
    // MARK: - Background
    
    private var immersiveBackground: some View {
        LinearGradient(
            colors: [
                Color.black,
                Color(red: 0.03, green: 0.05, blue: 0.10),
                Color.black
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    private var topEdgeFade: some View {
        LinearGradient(
            colors: [Color.black.opacity(0.22), Color.clear],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: 120)
        .ignoresSafeArea(edges: .top)
        .allowsHitTesting(false)
    }
    
    private var bottomDismissHint: some View {
        VStack {
            Spacer()
            Capsule()
                .fill(Color.white.opacity(0.45))
                .frame(width: 38, height: 5)
                .padding(.bottom, 10)
        }
        .ignoresSafeArea(edges: .bottom)
        .allowsHitTesting(false)
    }
    
    // MARK: - Floating Controls
    
    private var floatingControls: some View {
        VStack {
            HStack(spacing: 10) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 11, weight: .bold))
                        Text(L("journey.stop.confirm"))
                            .font(.system(size: 13, weight: .semibold))
                    }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(
                            Capsule()
                                .fill(Color.red.opacity(0.24))
                        )
                }
                
                Text(L("settings.privacy"))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.2), lineWidth: 0.6)
                    )
            )
            .shadow(color: .black.opacity(0.35), radius: 16, x: 0, y: 8)
            .padding(.horizontal, 16)
            .padding(.top, 8)
            
            Spacer()
        }
        .ignoresSafeArea(edges: .top)
    }
    
    // MARK: - Loading Overlay
    
    private var loadingOverlay: some View {
        VStack {
            HStack(spacing: 10) {
                ProgressView()
                    .tint(.white)
                
                Text(L("common.loading"))
                    .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.22), lineWidth: 0.6)
                    )
            )
            .padding(.top, 72)
            
            Spacer()
        }
        .allowsHitTesting(false)
    }
    
    // MARK: - Error Overlay
    
    private func errorOverlay(error: Error) -> some View {
        ZStack {
            Rectangle()
                .fill(Color.black.opacity(0.45))
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                Image(systemName: "wifi.exclamationmark")
                    .font(.system(size: 38, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(L("privacy.error.title"))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Text(error.localizedDescription)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.85))
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
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.16))
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
                            .stroke(Color.white.opacity(0.2), lineWidth: 0.8)
                    )
            )
            .padding(.horizontal, 24)
        }
    }
}

#Preview {
    PrivacyPolicyView()
}
