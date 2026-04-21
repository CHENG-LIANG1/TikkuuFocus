//
//  AboutView.swift
//  Tikkuu Focus
//
//  Created by Tikkuu on 2026/2/8.
//

import SwiftUI

struct AboutView: View {
    @ObservedObject private var settings = AppSettings.shared
    @Environment(\.colorScheme) private var colorScheme
    @State private var refreshID = UUID()
    @State private var heartScale: CGFloat = 1.0
    @State private var showContent = false
    
    var body: some View {
        ZStack {
            // Background based on theme
            backgroundView
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    VStack(spacing: 40) {
                        // Hero Section
                        VStack(spacing: 24) {
                            // Animated Icon
                            ZStack {
                                // Glow effect
                                Circle()
                                    .fill(
                                        RadialGradient(
                                            colors: [
                                                Color.cyan.opacity(0.4),
                                                Color.blue.opacity(0.2),
                                                Color.clear
                                            ],
                                            center: .center,
                                            startRadius: 20,
                                            endRadius: 80
                                        )
                                    )
                                    .frame(width: 160, height: 160)
                                    .blur(radius: 20)
                                
                                Image("AppLogo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 112, height: 112)
                                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                                            .stroke(Color.white.opacity(0.24), lineWidth: 1)
                                    )
                                    .shadow(color: Color.black.opacity(0.32), radius: 16, x: 0, y: 10)
                            }
                            .scaleEffect(showContent ? 1 : 0.5)
                            .opacity(showContent ? 1 : 0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.7), value: showContent)
                            
                            // App Name
                            VStack(spacing: 12) {
                                Text("Roam Focus")
                                    .font(.system(size: 42, weight: .semibold, design: .rounded))
                                    .foregroundStyle(
                                        false
                                            ? AnyShapeStyle(cardTextColor)
                                            : AnyShapeStyle(
                                                LinearGradient(
                                                    colors: [.white, .white.opacity(0.9)],
                                                    startPoint: .top,
                                                    endPoint: .bottom
                                                )
                                            )
                                    )
                                
                                Text(L("about.tagline"))
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundColor(cardSecondaryTextColor)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                            }
                            .scaleEffect(showContent ? 1 : 0.8)
                            .opacity(showContent ? 1 : 0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: showContent)
                        }
                        .padding(.top, 40)
                        
                        // Description Card
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(spacing: 8) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color.yellow, Color.orange],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                
                                Text(L("about.description.title"))
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(cardTextColor)
                            }
                            
                            Text(L("about.description.text"))
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(cardSecondaryTextColor)
                                .lineSpacing(6)
                        }
                        .padding(24)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(cardBackground)
                        .scaleEffect(showContent ? 1 : 0.9)
                        .opacity(showContent ? 1 : 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2), value: showContent)
                        
                        // Features Grid
                        VStack(spacing: 16) {
                            AboutFeatureCard(
                                icon: "map.fill",
                                title: L("about.feature.journey"),
                                description: L("about.feature.journey.desc"),
                                gradient: LinearGradient(
                                    colors: [Color.cyan, Color.blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                delay: 0.3
                            )
                            
                            AboutFeatureCard(
                                icon: "star.fill",
                                title: L("about.feature.poi"),
                                description: L("about.feature.poi.desc"),
                                gradient: LinearGradient(
                                    colors: [Color.orange, Color.pink],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                delay: 0.4
                            )
                            
                            AboutFeatureCard(
                                icon: "chart.line.uptrend.xyaxis",
                                title: L("about.feature.history"),
                                description: L("about.feature.history.desc"),
                                gradient: LinearGradient(
                                    colors: [Color.green, Color.teal],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                delay: 0.5
                            )
                        }
                        .opacity(showContent ? 1 : 0)
                        
                        // Made with Love
                        VStack(spacing: 16) {
                            HStack(spacing: 8) {
                                Text("Made with")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(cardSecondaryTextColor)
                                
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color.pink, Color.red],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .scaleEffect(heartScale)
                                    .onAppear {
                                        withAnimation(
                                            .easeInOut(duration: 0.8)
                                            .repeatForever(autoreverses: true)
                                        ) {
                                            heartScale = 1.2
                                        }
                                    }
                                
                                Text("by Tikkuu")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(cardSecondaryTextColor)
                            }
                            
                            // Version & Copyright
                            VStack(spacing: 6) {
                                Text(String(format: L("about.version.full"), AppInfo.version))
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(cardSecondaryTextColor.opacity(0.7))
                                
                                Text(L("about.copyright"))
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(cardSecondaryTextColor.opacity(0.7))
                            }
                        }
                        .scaleEffect(showContent ? 1 : 0.8)
                        .opacity(showContent ? 1 : 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.6), value: showContent)
                        .padding(.bottom, 40)
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
        .id(refreshID)
        .preferredColorScheme(false ? settings.currentColorScheme : .dark)
        .onAppear {
            showContent = true
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("LanguageChanged"))) { _ in
            refreshID = UUID()
        }
    }
    
    // MARK: - Helper Views & Properties
    
    @ViewBuilder
    private var backgroundView: some View {
        AnimatedGradientBackground()
    }
    
    private var cardTextColor: Color {
        .white
    }
    
    private var cardSecondaryTextColor: Color {
        Color.white.opacity(0.7)
    }
    
    @ViewBuilder
    private var cardBackground: some View {
        Color.clear
            .glassCard(cornerRadius: 20)
    }
}

// MARK: - About Feature Card

struct AboutFeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let gradient: LinearGradient
    let delay: Double
    @ObservedObject private var settings = AppSettings.shared
    @Environment(\.colorScheme) private var colorScheme
    @State private var show = false
    
    private var cardTextColor: Color {
        .white
    }
    
    private var cardSecondaryTextColor: Color {
        Color.white.opacity(0.7)
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(gradient.opacity(0.2))
                    .frame(width: 56, height: 56)
                
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(gradient)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(cardTextColor)
                
                Text(description)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(cardSecondaryTextColor)
                    .lineSpacing(4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .background(featureCardBackground)
        .scaleEffect(show ? 1 : 0.9)
        .opacity(show ? 1 : 0)
        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(delay), value: show)
        .onAppear {
            show = true
        }
    }
    
    @ViewBuilder
    private var featureCardBackground: some View {
        Color.clear
            .glassCard(cornerRadius: 20)
    }
}

#Preview {
    AboutView()
}
