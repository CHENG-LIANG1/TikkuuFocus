//
//  ActiveJourneyView.swift
//  Tikkuu Focus
//
//  Created by Tikkuu on 2026/2/8.
//

import SwiftUI
import MapKit
import SwiftData
import WeatherKit
import Combine

struct ActiveJourneyView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var journeyManager: JourneyManager
    @ObservedObject private var settings = AppSettings.shared

    @State private var showStopConfirmation = false
    @State private var selectedLocationSource: LocationSource = .currentLocation
    @State private var showHistory = false
    @State private var showCustomStopDialog = false
    @State private var currentSpeed: Double = 0.0
    @State private var isStatsExpanded = true
    @StateObject private var weatherManager = WeatherManager()
    private let weatherRefreshTimer = Timer.publish(every: 600, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            // Exploration map background
            if let session = journeyManager.state.session {
                ExplorationMapView(
                    session: session,
                    currentPosition: journeyManager.currentPosition,
                    discoveredPOIs: journeyManager.discoveredPOIs,
                    isPaused: journeyManager.state.isPaused,
                    currentSpeed: $currentSpeed
                )
                .ignoresSafeArea()
            }

            // Overlay UI
            VStack(spacing: 0) {
                topOverlay
                    .padding(.top, 12)

                Spacer()

                // Bottom stats panel
                VStack(spacing: 12) {
                    if shouldShowControlsPanel {
                        controlsPanel
                            .padding(.horizontal, 20)
                    }

                    statsPanel
                        .padding(.horizontal, 6)
                }
                .padding(.bottom, -2)
            }
        }
        .preferredColorScheme(settings.currentColorScheme)
        .overlay {
            if showCustomStopDialog {
                customStopDialog
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .sheet(isPresented: $showHistory) {
            HistoryView()
        }
        .task {
            await refreshWeather()
        }
        .onReceive(weatherRefreshTimer) { _ in
            Task {
                await refreshWeather()
            }
        }
    }

    // MARK: - Top Overlay

    private var topOverlay: some View {
        unifiedTopPill
    }

    private var isJourneyActive: Bool {
        if case .active = journeyManager.state { return true }
        return false
    }

    private var shouldShowControlsPanel: Bool {
        switch journeyManager.state {
        case .active, .paused:
            return true
        default:
            return false
        }
    }

    private var journeyStatusColor: Color {
        switch journeyManager.state {
        case .active:
            return .green
        case .completed:
            return .blue
        default:
            return .orange
        }
    }

    private var journeyStatusLabel: String {
        switch journeyManager.state {
        case .active:
            return L("journey.state.active")
        case .completed:
            return L("journey.completed")
        default:
            return L("journey.state.paused")
        }
    }

    // MARK: - Unified Top Pill

    private var unifiedTopPill: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(journeyStatusColor)
                        .frame(width: 8, height: 8)
                        .shadow(color: journeyStatusColor.opacity(0.6), radius: 3, x: 0, y: 0)
                    Text(journeyStatusLabel)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }

                if !weatherManager.isLoading {
                    Rectangle()
                        .fill(Color.white.opacity(0.22))
                        .frame(width: 1, height: 14)
                }

                HStack(spacing: 6) {
                    if weatherManager.isLoading {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.7)
                            .frame(width: 14, height: 14)
                    } else {
                        Image(systemName: weatherManager.weatherIcon)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .symbolRenderingMode(.hierarchical)

                        Text(weatherManager.temperatureString)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
            }

            if focusGoalText != nil || journeyManager.state.session?.vehicle != nil {
                HStack(spacing: 8) {
                    if let focusGoalText {
                        topPillTag(icon: "target", text: focusGoalText, maxWidth: 150)
                    }

                    if let vehicle = journeyManager.state.session?.vehicle {
                        topPillTag(
                            icon: vehicle.energyType == .electric ? "bolt.car.fill" : "car.fill",
                            text: vehicleTopPillText(vehicle),
                            maxWidth: 210
                        )
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(unifiedTopPillBackground)
        .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 6)
    }

    private func topPillTag(icon: String, text: String, maxWidth: CGFloat) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)

            Text(text)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .frame(maxWidth: maxWidth, alignment: .leading)
        .background(
            Capsule(style: .continuous)
                .fill(Color.white.opacity(0.10))
        )
    }

    private var focusGoalText: String? {
        let goal = journeyManager.state.session?.focusGoal ?? ""
        let trimmed = goal.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func vehicleTopPillText(_ vehicle: Vehicle) -> String {
        let plate = vehicle.plate.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !plate.isEmpty else { return vehicle.modelDisplayName }
        return "\(vehicle.modelDisplayName) · \(plate)"
    }

    @ViewBuilder
    private var unifiedTopPillBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)

            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.black.opacity(colorScheme == .dark ? 0.4 : 0.2))

            if !weatherManager.isLoading {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: weatherPalette.backgroundGradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                )
            }

            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Color.white.opacity(colorScheme == .dark ? 0.15 : 0.3), lineWidth: 1)
        }
    }

    private var weatherPalette: WeatherBannerPalette {
        let hour = Calendar.current.component(.hour, from: Date())

        if let condition = weatherManager.weatherCondition {
            switch condition {
            case .rain, .drizzle, .heavyRain, .freezingDrizzle, .freezingRain:
                return WeatherBannerPalette(
                    backgroundGradient: [
                        Color(red: 0.18, green: 0.31, blue: 0.50).opacity(0.34),
                        Color(red: 0.11, green: 0.20, blue: 0.33).opacity(0.24),
                        Color.black.opacity(0.14)
                    ],
                    iconGradient: [
                        Color(red: 0.35, green: 0.61, blue: 0.95),
                        Color(red: 0.19, green: 0.42, blue: 0.82)
                    ]
                )
            case .thunderstorms, .tropicalStorm, .hurricane:
                return WeatherBannerPalette(
                    backgroundGradient: [
                        Color(red: 0.34, green: 0.25, blue: 0.58).opacity(0.34),
                        Color(red: 0.13, green: 0.17, blue: 0.33).opacity(0.24),
                        Color.black.opacity(0.16)
                    ],
                    iconGradient: [
                        Color(red: 0.49, green: 0.43, blue: 0.94),
                        Color(red: 0.28, green: 0.37, blue: 0.83)
                    ]
                )
            case .snow, .sleet, .hail, .blizzard, .blowingSnow, .flurries:
                return WeatherBannerPalette(
                    backgroundGradient: [
                        Color(red: 0.62, green: 0.78, blue: 0.95).opacity(0.24),
                        Color(red: 0.32, green: 0.46, blue: 0.66).opacity(0.18),
                        Color.black.opacity(0.12)
                    ],
                    iconGradient: [
                        Color(red: 0.83, green: 0.92, blue: 1.0),
                        Color(red: 0.53, green: 0.72, blue: 0.93)
                    ]
                )
            case .cloudy, .mostlyCloudy, .partlyCloudy, .mostlyClear, .foggy, .haze, .smoky, .blowingDust:
                return hour >= 17 && hour < 20
                    ? WeatherBannerPalette(
                        backgroundGradient: [
                            Color(red: 0.67, green: 0.44, blue: 0.34).opacity(0.28),
                            Color(red: 0.33, green: 0.30, blue: 0.46).opacity(0.20),
                            Color.black.opacity(0.13)
                        ],
                        iconGradient: [
                            Color(red: 0.98, green: 0.69, blue: 0.45),
                            Color(red: 0.73, green: 0.54, blue: 0.82)
                        ]
                    )
                    : WeatherBannerPalette(
                        backgroundGradient: [
                            Color(red: 0.44, green: 0.54, blue: 0.66).opacity(0.24),
                            Color(red: 0.23, green: 0.30, blue: 0.40).opacity(0.18),
                            Color.black.opacity(0.12)
                        ],
                        iconGradient: [
                            Color(red: 0.73, green: 0.80, blue: 0.90),
                            Color(red: 0.46, green: 0.58, blue: 0.74)
                        ]
                    )
            case .clear:
                if hour >= 11 && hour < 16 {
                    return WeatherBannerPalette(
                        backgroundGradient: [
                            Color(red: 0.93, green: 0.72, blue: 0.25).opacity(0.30),
                            Color(red: 0.43, green: 0.32, blue: 0.11).opacity(0.18),
                            Color.black.opacity(0.12)
                        ],
                        iconGradient: [
                            Color(red: 1.0, green: 0.86, blue: 0.37),
                            Color(red: 0.98, green: 0.62, blue: 0.22)
                        ]
                    )
                } else if hour >= 17 && hour < 20 {
                    return WeatherBannerPalette(
                        backgroundGradient: [
                            Color(red: 0.95, green: 0.49, blue: 0.34).opacity(0.30),
                            Color(red: 0.56, green: 0.31, blue: 0.58).opacity(0.22),
                            Color.black.opacity(0.13)
                        ],
                        iconGradient: [
                            Color(red: 1.0, green: 0.72, blue: 0.41),
                            Color(red: 0.97, green: 0.43, blue: 0.48)
                        ]
                    )
                } else if hour >= 6 && hour < 11 {
                    return WeatherBannerPalette(
                        backgroundGradient: [
                            Color(red: 0.48, green: 0.68, blue: 0.94).opacity(0.28),
                            Color(red: 0.92, green: 0.65, blue: 0.31).opacity(0.18),
                            Color.black.opacity(0.12)
                        ],
                        iconGradient: [
                            Color(red: 0.76, green: 0.88, blue: 1.0),
                            Color(red: 1.0, green: 0.74, blue: 0.35)
                        ]
                    )
                } else {
                    return WeatherBannerPalette(
                        backgroundGradient: [
                            Color(red: 0.27, green: 0.34, blue: 0.66).opacity(0.28),
                            Color(red: 0.38, green: 0.29, blue: 0.62).opacity(0.20),
                            Color.black.opacity(0.14)
                        ],
                        iconGradient: [
                            Color(red: 0.64, green: 0.72, blue: 0.98),
                            Color(red: 0.47, green: 0.55, blue: 0.90)
                        ]
                    )
                }
            case .breezy, .windy:
                return WeatherBannerPalette(
                    backgroundGradient: [
                        Color(red: 0.86, green: 0.64, blue: 0.23).opacity(0.28),
                        Color(red: 0.32, green: 0.37, blue: 0.18).opacity(0.16),
                        Color.black.opacity(0.12)
                    ],
                    iconGradient: [
                        Color(red: 1.0, green: 0.83, blue: 0.33),
                        Color(red: 0.98, green: 0.67, blue: 0.22)
                    ]
                )
            default:
                break
            }
        }

        return WeatherBannerPalette(
            backgroundGradient: [
                Color(red: 0.37, green: 0.53, blue: 0.82).opacity(0.26),
                Color(red: 0.42, green: 0.35, blue: 0.74).opacity(0.18),
                Color.black.opacity(0.12)
            ],
            iconGradient: [
                Color(red: 0.59, green: 0.77, blue: 0.97),
                Color(red: 0.58, green: 0.52, blue: 0.93)
            ]
        )
    }

    private var weatherCaption: String {
        weatherManager.isLoading ? L("common.loading") : L("label.weather")
    }

    private var weatherSubtitle: String {
        if weatherManager.isLoading {
            return L("common.loading")
        }

        if !weatherManager.weatherDescription.isEmpty {
            return weatherManager.weatherDescription
        }

        return L("label.weather")
    }

    private func refreshWeather() async {
        guard let session = journeyManager.state.session else { return }
        let coordinate = journeyManager.currentPosition?.coordinate ?? session.startLocation
        await weatherManager.fetchWeather(for: coordinate)
    }

    private struct WeatherBannerPalette {
        let backgroundGradient: [Color]
        let iconGradient: [Color]
    }

    // MARK: - Stats Panel

    private var statsPanel: some View {
        VStack(spacing: 20) {
            if case .completed(let session) = journeyManager.state {
                CompletedJourneyStatsPanel(
                    session: session,
                    discoveredPOIs: journeyManager.discoveredPOIs
                ) {
                    HapticManager.success()
                    saveCompletedJourney(session: session)
                    presentSummary(
                        session: session,
                        progress: 1.0,
                        isCompleted: true,
                        actualDuration: Date().timeIntervalSince(session.startTime),
                        discoveredPOIs: journeyManager.discoveredPOIs
                    )
                }
                .padding(20)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(.ultraThinMaterial)

                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(Color.black.opacity(colorScheme == .dark ? 0.18 : 0.04))

                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .strokeBorder(Color.white.opacity(colorScheme == .dark ? 0.15 : 0.4), lineWidth: 1)
                    }
                )
                .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 8)
            } else if let position = journeyManager.currentPosition,
                      let session = journeyManager.state.session {
                // Time remaining (large)
                ActiveJourneyStatsPanel(
                    position: position,
                    currentSpeed: currentSpeed,
                    session: session,
                    isExpanded: isStatsExpanded,
                    onToggleExpanded: toggleStatsPanel
                )
                    .equatable()
                    .padding(isStatsExpanded ? 12 : 14)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: isStatsExpanded ? 30 : 34, style: .continuous)
                                .fill(.ultraThinMaterial)

                            RoundedRectangle(cornerRadius: isStatsExpanded ? 30 : 34, style: .continuous)
                                .fill(Color.black.opacity(colorScheme == .dark ? 0.10 : 0.015))

                            RoundedRectangle(cornerRadius: isStatsExpanded ? 30 : 34, style: .continuous)
                                .strokeBorder(Color.white.opacity(colorScheme == .dark ? 0.14 : 0.32), lineWidth: 1)
                        }
                    )
                    .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 8)
            }
        }
    }

    private func toggleStatsPanel() {
        HapticManager.light()
        withAnimation(AnimationConfig.smoothSpring) {
            isStatsExpanded.toggle()
        }
    }

    // MARK: - Controls Panel

    private var controlsPanel: some View {
        HStack(spacing: 10) {
            // Stop Button
            controlPill(
                icon: "stop.fill",
                title: L("journey.stop.confirm"),
                tint: Color.red,
                emphasized: true
            ) {
                HapticManager.light()
                showCustomStopDialog = true
            }

            // Pause / Resume Button
            controlPill(
                icon: isJourneyActive ? "pause.fill" : "play.fill",
                title: isJourneyActive ? L("label.pauseJourney") : L("label.resumeJourney"),
                tint: isJourneyActive ? .primary : Color.blue,
                emphasized: !isJourneyActive
            ) {
                HapticManager.medium()
                if isJourneyActive {
                    journeyManager.pauseJourney()
                } else {
                    journeyManager.resumeJourney()
                }
            }
        }
        .fixedSize(horizontal: true, vertical: false)
    }

    @ViewBuilder
    private func controlPill(
        icon: String,
        title: String,
        tint: Color,
        emphasized: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(tint)
            .padding(.vertical, 9)
            .padding(.horizontal, 18)
            .contentShape(Capsule())
            .background(
                ZStack {
                    Capsule()
                        .fill(.ultraThinMaterial)
                    Capsule()
                        .fill(emphasized
                            ? tint.opacity(colorScheme == .dark ? 0.16 : 0.12)
                            : Color.white.opacity(colorScheme == .dark ? 0.06 : 0.4))
                    Capsule()
                        .strokeBorder(
                            emphasized
                                ? tint.opacity(0.32)
                                : Color.white.opacity(colorScheme == .dark ? 0.14 : 0.32),
                            lineWidth: 1
                        )
                }
            )
            .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Custom Stop Dialog

    @ViewBuilder
    private var customStopDialog: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showCustomStopDialog = false
                    }
                }

            VStack(spacing: 24) {
                stopDialogIcon

                // Title and message
                VStack(spacing: 10) {
                    Text(L("journey.stop.title"))
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)

                    Text(L("journey.stop.message"))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(5)
                        .padding(.horizontal, 8)
                }

                VStack(spacing: 10) {
                    Button {
                        HapticManager.warning()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            showCustomStopDialog = false
                        }
                        stopAndSaveJourney()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "stop.fill")
                                .font(.system(size: 14, weight: .semibold))

                            Text(L("journey.stop.confirm"))
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(stopConfirmButtonBackground)
                        .shadow(color: Color.red.opacity(0.4), radius: 12, x: 0, y: 6)
                    }
                    .buttonStyle(ScaleButtonStyle())

                    Button {
                        HapticManager.light()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            showCustomStopDialog = false
                        }
                    } label: {
                        Text(L("journey.stop.cancel"))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(stopCancelButtonBackground)
                            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 36)
            .padding(.horizontal, 28)
            .background(stopDialogContainerBackground)
            .shadow(
                color: Color.black.opacity(0.35),
                radius: 35,
                x: 0,
                y: 18
            )
            .padding(.horizontal, 36)
        }
    }

    @ViewBuilder
    private var stopDialogIcon: some View {
        ZStack {
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 80, height: 80)

            Circle()
                .fill(Color.red.opacity(colorScheme == .dark ? 0.3 : 0.4))
                .frame(width: 80, height: 80)

            Circle()
                .strokeBorder(Color.white.opacity(colorScheme == .dark ? 0.2 : 0.4), lineWidth: 1)
                .frame(width: 80, height: 80)

            Image(systemName: "stop.circle.fill")
                .font(.system(size: 40, weight: .regular))
                .foregroundColor(.white)
        }
        .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 8)
    }

    @ViewBuilder
    private var stopConfirmButtonBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)

            RoundedRectangle(cornerRadius: 24)
                .fill(Color.red.opacity(colorScheme == .dark ? 0.4 : 0.6))

            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(Color.white.opacity(colorScheme == .dark ? 0.2 : 0.4), lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 4)
    }

    @ViewBuilder
    private var stopCancelButtonBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)

            RoundedRectangle(cornerRadius: 24)
                .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05))

            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(Color.white.opacity(colorScheme == .dark ? 0.2 : 0.4), lineWidth: 0.5)
        }
    }

    @ViewBuilder
    private var stopDialogContainerBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)

            RoundedRectangle(cornerRadius: 24)
                .fill(colorScheme == .dark ? Color.black.opacity(0.6) : Color.white.opacity(0.6))

            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(Color.white.opacity(colorScheme == .dark ? 0.2 : 0.5), lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(0.2), radius: 24, x: 0, y: 12)
    }



    // MARK: - Helper Functions


    private func stopAndSaveJourney() {
        guard let session = journeyManager.state.session,
              let position = journeyManager.currentPosition else {
            journeyManager.cancelJourney()
            return
        }

        // Calculate actual duration
        let actualDuration = Date().timeIntervalSince(session.startTime)
        let sanitizedDistance = sanitizeRecordedDistance(
            position.distanceTraveled,
            transportMode: session.transportMode,
            referenceDuration: actualDuration
        )

        let startLocationName = session.startLocationName.isEmpty
            ? getLocationName(for: session.startLocation)
            : session.startLocationName
        let destinationName = getNearestPOIName(to: position.coordinate)
            ?? (session.destinationName.isEmpty ? L("label.destination") : session.destinationName)

        // Create journey record
        let record = JourneyRecord(
            startTime: session.startTime,
            endTime: Date(),
            duration: actualDuration,
            plannedDuration: session.duration,
            transportMode: session.transportMode.rawValue,
            focusGoal: session.focusGoal,
            vehicleBrand: session.vehicle?.brand ?? "",
            vehicleModel: session.vehicle?.model ?? "",
            vehicleEnergyType: session.vehicle?.energyType.rawValue ?? "",
            vehiclePlate: session.vehicle?.plate ?? "",
            scenicRouteID: session.scenicRouteID,
            scenicRouteName: session.scenicRouteName,
            scenicRouteTotalDistance: session.scenicRouteTotalDistance,
            scenicRouteProgress: session.scenicRouteProgress(atSessionProgress: position.progress),
            startLocationName: startLocationName,
            startLatitude: session.startLocation.latitude,
            startLongitude: session.startLocation.longitude,
            destinationName: destinationName,
            destinationLatitude: position.coordinate.latitude,
            destinationLongitude: position.coordinate.longitude,
            totalDistance: session.totalDistance,
            distanceTraveled: sanitizedDistance,
            progress: position.progress,
            discoveredPOICount: journeyManager.discoveredPOIs.count,
            discoveredPOIsJSON: JourneyRecord.encodePOIs(journeyManager.discoveredPOIs),
            isCompleted: position.progress >= 1.0
        )

        // Save to SwiftData
        modelContext.insert(record)
        persistJourneyChanges()
        updateRouteProgressAndTrophies(for: record)

        presentSummary(
            session: session,
            progress: position.progress,
            isCompleted: position.progress >= 1.0,
            actualDuration: actualDuration,
            discoveredPOIs: journeyManager.discoveredPOIs
        )
    }

    private func presentSummary(
        session: JourneySession,
        progress: Double,
        isCompleted: Bool,
        actualDuration: TimeInterval,
        discoveredPOIs: [DiscoveredPOI]
    ) {
        let payload = JourneySummaryPayload(
            session: session,
            discoveredPOIs: discoveredPOIs,
            weatherCondition: weatherManager.weatherDescription.isEmpty ? L("weather.condition.clear") : weatherManager.weatherDescription,
            temperature: weatherManager.temperatureString,
            isDaytime: weatherManager.isDaytime,
            progress: progress,
            isCompleted: isCompleted,
            actualDuration: actualDuration,
            attribution: weatherManager.attribution
        )

        // Dismiss map screen first.
        journeyManager.cancelJourney()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            journeyManager.pendingSummaryPayload = payload
        }
    }

    private func getLocationName(for coordinate: CLLocationCoordinate2D) -> String {
        // Try to match with preset locations
        if let preset = PresetLocation.presets.first(where: {
            abs($0.coordinate.latitude - coordinate.latitude) < 0.01 &&
            abs($0.coordinate.longitude - coordinate.longitude) < 0.01
        }) {
            return preset.localizedName
        }

        // Use current location name if available
        let locationName = locationManager.currentLocationName
        if !locationName.isEmpty {
            return locationName
        }

        return L("location.current")
    }

    private func getNearestPOIName(to coordinate: CLLocationCoordinate2D) -> String? {
        guard !journeyManager.discoveredPOIs.isEmpty else { return nil }

        // Find the nearest POI to the given coordinate
        let nearest = journeyManager.discoveredPOIs.min(by: { poi1, poi2 in
            let distance1 = coordinate.distance(to: poi1.coordinate)
            let distance2 = coordinate.distance(to: poi2.coordinate)
            return distance1 < distance2
        })

        return nearest?.name
    }

    private func saveCompletedJourney(session: JourneySession) {
        let actualDuration = Date().timeIntervalSince(session.startTime)
        let sanitizedDistance = sanitizeRecordedDistance(
            session.totalDistance,
            transportMode: session.transportMode,
            referenceDuration: session.duration
        )

        let startLocationName = session.startLocationName.isEmpty
            ? getLocationName(for: session.startLocation)
            : session.startLocationName
        let destinationName = getNearestPOIName(to: session.destinationLocation)
            ?? (session.destinationName.isEmpty ? L("label.destination") : session.destinationName)

        let record = JourneyRecord(
            startTime: session.startTime,
            endTime: Date(),
            duration: actualDuration,
            plannedDuration: session.duration,
            transportMode: session.transportMode.rawValue,
            focusGoal: session.focusGoal,
            vehicleBrand: session.vehicle?.brand ?? "",
            vehicleModel: session.vehicle?.model ?? "",
            vehicleEnergyType: session.vehicle?.energyType.rawValue ?? "",
            vehiclePlate: session.vehicle?.plate ?? "",
            scenicRouteID: session.scenicRouteID,
            scenicRouteName: session.scenicRouteName,
            scenicRouteTotalDistance: session.scenicRouteTotalDistance,
            scenicRouteProgress: session.scenicRouteProgress(atSessionProgress: 1),
            startLocationName: startLocationName,
            startLatitude: session.startLocation.latitude,
            startLongitude: session.startLocation.longitude,
            destinationName: destinationName,
            destinationLatitude: session.destinationLocation.latitude,
            destinationLongitude: session.destinationLocation.longitude,
            totalDistance: session.totalDistance,
            distanceTraveled: sanitizedDistance,
            progress: 1.0,
            discoveredPOICount: journeyManager.discoveredPOIs.count,
            discoveredPOIsJSON: JourneyRecord.encodePOIs(journeyManager.discoveredPOIs),
            isCompleted: true
        )

        modelContext.insert(record)
        persistJourneyChanges()
        updateRouteProgressAndTrophies(for: record)

        // Mark first journey as completed
        if !settings.hasCompletedFirstJourney {
            settings.hasCompletedFirstJourney = true
        }
    }

    private func sanitizeRecordedDistance(
        _ rawDistance: Double,
        transportMode: TransportMode,
        referenceDuration: TimeInterval
    ) -> Double {
        guard rawDistance.isFinite, rawDistance > 0 else { return 0 }

        let expectedDistance = transportMode.speedMps * max(referenceDuration, 0)
        let maxReasonableDistance = max(300, expectedDistance * 1.8 + 200)
        return min(rawDistance, maxReasonableDistance)
    }

    private func persistJourneyChanges() {
        try? modelContext.save()
        WidgetSnapshotStore.shared.refreshSnapshot(using: modelContext, settings: settings)
    }

    private func updateRouteProgressAndTrophies(for record: JourneyRecord) {
        if record.hasScenicRoute {
            ScenicRouteProgressStore.shared.update(
                routeID: record.scenicRouteID,
                progress: record.scenicRouteProgress
            )
        }

        let descriptor = FetchDescriptor<JourneyRecord>(
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        let records = (try? modelContext.fetch(descriptor)) ?? []
        let manager = TrophyManager()
        _ = manager.updateProgress(with: records, notifyNewUnlocks: true)
    }

}

