//
//  ExplorationMapView.swift
//  Tikkuu Focus
//
//  Created by Tikkuu on 2026/2/8.
//

import SwiftUI
import MapKit

/// Exploration-style map view that reveals the route progressively
struct ExplorationMapView: View {
    let session: JourneySession
    let currentPosition: VirtualPosition?
    let discoveredPOIs: [DiscoveredPOI]
    @Binding var currentSpeed: Double
    
    @State private var cameraPosition: MapCameraPosition
    @State private var revealedRouteProgress: Double = 0.0
    @State private var traveledPath: [CLLocationCoordinate2D] = []
    @State private var animatedPosition: CLLocationCoordinate2D?
    @State private var hasInitialized = false
    @State private var isFollowingUser = true
    @State private var isProgrammaticCameraChange = false
    @State private var displaySpeed: Double = 0.0
    @State private var showRecenterButton = false
    @State private var speedTimer: Timer?
    @State private var lastCameraFollowCoordinate: CLLocationCoordinate2D?
    @State private var lastCameraFollowUpdateTime: Date?
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject private var settings = AppSettings.shared

    private let cameraFollowDistanceThreshold: CLLocationDistance = 20
    private let cameraFollowMinInterval: TimeInterval = 1.0

    init(
        session: JourneySession,
        currentPosition: VirtualPosition?,
        discoveredPOIs: [DiscoveredPOI],
        currentSpeed: Binding<Double>
    ) {
        self.session = session
        self.currentPosition = currentPosition
        self.discoveredPOIs = discoveredPOIs
        self._currentSpeed = currentSpeed

        let initialCenter = currentPosition?.coordinate ?? session.startLocation
        let initialZoom = Self.defaultZoom(for: session.transportMode)
        _cameraPosition = State(initialValue: .region(
            MKCoordinateRegion(
                center: initialCenter,
                latitudinalMeters: initialZoom,
                longitudinalMeters: initialZoom
            )
        ))
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
    
    var body: some View {
        ZStack {
            MapReader { proxy in
                Map(position: $cameraPosition, interactionModes: [.pan, .zoom]) {
            // Start marker (no label to avoid flickering)
            Marker(coordinate: session.startLocation) {
                ZStack {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 16, height: 16)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 3)
                        )
                        .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                }
            }
            .tint(.green)
            
            // Traveled path (trail behind avatar) - Bright and visible
            if traveledPath.count >= 2 {
                MapPolyline(coordinates: traveledPath)
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
            if currentPosition != nil, revealedRouteProgress > 0 {
                let revealedCoordinates = getRevealedRoute(progress: revealedRouteProgress)
                if revealedCoordinates.count >= 2 {
                    MapPolyline(coordinates: revealedCoordinates)
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
            }
            
            // Current position (avatar) with smooth animation and pulsing effect (no label to avoid flickering)
            if let position = animatedPosition ?? currentPosition?.coordinate {
                Marker(coordinate: position) {
                    ZStack {
                        // Pulsing outer ring
                        Circle()
                            .fill(Color.blue.opacity(0.3))
                            .frame(width: 50, height: 50)
                            .scaleEffect(pulseScale)
                        
                        // Main avatar with glow
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
                            .frame(width: 32, height: 32)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 3)
                            )
                            .shadow(color: Color.blue.opacity(0.5), radius: 8, x: 0, y: 4)
                            .shadow(color: Color.black.opacity(0.3), radius: 6, x: 0, y: 3)
                        
                        Image(systemName: session.transportMode.iconName)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .tint(.blue)
            }
            
            // Discovered POI markers (icon only, no tooltip bubble)
            ForEach(discoveredPOIs) { poi in
                Annotation(poi.name, coordinate: poi.coordinate) {
                    POIBubbleMarker(poi: poi)
                }
            }
            

            
            // Destination marker (only show when journey is complete or very close, no label to avoid flickering)
            if let position = currentPosition, position.progress > 0.95 {
                Marker(coordinate: session.destinationLocation) {
                    ZStack {
                        Circle()
                            .fill(Color.red.opacity(0.2))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "flag.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(Color.red, Color.white)
                            .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                }
                .tint(.red)
            }
        }
        .mapStyle(settings.selectedMapMode.style)
        .onMapCameraChange { context in
            // Only show recenter when user manually pans (drags) the map, not on zoom
            guard !isProgrammaticCameraChange, let currentPos = currentPosition?.coordinate else { return }

            let cameraCenter = context.region.center
            let distance = currentPos.distance(to: cameraCenter)

            // Only trigger on significant pan (drag), ignore zoom-only changes
            if distance > 50 {
                isFollowingUser = false
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showRecenterButton = true
                }
            }
        }
            } // Close MapReader
        .onAppear {
            if !hasInitialized {
                hasInitialized = true
                startPulseAnimation()
                
                // Initialize speed
                displaySpeed = randomSpeed(for: session.transportMode)
                
                // Start speed update timer
                startSpeedUpdateTimer()
            }
        }
        .onDisappear {
            stopSpeedUpdateTimer()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                startSpeedUpdateTimer()
            } else {
                stopSpeedUpdateTimer()
            }
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
                    HStack(spacing: 8) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 16, weight: .semibold))
                        
