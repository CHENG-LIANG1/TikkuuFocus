//
//  ExplorationMapView.swift
//  Tikkuu Focus
//
//  Created by Tikkuu on 2026/2/8.
//

import SwiftUI
import MapKit
import SwiftData
import UIKit

/// Exploration-style map view that reveals the route progressively
struct ExplorationMapView: View {
    let session: JourneySession
    let currentPosition: VirtualPosition?
    let discoveredPOIs: [DiscoveredPOI]
    let isPaused: Bool
    @Binding var currentSpeed: Double
    
    @State private var cameraPosition: MapCameraPosition
    @State private var revealedRouteCoordinates: [CLLocationCoordinate2D] = []
    @State private var traveledPath: [CLLocationCoordinate2D] = []
    @State private var animatedPosition: CLLocationCoordinate2D?
    @State private var hasInitialized = false
    @State private var isFollowingUser = true
    @State private var isProgrammaticCameraChange = false
    @State private var speedState: JourneySpeedState
    @State private var showRecenterButton = false
    @State private var speedTimer: Timer?
    @State private var lastCameraFollowCoordinate: CLLocationCoordinate2D?
    @State private var lastCameraFollowUpdateTime: Date?
    @State private var lastKnownCameraRegion: MKCoordinateRegion
    @State private var cameraAnimationTask: Task<Void, Never>?
    @State private var cameraGuardToken = UUID()
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ObservedObject private var settings = AppSettings.shared
    @Query private var transportAvatarSettings: [TransportAvatarSettings]

    private let traveledPathMaxPoints = 180
    private let traveledPathTargetPoints = 120
    private let displayedRouteTargetPoints = 140

    init(
        session: JourneySession,
        currentPosition: VirtualPosition?,
        discoveredPOIs: [DiscoveredPOI],
        isPaused: Bool,
        currentSpeed: Binding<Double>
    ) {
        self.session = session
        self.currentPosition = currentPosition
        self.discoveredPOIs = discoveredPOIs
        self.isPaused = isPaused
        self._currentSpeed = currentSpeed

        let initialCenter = currentPosition?.coordinate ?? session.startLocation
        let initialZoom = Self.defaultZoom(for: session.transportMode)
        let initialRegion = MKCoordinateRegion(
            center: initialCenter,
            latitudinalMeters: initialZoom,
            longitudinalMeters: initialZoom
        )
        _cameraPosition = State(initialValue: .region(
            initialRegion
        ))
        _lastKnownCameraRegion = State(initialValue: initialRegion)
        _speedState = State(initialValue: JourneySpeedState(transportMode: session.transportMode))
    }
    
    // Speed range for each transport mode (in km/h)
    private func speedRange(for mode: TransportMode) -> (min: Double, max: Double) {
        switch mode {
        case .walking:
            return (3.0, 6.0)  // 3-6 km/h
        case .cycling:
            return (15.0, 25.0)  // 15-25 km/h
        case .driving:
            return (40.0, 100.0)  // 40-100 km/h (faster and smoother)
        case .skateboard:
            return (10.0, 30.0)  // 10-30 km/h
        }
    }
    
    // Generate random speed within range
    private func randomSpeed(for mode: TransportMode) -> Double {
        let range = speedRange(for: mode)
        return Double.random(in: range.min...range.max)
    }
    
    // Dynamic zoom based on speed
    private static func defaultZoom(for mode: TransportMode) -> Double {
        switch mode {
        case .walking:
            return 800
        case .cycling:
            return 1500
        case .driving:
            return 3000
        case .skateboard:
            return 1200
        }
    }

    private func zoomLevel(for speed: Double) -> Double {
        switch session.transportMode {
        case .walking:
            return 800
        case .cycling:
            return 1500
        case .driving:
            return 3000
        case .skateboard:
            return 1200
        }
    }