struct ActiveJourneyStatsPanel: View, Equatable {
    let position: VirtualPosition
    let currentSpeed: Double
    let session: JourneySession
    let isExpanded: Bool
    let onToggleExpanded: () -> Void

    static func == (lhs: ActiveJourneyStatsPanel, rhs: ActiveJourneyStatsPanel) -> Bool {
        lhs.position == rhs.position &&
        lhs.currentSpeed == rhs.currentSpeed &&
        lhs.session == rhs.session &&
        lhs.isExpanded == rhs.isExpanded
    }

    var body: some View {
        VStack(spacing: isExpanded ? 7 : 8) {
            if isExpanded {
                expandedHeader
            } else {
                collapsedHeader
            }

            if isExpanded {
                scenicRouteProgressRow
                vehicleSummaryRow
                expandedStatCards
            }
        }
    }

    @ViewBuilder
    private var expandedStatCards: some View {
        let cards = compactCardItems

        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8)
            ],
            spacing: 7
        ) {
            ForEach(cards) { item in
                CompactStatCard(
                    icon: item.icon,
                    label: item.label,
                    value: item.value
                )
            }
        }
    }

    private var expandedHeader: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(L("label.timeRemaining"))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)

                Text(FormatUtilities.formatTimeDigital(position.remainingTime))
                    .font(.system(size: 36, weight: .semibold, design: .rounded))
                    .foregroundStyle(LiquidGlassStyle.primaryGradient)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }

            Spacer(minLength: 8)

            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 3.5)
                    .frame(width: 36, height: 36)

                Circle()
                    .trim(from: 0, to: position.progress)
                    .stroke(
                        LiquidGlassStyle.primaryGradient,
                        style: StrokeStyle(lineWidth: 3.5, lineCap: .round)
                    )
                    .frame(width: 36, height: 36)
                    .rotationEffect(.degrees(-90))

                Text(FormatUtilities.formatProgress(position.progress))
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
            }

            toggleButton
        }
    }

    @ViewBuilder
    private var scenicRouteProgressRow: some View {
        if session.hasScenicRoute {
            HStack(spacing: 8) {
                Image(systemName: "point.topleft.down.curvedto.point.bottomright.up")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(LiquidGlassStyle.primaryGradient)

                Text(session.scenicRouteName)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Spacer(minLength: 8)

                Text(routeProgressText)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(LiquidGlassStyle.primaryGradient)
                    .monospacedDigit()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.7)
                    )
            )
        }
    }

    @ViewBuilder
    private var vehicleSummaryRow: some View {
        if let vehicle = session.vehicle {
            let plate = vehicle.plate.trimmingCharacters(in: .whitespacesAndNewlines)
            HStack(spacing: 8) {
                Image(systemName: vehicle.energyType == .electric ? "bolt.car.fill" : "car.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(LiquidGlassStyle.accentGradient)

                Text(vehicle.modelDisplayName)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                if !plate.isEmpty {
                    Text(plate)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        Capsule(style: .continuous)
                            .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.7)
                    )
            )
        }
    }

    private var collapsedHeader: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(FormatUtilities.formatTimeDigital(position.remainingTime))
                .font(.system(size: 34, weight: .semibold, design: .rounded))
                .foregroundStyle(LiquidGlassStyle.primaryGradient)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Spacer(minLength: 12)

            toggleButton
        }
    }

    private var toggleButton: some View {
        Button(action: onToggleExpanded) {
            Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.primary.opacity(0.78))
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.08))
                )
                .overlay {
                    Circle()
                        .strokeBorder(Color.white.opacity(0.18), lineWidth: 0.8)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isExpanded ? Text(L("common.collapse")) : Text(L("common.expand")))
    }

    private var elapsedDuration: TimeInterval {
        max(session.duration - position.remainingTime, 0)
    }

    private var virtualMetrics: VirtualJourneyMetrics {
        VirtualJourneyMetrics(
            distanceMeters: position.distanceTraveled,
            duration: elapsedDuration,
            transportMode: session.transportMode,
            sessionID: session.id,
            energyType: session.vehicle?.energyType ?? .gasoline
        )
    }

    private var scenicRouteProgress: Double {
        min(max(session.scenicRouteProgress(atSessionProgress: position.progress), 0), 1)
    }

    private var routeProgressText: String {
        FormatUtilities.formatProgress(scenicRouteProgress)
    }

    private var compactCardItems: [ActiveJourneyStatCardItem] {
        var items = [
            ActiveJourneyStatCardItem(
                icon: "location.fill",
                label: L("label.distanceTraveled"),
                value: FormatUtilities.formatDistance(position.distanceTraveled)
            ),
            ActiveJourneyStatCardItem(
                icon: "speedometer",
                label: L("label.currentSpeed"),
                value: String(format: "%.1f km/h", currentSpeed)
            )
        ]

        items += virtualMetrics.cardItems.map {
            ActiveJourneyStatCardItem(
                icon: $0.icon,
                label: $0.title,
                value: $0.value
            )
        }

        return items
    }
}

