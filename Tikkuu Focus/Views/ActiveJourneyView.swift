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
                    .padding(.top, 60)
                
                Spacer()

                // Bottom stats panel
                VStack(spacing: 12) {
                    controlsPanel
                        .padding(.horizontal, 24)
                    
                    statsPanel
                        .padding(.horizontal, 24)
                }
                .padding(.bottom, 32)
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
            .padding(.top, 8)
    }
    
    private var isJourneyActive: Bool {
        if case .active = journeyManager.state { return true }
        return false
    }
    
    // MARK: - Unified Top Pill
    
    private var unifiedTopPill: some View {
        HStack(spacing: 12) {
            // Journey state
            HStack(spacing: 6) {
                Circle()
                    .fill(isJourneyActive ? Color.green : Color.orange)
                    .frame(width: 8, height: 8)
                    .shadow(color: (isJourneyActive ? Color.green : Color.orange).opacity(0.6), radius: 3, x: 0, y: 0)
                Text(isJourneyActive ? L("journey.state.active") : L("journey.state.paused"))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }
            
            // Divider
            if !weatherManager.isLoading {
                Rectangle()
                    .fill(Color.white.opacity(0.25))
                    .frame(width: 1, height: 14)
            }
            
            // Weather
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
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(unifiedTopPillBackground)
        .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 6)
    }
    
    @ViewBuilder
    private var unifiedTopPillBackground: some View {
        ZStack {
            Capsule()
                .fill(.ultraThinMaterial)
            
            Capsule()
                .fill(Color.black.opacity(colorScheme == .dark ? 0.4 : 0.2))
            
            if !weatherManager.isLoading {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: weatherPalette.backgroundGradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            Capsule()
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
            // Time remaining (large)
            if let position = journeyManager.currentPosition,
               let session = journeyManager.state.session {
                ActiveJourneyStatsPanel(
                    position: position,
                    currentSpeed: currentSpeed,
                    session: session
                )
                    .equatable()
                    .padding(20)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .fill(.ultraThinMaterial)
                            
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .fill(Color.black.opacity(colorScheme == .dark ? 0.35 : 0.1))
                            
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .strokeBorder(Color.white.opacity(colorScheme == .dark ? 0.15 : 0.4), lineWidth: 1)
                        }
                    )
                    .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 8)
            } else if case .completed(let session) = journeyManager.state {
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
                            .fill(Color.black.opacity(colorScheme == .dark ? 0.35 : 0.1))
                        
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .strokeBorder(Color.white.opacity(colorScheme == .dark ? 0.15 : 0.4), lineWidth: 1)
                    }
                )
                .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 8)
            }
        }
    }
    
    // MARK: - Controls Panel
    
    private var controlsPanel: some View {
        HStack(spacing: 0) {
            // Stop Button
            Button {
                HapticManager.light()
                showCustomStopDialog = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 16, weight: .bold))
                    Text(L("journey.stop.confirm"))
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(Color.red.opacity(colorScheme == .dark ? 0.8 : 0.9))
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .contentShape(Rectangle())
            }
            .buttonStyle(ScaleButtonStyle())
            
            Divider()
                .frame(height: 24)
                .background(Color.gray.opacity(0.4))
            
            // Pause / Resume Button
            Button {
                HapticManager.medium()
                if isJourneyActive {
                    journeyManager.pauseJourney()
                } else {
                    journeyManager.resumeJourney()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: isJourneyActive ? "pause.fill" : "play.fill")
                        .font(.system(size: 16, weight: .bold))
                    Text(isJourneyActive ? L("label.pauseJourney") : L("label.resumeJourney"))
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(isJourneyActive ? .primary : Color.blue)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .contentShape(Rectangle())
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .background(
            ZStack {
                Capsule()
                    .fill(.ultraThinMaterial)
                
                Capsule()
                    .fill(Color.black.opacity(colorScheme == .dark ? 0.4 : 0.1))
                
                Capsule()
                    .strokeBorder(Color.white.opacity(colorScheme == .dark ? 0.15 : 0.4), lineWidth: 1)
            }
        )
        .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 8)
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
        
        // Find nearest POI to current position as destination
        let destinationName = getNearestPOIName(to: position.coordinate) ?? L("label.destination")
        
        // Create journey record
        let record = JourneyRecord(
            startTime: session.startTime,
            endTime: Date(),
            duration: actualDuration,
            plannedDuration: session.duration,
            transportMode: session.transportMode.rawValue,
            startLocationName: getLocationName(for: session.startLocation),
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
        
        // Use destination location or nearest POI
        let destinationName = getNearestPOIName(to: session.destinationLocation) ?? L("label.destination")
        
        let record = JourneyRecord(
            startTime: session.startTime,
            endTime: Date(),
            duration: actualDuration,
            plannedDuration: session.duration,
            transportMode: session.transportMode.rawValue,
            startLocationName: getLocationName(for: session.startLocation),
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
    
}

struct ActiveJourneyStatsPanel: View, Equatable {
    let position: VirtualPosition
    let currentSpeed: Double
    let session: JourneySession

    static func == (lhs: ActiveJourneyStatsPanel, rhs: ActiveJourneyStatsPanel) -> Bool {
        lhs.position == rhs.position &&
        lhs.currentSpeed == rhs.currentSpeed &&
        lhs.session == rhs.session
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L("label.timeRemaining"))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)

                    Text(FormatUtilities.formatTimeDigital(position.remainingTime))
                        .font(.system(size: 48, weight: .semibold, design: .rounded))
                        .foregroundStyle(LiquidGlassStyle.primaryGradient)
                }

                Spacer()

                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 4)
                        .frame(width: 44, height: 44)

                    Circle()
                        .trim(from: 0, to: position.progress)
                        .stroke(
                            LiquidGlassStyle.primaryGradient,
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 44, height: 44)
                        .rotationEffect(.degrees(-90))

                    Text(FormatUtilities.formatProgress(position.progress))
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                }
            }

            HStack(spacing: 10) {
                CompactStatCard(
                    icon: "location.fill",
                    label: L("label.distanceTraveled"),
                    value: FormatUtilities.formatDistance(position.distanceTraveled),
                    detail: virtualMetrics.distanceCardDetail
                )

                CompactStatCard(
                    icon: "speedometer",
                    label: L("label.currentSpeed"),
                    value: String(format: "%.1f km/h", currentSpeed),
                    detail: virtualMetrics.speedCardDetail
                )
            }
        }
    }

    private var elapsedDuration: TimeInterval {
        max(session.duration - position.remainingTime, 0)
    }

    private var virtualMetrics: VirtualJourneyMetrics {
        VirtualJourneyMetrics(
            distanceMeters: position.distanceTraveled,
            duration: elapsedDuration,
            transportMode: session.transportMode,
            sessionID: session.id
        )
    }
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
    let detail: String?

    init(
        icon: String,
        label: String,
        value: String,
        detail: String? = nil
    ) {
        self.icon = icon
        self.label = label
        self.value = value
        self.detail = detail
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(iconColor)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(labelColor)
                    .lineLimit(1)
                
                Text(value)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(valueColor)
                    .lineLimit(1)

                Text(detail ?? " ")
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .foregroundColor(valueColor.opacity(detail == nil ? 0 : 0.72))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
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
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
            
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
            
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.white.opacity(0.15), lineWidth: 0.7)
        }
    }
}

#Preview {
    ActiveJourneyView(
        locationManager: LocationManager(),
        journeyManager: JourneyManager()
    )
}
