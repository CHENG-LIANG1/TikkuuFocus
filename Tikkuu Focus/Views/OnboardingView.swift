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
                        pageContent(for: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .onChange(of: currentPage) { _, _ in
                    HapticManager.selection()
                    animationPhase = 0
                    withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                        animationPhase = 1
                    }
                }

                bottomControls
            }
        }
        .id(refreshID)
        .preferredColorScheme(settings.currentColorScheme)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                animationPhase = 1
            }
        }
        .onChange(of: settings.selectedLanguage) { _, _ in
            refreshID = UUID()
        }
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
                colors: [Color(red: 0.05, green: 0.08, blue: 0.24), Color(red: 0.11, green: 0.18, blue: 0.42)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color.blue.opacity(0.25))
                .frame(width: 380, height: 380)
                .blur(radius: 40)
                .offset(x: -120 + (animationPhase * 30), y: -300)

            Circle()
                .fill(Color.cyan.opacity(0.22))
                .frame(width: 300, height: 300)
                .blur(radius: 45)
                .offset(x: 150 - (animationPhase * 25), y: -180)

            Circle()
                .fill(Color.purple.opacity(0.2))
                .frame(width: 360, height: 360)
                .blur(radius: 55)
                .offset(x: 140, y: 300 - (animationPhase * 20))
        }
    }

    private var topBar: some View {
        HStack {
            Text(L("onboarding.v2.header"))
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))

            Spacer()

            if canDismiss {
                topBarButton(title: L("common.done")) {
                    HapticManager.light()
                    dismiss()
                }
            } else if currentPage < pages.count - 1 {
                topBarButton(title: L("onboarding.skip")) {
                    HapticManager.light()
                    completeOnboarding()
                }
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
            HStack(spacing: 8) {
                ForEach(0..<pages.count, id: \.self) { index in
                    Capsule()
                        .fill(currentPage == index ? Color.white : Color.white.opacity(0.3))
                        .frame(width: currentPage == index ? 30 : 8, height: 8)
                        .animation(.spring(response: 0.36, dampingFraction: 0.8), value: currentPage)
                }
            }

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
                                colors: [Color(red: 0.35, green: 0.53, blue: 0.98), Color(red: 0.45, green: 0.78, blue: 0.95)],
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
                        .fill(Color.black.opacity(0.24))
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.22), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
    }

    private func pageContent(for page: OnboardingPageModel) -> some View {
        VStack(spacing: 20) {
            heroCard(for: page)
                .padding(.top, 6)

            VStack(spacing: 10) {
                Text(L(page.titleKey))
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)

                Text(L(page.subtitleKey))
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white.opacity(0.82))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 34)
            }

            VStack(spacing: 12) {
                ForEach(page.bullets, id: \.titleKey) { bullet in
                    featureRow(bullet: bullet)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.white.opacity(0.16), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 24)

            Spacer(minLength: 8)
        }
    }

    private func heroCard(for page: OnboardingPageModel) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            page.gradient[0].opacity(0.8),
                            page.gradient[1].opacity(0.58)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )

            VStack(spacing: 16) {
                HStack {
                    Label(L(page.badgeTextKey), systemImage: page.badgeIcon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Color.black.opacity(0.25)))
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)

                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.16))
                        .frame(width: 122, height: 122)
                        .blur(radius: 1)

                    Circle()
                        .fill(.ultraThinMaterial.opacity(0.85))
                        .frame(width: 102, height: 102)

                    Image(systemName: page.heroIcon)
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(Double(animationPhase) * 6.0))
                }
                .shadow(color: page.gradient[0].opacity(0.55), radius: 18, x: 0, y: 10)

                HStack(spacing: 10) {
                    statChip(title: L("onboarding.v2.hero.chip1"), icon: "clock.fill")
                    statChip(title: L("onboarding.v2.hero.chip2"), icon: "point.topleft.down.curvedto.point.bottomright.up")
                    statChip(title: L("onboarding.v2.hero.chip3"), icon: "star.fill")
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .frame(height: 288)
        .padding(.horizontal, 24)
    }

    private func statChip(title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
            Text(title)
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.black.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }

    private func featureRow(bullet: OnboardingBullet) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(bullet.tint.opacity(0.28))
                    .frame(width: 34, height: 34)

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
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.74))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
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
