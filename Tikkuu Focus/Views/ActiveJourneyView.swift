//
//  ActiveJourneyView.swift
//  Tikkuu Focus
//
//  Created by Tikkuu on 2026/2/8.
//

import SwiftUI
import MapKit
import SwiftData

struct ActiveJourneyView: View {
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
    
    var body: some View {
        ZStack {
            // Exploration map background
            if let session = journeyManager.state.session {
                ExplorationMapView(
                    session: session,
                    currentPosition: journeyManager.currentPosition,
                    discoveredPOIs: journeyManager.discoveredPOIs,
                    currentSpeed: $currentSpeed
                )
                .ignoresSafeArea()
            }
            
            // Overlay UI
            VStack {
                // Top bar
                topBar
                    .padding(.top, 60)
                    .padding(.horizontal, 24)
                
                Spacer()

                // Bottom stats panel
                statsPanel
                    .padding(24)
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
        .onAppear {
            if !AppMapMode.focusSelectableModes.contains(settings.selectedMapMode) {
                settings.selectedMapMode = .explore
            }
        }
        .task {
            // Fetch weather when view appears
            if let session = journeyManager.state.session {
                await weatherManager.fetchWeather(for: session.startLocation)
            }
        }
    }
    
    // MARK: - Top Bar
    
    private var topBar: some View {
        HStack(spacing: 12) {
            // Stop button (with confirmation)
            Button {
                HapticManager.light()
                showCustomStopDialog = true
            } label: {
                Image(systemName: "stop.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(Color.red.opacity(0.8))
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
            }
            
            // DEBUG: Test Complete Button (Remove before release)
            #if DEBUG
            Button {
                HapticManager.success()
                testCompleteJourney()
            } label: {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(Color.green.opacity(0.8))
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
            }
            #endif
            
            Spacer()
            
            // Journey state badge
            if case .active = journeyManager.state {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text(L("journey.state.active"))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color.black.opacity(0.4)))
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
            } else if case .paused = journeyManager.state {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 8, height: 8)
                    Text(L("journey.state.paused"))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color.black.opacity(0.4)))
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
            }
            
            Spacer()
            
            HStack(spacing: 10) {
                Menu {
                    ForEach(AppMapMode.focusSelectableModes, id: \.self) { mode in
                        Button {
                            HapticManager.selection()
                            settings.selectedMapMode = mode
                        } label: {
                            Label {
                                Text(mode.title)
                            } icon: {
                                Image(systemName: settings.selectedMapMode == mode ? "checkmark.circle.fill" : mode.iconName)
                            }
                        }
                    }
                } label: {
                    Image(systemName: "map.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(Color.black.opacity(0.4))
                        )
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                }

                // Pause/Resume button
                if case .active = journeyManager.state {
                    Button {
                        HapticManager.medium()
                        journeyManager.pauseJourney()
                    } label: {
                        Image(systemName: "pause.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(Color.black.opacity(0.4))
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                    }
                } else if case .paused = journeyManager.state {
                    Button {
                        HapticManager.medium()
                        journeyManager.resumeJourney()
                    } label: {
                        Image(systemName: "play.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(Color.black.opacity(0.4))
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                    }
                }
            }
        }
    }
    
    // MARK: - Stats Panel
    