                        Text(L("map.recenter"))
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(Color.blue)
                            .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
                    )
                }
                .padding(.bottom, 280) // 增加底部间距，避免被 statsPanel 挡住
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
        }
    }
    
    // MARK: - Pulsing Animation
    
    @State private var pulseScale: CGFloat = 1.0
    
    private func startPulseAnimation() {
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            pulseScale = 1.3
        }
    }
    
    // MARK: - Speed Update Timer
    
    // 性能优化：降低速度更新频率从 3s 到 5s
    private func startSpeedUpdateTimer() {
        guard speedTimer == nil else { return }
        let interval = PerformanceOptimizer.shared.secondaryUpdateInterval
        speedTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            updateSpeed()
        }
    }

    private func stopSpeedUpdateTimer() {
        speedTimer?.invalidate()
        speedTimer = nil
    }
    
    private func updateSpeed() {
        let newSpeed: Double
        
        // For driving, make speed changes more gradual
        if session.transportMode == .driving {
            let range = speedRange(for: session.transportMode)
            let targetSpeed = Double.random(in: range.min...range.max)
            
            // Smooth transition: only change speed by max 20 km/h at a time
            let maxChange: Double = 20.0
            let speedDiff = targetSpeed - displaySpeed
            
            if abs(speedDiff) > maxChange {
                newSpeed = displaySpeed + (speedDiff > 0 ? maxChange : -maxChange)
            } else {
                newSpeed = targetSpeed
            }
        } else {
            newSpeed = randomSpeed(for: session.transportMode)
        }
        
        // Update display speed without animation to avoid visual glitches
        displaySpeed = newSpeed
        
        // Update binding on main thread without animation
        DispatchQueue.main.async {
            currentSpeed = newSpeed
        }
    }
    
    // MARK: - Helper Functions
    
    private func animateToPosition(_ newCoordinate: CLLocationCoordinate2D) {
        withAnimation(.linear(duration: 1.0)) {
            animatedPosition = newCoordinate
        }
    }
    
    private func updateCameraToFollowUser(at coordinate: CLLocationCoordinate2D) {
        // Follow only in explicit follow mode.
        guard isFollowingUser else { return }
        guard shouldUpdateFollowCamera(to: coordinate) else { return }
        
        let zoom = zoomLevel(for: session.transportMode.speedMps)

        // Use linear animation for smooth continuous movement.
        setCamera(center: coordinate, zoom: zoom, animation: .linear(duration: 1.0))
    }
    
    private func recenterCamera() {
        guard let position = currentPosition?.coordinate else { return }

        isFollowingUser = true
        lastCameraFollowCoordinate = nil
        lastCameraFollowUpdateTime = nil
        let zoom = zoomLevel(for: session.transportMode.speedMps)

        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            showRecenterButton = false
        }

        setCamera(center: position, zoom: zoom, animation: .spring(response: 0.5, dampingFraction: 0.7))
    }

    private func setCamera(center: CLLocationCoordinate2D, zoom: Double, animation: Animation?) {
        isProgrammaticCameraChange = true

        let update = {
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: center,
                    latitudinalMeters: zoom,
                    longitudinalMeters: zoom
                )
            )
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
            isProgrammaticCameraChange = false
        }
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
            if distance > 10 { // More than 10 meters
                traveledPath.append(newCoordinate)
            }
        }
    }
    
    private func getRevealedRoute(progress: Double) -> [CLLocationCoordinate2D] {
        guard !session.route.isEmpty else { return [] }
        
        // Calculate how many coordinates to reveal based on progress
        let totalPoints = session.route.count
        let revealedPoints = Int(Double(totalPoints) * progress)
        
        guard revealedPoints > 0 else { return [] }
        
        let endIndex = min(revealedPoints, totalPoints)
        return Array(session.route[0..<endIndex])
    }
    
    private func updateRevealedRoute(progress: Double) {
        withAnimation(.linear(duration: 0.5)) {
            revealedRouteProgress = progress
        }
    }
}

// MARK: - POI Bubble Marker

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
        currentSpeed: $speed
    )
}
