//
//  OnboardingView.swift
//  Tikkuu Focus
//
//  Created by Tikkuu on 2026/2/8.
//

import SwiftUI
import CoreLocation

struct OnboardingView: View {
    @StateObject private var settings = AppSettings.shared
    @State private var currentPage = 0
    @State private var refreshID = UUID()
    @State private var orbDrift: CGFloat = 0
    @State private var cardLift: CGFloat = 0
    let canDismiss: Bool
    @Environment(\.dismiss) private var dismiss

    init(canDismiss: Bool = false) {
        self.canDismiss = canDismiss
    }

    var body: some View {
        GeometryReader { geometry in
            let isCompact = geometry.size.height < 760

            ZStack {
                backgroundView
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    topBar(isCompact: isCompact)

                    TabView(selection: $currentPage) {
                        ForEach(Array(pages.enumerated()), id: \.offset) { index, slide in
                            OnboardingSlideView(
                                slide: slide,
                                isCompact: isCompact,
                                cardLift: cardLift,
                                isVisible: currentPage == index
                            )
                            .tag(index)
                            .padding(.horizontal, 20)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .onChange(of: currentPage) { _, _ in
                        HapticManager.selection()
                    }

                    bottomSection(isCompact: isCompact)
                }
            }
        }
        .id(refreshID)
        .preferredColorScheme(settings.currentColorScheme)
        .onAppear {
            startAnimations()
        }
        .onChange(of: settings.selectedLanguage) { _, _ in
            refreshID = UUID()
        }
    }

    private var activeSlide: OnboardingSlide {
        pages[min(max(currentPage, 0), pages.count - 1)]
    }

    private var progressText: String {
        "\(currentPage + 1) / \(pages.count)"
    }

    private var pages: [OnboardingSlide] {
        [
            OnboardingSlide(
                kind: .plan,
                titleKey: "onboarding.animated.page1.title",
                subtitleKey: "onboarding.animated.page1.subtitle",
                gradient: [Color(red: 0.25, green: 0.54, blue: 0.98), Color(red: 0.20, green: 0.80, blue: 0.84)],
                backgroundAccent: Color(red: 0.12, green: 0.24, blue: 0.52),
                symbol: "map.fill",
                symbolColor: .blue
            ),
            OnboardingSlide(
                kind: .focus,
                titleKey: "onboarding.animated.page2.title",
                subtitleKey: "onboarding.animated.page2.subtitle",
                gradient: [Color(red: 0.97, green: 0.53, blue: 0.32), Color(red: 0.90, green: 0.27, blue: 0.56)],
                backgroundAccent: Color(red: 0.44, green: 0.16, blue: 0.30),
                symbol: "location.north.line.fill",
                symbolColor: .orange
            ),
            OnboardingSlide(
                kind: .grow,
                titleKey: "onboarding.animated.page3.title",
                subtitleKey: "onboarding.animated.page3.subtitle",
                gradient: [Color(red: 0.99, green: 0.77, blue: 0.25), Color(red: 0.97, green: 0.46, blue: 0.25)],
                backgroundAccent: Color(red: 0.38, green: 0.22, blue: 0.09),
                symbol: "trophy.fill",
                symbolColor: .yellow
            )
        ]
    }

    private var backgroundView: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.03, green: 0.05, blue: 0.10),
                    activeSlide.backgroundAccent.opacity(0.88),
                    Color(red: 0.06, green: 0.07, blue: 0.14)
                ],
                startPoint: .topLeading,
                endPoint: .bottom
            )

            Circle()
                .fill(activeSlide.gradient[0].opacity(0.30))
                .frame(width: 360, height: 360)
                .blur(radius: 92)
                .offset(x: -110, y: -250 + orbDrift * 22)

            Circle()
                .fill(activeSlide.gradient[1].opacity(0.28))
                .frame(width: 280, height: 280)
                .blur(radius: 84)
                .offset(x: 130, y: 100 - orbDrift * 18)

            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 180, height: 180)
                .blur(radius: 60)
                .offset(x: 26, y: 330 + orbDrift * 14)
        }
        .animation(.easeInOut(duration: 0.75), value: currentPage)
    }

    private func topBar(isCompact: Bool) -> some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Circle()
                    .fill(activeSlide.gradient[0])
                    .frame(width: 8, height: 8)

                Text(progressText)
                    .font(.system(size: isCompact ? 12 : 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(0.14))
            )

            Spacer()

            if canDismiss {
                ghostButton(title: L("common.done"), action: dismissAction)
            } else if currentPage < pages.count - 1 {
                ghostButton(title: L("onboarding.skip"), action: completeOnboarding)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, isCompact ? 12 : 20)
    }

    private func ghostButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.85))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule(style: .continuous)
                        .fill(Color.white.opacity(0.12))
                )
        }
        .buttonStyle(.plain)
    }

    private func bottomSection(isCompact: Bool) -> some View {
        VStack(spacing: isCompact ? 20 : 28) {
            HStack(spacing: 9) {
                ForEach(0..<pages.count, id: \.self) { index in
                    Capsule(style: .continuous)
                        .fill(currentPage == index ? Color.white : Color.white.opacity(0.30))
                        .frame(width: currentPage == index ? 28 : 8, height: 8)
                        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: currentPage)
                }
            }

            Button(action: handlePrimaryAction) {
                Text(primaryButtonTitle)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, isCompact ? 15 : 18)
                    .background(
                        Capsule(style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: activeSlide.gradient,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: activeSlide.gradient[0].opacity(0.45), radius: 18, x: 0, y: 10)
                    )
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(.horizontal, 24)
        .padding(.bottom, isCompact ? 30 : 50)
    }

    private var primaryButtonTitle: String {
        if currentPage < pages.count - 1 {
            return L("onboarding.animated.next")
        }
        return canDismiss ? L("common.done") : L("onboarding.animated.start")
    }

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

    private func startAnimations() {
        withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
            orbDrift = 1
        }
        withAnimation(.easeInOut(duration: 2.3).repeatForever(autoreverses: true)) {
            cardLift = 1
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

private struct OnboardingSlideView: View {
    let slide: OnboardingSlide
    let isCompact: Bool
    let cardLift: CGFloat
    let isVisible: Bool

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: isCompact ? 32 : 48) {
                Spacer().frame(height: isCompact ? 20 : 40)
                symbolSection
                textSection
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(.top, isCompact ? 10 : 18)
            .padding(.bottom, 8)
        }
    }

    private var symbolSection: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.15),
                            Color.white.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: isCompact ? 160 : 200, height: isCompact ? 160 : 200)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: slide.symbolColor.opacity(0.3), radius: 20, x: 0, y: 10)
            
            if #available(iOS 17.0, *) {
                Image(systemName: slide.symbol)
                    .font(.system(size: isCompact ? 70 : 90, weight: .semibold))
                    .foregroundStyle(slide.symbolColor)
                    .symbolEffect(.bounce.up, options: .repeating, isActive: isVisible)
            } else {
                Image(systemName: slide.symbol)
                    .font(.system(size: isCompact ? 70 : 90, weight: .semibold))
                    .foregroundStyle(slide.symbolColor)
                    .scaleEffect(isVisible ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isVisible)
            }
        }
        .offset(y: -cardLift * 8)
    }

    private var textSection: some View {
        VStack(spacing: 16) {
            Text(L(slide.titleKey))
                .font(.system(size: isCompact ? 28 : 34, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 10)

            Text(L(slide.subtitleKey))
                .font(.system(size: isCompact ? 16 : 18, weight: .regular))
                .foregroundStyle(.white.opacity(0.85))
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding(.horizontal, 20)
        }
    }
}

private enum OnboardingPageKind {
    case plan
    case focus
    case grow
}

private struct OnboardingSlide {
    let kind: OnboardingPageKind
    let titleKey: String
    let subtitleKey: String
    let gradient: [Color]
    let backgroundAccent: Color
    let symbol: String
    let symbolColor: Color
}

#Preview {
    OnboardingView()
}