    private var statsPanel: some View {
        VStack(spacing: 12) {
            // Time remaining (large)
            if let position = journeyManager.currentPosition {
                VStack(spacing: 12) {
                    // Time and progress combined
                    HStack(alignment: .center, spacing: 16) {
                        // Time - 更显眼
                        VStack(alignment: .leading, spacing: 4) {
                            Text(L("label.timeRemaining"))
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.secondary)
                            
                            Text(FormatUtilities.formatTimeDigital(position.remainingTime))
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.3, green: 0.6, blue: 1.0),
                                            Color(red: 0.5, green: 0.4, blue: 0.95)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        
                        Spacer()
                        
                        // Progress circle - 缩小
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
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                        }
                    }
                    

                    // Stats grid - more compact
                    HStack(spacing: 10) {
                        CompactStatCard(
                            icon: "location.fill",
                            label: L("label.distanceTraveled"),
                            value: FormatUtilities.formatDistance(position.distanceTraveled)
                        )
                        
                        CompactStatCard(
                            icon: "speedometer",
                            label: L("label.currentSpeed"),
                            value: String(format: "%.1f km/h", currentSpeed)
                        )
                    }
                }
            } else if case .completed(let session) = journeyManager.state {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(Color.green)
                        .shadow(color: Color.green.opacity(0.3), radius: 10, x: 0, y: 5)
                    
                    Text(L("journey.completed"))
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text(FormatUtilities.formatDistance(session.totalDistance))
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Text(String(format: L("journey.completed.duration"), FormatUtilities.formatTime(Date().timeIntervalSince(session.startTime))))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Text(String(format: L("journey.completed.pois"), journeyManager.discoveredPOIs.count))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Button {
                        HapticManager.success()
                        saveCompletedJourney(session: session)
                        presentSummary(
                            session: session,
                            progress: 1.0,
                            isCompleted: true,
                            actualDuration: Date().timeIntervalSince(session.startTime),
                            discoveredPOIs: journeyManager.discoveredPOIs
                        )
                    } label: {
                        Text(L("journey.viewSummary"))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(LiquidGlassStyle.primaryGradient)
                                    .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                            )
                    }
                    .padding(.top, 8)
                }
            }
        }
        .padding(16)
        .background {
            if settings.selectedVisualStyle == .liquidGlass {
                let shape = RoundedRectangle(cornerRadius: 20, style: .continuous)
                ZStack {
                    shape
                        .fill(.ultraThinMaterial)

                    shape
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.14), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .blendMode(.overlay)

                    shape
                        .strokeBorder(Color.white.opacity(0.35), lineWidth: 1.2)
                }
            } else {
                NeumorphSurface(cornerRadius: 20, depth: NeumorphDepth.inset)
            }
        }
    }
    
    // MARK: - Custom Stop Dialog
    
    @ViewBuilder
    private var customStopDialog: some View {
        ZStack {
            // Backdrop with blur
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showCustomStopDialog = false
                    }
                }
            
            VStack(spacing: 28) {
                // Warning icon with glow
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.red.opacity(0.25),
                                    Color.orange.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 90, height: 90)
                        .blur(radius: 20)
                    
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.red.opacity(0.15),
                                    Color.orange.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 70, height: 70)
                    
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.red, Color.orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .shadow(color: Color.red.opacity(0.4), radius: 25, x: 0, y: 12)
                
                // Title and message
                VStack(spacing: 10) {
                    Text(L("journey.stop.title"))
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text(L("journey.stop.message"))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(5)
                        .padding(.horizontal, 8)
                }
                
                // Action buttons
                VStack(spacing: 10) {
                    // Stop button
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
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.red, Color.orange],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0.2),
                                                Color.clear
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .blendMode(.overlay)
                            }
                        )
                        .shadow(color: Color.red.opacity(0.4), radius: 12, x: 0, y: 6)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    
                    // Cancel button
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
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(.ultraThinMaterial)
                                    
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color.white.opacity(0.15),
                                                    Color.clear
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .blendMode(.overlay)
                                    
                                    RoundedRectangle(cornerRadius: 16)
                                        .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                                }
                            )
                            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 36)
            .padding(.horizontal, 28)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 28)
                        .fill(.ultraThinMaterial)
                    
                    RoundedRectangle(cornerRadius: 28)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.12),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .blendMode(.overlay)
                    
                    RoundedRectangle(cornerRadius: 28)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.4),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                }
            )
            .shadow(color: Color.black.opacity(0.35), radius: 35, x: 0, y: 18)
            .padding(.horizontal, 36)
        }
    }
    
    // MARK: - Helper Functions
    
    // DEBUG: Test function to simulate journey completion (Remove before release)
    #if DEBUG
    private func testCompleteJourney() {
        guard let session = journeyManager.state.session else { return }
        
        let actualDuration = Date().timeIntervalSince(session.startTime)
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
            distanceTraveled: session.totalDistance,
            progress: 1.0,
            discoveredPOICount: journeyManager.discoveredPOIs.count,
            discoveredPOIsJSON: JourneyRecord.encodePOIs(journeyManager.discoveredPOIs),
            isCompleted: true
        )
        
        modelContext.insert(record)
        
        // Force update current position to 100%
        journeyManager.currentPosition = VirtualPosition(
            coordinate: session.destinationLocation,
            progress: 1.0,
            distanceTraveled: session.totalDistance,
            remainingTime: 0
        )

        presentSummary(
            session: session,
            progress: 1.0,
            isCompleted: true,
            actualDuration: actualDuration,
            discoveredPOIs: journeyManager.discoveredPOIs
        )
    }
    #endif
    
    private func stopAndSaveJourney() {
        guard let session = journeyManager.state.session,
              let position = journeyManager.currentPosition else {
            journeyManager.cancelJourney()
            return
        }
        
        // Calculate actual duration
        let actualDuration = Date().timeIntervalSince(session.startTime)
        
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
            distanceTraveled: position.distanceTraveled,
            progress: position.progress,
            discoveredPOICount: journeyManager.discoveredPOIs.count,
            discoveredPOIsJSON: JourneyRecord.encodePOIs(journeyManager.discoveredPOIs),
            isCompleted: position.progress >= 1.0
        )
        
        // Save to SwiftData
        modelContext.insert(record)

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
            isDaytime: weatherManager.isDaytime,
            progress: progress,
            isCompleted: isCompleted,
            actualDuration: actualDuration
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
            distanceTraveled: session.totalDistance,
            progress: 1.0,
            discoveredPOICount: journeyManager.discoveredPOIs.count,
            discoveredPOIsJSON: JourneyRecord.encodePOIs(journeyManager.discoveredPOIs),
            isCompleted: true
        )
        
        modelContext.insert(record)
        
        // Mark first journey as completed
        if !settings.hasCompletedFirstJourney {
            settings.hasCompletedFirstJourney = true
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
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
    }
}

