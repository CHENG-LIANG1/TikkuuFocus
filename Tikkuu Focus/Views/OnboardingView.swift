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
                                cardLift: cardLift
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
                artwork: .route,
                titleKey: "onboarding.new.page1.title",
                subtitleKey: "onboarding.new.page1.subtitle",
                chips: [
                    "onboarding.new.tag.realMap",
                    "onboarding.new.tag.transport",
                    "onboarding.new.tag.discover"
                ],
                gradient: [Color(red: 0.20, green: 0.55, blue: 0.98), Color(red: 0.18, green: 0.79, blue: 0.81)],
                backgroundAccent: Color(red: 0.12, green: 0.29, blue: 0.60)
            ),
            OnboardingSlide(
                artwork: .compass,
                titleKey: "onboarding.new.page2.title",
                subtitleKey: "onboarding.new.page2.subtitle",
                chips: [
                    "onboarding.new.tag.liveProgress",
                    "onboarding.new.tag.freeExplore",
                    "onboarding.new.tag.pois"
                ],
                gradient: [Color(red: 0.98, green: 0.55, blue: 0.30), Color(red: 0.93, green: 0.29, blue: 0.48)],
                backgroundAccent: Color(red: 0.50, green: 0.19, blue: 0.34)
            ),
            OnboardingSlide(
                artwork: .stats,
                titleKey: "onboarding.new.page3.title",
                subtitleKey: "onboarding.new.page3.subtitle",
                chips: [
                    "onboarding.new.tag.stats",
                    "onboarding.new.tag.history",
                    "onboarding.new.tag.achievements"
                ],
                gradient: [Color(red: 0.31, green: 0.83, blue: 0.56), Color(red: 0.18, green: 0.64, blue: 0.93)],
                backgroundAccent: Color(red: 0.09, green: 0.35, blue: 0.42)
            )
        ]
    }

    private var backgroundView: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.03, green: 0.05, blue: 0.10),
                    activeSlide.backgroundAccent.opacity(0.85),
                    Color(red: 0.06, green: 0.07, blue: 0.14)
                ],
                startPoint: .topLeading,
                endPoint: .bottom
            )

            Circle()
                .fill(activeSlide.gradient[0].opacity(0.32))
                .frame(width: 350, height: 350)
                .blur(radius: 92)
                .offset(x: -120, y: -250 + orbDrift * 22)

            Circle()
                .fill(activeSlide.gradient[1].opacity(0.30))
                .frame(width: 280, height: 280)
                .blur(radius: 84)
                .offset(x: 130, y: 110 - orbDrift * 18)

            Circle()
                .fill(Color.white.opacity(0.07))
                .frame(width: 180, height: 180)
                .blur(radius: 60)
                .offset(x: 32, y: 330 + orbDrift * 14)
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
            return L("onboarding.next")
        }
        return canDismiss ? L("common.done") : L("onboarding.getStarted")
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

    var body: some View {
        VStack(spacing: isCompact ? 22 : 30) {
            Spacer(minLength: isCompact ? 16 : 24)
            heroCard
            textSection
            chipSection
            Spacer(minLength: 10)
        }
    }

    private var heroCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.26),
                            Color.white.opacity(0.10)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(Color.white.opacity(0.28), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.18), radius: 24, x: 0, y: 18)

            OnboardingArtworkView(
                artwork: slide.artwork,
                gradient: slide.gradient,
                cardLift: cardLift
            )
            .padding(20)
        }
        .frame(height: isCompact ? 250 : 305)
    }

    private var textSection: some View {
        VStack(spacing: 12) {
            Text(L(slide.titleKey))
                .font(.system(size: isCompact ? 30 : 36, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Text(L(slide.subtitleKey))
                .font(.system(size: isCompact ? 15 : 17, weight: .medium))
                .foregroundStyle(.white.opacity(0.78))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .padding(.horizontal, 10)
    }

    private var chipSection: some View {
        HStack(spacing: 10) {
            ForEach(slide.chips, id: \.self) { key in
                Text(L(key))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.92))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color.white.opacity(0.16))
                    )
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }
}

