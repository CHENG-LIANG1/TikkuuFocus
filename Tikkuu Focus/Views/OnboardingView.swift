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
            onboardingBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        pageContent(for: page, index: index)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .onChange(of: currentPage) { _, _ in
                    triggerPageAnimation()
                }

                bottomControls
            }
        }
        .id(refreshID)
        .preferredColorScheme(settings.currentColorScheme)
        .onAppear {
            triggerPageAnimation()
        }
        .onChange(of: settings.selectedLanguage) { _, _ in
            refreshID = UUID()
        }
    }

    private var activePage: OnboardingPageModel {
        let boundedIndex = min(max(currentPage, 0), pages.count - 1)
        return pages[boundedIndex]
    }

    private var pages: [OnboardingPageModel] {
        [
            OnboardingPageModel(
                heroIcon: "globe.europe.africa.fill",
                badgeIcon: "location.fill",
                badgeTextKey: "onboarding.v2.page1.badge",
                titleKey: "onboarding.v2.page1.title",
                subtitleKey: "onboarding.v2.page1.subtitle",
                gradient: [Color(red: 0.13, green: 0.52, blue: 0.98), Color(red: 0.37, green: 0.28, blue: 0.91)],
                bullets: [
                    .init(icon: "paperplane.fill", titleKey: "onboarding.v2.page1.feature1.title", descriptionKey: "onboarding.v2.page1.feature1.desc", tint: .blue),
                    .init(icon: "bicycle", titleKey: "onboarding.v2.page1.feature2.title", descriptionKey: "onboarding.v2.page1.feature2.desc", tint: .cyan),
                    .init(icon: "sparkles", titleKey: "onboarding.v2.page1.feature3.title", descriptionKey: "onboarding.v2.page1.feature3.desc", tint: .mint)
                ]
            ),
            OnboardingPageModel(
                heroIcon: "map.fill",
                badgeIcon: "bolt.fill",
                badgeTextKey: "onboarding.v2.page2.badge",
                titleKey: "onboarding.v2.page2.title",
                subtitleKey: "onboarding.v2.page2.subtitle",
                gradient: [Color(red: 0.99, green: 0.56, blue: 0.24), Color(red: 0.94, green: 0.35, blue: 0.52)],
                bullets: [
                    .init(icon: "timer", titleKey: "onboarding.v2.page2.feature1.title", descriptionKey: "onboarding.v2.page2.feature1.desc", tint: .orange),
                    .init(icon: "point.topleft.down.curvedto.point.bottomright.up", titleKey: "onboarding.v2.page2.feature2.title", descriptionKey: "onboarding.v2.page2.feature2.desc", tint: .pink),
                    .init(icon: "scope", titleKey: "onboarding.v2.page2.feature3.title", descriptionKey: "onboarding.v2.page2.feature3.desc", tint: .red)
                ]
            ),
            OnboardingPageModel(
                heroIcon: "chart.bar.fill",
                badgeIcon: "star.fill",
                badgeTextKey: "onboarding.v2.page3.badge",
                titleKey: "onboarding.v2.page3.title",
                subtitleKey: "onboarding.v2.page3.subtitle",
                gradient: [Color(red: 0.16, green: 0.73, blue: 0.49), Color(red: 0.11, green: 0.61, blue: 0.82)],
                bullets: [
                    .init(icon: "clock.fill", titleKey: "onboarding.v2.page3.feature1.title", descriptionKey: "onboarding.v2.page3.feature1.desc", tint: .green),
                    .init(icon: "flag.pattern.checkered", titleKey: "onboarding.v2.page3.feature2.title", descriptionKey: "onboarding.v2.page3.feature2.desc", tint: .teal),
                    .init(icon: "trophy.fill", titleKey: "onboarding.v2.page3.feature3.title", descriptionKey: "onboarding.v2.page3.feature3.desc", tint: .yellow)
                ]
            ),
            OnboardingPageModel(
                heroIcon: "checkmark.seal.fill",
                badgeIcon: "figure.run",
                badgeTextKey: "onboarding.v2.page4.badge",
                titleKey: "onboarding.v2.page4.title",
                subtitleKey: "onboarding.v2.page4.subtitle",
                gradient: [Color(red: 0.40, green: 0.36, blue: 0.95), Color(red: 0.24, green: 0.66, blue: 0.98)],
                bullets: [
                    .init(icon: "play.fill", titleKey: "onboarding.v2.page4.feature1.title", descriptionKey: "onboarding.v2.page4.feature1.desc", tint: .indigo),
                    .init(icon: "leaf.fill", titleKey: "onboarding.v2.page4.feature2.title", descriptionKey: "onboarding.v2.page4.feature2.desc", tint: .blue),
                    .init(icon: "lock.shield.fill", titleKey: "onboarding.v2.page4.feature3.title", descriptionKey: "onboarding.v2.page4.feature3.desc", tint: .mint)
                ]
            )
        ]
    }

    private var onboardingBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.03, green: 0.06, blue: 0.16),
                    activePage.gradient[0].opacity(0.5),
                    activePage.gradient[1].opacity(0.42)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(activePage.gradient[0].opacity(0.4))
                .frame(width: 360, height: 360)
                .blur(radius: 56)
                .offset(x: -120 + (animationPhase * 24), y: -270)

            Circle()
                .fill(activePage.gradient[1].opacity(0.34))
                .frame(width: 310, height: 310)
                .blur(radius: 60)
                .offset(x: 150 - (animationPhase * 20), y: -160)

            RoundedRectangle(cornerRadius: 180, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .frame(width: 340, height: 340)
                .blur(radius: 72)
                .offset(x: 120, y: 280 - (animationPhase * 18))
        }
        .animation(.easeInOut(duration: 0.7), value: currentPage)
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(L("onboarding.v2.header"))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white.opacity(0.95))

                Text("\(currentPage + 1)/\(pages.count)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.62))
            }

            Spacer()

            if canDismiss {
                topBarButton(title: L("common.done"), action: dismissAction)
            } else if currentPage < pages.count - 1 {
                topBarButton(title: L("onboarding.skip"), action: completeOnboarding)
            } else {
                Color.clear.frame(width: 72, height: 36)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 14)
        .padding(.bottom, 8)
    }

    private var bottomControls: some View {
        VStack(spacing: 18) {
            HStack(spacing: 7) {
                ForEach(0..<pages.count, id: \.self) { index in
                    Capsule()
                        .fill(currentPage == index ? Color.white : Color.white.opacity(0.3))
                        .frame(width: currentPage == index ? 28 : 9, height: 8)
                        .animation(.spring(response: 0.36, dampingFraction: 0.8), value: currentPage)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.black.opacity(0.24))
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(Color.white.opacity(0.16), lineWidth: 0.8)
                    )
            )

            Button(action: handlePrimaryAction) {
                HStack(spacing: 10) {
                    Text(primaryButtonTitle)
                        .font(.system(size: 18, weight: .semibold))

                    Image(systemName: currentPage < pages.count - 1 ? "arrow.right" : "checkmark")
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    activePage.gradient[0].opacity(0.92),
                                    activePage.gradient[1].opacity(0.92)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Color.black.opacity(0.25), radius: 16, x: 0, y: 8)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 30)
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
            withAnimation(.spring(response: 0.42, dampingFraction: 0.84)) {
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

    private func topBarButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.28))
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.22), lineWidth: 0.8)
                        )
                )
        }
        .buttonStyle(.plain)
    }

    private func pageContent(for page: OnboardingPageModel, index: Int) -> some View {
        GeometryReader { proxy in
            let heroHeight = min(max(proxy.size.height * 0.42, 220), 292)

            VStack(spacing: 14) {
                flowHeader(labelKey: page.badgeTextKey)

                heroCard(for: page, index: index, height: heroHeight)

                featurePanel(for: page)

                Spacer(minLength: 6)
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 6)
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)
        }
    }

    private func flowHeader(labelKey: String) -> some View {
        HStack(spacing: 12) {
            HStack(spacing: 7) {
                ForEach(0..<pages.count, id: \.self) { index in
                    Capsule()
                        .fill(index == currentPage ? Color.white : Color.white.opacity(0.32))
                        .frame(width: index == currentPage ? 24 : 8, height: 6)
                        .animation(.spring(response: 0.34, dampingFraction: 0.82), value: currentPage)
                }
            }

            Spacer()

            Label(L(labelKey), systemImage: "sparkle")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.88))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule(style: .continuous)
                        .fill(Color.black.opacity(0.22))
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(Color.white.opacity(0.16), lineWidth: 0.8)
                        )
                )
        }
    }

    private func heroCard(for page: OnboardingPageModel, index: Int, height: CGFloat) -> some View {
        VStack(spacing: 16) {
            HStack(spacing: 10) {
                Label(L(page.badgeTextKey), systemImage: page.badgeIcon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.black.opacity(0.24)))

                Spacer()

                Text("\(index + 1)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white.opacity(0.9))
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(Color.white.opacity(0.2)))
            }

            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.16))
                    .frame(width: 120, height: 120)

                Circle()
                    .fill(.ultraThinMaterial.opacity(0.92))
                    .frame(width: 98, height: 98)

                Image(systemName: page.heroIcon)
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(Double(animationPhase) * 6.0))
            }
            .shadow(color: page.gradient[0].opacity(0.5), radius: 16, x: 0, y: 10)

            VStack(spacing: 10) {
                Text(L(page.titleKey))
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.85)
                    .lineLimit(2)

                Text(L(page.subtitleKey))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.82))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            .padding(.horizontal, 6)
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .frame(height: height, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            page.gradient[0].opacity(0.82),
                            page.gradient[1].opacity(0.6)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(Color.white.opacity(0.24), lineWidth: 0.9)
                )
        )
    }

    private func featurePanel(for page: OnboardingPageModel) -> some View {
        VStack(spacing: 10) {
            ForEach(Array(page.bullets.enumerated()), id: \.element.titleKey) { index, bullet in
                featureRow(bullet: bullet, index: index + 1)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.11))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.16), lineWidth: 0.8)
                )
        )
    }

    private func featureRow(bullet: OnboardingBullet, index: Int) -> some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(bullet.tint.opacity(0.28))
                    .frame(width: 36, height: 36)

                Image(systemName: bullet.icon)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(L(bullet.titleKey))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(L(bullet.descriptionKey))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.72))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text("\(index)")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 18)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.black.opacity(0.16))
        )
    }

    private func triggerPageAnimation() {
        HapticManager.selection()
        animationPhase = 0
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            animationPhase = 1
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

private struct OnboardingPageModel {
    let heroIcon: String
    let badgeIcon: String
    let badgeTextKey: String
    let titleKey: String
    let subtitleKey: String
    let gradient: [Color]
    let bullets: [OnboardingBullet]
}

private struct OnboardingBullet {
    let icon: String
    let titleKey: String
    let descriptionKey: String
    let tint: Color
}

#Preview {
    OnboardingView()
}