    private var cameraFollowDistanceThreshold: CLLocationDistance {
        switch session.transportMode {
        case .walking:
            return 35
        case .cycling, .skateboard:
            return 60
        case .driving:
            return 110
        }
    }

    private var cameraFollowMinInterval: TimeInterval {
        let base: TimeInterval
        switch session.transportMode {
        case .walking:
            base = 2.5
        case .cycling, .skateboard:
            base = 3.0
        case .driving:
            base = 3.5
        }

        return PerformanceOptimizer.shared.isEnergySavingMode ? base * 1.8 : base
    }

    private var positionAnimationDuration: TimeInterval {
        max(0.35, PerformanceOptimizer.shared.journeyUpdateInterval * 0.85)
    }

    private var cameraAnimationDuration: TimeInterval {
        max(0.45, PerformanceOptimizer.shared.journeyUpdateInterval * 0.95)
    }

    private var recenterAnimationDuration: TimeInterval {
        guard PerformanceConfig.enableMapCameraAnimations, !reduceMotion else { return 0 }
        return PerformanceOptimizer.shared.isEnergySavingMode ? 0.42 : 0.62
    }

    private var recenterAnimationStepCount: Int {
        guard recenterAnimationDuration > 0 else { return 1 }
        return PerformanceOptimizer.shared.isEnergySavingMode ? 12 : 20
    }
    
