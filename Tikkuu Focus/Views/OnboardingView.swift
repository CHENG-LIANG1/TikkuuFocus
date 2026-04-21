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
    @State private var floatOffset: CGFloat = 0
    let canDismiss: Bool
    @Environment(\.dismiss) private var dismiss
    
    init(canDismiss: Bool = false) {
        self.canDismiss = canDismiss
    }
    
    var body: some View {
        GeometryReader { geometry in
            let isCompact = geometry.size.height < 700
            
            ZStack {
                // Animated background
                backgroundView
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Skip button
                    HStack {
                        Spacer()
                        if canDismiss {
                            skipButton(title: L("common.done"), action: dismissAction)
                        } else if currentPage < pages.count - 1 {
                            skipButton(title: L("onboarding.skip"), action: completeOnboarding)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, isCompact ? 12 : 20)
                    
                    // Main content
                    TabView(selection: $currentPage) {
                        ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                            PageContentView(
                                page: page,
                                floatOffset: floatOffset,
                                isCompact: isCompact
                            )
                            .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .onChange(of: currentPage) { _, _ in
                        HapticManager.selection()
                    }
                    
                    // Bottom section
                    bottomSection(isCompact: isCompact)
                }
            }
        }
        .id(refreshID)
        .preferredColorScheme(settings.currentColorScheme)
        .onAppear {
            startFloatingAnimation()
        }
        .onChange(of: settings.selectedLanguage) { _, _ in
            refreshID = UUID()
        }
    }
    
    // MARK: - Data
    
    private var activePage: OnboardingPage {
        pages[min(max(currentPage, 0), pages.count - 1)]
    }
    
    private var pages: [OnboardingPage] {
        [
            OnboardingPage(
                illustration: .journey,
                titleKey: "onboarding.new.page1.title",
                subtitleKey: "onboarding.new.page1.subtitle",
                gradient: [Color(red: 0.29, green: 0.56, blue: 1.0), Color(red: 0.58, green: 0.40, blue: 0.98)]
            ),
            OnboardingPage(
                illustration: .explore,
                titleKey: "onboarding.new.page2.title",
                subtitleKey: "onboarding.new.page2.subtitle",
                gradient: [Color(red: 1.0, green: 0.62, blue: 0.35), Color(red: 0.98, green: 0.42, blue: 0.56)]
            ),
            OnboardingPage(
                illustration: .achieve,
                titleKey: "onboarding.new.page3.title",
                subtitleKey: "onboarding.new.page3.subtitle",
                gradient: [Color(red: 0.30, green: 0.85, blue: 0.65), Color(red: 0.25, green: 0.72, blue: 0.95)]
            )
        ]
    }
    
    // MARK: - Background
    
    private var backgroundView: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    Color(red: 0.06, green: 0.08, blue: 0.14),
                    activePage.gradient[0].opacity(0.35),
                    activePage.gradient[1].opacity(0.25)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Floating orbs
            Circle()
                .fill(activePage.gradient[0].opacity(0.3))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: -80, y: -200 + floatOffset * 15)
            
            Circle()
                .fill(activePage.gradient[1].opacity(0.25))
                .frame(width: 250, height: 250)
                .blur(radius: 70)
                .offset(x: 100, y: 100 - floatOffset * 12)
            
            Circle()
                .fill(Color.white.opacity(0.05))
                .frame(width: 200, height: 200)
                .blur(radius: 60)
                .offset(x: 50, y: 300 + floatOffset * 10)
        }
        .animation(.easeInOut(duration: 0.8), value: currentPage)
    }
    
    // MARK: - Skip Button
    
    private func skipButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Bottom Section
    
    private func bottomSection(isCompact: Bool) -> some View {
        VStack(spacing: isCompact ? 20 : 28) {
            // Page indicators
            HStack(spacing: 8) {
                ForEach(0..<pages.count, id: \.self) { index in
                    Circle()
                        .fill(currentPage == index ? Color.white : Color.white.opacity(0.3))
                        .frame(width: currentPage == index ? 10 : 8, height: currentPage == index ? 10 : 8)
                        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: currentPage)
                }
            }
            
            // Action button
            Button(action: handlePrimaryAction) {
                Text(primaryButtonTitle)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: 280)
                    .padding(.vertical, isCompact ? 15 : 18)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: activePage.gradient,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: activePage.gradient[0].opacity(0.5), radius: 20, x: 0, y: 10)
                    )
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(.horizontal, 32)
        .padding(.bottom, isCompact ? 30 : 50)
    }
    
    private var primaryButtonTitle: String {
        if currentPage < pages.count - 1 {
            return L("onboarding.next")
        }
        return canDismiss ? L("common.done") : L("onboarding.getStarted")
    }
    
    // MARK: - Actions
    
    private func handlePrimaryAction() {
        HapticManager.medium()
        if currentPage < pages.count - 1 {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                currentPage += 1
            }
            return
        }
        if canDismiss {
            dismiss()
        } else {
            completeOnboarding()
        }
    }
    
    private func startFloatingAnimation() {
        withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
            floatOffset = 1
        }
    }
    
    private func dismissAction() {
        HapticManager.light()
        dismiss()
    }
    
    private func completeOnboarding() {
        HapticManager.success()
        withAnimation {
            settings.hasCompletedOnboarding = true
        }
        dismiss()
    }
}

// MARK: - Page Content View

private struct PageContentView: View {
    let page: OnboardingPage
    let floatOffset: CGFloat
    let isCompact: Bool
    
