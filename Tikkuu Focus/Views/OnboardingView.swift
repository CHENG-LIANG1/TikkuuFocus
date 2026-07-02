import SwiftUI
import CoreLocation

// MARK: - Onboarding View

struct OnboardingView: View {
    @StateObject private var settings = AppSettings.shared
    @State private var currentPage = 0
    @State private var refreshID = UUID()
    @State private var orbDrift: CGFloat = 0
    @State private var selectedTransport: TransportMode = .cycling
    @State private var selectedDuration: Int = 25
    @State private var locationPermissionStatus: CLAuthorizationStatus = CLLocationManager().authorizationStatus
    let canDismiss: Bool
    @Environment(\.dismiss) private var dismiss

    init(canDismiss: Bool = false) {
        self.canDismiss = canDismiss
        _selectedTransport = State(initialValue: AppSettings.shared.preferredTransportMode)
        _selectedDuration = State(initialValue: AppSettings.shared.preferredDuration)
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
                        welcomePage(isCompact: isCompact)
                            .tag(0)
                        interactiveSetupPage(isCompact: isCompact)
                            .tag(1)
                        simulationPage(isCompact: isCompact)
                            .tag(2)
                        permissionsPage(isCompact: isCompact)
                            .tag(3)
                        readyPage(isCompact: isCompact)
                            .tag(4)
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

    // MARK: - Pages

    private func welcomePage(isCompact: Bool) -> some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)

            // Pomodoro timer hero — a focus ring wrapped around a tomato
            pomodoroHero
                .frame(height: isCompact ? 150 : 180)

            Spacer().frame(height: isCompact ? 18 : 26)