private struct ActiveJourneyStatCardItem: Identifiable {
    let id = UUID()
    let icon: String
    let label: String
    let value: String
}

private struct CompletedJourneyStatsPanel: View {
    let session: JourneySession
    let discoveredPOIs: [DiscoveredPOI]
    let onShowSummary: () -> Void

    private var timeRangeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let startString = formatter.string(from: session.startTime)
        let endString = formatter.string(from: Date())
        return "\(startString) - \(endString)"
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.green)

            Text(L("journey.completed"))
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.primary)

            // Basic Stats
            HStack(spacing: 24) {
                VStack(spacing: 4) {
                    Text(L("journey.summary.distance"))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    Text(FormatUtilities.formatDistance(session.totalDistance))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                }

                Divider().frame(height: 30)

                VStack(spacing: 4) {
                    Text(L("journey.summary.timeRange"))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    Text(timeRangeString)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                }
            }
            .padding(.vertical, 4)

            // POIs
            if !discoveredPOIs.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text(String(format: L("journey.completed.pois"), discoveredPOIs.count))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(discoveredPOIs.prefix(3)) { poi in
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(Color.yellow.opacity(0.8))
                                    .frame(width: 4, height: 4)
                                Text(poi.name)
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                    .padding(.leading, 6)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.gray.opacity(0.1))
                )
            } else {
                Text(String(format: L("journey.completed.pois"), 0))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.secondary)
            }

            Button(action: onShowSummary) {
                Text(L("journey.viewSummary"))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(LiquidGlassStyle.primaryGradient)
                    )
            }
            .padding(.top, 8)
        }
    }
}

// MARK: - Guide Feature Row

struct GuideFeatureRow: View {
    let icon: String
    let title: String
    let gradient: LinearGradient

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(gradient.opacity(0.2))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(gradient)
            }

            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.1))
        )
    }
}

// MARK: - Compact Stat Card

struct CompactStatCard: View {
    let icon: String
    let label: String
    let value: String

    init(
        icon: String,
        label: String,
        value: String
    ) {
        self.icon = icon
        self.label = label
        self.value = value
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(iconColor)
                .frame(width: 17)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(labelColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text(value)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(valueColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 42, alignment: .leading)
        .padding(.vertical, 7)
        .padding(.horizontal, 9)
        .background(backgroundView)
    }

    private var iconColor: some ShapeStyle {
        return AnyShapeStyle(LiquidGlassStyle.accentGradient)
    }

    private var labelColor: Color {
        return .secondary
    }

    private var valueColor: Color {
        return .primary
    }

    @ViewBuilder
    private var backgroundView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial)

            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.03))

            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.7)
        }
    }
}

#Preview {
    ActiveJourneyView(
        locationManager: LocationManager(),
        journeyManager: JourneyManager()
    )
}