    var body: some View {
        ZStack {
            Map(position: $cameraPosition, interactionModes: [.pan, .zoom]) {
            // Start marker (no label to avoid flickering)
            Marker(coordinate: session.startLocation) {
                StartMarker()
            }
            .tint(.green)
            
            // Traveled path (trail behind avatar) - Bright and visible
            if displayedTraveledPath.count >= 2 {
                MapPolyline(coordinates: displayedTraveledPath)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color(red: 0.2, green: 0.6, blue: 1.0),
                                Color(red: 0.4, green: 0.7, blue: 0.9)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round)
                    )
            }
            
            // Revealed route (dimmed, shows where you can go)
            if currentPosition != nil, displayedRevealedRoute.count >= 2 {
                MapPolyline(coordinates: displayedRevealedRoute)
                    .stroke(
                        Color.gray.opacity(0.3),
                        style: StrokeStyle(
                            lineWidth: 4,
                            lineCap: .round,
                            lineJoin: .round,
                            dash: [10, 5]
                        )
                    )
            }
            
            // Current position (avatar) with smooth animation and pulsing effect (no label to avoid flickering)
            if let position = animatedPosition ?? currentPosition?.coordinate {
                Annotation("", coordinate: position) {
                    AvatarMarker(
                        transportMode: session.transportMode,
                        pulseScale: pulseScale,
                        avatarSettings: transportAvatarSettings.first
                    )
                }
            }
            
            // Discovered POI markers (icon only, no tooltip bubble)
            ForEach(discoveredPOIs.prefix(PerformanceConfig.maxPOIMarkers)) { poi in
                Annotation(poi.name, coordinate: poi.coordinate) {
                    POIBubbleMarker(poi: poi)
                }
            }
            
            // Destination marker (only show when journey is complete or very close, no label to avoid flickering)
            if let position = currentPosition, position.progress > 0.95 {
                Marker(coordinate: session.destinationLocation) {
                    DestinationMarker()
                }
                .tint(.red)
            }
        }
        .mapStyle(settings.selectedMapMode.style)
        .onMapCameraChange(frequency: .continuous) { context in
            lastKnownCameraRegion = context.region

            // Only show recenter when user manually pans (drags) the map, not on zoom
            guard !isProgrammaticCameraChange, let currentPos = currentPosition?.coordinate else { return }

            let cameraCenter = context.region.center
            let distance = currentPos.distance(to: cameraCenter)

            // Only trigger on significant pan (drag), ignore zoom-only changes
            if distance > 50 {
                isFollowingUser = false
                if !showRecenterButton {
                    withAnimation(AnimationConfig.quickSpring) {
                        showRecenterButton = true
                    }
                }
            }
        }
        .onAppear {
            if !hasInitialized {
                hasInitialized = true
                startPulseAnimation()
                syncSpeedState()

                if let position = currentPosition {
                    updateRevealedRoute(progress: position.progress)
                    updateTraveledPath(position.coordinate)
                }
            }
        }
        .onDisappear {
            cameraAnimationTask?.cancel()
            cameraAnimationTask = nil
            isProgrammaticCameraChange = false
            stopSpeedUpdateTimer()
            stopPulseAnimation()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                syncSpeedState()
                startPulseAnimation()
            } else {
                cameraAnimationTask?.cancel()
                cameraAnimationTask = nil
                isProgrammaticCameraChange = false
                stopSpeedUpdateTimer()
                stopPulseAnimation()
            }
        }
        .onChange(of: isPaused) { _, _ in
            syncSpeedState()
        }
        .onChange(of: currentPosition) { oldPosition, newPosition in
            guard hasInitialized else { return }
            
            if let position = newPosition {
                // Smoothly animate to new position
                animateToPosition(position.coordinate)
                
                // Only auto-follow if user is not interacting
                if isFollowingUser {
                    updateCameraToFollowUser(at: position.coordinate)
                }
                
                updateRevealedRoute(progress: position.progress)
                updateTraveledPath(position.coordinate)
            }
        }
        
        // Recenter button - moved higher to avoid being blocked
        if showRecenterButton {
            VStack {
                Spacer()
                
                Button {
                    HapticManager.light()
                    recenterCamera()
                } label: {
                    MapRecenterButtonLabel(
                        title: L("map.recenter"),
                        colorScheme: colorScheme
                    )
                }
                .buttonStyle(MapOverlayButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 360) // Increased padding to clear the new bottom controls
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
        }
    }
    
    // MARK: - Pulsing Animation
    
    @State private var pulseScale: CGFloat = 1.0
    
    private func startPulseAnimation() {
        guard PerformanceConfig.enableAmbientAnimations else { return }
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            pulseScale = 1.3
        }
    }
    
    private func stopPulseAnimation() {
        withAnimation(.easeInOut(duration: 0.2)) {
            pulseScale = 1.0
        }
    }
    
    // MARK: - Speed Update Timer
    
    // 性能优化：降低速度更新频率从 3s 到 5s
    private func startSpeedUpdateTimer() {
        stopSpeedUpdateTimer()
        guard scenePhase == .active else { return }
        guard !isPaused else { return }
        guard !PerformanceOptimizer.shared.isEnergySavingMode else { return }
        let interval = PerformanceOptimizer.shared.secondaryUpdateInterval
        speedTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            updateSpeed()
        }
    }

    private func stopSpeedUpdateTimer() {
        speedTimer?.invalidate()
        speedTimer = nil
    }
    
    private func syncSpeedState() {
        let stableSpeed = speedState.ensureInitialized(using: randomSpeed(for:))
        publishCurrentSpeed(stableSpeed)

        if isPaused {
            stopSpeedUpdateTimer()
        } else {
            startSpeedUpdateTimer()
        }
    }

    private func updateSpeed() {
        let newSpeed = speedState.tickIfNeeded(isPaused: isPaused) { mode, currentSpeed in
            // For driving, make speed changes more gradual
            if mode == .driving {
                let range = speedRange(for: mode)
                let targetSpeed = Double.random(in: range.min...range.max)

                // Smooth transition: only change speed by max 20 km/h at a time
                let maxChange: Double = 20.0
                let speedDiff = targetSpeed - currentSpeed

                if abs(speedDiff) > maxChange {
                    return currentSpeed + (speedDiff > 0 ? maxChange : -maxChange)
                }

                return targetSpeed
            }

            return randomSpeed(for: mode)
        }

        publishCurrentSpeed(newSpeed)
    }

    private func publishCurrentSpeed(_ speed: Double) {
        currentSpeed = speed
    }
    
    // MARK: - Helper Functions
    
    private func animateToPosition(_ newCoordinate: CLLocationCoordinate2D) {
        guard PerformanceConfig.enableMapCameraAnimations else {
            animatedPosition = newCoordinate
            return
        }

        withAnimation(.linear(duration: positionAnimationDuration)) {
            animatedPosition = newCoordinate
        }
    }
    
    private func updateCameraToFollowUser(at coordinate: CLLocationCoordinate2D) {
        // Follow only in explicit follow mode.
        guard isFollowingUser else { return }
        guard shouldUpdateFollowCamera(to: coordinate) else { return }
        
        let zoom = zoomLevel(for: session.transportMode.speedMps)

        let animation: Animation? = PerformanceConfig.enableMapCameraAnimations
            ? .linear(duration: cameraAnimationDuration)
            : nil
        setCamera(center: coordinate, zoom: zoom, animation: animation)
    }
    
    private func recenterCamera() {
        let position = currentPosition?.coordinate ?? session.route.first ?? session.startLocation

        isFollowingUser = true
        lastCameraFollowCoordinate = position
        lastCameraFollowUpdateTime = Date()
        let zoom = zoomLevel(for: session.transportMode.speedMps)

        withAnimation(AnimationConfig.smoothSpring) {
            showRecenterButton = false
            cameraPosition = .region(MKCoordinateRegion(
                center: position,
                latitudinalMeters: zoom,
                longitudinalMeters: zoom
            ))
        }
    }

    private func setCamera(center: CLLocationCoordinate2D, zoom: Double, animation: Animation?) {
        cameraAnimationTask?.cancel()
        cameraAnimationTask = nil
        let guardToken = UUID()
        cameraGuardToken = guardToken
        isProgrammaticCameraChange = true
        let region = MKCoordinateRegion(
            center: center,
            latitudinalMeters: zoom,
            longitudinalMeters: zoom
        )

        let update = {
            cameraPosition = .region(region)
            lastKnownCameraRegion = region
        }

        if let animation {
            withAnimation(animation) {
                update()
            }
        } else {
            update()
        }

        // Release the guard shortly after the camera update settles.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            guard cameraGuardToken == guardToken else { return }
            isProgrammaticCameraChange = false
        }
    }

    private func animateCameraTransition(to center: CLLocationCoordinate2D, zoom: Double) {
        guard recenterAnimationDuration > 0 else {
            setCamera(center: center, zoom: zoom, animation: nil)
            return
        }

        cameraAnimationTask?.cancel()

        let startRegion = lastKnownCameraRegion
        let targetRegion = MKCoordinateRegion(
            center: center,
            latitudinalMeters: zoom,
            longitudinalMeters: zoom
        )
        let stepDuration = recenterAnimationDuration / Double(recenterAnimationStepCount)
        let guardToken = UUID()

        cameraGuardToken = guardToken
        isProgrammaticCameraChange = true
        cameraAnimationTask = Task { @MainActor in
            for step in 1...recenterAnimationStepCount {
                if Task.isCancelled {
                    if cameraGuardToken == guardToken {
                        isProgrammaticCameraChange = false
                    }
                    cameraAnimationTask = nil
                    return
                }

                let progress = smoothStep(Double(step) / Double(recenterAnimationStepCount))
                let region = MKCoordinateRegion(
                    center: CLLocationCoordinate2D(
                        latitude: interpolate(
                            from: startRegion.center.latitude,
                            to: targetRegion.center.latitude,
                            progress: progress
                        ),
                        longitude: interpolate(
                            from: startRegion.center.longitude,
                            to: targetRegion.center.longitude,
                            progress: progress
                        )
                    ),
                    latitudinalMeters: interpolate(
                        from: startRegion.latitudinalMeters,
                        to: targetRegion.latitudinalMeters,
                        progress: progress
                    ),
                    longitudinalMeters: interpolate(
                        from: startRegion.longitudinalMeters,
                        to: targetRegion.longitudinalMeters,
                        progress: progress
                    )
                )

                cameraPosition = .region(region)
                lastKnownCameraRegion = region

                if step < recenterAnimationStepCount {
                    do {
                        try await Task.sleep(for: .seconds(stepDuration))
                    } catch {
                        if cameraGuardToken == guardToken {
                            isProgrammaticCameraChange = false
                        }
                        cameraAnimationTask = nil
                        return
                    }
                }
            }

            cameraPosition = .region(targetRegion)
            lastKnownCameraRegion = targetRegion
            if cameraGuardToken == guardToken {
                isProgrammaticCameraChange = false
            }
            cameraAnimationTask = nil
        }
    }

    private func interpolate(from start: Double, to end: Double, progress: Double) -> Double {
        start + (end - start) * progress
    }

    private func smoothStep(_ value: Double) -> Double {
        let clamped = min(max(value, 0), 1)
        return clamped * clamped * (3 - 2 * clamped)
    }

    private func shouldUpdateFollowCamera(to coordinate: CLLocationCoordinate2D) -> Bool {
        let now = Date()

        if let lastCoordinate = lastCameraFollowCoordinate,
           let lastUpdateTime = lastCameraFollowUpdateTime {
            let distance = lastCoordinate.distance(to: coordinate)
            let elapsed = now.timeIntervalSince(lastUpdateTime)
            if distance < cameraFollowDistanceThreshold && elapsed < cameraFollowMinInterval {
                return false
            }
        }

        lastCameraFollowCoordinate = coordinate
        lastCameraFollowUpdateTime = now
        return true
    }
    
    private func updateTraveledPath(_ newCoordinate: CLLocationCoordinate2D) {
        // Add to traveled path if it's a new position
        if traveledPath.isEmpty {
            traveledPath.append(session.startLocation)
        }
        
        // Only add if the new coordinate is different enough (avoid duplicates)
        if let last = traveledPath.last {
            let distance = last.distance(to: newCoordinate)
            if distance > traveledPathMinDistance(for: session.transportMode) {
                traveledPath.append(newCoordinate)
                compactTraveledPathIfNeeded()
            }
        }
    }

    private func updateRevealedRoute(progress: Double) {
        guard !session.route.isEmpty else {
            revealedRouteCoordinates = []
            return
        }

        let totalPoints = session.route.count
        let targetCount = min(max(Int(Double(totalPoints) * progress), 0), totalPoints)

        if targetCount <= 1 {
            if targetCount == 1 && revealedRouteCoordinates.isEmpty {
                revealedRouteCoordinates = [session.route[0]]
            }
            return
        }

        if targetCount > revealedRouteCoordinates.count {
            let startIndex = revealedRouteCoordinates.count
            let update = {
                revealedRouteCoordinates.append(contentsOf: session.route[startIndex..<targetCount])
            }
            if PerformanceConfig.enableMapCameraAnimations {
                withAnimation(.linear(duration: 0.2)) {
                    update()
                }
            } else {
                update()
            }
            return
        }

        // Defensive fallback for rare non-monotonic progress updates.
        if targetCount < revealedRouteCoordinates.count {
            revealedRouteCoordinates = Array(session.route.prefix(targetCount))
        }
    }

    private func traveledPathMinDistance(for mode: TransportMode) -> CLLocationDistance {
        switch mode {
        case .walking:
            return 15
        case .cycling, .skateboard:
            return 28
        case .driving:
            return 60
        }
    }

    private func compactTraveledPathIfNeeded() {
        guard traveledPath.count > traveledPathMaxPoints else { return }
        traveledPath = downsample(path: traveledPath, targetCount: traveledPathTargetPoints)
    }

    private var displayedTraveledPath: [CLLocationCoordinate2D] {
        downsample(path: traveledPath, targetCount: traveledPathTargetPoints)
    }

    private var displayedRevealedRoute: [CLLocationCoordinate2D] {
        downsample(path: revealedRouteCoordinates, targetCount: displayedRouteTargetPoints)
    }

    private func downsample(path: [CLLocationCoordinate2D], targetCount: Int) -> [CLLocationCoordinate2D] {
        guard path.count > targetCount, targetCount > 2 else { return path }

        var sampled: [CLLocationCoordinate2D] = []
        sampled.reserveCapacity(targetCount)
        sampled.append(path[0])

        let interiorTargetCount = max(targetCount - 2, 0)
        let interiorSourceCount = max(path.count - 2, 0)

        if interiorTargetCount > 0, interiorSourceCount > 0 {
            let step = Double(interiorSourceCount) / Double(interiorTargetCount)
            for i in 0..<interiorTargetCount {
                let rawIndex = 1 + Int(round(Double(i) * step))
                let boundedIndex = min(max(rawIndex, 1), path.count - 2)
                let point = path[boundedIndex]
                if sampled.last != point {
                    sampled.append(point)
                }
            }
        }

        if sampled.last != path[path.count - 1] {
            sampled.append(path[path.count - 1])
        }

        return sampled
    }
}