            // Pomodoro badge
            HStack(spacing: 6) {
                Image(systemName: "timer")
                    .font(.system(size: 11, weight: .bold))
                Text(L("onboarding.welcome.badge"))
                    .font(.system(size: 12, weight: .bold))
            }
            .foregroundStyle(.white.opacity(0.92))
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(
                Capsule(style: .continuous)
                    .fill(Color(red: 0.95, green: 0.33, blue: 0.28).opacity(0.22))
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(Color(red: 0.98, green: 0.5, blue: 0.4).opacity(0.45), lineWidth: 1)
                    )
            )

            Spacer().frame(height: isCompact ? 12 : 16)

            VStack(spacing: 10) {
                Text(L("onboarding.welcome.title"))
                    .font(.system(size: isCompact ? 27 : 33, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)

                Text(L("onboarding.welcome.subtitle"))
                    .font(.system(size: isCompact ? 14 : 16, weight: .regular))
                    .foregroundStyle(.white.opacity(0.78))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 36)
            }

            Spacer().frame(height: isCompact ? 20 : 28)

            // How it works — 3 quick steps
            HStack(spacing: 10) {
                conceptStep(number: "1", icon: "timer", label: L("onboarding.welcome.step1"), color: Color(red: 0.97, green: 0.45, blue: 0.30))
                stepArrow
                conceptStep(number: "2", icon: "figure.walk", label: L("onboarding.welcome.step2"), color: .cyan)
                stepArrow
                conceptStep(number: "3", icon: "trophy.fill", label: L("onboarding.welcome.step3"), color: .yellow)
            }
            .padding(.horizontal, 24)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var pomodoroHero: some View {
        ZStack {
            Circle()
                .fill(Color(red: 0.95, green: 0.33, blue: 0.28).opacity(0.18))
                .frame(width: 200, height: 200)
                .blur(radius: 46)

            // Timer track
            Circle()
                .stroke(Color.white.opacity(0.12), lineWidth: 11)
                .frame(width: 150, height: 150)

            // Timer progress arc
            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(
                    LinearGradient(
                        colors: [Color(red: 0.99, green: 0.55, blue: 0.28), Color(red: 0.95, green: 0.28, blue: 0.30)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 11, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: 150, height: 150)

            // Endpoint dot
            Circle()
                .fill(.white)
                .frame(width: 13, height: 13)
                .shadow(color: .black.opacity(0.25), radius: 3, y: 1)
                .offset(y: -75)
                .rotationEffect(.degrees(0.7 * 360))

            // Tomato center
            Text("🍅")
                .font(.system(size: 56))
                .shadow(color: .red.opacity(0.3), radius: 10, y: 4)
        }
    }

    private var stepArrow: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(.white.opacity(0.3))
    }

    private func conceptStep(number: String, icon: String, label: String, color: Color) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.16))
                    .overlay(Circle().stroke(color.opacity(0.4), lineWidth: 1))
                    .frame(width: 52, height: 52)
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(color)
            }
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.85))
        }
    }

    private func interactiveSetupPage(isCompact: Bool) -> some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)

            Text(L("onboarding.setup.title"))
                .font(.system(size: isCompact ? 24 : 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            Spacer().frame(height: isCompact ? 6 : 10)

            Text(L("onboarding.setup.subtitle"))
                .font(.system(size: isCompact ? 14 : 15, weight: .regular))
                .foregroundStyle(.white.opacity(0.75))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer().frame(height: isCompact ? 14 : 20)

            // Transport mode selector
            VStack(spacing: 8) {
                Text(L("onboarding.setup.transport.label"))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)

                HStack(spacing: 10) {
                    ForEach(TransportMode.allCases) { mode in
                        transportButton(mode: mode, isSelected: selectedTransport == mode)
                    }
                }
                .padding(.horizontal, 20)
            }

            Spacer().frame(height: isCompact ? 12 : 16)

            // Duration selector
            VStack(spacing: 8) {
                Text(L("onboarding.setup.duration.label"))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)

                HStack(spacing: 10) {
                    ForEach([15, 25, 45], id: \.self) { duration in
                        durationButton(duration: duration, isSelected: selectedDuration == duration)
                    }
                }
                .padding(.horizontal, 20)
            }

            Spacer().frame(height: isCompact ? 14 : 18)

            // Live preview card
            VStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "eye.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.cyan)
                    Text(L("onboarding.setup.preview.title"))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.8))
                }

                HStack(spacing: 16) {
                    previewItem(icon: selectedTransport.iconName, label: selectedTransport.localizedName, color: .cyan)
                    Text("→")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white.opacity(0.3))
                    previewItem(icon: "timer", label: "\(selectedDuration) min", color: .orange)
                    Text("→")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white.opacity(0.3))
                    previewItem(icon: "map.fill", label: estimatedDistance, color: .green)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 14)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                )
            }
            .padding(.horizontal, 20)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func transportButton(mode: TransportMode, isSelected: Bool) -> some View {
        Button {
            HapticManager.medium()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                selectedTransport = mode
            }
        } label: {
            VStack(spacing: 8) {
                Image(systemName: mode.iconName)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(isSelected ? .white : .white.opacity(0.7))
                    .frame(width: 56, height: 56)
                    .background(
                        Circle()
                            .fill(isSelected ? Color.cyan.opacity(0.25) : Color.white.opacity(0.08))
                            .overlay(
                                Circle()
                                    .stroke(isSelected ? Color.cyan.opacity(0.5) : Color.white.opacity(0.1), lineWidth: isSelected ? 2 : 1)
                            )
                    )

                Text(mode.localizedName)
                    .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                    .foregroundStyle(isSelected ? .white : .white.opacity(0.6))
            }
        }
        .buttonStyle(.plain)
    }

    private func durationButton(duration: Int, isSelected: Bool) -> some View {
        Button {
            HapticManager.medium()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                selectedDuration = duration
            }
        } label: {
            Text("\(duration) min")
                .font(.system(size: 15, weight: isSelected ? .bold : .semibold))
                .foregroundStyle(isSelected ? .white : .white.opacity(0.7))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    Capsule(style: .continuous)
                        .fill(isSelected ? Color.orange.opacity(0.25) : Color.white.opacity(0.08))
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(isSelected ? Color.orange.opacity(0.5) : Color.white.opacity(0.1), lineWidth: isSelected ? 2 : 1)
                        )
                )
        }
        .buttonStyle(.plain)
    }

    private func previewItem(icon: String, label: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
        }
    }

    private var estimatedDistance: String {
        let km = Double(selectedDuration) / 60.0 * selectedTransport.speedKmh
        if km < 1 {
            return String(format: "%.0f m", km * 1000)
        }
        return String(format: "%.1f km", km)
    }

    private func simulationPage(isCompact: Bool) -> some View {
        VStack(spacing: isCompact ? 20 : 28) {
            Spacer().frame(height: isCompact ? 8 : 16)

            Text(L("onboarding.sim.title"))
                .font(.system(size: isCompact ? 26 : 30, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            Text(L("onboarding.sim.subtitle"))
                .font(.system(size: isCompact ? 15 : 16, weight: .regular))
                .foregroundStyle(.white.opacity(0.75))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            JourneySimulationView(transportMode: selectedTransport)
                .frame(height: isCompact ? 200 : 260)
                .padding(.horizontal, 20)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func permissionsPage(isCompact: Bool) -> some View {
        VStack(spacing: isCompact ? 24 : 36) {
            Spacer().frame(height: isCompact ? 20 : 40)

            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 140, height: 140)
                    .blur(radius: 40)

                Image(systemName: "location.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(
                        LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .shadow(color: .green.opacity(0.4), radius: 16, y: 8)
            }
            .frame(height: 140)

            VStack(spacing: 14) {
                Text(L("onboarding.perm.title"))
                    .font(.system(size: isCompact ? 26 : 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)

                Text(L("onboarding.perm.subtitle"))
                    .font(.system(size: isCompact ? 15 : 16, weight: .regular))
                    .foregroundStyle(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .padding(.horizontal, 36)
            }

            VStack(spacing: 14) {
                permissionRow(icon: "location.fill", color: .green, title: L("onboarding.perm.location.title"), desc: L("onboarding.perm.location.desc"))
                permissionRow(icon: "bell.fill", color: .orange, title: L("onboarding.perm.notif.title"), desc: L("onboarding.perm.notif.desc"))
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func permissionRow(icon: String, color: Color, title: String, desc: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(color.opacity(0.15))
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                Text(desc)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
    }

    private func readyPage(isCompact: Bool) -> some View {
        VStack(spacing: isCompact ? 24 : 36) {
            Spacer().frame(height: isCompact ? 20 : 40)

            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.15))
                    .frame(width: 160, height: 160)
                    .blur(radius: 50)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(
                        LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .shadow(color: .purple.opacity(0.4), radius: 18, y: 8)
                    .scaleEffect(1.0)
            }
            .frame(height: 140)

            VStack(spacing: 12) {
                Text(L("onboarding.ready.title"))
                    .font(.system(size: isCompact ? 28 : 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text(L("onboarding.ready.subtitle"))
                    .font(.system(size: isCompact ? 15 : 16, weight: .regular))
                    .foregroundStyle(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 36)
            }

            // Summary card
            VStack(spacing: 16) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.yellow)
                    Text(L("onboarding.ready.config.title"))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.8))
                }

                HStack(spacing: 16) {
                    summaryPill(icon: selectedTransport.iconName, text: selectedTransport.localizedName, color: .cyan)
                    summaryPill(icon: "timer", text: "\(selectedDuration) min", color: .orange)
                    summaryPill(icon: "map.fill", text: estimatedDistance, color: .green)
                }
            }
            .padding(.vertical, 18)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 24)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func summaryPill(icon: String, text: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(color)
            Text(text)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(width: 80)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
    }

    // MARK: - Background

    private var backgroundView: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.03, green: 0.05, blue: 0.10),
                    pageAccentColor.opacity(0.7),
                    Color(red: 0.06, green: 0.07, blue: 0.14)
                ],
                startPoint: .topLeading,
                endPoint: .bottom
            )

            Circle()
                .fill(pageGradient[0].opacity(0.25))
                .frame(width: 360, height: 360)
                .blur(radius: 92)
                .offset(x: -110, y: -250 + orbDrift * 22)

            Circle()
                .fill(pageGradient[1].opacity(0.22))
                .frame(width: 280, height: 280)
                .blur(radius: 84)
                .offset(x: 130, y: 100 - orbDrift * 18)

            Circle()
                .fill(Color.white.opacity(0.06))
                .frame(width: 180, height: 180)
                .blur(radius: 60)
                .offset(x: 26, y: 330 + orbDrift * 14)
        }
        .animation(.easeInOut(duration: 0.75), value: currentPage)
    }

    private var pageGradient: [Color] {
        switch currentPage {
        case 0: return [Color(red: 0.25, green: 0.54, blue: 0.98), Color(red: 0.20, green: 0.80, blue: 0.84)]
        case 1: return [Color(red: 0.97, green: 0.53, blue: 0.32), Color(red: 0.90, green: 0.27, blue: 0.56)]
        case 2: return [Color(red: 0.99, green: 0.77, blue: 0.25), Color(red: 0.97, green: 0.46, blue: 0.25)]
        case 3: return [Color(red: 0.30, green: 0.85, blue: 0.50), Color(red: 0.20, green: 0.70, blue: 0.85)]
        case 4: return [Color(red: 0.65, green: 0.35, blue: 0.95), Color(red: 0.95, green: 0.30, blue: 0.65)]
        default: return [.blue, .cyan]
        }
    }

    private var pageAccentColor: Color {
        switch currentPage {
        case 0: return Color(red: 0.12, green: 0.24, blue: 0.52)
        case 1: return Color(red: 0.44, green: 0.16, blue: 0.30)
        case 2: return Color(red: 0.38, green: 0.22, blue: 0.09)
        case 3: return Color(red: 0.10, green: 0.30, blue: 0.20)
        case 4: return Color(red: 0.25, green: 0.12, blue: 0.40)
        default: return .black
        }
    }

    // MARK: - Top Bar

    private func topBar(isCompact: Bool) -> some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Circle()
                    .fill(pageGradient[0])
                    .frame(width: 8, height: 8)

                Text("\(currentPage + 1) / 5")
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
            } else if currentPage < 4 {
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

    // MARK: - Bottom Section

    private func bottomSection(isCompact: Bool) -> some View {
        VStack(spacing: isCompact ? 20 : 28) {
            HStack(spacing: 9) {
                ForEach(0..<5, id: \.self) { index in
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
                                    colors: pageGradient,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: pageGradient[0].opacity(0.45), radius: 18, x: 0, y: 10)
                    )
            }
            .buttonStyle(ScaleButtonStyle())
            .disabled(isPrimaryButtonDisabled)
            .opacity(isPrimaryButtonDisabled ? 0.6 : 1)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, isCompact ? 30 : 50)
    }

    private var primaryButtonTitle: String {
        switch currentPage {
        case 0: return L("onboarding.btn.start")
        case 1: return L("onboarding.btn.next")
        case 2: return L("onboarding.btn.gotit")
        case 3:
            if locationPermissionStatus == .notDetermined {
                return L("onboarding.btn.allowlocation")
            } else if locationPermissionStatus == .denied || locationPermissionStatus == .restricted {
                return L("onboarding.btn.opensettings")
            }
            return L("onboarding.btn.next")
        case 4: return canDismiss ? L("common.done") : L("onboarding.btn.begin")
        default: return L("onboarding.btn.next")
        }
    }

    private var isPrimaryButtonDisabled: Bool {
        false
    }

    private func handlePrimaryAction() {
        HapticManager.medium()

        switch currentPage {
        case 0, 1, 2:
            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                currentPage += 1
            }
        case 3:
            handlePermissionPageAction()
        case 4:
            if canDismiss {
                dismiss()
            } else {
                completeOnboarding()
            }
        default:
            break
        }
    }

    private func handlePermissionPageAction() {
        let status = CLLocationManager().authorizationStatus
        locationPermissionStatus = status

        switch status {
        case .notDetermined:
            let manager = CLLocationManager()
            manager.requestWhenInUseAuthorization()
            // Poll for change
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                locationPermissionStatus = CLLocationManager().authorizationStatus
                if locationPermissionStatus != .notDetermined {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                        currentPage += 1
                    }
                }
            }
        case .denied, .restricted:
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                currentPage += 1
            }
        case .authorizedWhenInUse, .authorizedAlways:
            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                currentPage += 1
            }
        @unknown default:
            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                currentPage += 1
            }
        }
    }

    private func startAnimations() {
        withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
            orbDrift = 1
        }
    }

    private func dismissAction() {
        HapticManager.light()
        dismiss()
    }

    private func completeOnboarding() {
        HapticManager.success()
        settings.preferredTransportMode = selectedTransport
        settings.preferredDuration = selectedDuration
        withAnimation {
            settings.hasCompletedOnboarding = true
        }
        dismiss()
    }
}