    var body: some View {
        VStack(spacing: isCompact ? 28 : 40) {
            Spacer()
            
            // Illustration
            IllustrationView(
                type: page.illustration,
                gradient: page.gradient,
                floatOffset: floatOffset,
                isCompact: isCompact
            )
            
            // Text content
            VStack(spacing: isCompact ? 12 : 16) {
                Text(L(page.titleKey))
                    .font(.system(size: isCompact ? 28 : 34, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(L(page.subtitleKey))
                    .font(.system(size: isCompact ? 15 : 17, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 32)
            
            Spacer()
            Spacer()
        }
    }
}

// MARK: - Illustration View

private struct IllustrationView: View {
    let type: IllustrationType
    let gradient: [Color]
    let floatOffset: CGFloat
    let isCompact: Bool
    
    private var size: CGFloat { isCompact ? 200 : 260 }
    
    var body: some View {
        ZStack {
            // Background glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [gradient[0].opacity(0.4), gradient[1].opacity(0.1), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.7
                    )
                )
                .frame(width: size * 1.4, height: size * 1.4)
            
            // Main illustration container
            ZStack {
                // Glass card
                RoundedRectangle(cornerRadius: size * 0.2, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .frame(width: size, height: size)
                    .overlay(
                        RoundedRectangle(cornerRadius: size * 0.2, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.3), Color.white.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: Color.black.opacity(0.06), radius: 20, x: 0, y: 10)
                
                // Illustration content
                illustrationContent
            }
            .offset(y: floatOffset * -8)
        }
    }
    
    @ViewBuilder
    private var illustrationContent: some View {
        switch type {
        case .journey:
            journeyIllustration
        case .explore:
            exploreIllustration
        case .achieve:
            achieveIllustration
        }
    }
    
    private var journeyIllustration: some View {
        ZStack {
            // Route line
            Path { path in
                path.move(to: CGPoint(x: size * 0.25, y: size * 0.7))
                path.addCurve(
                    to: CGPoint(x: size * 0.75, y: size * 0.3),
                    control1: CGPoint(x: size * 0.35, y: size * 0.4),
                    control2: CGPoint(x: size * 0.65, y: size * 0.5)
                )
            }
            .stroke(
                LinearGradient(colors: gradient, startPoint: .leading, endPoint: .trailing),
                style: StrokeStyle(lineWidth: 4, lineCap: .round, dash: [8, 6])
            )
            .frame(width: size, height: size)
            
            // Start point
            Circle()
                .fill(gradient[0])
                .frame(width: 20, height: 20)
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                .offset(x: -size * 0.25, y: size * 0.2)
            
            // End point
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 32, weight: .medium))
                .foregroundStyle(gradient[1], .white)
                .offset(x: size * 0.25, y: -size * 0.2)
            
            // Globe icon
            Image(systemName: "globe.asia.australia.fill")
                .font(.system(size: isCompact ? 50 : 64, weight: .light))
                .foregroundStyle(
                    LinearGradient(colors: [.white.opacity(0.9), .white.opacity(0.6)], startPoint: .top, endPoint: .bottom)
                )
                .offset(y: floatOffset * 4)
        }
    }
    
    private var exploreIllustration: some View {
        ZStack {
            // Map grid
            ForEach(0..<3) { row in
                ForEach(0..<3) { col in
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                        .frame(width: size * 0.22, height: size * 0.22)
                        .offset(
                            x: CGFloat(col - 1) * size * 0.26,
                            y: CGFloat(row - 1) * size * 0.26
                        )
                }
            }
            
            // POI markers
            Image(systemName: "cup.and.saucer.fill")
                .font(.system(size: 18))
                .foregroundColor(gradient[0])
                .offset(x: -size * 0.2, y: -size * 0.15)
            
            Image(systemName: "leaf.fill")
                .font(.system(size: 18))
                .foregroundColor(.green)
                .offset(x: size * 0.22, y: size * 0.1)
            
            Image(systemName: "building.2.fill")
                .font(.system(size: 18))
                .foregroundColor(gradient[1])
                .offset(x: size * 0.05, y: -size * 0.25)
            
            // Center icon
            Image(systemName: "location.north.fill")
                .font(.system(size: isCompact ? 44 : 56, weight: .medium))
                .foregroundStyle(
                    LinearGradient(colors: gradient, startPoint: .top, endPoint: .bottom)
                )
                .rotationEffect(.degrees(floatOffset * 15))
        }
    }
    
    private var achieveIllustration: some View {
        ZStack {
            // Stats bars
            HStack(spacing: 12) {
                ForEach(0..<4) { index in
                    VStack {
                        Spacer()
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [gradient[0].opacity(0.8), gradient[1].opacity(0.6)],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                            .frame(width: 20, height: CGFloat([50, 70, 45, 85][index]) + floatOffset * 5)
                    }
                    .frame(height: 100)
                }
            }
            .offset(y: size * 0.15)
            
            // Trophy
            Image(systemName: "trophy.fill")
                .font(.system(size: isCompact ? 52 : 66, weight: .medium))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(red: 1.0, green: 0.85, blue: 0.35), Color(red: 1.0, green: 0.65, blue: 0.2)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: Color.orange.opacity(0.4), radius: 15, x: 0, y: 8)
                .offset(y: -size * 0.12 + floatOffset * 6)
            
            // Sparkles
            Image(systemName: "sparkle")
                .font(.system(size: 14))
                .foregroundColor(.yellow)
                .offset(x: -size * 0.28, y: -size * 0.25)
            
            Image(systemName: "sparkle")
                .font(.system(size: 10))
                .foregroundColor(.yellow.opacity(0.7))
                .offset(x: size * 0.3, y: -size * 0.18)
        }
    }
}

// MARK: - Data Models

private enum IllustrationType {
    case journey
    case explore
    case achieve
}

private struct OnboardingPage {
    let illustration: IllustrationType
    let titleKey: String
    let subtitleKey: String
    let gradient: [Color]
}

#Preview {
    OnboardingView()
}