// MARK: - Marker Components

struct StartMarker: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.green)
                .frame(width: 16, height: 16)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 3)
                )
                .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
        }
    }
}

struct AvatarMarker: View {
    let transportMode: TransportMode
    let pulseScale: CGFloat
    let avatarSettings: TransportAvatarSettings?
    
    var body: some View {
        ZStack {
            // Pulsing outer ring
            Circle()
                .fill(Color.blue.opacity(0.3))
                .frame(width: 50, height: 50)
                .scaleEffect(pulseScale)

            if let avatarImage {
                Image(uiImage: avatarImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 3)
                    )
                    .shadow(color: Color.blue.opacity(0.5), radius: 8, x: 0, y: 4)
                    .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
            } else {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.4, green: 0.7, blue: 0.9),
                                Color(red: 0.3, green: 0.5, blue: 0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 30, height: 30)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2.5)
                    )
                    .shadow(color: Color.blue.opacity(0.5), radius: 8, x: 0, y: 4)
                    .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)

                Image(systemName: transportMode.iconName)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 30, height: 30)
            }
        }
    }

    private var avatarImage: UIImage? {
        guard avatarSettings?.isEnabled == true,
              let avatarSettings,
              let data = avatarSettings.imageData else {
            return nil
        }
        let key = "map-avatar-\(avatarSettings.id.uuidString)-\(avatarSettings.updatedAt.timeIntervalSince1970)-\(data.count)"
        return ImageProcessing.avatarImage(from: data, cacheKey: key)
    }
}