// MARK: - Journey Simulation View

private struct JourneySimulationView: View {
    let transportMode: TransportMode
    @State private var progress: CGFloat = 0
    @State private var showPOI1 = false
    @State private var showPOI2 = false
    @State private var showPOI3 = false
    @State private var hasStarted = false

    var body: some View {
        ZStack {
            // Background map hint
            Image(systemName: "map.fill")
                .font(.system(size: 140))
                .foregroundStyle(.white.opacity(0.05))

            // Route path
            Path { path in
                let w: CGFloat = 180
                let h: CGFloat = 120
                path.move(to: CGPoint(x: -w * 0.45, y: h * 0.35))
                path.addCurve(
                    to: CGPoint(x: w * 0.5, y: -h * 0.3),
                    control1: CGPoint(x: -w * 0.15, y: h * 0.6),
                    control2: CGPoint(x: w * 0.2, y: -h * 0.55)
                )
            }
            .trim(from: 0, to: progress)
            .stroke(
                LinearGradient(colors: [.orange, .pink, .purple], startPoint: .leading, endPoint: .trailing),
                style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round)
            )
            .frame(width: 180, height: 120)

            // POI markers
            poiMarker(icon: "cup.and.saucer.fill", label: "Starbucks", color: .orange)
                .offset(x: -30, y: 55)
                .opacity(showPOI1 ? 1 : 0)
                .scaleEffect(showPOI1 ? 1 : 0.01)

            poiMarker(icon: "leaf.fill", label: "Park", color: .green)
                .offset(x: 50, y: -10)
                .opacity(showPOI2 ? 1 : 0)
                .scaleEffect(showPOI2 ? 1 : 0.01)

            poiMarker(icon: "building.columns.fill", label: "Museum", color: .purple)
                .offset(x: -10, y: -55)
                .opacity(showPOI3 ? 1 : 0)
                .scaleEffect(showPOI3 ? 1 : 0.01)

            // Traveling avatar
            if progress > 0 {
                AvatarOnPath(progress: progress, icon: transportMode.iconName)
                    .frame(width: 180, height: 120)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .onAppear {
            if !hasStarted {
                hasStarted = true
                startAnimation()
            }
        }
    }

    private func poiMarker(icon: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(Circle().fill(color.gradient))
                .shadow(color: color.opacity(0.4), radius: 6, y: 3)

            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.5))
                )
        }
    }

    private func startAnimation() {
        progress = 0; showPOI1 = false; showPOI2 = false; showPOI3 = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeInOut(duration: 2.8)) { progress = 1 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) { showPOI1 = true }
            HapticManager.light()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) { showPOI2 = true }
            HapticManager.light()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) { showPOI3 = true }
            HapticManager.success()
        }
    }
}