// MARK: - Compact Stat Card

struct CompactStatCard: View {
    @ObservedObject private var settings = AppSettings.shared
    @Environment(\.colorScheme) private var colorScheme
    
    let icon: String
    let label: String
    let value: String
    
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
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(valueColor)
                    .lineLimit(1)
            }
            
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(backgroundView)
    }
    
    private var iconColor: some ShapeStyle {
        if settings.selectedVisualStyle == .neumorphism {
            return AnyShapeStyle(
                settings.isNeumorphismLight
                    ? Color(red: 0.35, green: 0.45, blue: 0.65)
                    : Color(red: 0.545, green: 0.655, blue: 1.0)
            )
        }
        return AnyShapeStyle(LiquidGlassStyle.accentGradient)
    }
    
    private var labelColor: Color {
        if settings.selectedVisualStyle == .neumorphism && settings.isNeumorphismLight {
            return Color(red: 0.35, green: 0.40, blue: 0.48)
        }
        return .secondary
    }
    
    private var valueColor: Color {
        if settings.selectedVisualStyle == .neumorphism && settings.isNeumorphismLight {
            return Color(red: 0.25, green: 0.30, blue: 0.38)
        }
        return .primary
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        if settings.selectedVisualStyle == .neumorphism {
            NeumorphSurface(
                cornerRadius: 10,
                depth: .raised
            )
        } else {
            RoundedRectangle(cornerRadius: 10)
                .fill(.thinMaterial)
                .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

#Preview {
    ActiveJourneyView(
        locationManager: LocationManager(),
        journeyManager: JourneyManager()
    )
}