private struct OnboardingArtworkView: View {
    let artwork: OnboardingArtwork
    let gradient: [Color]
    let cardLift: CGFloat

    var body: some View {
        artworkContent
            .offset(y: -cardLift * 8)
    }

    @ViewBuilder
    private var artworkContent: some View {
        switch artwork {
        case .route:
            routeArtwork
        case .compass:
            compassArtwork
        case .stats:
            statsArtwork
        }
    }

    private var routeArtwork: some View {
        ZStack {
            Path { path in
                path.move(to: CGPoint(x: 40, y: 178))
                path.addCurve(
                    to: CGPoint(x: 256, y: 58),
                    control1: CGPoint(x: 95, y: 90),
                    control2: CGPoint(x: 188, y: 140)
                )
            }
            .stroke(
                LinearGradient(colors: gradient, startPoint: .leading, endPoint: .trailing),
                style: StrokeStyle(lineWidth: 6, lineCap: .round, dash: [9, 7])
            )
            .frame(width: 300, height: 220)

            Circle()
                .fill(gradient[0])
                .frame(width: 18, height: 18)
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                .offset(x: -108, y: 64)

            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(gradient[1], .white)
                .offset(x: 110, y: -60)

            Image(systemName: "map.fill")
                .font(.system(size: 74, weight: .light))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white.opacity(0.96), .white.opacity(0.58)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .offset(y: -6)
        }
    }

    private var compassArtwork: some View {
        ZStack {
            ForEach(0..<3) { row in
                ForEach(0..<3) { col in
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 58, height: 58)
                        .offset(
                            x: CGFloat(col - 1) * 66,
                            y: CGFloat(row - 1) * 66
                        )
                }
            }

            Image(systemName: "cup.and.saucer.fill")
                .font(.system(size: 18))
                .foregroundColor(gradient[0])
                .offset(x: -56, y: -46)

            Image(systemName: "leaf.fill")
                .font(.system(size: 18))
                .foregroundColor(.green)
                .offset(x: 62, y: 34)

            Image(systemName: "building.2.fill")
                .font(.system(size: 18))
                .foregroundColor(gradient[1])
                .offset(x: 16, y: -72)

            Image(systemName: "location.north.fill")
                .font(.system(size: 56, weight: .bold))
                .foregroundStyle(
                    LinearGradient(colors: gradient, startPoint: .top, endPoint: .bottom)
                )
                .rotationEffect(.degrees(Double(cardLift) * 12))
        }
    }

    private var statsArtwork: some View {
        ZStack {
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
                            .frame(width: 20, height: CGFloat([48, 70, 52, 92][index]) + cardLift * 6)
                    }
                    .frame(height: 110)
                }
            }
            .offset(y: 56)

            Image(systemName: "trophy.fill")
                .font(.system(size: 64, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(red: 1.0, green: 0.85, blue: 0.35), Color(red: 1.0, green: 0.65, blue: 0.2)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: Color.orange.opacity(0.4), radius: 15, x: 0, y: 8)
                .offset(y: -40 + cardLift * 8)

            Image(systemName: "sparkle")
                .font(.system(size: 14))
                .foregroundColor(.yellow)
                .offset(x: -88, y: -72)

            Image(systemName: "sparkle")
                .font(.system(size: 10))
                .foregroundColor(.yellow.opacity(0.7))
                .offset(x: 92, y: -52)
        }
    }
}

private enum OnboardingArtwork {
    case route
    case compass
    case stats
}

private struct OnboardingSlide {
    let artwork: OnboardingArtwork
    let titleKey: String
    let subtitleKey: String
    let chips: [String]
    let gradient: [Color]
    let backgroundAccent: Color
}

#Preview {
    OnboardingView()
}