private struct AvatarOnPath: View {
    let progress: CGFloat
    let icon: String

    var body: some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            let h = geometry.size.height
            let point = cubicBezierPoint(
                t: progress,
                p0: CGPoint(x: -w * 0.45, y: h * 0.35),
                p1: CGPoint(x: -w * 0.15, y: h * 0.6),
                p2: CGPoint(x: w * 0.2, y: -h * 0.55),
                p3: CGPoint(x: w * 0.5, y: -h * 0.3)
            )

            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 44, height: 44)
                    .blur(radius: 8)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(LinearGradient(colors: [.cyan, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                    )
                    .shadow(color: .cyan.opacity(0.5), radius: 10, y: 5)
            }
            .position(x: point.x + w / 2, y: point.y + h / 2)
        }
    }

    private func cubicBezierPoint(t: CGFloat, p0: CGPoint, p1: CGPoint, p2: CGPoint, p3: CGPoint) -> CGPoint {
        let mt = 1 - t
        let mt2 = mt * mt
        let mt3 = mt2 * mt
        let t2 = t * t
        let t3 = t2 * t

        let x = mt3 * p0.x + 3 * mt2 * t * p1.x + 3 * mt * t2 * p2.x + t3 * p3.x
        let y = mt3 * p0.y + 3 * mt2 * t * p1.y + 3 * mt * t2 * p2.y + t3 * p3.y
        return CGPoint(x: x, y: y)
    }
}

// MARK: - Preview

#Preview {
    OnboardingView()
}
