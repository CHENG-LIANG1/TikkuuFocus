//
//  OnboardingView.swift
//  Tikkuu Focus
//
//  Created by Tikkuu on 2026/2/8.
//

import SwiftUI

struct OnboardingView: View {
    @StateObject private var settings = AppSettings.shared
    @State private var currentPage = 0
    @State private var refreshID = UUID()
    @State private var animationPhase: CGFloat = 0
    let canDismiss: Bool
    @Environment(\.dismiss) private var dismiss
    
    init(canDismiss: Bool = false) {
        self.canDismiss = canDismiss
    }
    
    var body: some View {
        ZStack {
            // Dynamic gradient background
            AnimatedGradientBackground()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Spacer()
                    
                    if canDismiss {
                        Button {
                            HapticManager.light()
                            dismiss()
                        } label: {
                            Text(L("common.done"))
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                    } else if currentPage < 2 {
                        Button {
                            HapticManager.light()
                            completeOnboarding()
                        } label: {
                            Text(L("onboarding.skip"))
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary.opacity(0.7))
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .frame(height: 60)
                
                // Content
                TabView(selection: $currentPage) {
                    page1Content.tag(0)
                    page2Content.tag(1)
                    page3Content.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .onChange(of: currentPage) { _, _ in
                    HapticManager.selection()
                    animationPhase = 0
                    withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                        animationPhase = 1
                    }
                }
                
                // Bottom controls
                VStack(spacing: 20) {
                    // Page indicator
                    HStack(spacing: 8) {
                        ForEach(0..<3) { index in
                            Capsule()
                                .fill(currentPage == index ? Color.primary : Color.primary.opacity(0.2))
                                .frame(width: currentPage == index ? 32 : 8, height: 8)
                                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentPage)
                        }
                    }
                    
                    // Action button
                    Button {
                        HapticManager.medium()
                        if currentPage < 2 {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                currentPage += 1
                            }
                        } else {
                            if canDismiss {
                                dismiss()
                            } else {
                                completeOnboarding()
                            }
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Text(currentPage < 2 ? L("onboarding.next") : L("onboarding.getStarted"))
                                .font(.system(size: 18, weight: .semibold))
                            
                            Image(systemName: currentPage < 2 ? "arrow.right" : "checkmark")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(LiquidGlassStyle.primaryGradient)
                                .shadow(color: Color.black.opacity(0.3), radius: 12, x: 0, y: 6)
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .id(refreshID)
        .preferredColorScheme(settings.currentColorScheme)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                animationPhase = 1
            }
        }
        .onChange(of: settings.selectedLanguage) { _, _ in
            refreshID = UUID()
        }
    }
    
    // MARK: - Page 1: Journey Exploration
    
    private var page1Content: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Visual hero
            ZStack {
                // Animated circles
                ForEach(0..<3) { index in
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.blue.opacity(0.3),
                                    Color.purple.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 120 + CGFloat(index) * 60, height: 120 + CGFloat(index) * 60)
                        .scaleEffect(1 + animationPhase * 0.1 * CGFloat(index + 1))
                        .opacity(0.6 - Double(index) * 0.15)
                }
                
                // Center icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.blue.opacity(0.2),
                                    Color.purple.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .blur(radius: 20)
                    
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "map.fill")
                        .font(.system(size: 50, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.blue, Color.purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .rotationEffect(.degrees(animationPhase * 5))
                }
                .shadow(color: Color.blue.opacity(0.3), radius: 30, x: 0, y: 15)
                
                // Floating icons
                FloatingIcon(icon: "location.fill", color: .blue, offset: CGPoint(x: -80, y: -60), phase: animationPhase)
                FloatingIcon(icon: "figure.walk", color: .green, offset: CGPoint(x: 80, y: -40), phase: animationPhase, delay: 0.3)
                FloatingIcon(icon: "star.fill", color: .yellow, offset: CGPoint(x: -70, y: 70), phase: animationPhase, delay: 0.6)
            }
            .frame(height: 300)
            
            Spacer().frame(height: 60)
            
            // Title
            Text(L("onboarding.page1.title"))
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Spacer().frame(height: 16)
            
            // Subtitle
            Text(L("onboarding.page1.description"))
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 40)
            
            Spacer()
        }
    }
    
    // MARK: - Page 2: Real-time Tracking
    
    private var page2Content: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Visual hero
            ZStack {
                // Progress ring
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                    .frame(width: 200, height: 200)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        LinearGradient(
                            colors: [Color.orange, Color.pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .rotationEffect(.degrees(animationPhase * 360))
                
                // Center content
                VStack(spacing: 8) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 50, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.orange, Color.pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("12:34")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                }
                
                // Orbiting dots
                ForEach(0..<3) { index in
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.orange, Color.pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 12, height: 12)
                        .offset(y: -110)
                        .rotationEffect(.degrees(Double(index) * 120 + animationPhase * 360))
                }
            }
            .frame(height: 300)
            
            Spacer().frame(height: 60)
            
            // Title
            Text(L("onboarding.page2.title"))
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Spacer().frame(height: 16)
            
            // Subtitle
            Text(L("onboarding.page2.description"))
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 40)
            
            Spacer()
        }
    }
    
    // MARK: - Page 3: Achievements
    
    private var page3Content: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Visual hero
            ZStack {
                // Glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.yellow.opacity(0.3),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 120
                        )
                    )
                    .frame(width: 240, height: 240)
                    .scaleEffect(1 + animationPhase * 0.2)
                
                // Trophy
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 140, height: 140)
                    
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 70, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.yellow, Color.orange],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .scaleEffect(1 + animationPhase * 0.1)
                        .rotationEffect(.degrees(animationPhase * -5))
                }
                .shadow(color: Color.yellow.opacity(0.4), radius: 30, x: 0, y: 15)
                
                // Sparkles
                ForEach(0..<6) { index in
                    Image(systemName: "sparkle")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.yellow)
                        .offset(
                            x: cos(Double(index) * .pi / 3) * 100,
                            y: sin(Double(index) * .pi / 3) * 100
                        )
                        .scaleEffect(0.5 + animationPhase * 0.5)
                        .opacity(0.3 + animationPhase * 0.7)
                        .rotationEffect(.degrees(Double(index) * 60 + animationPhase * 360))
                }
            }
            .frame(height: 300)
            
            Spacer().frame(height: 60)
            
            // Title
            Text(L("onboarding.page4.title"))
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Spacer().frame(height: 16)
            
            // Subtitle
            Text(L("onboarding.page4.description"))
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 40)
            
            Spacer()
        }
    }
    
    private func completeOnboarding() {
        HapticManager.success()
        withAnimation {
            settings.hasCompletedOnboarding = true
        }
    }
}

// MARK: - Floating Icon

struct FloatingIcon: View {
    let icon: String
    let color: Color
    let offset: CGPoint
    let phase: CGFloat
    var delay: Double = 0
    
    var body: some View {
        let yOffset = offset.y + sin((Double(phase) * Double.pi * 2.0) + delay) * 10.0
        
        return ZStack {
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: 50, height: 50)
                .blur(radius: 10)
            
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 44, height: 44)
            
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(color)
        }
        .offset(x: offset.x, y: yOffset)
        .shadow(color: color.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}

#Preview {
    OnboardingView()
}