struct DestinationMarker: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.red.opacity(0.2))
                .frame(width: 40, height: 40)
            
            Image(systemName: "flag.fill")
                .font(.system(size: 24))
                .foregroundStyle(Color.red, Color.white)
                .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
        }
    }
}

struct POIBubbleMarker: View {
    let poi: DiscoveredPOI
    
    var body: some View {
        VStack(spacing: 0) {
            // Pin
            ZStack {
                Circle()
                    .fill(Color.yellow)
                    .frame(width: 30, height: 30)
                    .shadow(color: Color.yellow.opacity(0.5), radius: 8, x: 0, y: 4)
                
                Image(systemName: "star.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .accessibilityLabel(Text(poi.name))
    }
}

private struct MapRecenterButtonLabel: View {
    let title: String
    let colorScheme: ColorScheme

    private var baseFill: LinearGradient {
        if PerformanceConfig.shouldReduceVisualEffects {
            return LinearGradient(
                colors: [
                    Color(red: 0.13, green: 0.18, blue: 0.28).opacity(0.94),
                    Color(red: 0.09, green: 0.13, blue: 0.21).opacity(0.92)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        return LinearGradient(
            colors: colorScheme == .dark
                ? [
                    Color(red: 0.14, green: 0.19, blue: 0.29).opacity(0.86),
                    Color(red: 0.10, green: 0.14, blue: 0.22).opacity(0.78)
                ]
                : [
                    Color.white.opacity(0.90),
                    Color(red: 0.92, green: 0.96, blue: 1.0).opacity(0.84)
                ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var accentGradient: LinearGradient {
        LinearGradient(
            colors: [
                LiquidGlassStyle.accentBlueLight.opacity(colorScheme == .dark ? 0.95 : 0.90),
                Color(red: 0.32, green: 0.72, blue: 0.96).opacity(colorScheme == .dark ? 0.88 : 0.82)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var titleColor: Color {
        colorScheme == .dark ? .white : Color(red: 0.12, green: 0.18, blue: 0.28)
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(accentGradient)
                    .frame(width: 34, height: 34)

                Circle()
                    .stroke(Color.white.opacity(0.28), lineWidth: 1)
                    .frame(width: 34, height: 34)

                Image(systemName: "location.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
            }

            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(titleColor)
                .padding(.trailing, 4)
        }
        .padding(.leading, 12)
        .padding(.trailing, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(baseFill)
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .opacity(PerformanceConfig.shouldReduceVisualEffects ? 0 : 0.42)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(
                            Color.white.opacity(colorScheme == .dark ? 0.14 : 0.36),
                            lineWidth: 1
                        )
                }
        )
        .shadow(
            color: Color.black.opacity(colorScheme == .dark ? 0.24 : 0.12),
            radius: 18,
            x: 0,
            y: 10
        )
        .shadow(
            color: LiquidGlassStyle.accentBlueLight.opacity(colorScheme == .dark ? 0.22 : 0.14),
            radius: 10,
            x: 0,
            y: 4
        )
    }
}

private struct MapOverlayButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .brightness(configuration.isPressed ? -0.02 : 0)
            .animation(AnimationConfig.pressDown, value: configuration.isPressed)
    }
}

private extension MKCoordinateRegion {
    var latitudinalMeters: CLLocationDistance {
        let halfDelta = span.latitudeDelta / 2
        let north = CLLocation(latitude: center.latitude + halfDelta, longitude: center.longitude)
        let south = CLLocation(latitude: center.latitude - halfDelta, longitude: center.longitude)
        return max(north.distance(from: south), 1)
    }

    var longitudinalMeters: CLLocationDistance {
        let halfDelta = span.longitudeDelta / 2
        let east = CLLocation(latitude: center.latitude, longitude: center.longitude + halfDelta)
        let west = CLLocation(latitude: center.latitude, longitude: center.longitude - halfDelta)
        return max(east.distance(from: west), 1)
    }
}

#Preview {
    @Previewable @State var speed: Double = 20.0
    
    ExplorationMapView(
        session: JourneySession(
            id: UUID(),
            startLocation: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            destinationLocation: CLLocationCoordinate2D(latitude: 37.8049, longitude: -122.4494),
            route: [
                CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4244),
                CLLocationCoordinate2D(latitude: 37.7949, longitude: -122.4344),
                CLLocationCoordinate2D(latitude: 37.8049, longitude: -122.4494)
            ],
            totalDistance: 5000,
            duration: 1500,
            transportMode: .cycling,
            startTime: Date()
        ),
        currentPosition: VirtualPosition(
            coordinate: CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4244),
            progress: 0.5,
            distanceTraveled: 2500,
            remainingTime: 750
        ),
        discoveredPOIs: [
            DiscoveredPOI(
                name: "Golden Gate Park",
                category: "park",
                coordinate: CLLocationCoordinate2D(latitude: 37.7694, longitude: -122.4862)
            )
        ],
        isPaused: false,
        currentSpeed: $speed
    )
}
