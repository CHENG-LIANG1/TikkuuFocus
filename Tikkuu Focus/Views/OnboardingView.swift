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
                titleKey: "onboarding.demo.page1.title",
                subtitleKey: "onboarding.demo.page1.subtitle",
                gradient: [Color(red: 0.25, green: 0.54, blue: 0.98), Color(red: 0.20, green: 0.80, blue: 0.84)],
                backgroundAccent: Color(red: 0.12, green: 0.24, blue: 0.52)
            ),
            OnboardingSlide(
                kind: .focus,
                titleKey: "onboarding.demo.page2.title",
                subtitleKey: "onboarding.demo.page2.subtitle",
                gradient: [Color(red: 0.97, green: 0.53, blue: 0.32), Color(red: 0.90, green: 0.27, blue: 0.56)],
                backgroundAccent: Color(red: 0.44, green: 0.16, blue: 0.30)
            ),
            OnboardingSlide(
                kind: .grow,
                titleKey: "onboarding.demo.page3.title",
                subtitleKey: "onboarding.demo.page3.subtitle",
                gradient: [Color(red: 0.99, green: 0.77, blue: 0.25), Color(red: 0.97, green: 0.46, blue: 0.25)],
                backgroundAccent: Color(red: 0.38, green: 0.22, blue: 0.09)
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
            return L("onboarding.demo.next")
        }
        return canDismiss ? L("common.done") : L("onboarding.demo.start")
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
                visualSection
                textSection
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(.top, isCompact ? 10 : 18)
            .padding(.bottom, 8)
        }
    }

    @ViewBuilder
    private var visualSection: some View {
        ZStack {
            switch slide.kind {
            case .plan:
                SetupDemoVisual(isVisible: isVisible)
            case .focus:
                RoamingDemoVisual(isVisible: isVisible)
            case .grow:
                AchievementDemoVisual(isVisible: isVisible)
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

// MARK: - Animated Visual Components

private struct SetupDemoVisual: View {
    let isVisible: Bool
    @State private var step1 = false
    @State private var step2 = false
    @State private var step3 = false

    var body: some View {
        HStack(spacing: 20) {
            demoItem(icon: "mappin.and.ellipse", color: .blue, show: step1)
            Image(systemName: "arrow.right").foregroundStyle(.white.opacity(0.3)).opacity(step1 ? 1 : 0)
            
            demoItem(icon: "figure.walk", color: .cyan, show: step2)
            Image(systemName: "arrow.right").foregroundStyle(.white.opacity(0.3)).opacity(step2 ? 1 : 0)
            
            demoItem(icon: "timer", color: .mint, show: step3)
        }
        .frame(height: 160)
        .onChange(of: isVisible) { _, visible in
            if visible { startAnimation() } else { resetAnimation() }
        }
        .onAppear { if isVisible { startAnimation() } }
    }

    func demoItem(icon: String, color: Color, show: Bool) -> some View {
        Image(systemName: icon)
            .font(.system(size: 32, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 72, height: 72)
            .background(Circle().fill(color.gradient))
            .shadow(color: color.opacity(0.4), radius: 10, y: 5)
            .scaleEffect(show ? 1 : 0.01)
            .opacity(show ? 1 : 0)
    }

    func startAnimation() {
        step1 = false; step2 = false; step3 = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) { step1 = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) { step2 = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) { step3 = true }
        }
    }
    
    func resetAnimation() {
        step1 = false; step2 = false; step3 = false
    }
}

private struct RoamingDemoVisual: View {
    let isVisible: Bool
    @State private var progress: CGFloat = 0
    @State private var showPOI1 = false
    @State private var showPOI2 = false

    var body: some View {
        ZStack {
            Image(systemName: "map.fill")
                .font(.system(size: 110))
                .foregroundStyle(.white.opacity(0.08))
            
            Path { p in
                p.move(to: CGPoint(x: -70, y: 30))
                p.addCurve(to: CGPoint(x: 70, y: -30), control1: CGPoint(x: -30, y: 70), control2: CGPoint(x: 30, y: -70))
            }
            .trim(from: 0, to: progress)
            .stroke(
                LinearGradient(colors: [.orange, .pink], startPoint: .leading, endPoint: .trailing),
                style: StrokeStyle(lineWidth: 6, lineCap: .round)
            )
            .frame(width: 0, height: 0)

            poiMarker(icon: "camera.fill", color: .orange, show: showPOI1)
                .offset(x: -20, y: 35)

            poiMarker(icon: "star.fill", color: .pink, show: showPOI2)
                .offset(x: 70, y: -30)
        }
        .frame(height: 160)
        .onChange(of: isVisible) { _, visible in
            if visible { startAnimation() } else { resetAnimation() }
        }
        .onAppear { if isVisible { startAnimation() } }
    }
    
    func poiMarker(icon: String, color: Color, show: Bool) -> some View {
        Image(systemName: icon)
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 36, height: 36)
            .background(Circle().fill(color.gradient))
            .shadow(color: color.opacity(0.4), radius: 6, y: 3)
            .scaleEffect(show ? 1 : 0.01)
            .opacity(show ? 1 : 0)
    }

    func startAnimation() {
        progress = 0; showPOI1 = false; showPOI2 = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeInOut(duration: 2.5)) { progress = 1 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) { showPOI1 = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.7) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) { showPOI2 = true }
        }
    }
    
    func resetAnimation() {
        progress = 0; showPOI1 = false; showPOI2 = false
    }
}

private struct AchievementDemoVisual: View {
    let isVisible: Bool
    @State private var showTrophy = false
    @State private var showStat1 = false
    @State private var showStat2 = false
    @State private var floatOffset: CGFloat = 0

    var body: some View {
        ZStack {
            Image(systemName: "trophy.fill")
                .font(.system(size: 90))
                .foregroundStyle(
                    LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .shadow(color: .orange.opacity(0.5), radius: 20, y: 10)
                .scaleEffect(showTrophy ? 1 : 0.01)
                .rotationEffect(.degrees(showTrophy ? 0 : -20))
                .offset(y: floatOffset)

            statPill(icon: "map.fill", text: "25 km", color: .blue)
                .offset(x: -80, y: -40 + floatOffset * 0.5)
                .scaleEffect(showStat1 ? 1 : 0.01)
                .opacity(showStat1 ? 1 : 0)

            statPill(icon: "star.fill", text: "12 POIs", color: .pink)
                .offset(x: 75, y: 50 + floatOffset * 0.8)
                .scaleEffect(showStat2 ? 1 : 0.01)
                .opacity(showStat2 ? 1 : 0)
        }
        .frame(height: 160)
        .onChange(of: isVisible) { _, visible in
            if visible { startAnimation() } else { resetAnimation() }
        }
        .onAppear { if isVisible { startAnimation() } }
    }

    func statPill(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).foregroundStyle(color)
            Text(text).font(.system(size: 14, weight: .bold)).foregroundStyle(.white)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.15))
                .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1))
        )
        .shadow(radius: 10)
    }

    func startAnimation() {
        showTrophy = false; showStat1 = false; showStat2 = false; floatOffset = 0
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) { showTrophy = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) { showStat1 = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) { showStat2 = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                floatOffset = -10
            }
        }
    }
    
    func resetAnimation() {
        showTrophy = false; showStat1 = false; showStat2 = false; floatOffset = 0
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
}

#Preview {
    OnboardingView()
}
