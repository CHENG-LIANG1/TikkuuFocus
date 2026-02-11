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
    
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var revealedRouteProgress: Double = 0.0
    @State private var traveledPath: [CLLocationCoordinate2D] = []
    @State private var animatedPosition: CLLocationCoordinate2D?
    @State private var hasInitialized = false
    @State private var currentStationIndex: Int? = nil
    @State private var showStationToast = false
    @State private var currentStation: SubwayStationInfo? = nil
    @State private var isUserInteracting = false
    @State private var lastAutoUpdateTime = Date()
    @State private var displaySpeed: Double = 0.0
    @State private var showRecenterButton = false
    @State private var userCameraPosition: CLLocationCoordinate2D?
    @State private var subwayDirection: Int = 1 // 1 for forward, -1 for backward
    @State private var targetStationIndex: Int = 0
    @State private var isApproachingStation = false
    @State private var hideAllBubbles = false
    @State private var hideAllLabels = false
    
    // Speed range for each transport mode (in km/h)
    private func speedRange(for mode: TransportMode) -> (min: Double, max: Double) {
        switch mode {
        case .walking:
            return (3.0, 6.0)  // 3-6 km/h
        case .cycling:
            return (15.0, 25.0)  // 15-25 km/h
        case .driving:
            return (40.0, 100.0)  // 40-100 km/h (faster and smoother)
        case .subway:
            return (50.0, 90.0)  // 50-90 km/h
        }
    }
    
    // Generate random speed within range
    private func randomSpeed(for mode: TransportMode) -> Double {
        let range = speedRange(for: mode)
        return Double.random(in: range.min...range.max)
    }
    
    // Calculate subway speed based on station proximity
    private func calculateSubwaySpeed() -> Double {
        guard session.transportMode == .subway,
              let stations = session.subwayStations,
              let currentPos = currentPosition?.coordinate else {
            return randomSpeed(for: session.transportMode)
        }
        
        // Find nearest station
        var nearestDistance = Double.infinity
        var nearestIndex = 0
        
        for (index, station) in stations.enumerated() {
            let distance = currentPos.distance(to: station.coordinate)
            if distance < nearestDistance {
                nearestDistance = distance
                nearestIndex = index
            }
        }
        
        // If within 200m of a station, slow down to 0
        if nearestDistance < 200 {
            let slowdownFactor = nearestDistance / 200.0
            let maxSpeed = Double.random(in: 50...90)
            let speed = maxSpeed * slowdownFactor
            
            // If very close (< 50m), speed is 0
            if nearestDistance < 50 {
                // Check if we should reverse direction
                if nearestIndex == 0 || nearestIndex == stations.count - 1 {
                    // At terminal station, reverse direction
                    subwayDirection *= -1
                    targetStationIndex = nearestIndex + subwayDirection
                }
                return 0
            }
            
            return speed
        }
        
        // Between stations, run at full speed
        return Double.random(in: 50...90)
    }
    
    // Dynamic zoom based on speed
    private func zoomLevel(for speed: Double) -> Double {
        // speed is in meters per second
        // Walking: ~1.4 m/s → 800m view
        // Cycling: ~5.5 m/s → 1500m view
        // Driving: ~16.7 m/s → 3000m view
        // Subway: ~11.1 m/s → 2000m view
        
        switch session.transportMode {
        case .walking:
            return 800
        case .cycling:
            return 1500
        case .driving:
            return 3000
        case .subway:
            return 2000
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
                            style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round, dash: [10, 5])
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
            
            // Discovered POI markers with bubbles
            ForEach(discoveredPOIs) { poi in
                Annotation(poi.name, coordinate: poi.coordinate) {
                    POIBubbleMarker(poi: poi, hideAllBubbles: $hideAllBubbles)
                }
            }
            
            // Subway stations (only for subway mode)
            if session.transportMode == .subway, let stations = session.subwayStations {
                ForEach(stations) { station in
                    Annotation(station.name, coordinate: station.coordinate) {
                        SubwayStationMarker(
                            station: station,
                            isCurrent: isCurrentStation(station),
                            hideAllLabels: $hideAllLabels
                        )
                    }
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
        .mapStyle(.standard(elevation: .realistic))
        .onTapGesture { screenCoordinate in
            // Hide all bubbles and labels when tapping on empty space
            hideAllBubbles = true
            hideAllLabels = true
            
            // Reset after a short delay to allow re-showing
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                hideAllBubbles = false
                hideAllLabels = false
            }
        }
        .onMapCameraChange { context in
            // Detect user interaction
            if let currentPos = currentPosition?.coordinate {
                let cameraCenter = context.region.center
                let distance = currentPos.distance(to: cameraCenter)
                
                // If camera moved more than 100 meters from user position, show recenter button
                if distance > 100 {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showRecenterButton = true
                    }
                    isUserInteracting = true
                    userCameraPosition = cameraCenter
                } else {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showRecenterButton = false
                    }
                    isUserInteracting = false
                }
            }
            lastAutoUpdateTime = Date()
        }
            } // Close MapReader
        .onAppear {
            if !hasInitialized {
                hasInitialized = true
                startPulseAnimation()
                
                // Initialize camera position with appropriate zoom
                if let position = currentPosition {
                    let zoom = zoomLevel(for: session.transportMode.speedMps)
                    cameraPosition = .region(
                        MKCoordinateRegion(
                            center: position.coordinate,
                            latitudinalMeters: zoom,
                            longitudinalMeters: zoom
                        )
                    )
                }
                
                // Initialize speed
                if session.transportMode == .subway {
                    displaySpeed = calculateSubwaySpeed()
                } else {
                    displaySpeed = randomSpeed(for: session.transportMode)
                }
                
                // Start speed update timer
                startSpeedUpdateTimer()
            }
        }
        .onChange(of: currentPosition) { oldPosition, newPosition in
            guard hasInitialized else { return }
            
            if let position = newPosition {
                // Smoothly animate to new position
                animateToPosition(position.coordinate)
                
                // Only auto-follow if user is not interacting
                if !isUserInteracting {
                    updateCameraToFollowUser(at: position.coordinate)
                }
                
                updateRevealedRoute(progress: position.progress)
                updateTraveledPath(position.coordinate)
                
                // Check for subway station arrival
                if session.transportMode == .subway {
                    checkSubwayStationArrival(at: position.coordinate)
                }
            }
        }
        
        // Station toast overlay
        stationToastView
        
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
    
    // MARK: - Subway Station Detection
    
    private func isCurrentStation(_ station: SubwayStationInfo) -> Bool {
        guard let index = currentStationIndex,
              let stations = session.subwayStations,
              index < stations.count else {
            return false
        }
        return stations[index].id == station.id
    }
    
    private func checkSubwayStationArrival(at coordinate: CLLocationCoordinate2D) {
        guard let stations = session.subwayStations else { return }
        
        // Check if we're near any station (within 50 meters)
        for (index, station) in stations.enumerated() {
            let distance = coordinate.distance(to: station.coordinate)
            
            if distance < 50 {
                // Check if this is a new station
                if currentStationIndex != index {
                    currentStationIndex = index
                    currentStation = station
                    
                    // Check if at terminal station
                    if index == 0 || index == stations.count - 1 {
                        // At terminal, will reverse direction
                        showStationNotification(station: station, isTerminal: true)
                    } else {
                        showStationNotification(station: station, isTerminal: false)
                    }
                }
                return
            }
        }
    }
    
    private func showStationNotification(station: SubwayStationInfo, isTerminal: Bool) {
        currentStation = station
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            showStationToast = true
        }
        
        // Auto-hide after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showStationToast = false
            }
        }
    }
    
    // MARK: - View Body Extension
    
    private var stationToastView: some View {
        Group {
            if showStationToast, let station = currentStation {
                VStack {
                    Spacer()
                    
                    SubwayStationToast(station: station)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 200)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
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
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            updateSpeed()
        }
    }
    
    private func updateSpeed() {
        let newSpeed: Double
        
        // Use special logic for subway
        if session.transportMode == .subway {
            newSpeed = calculateSubwaySpeed()
        } else {
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
        // Only follow user if not manually interacting
        guard !isUserInteracting else { return }
        
        let zoom = zoomLevel(for: session.transportMode.speedMps)
        
        // Use linear animation for smooth continuous movement
        withAnimation(.linear(duration: 1.0)) {
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: coordinate,
                    latitudinalMeters: zoom,
                    longitudinalMeters: zoom
                )
            )
        }
    }
    
    private func recenterCamera() {
        guard let position = currentPosition?.coordinate else { return }
        
        isUserInteracting = false
        userCameraPosition = nil
        
        let zoom = zoomLevel(for: session.transportMode.speedMps)
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: position,
                    latitudinalMeters: zoom,
                    longitudinalMeters: zoom
                )
            )
            showRecenterButton = false
        }
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
    @Binding var hideAllBubbles: Bool
    @State private var showBubble = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Bubble
            if showBubble && !hideAllBubbles {
                VStack(spacing: 4) {
                    Text(poi.name)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                    
                    Text(poi.category)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.yellow.opacity(0.5), lineWidth: 2)
                )
                .transition(.scale.combined(with: .opacity))
            }
            
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
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.3)) {
                showBubble = true
            }
            
            // Auto-hide bubble after 5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                withAnimation(.easeOut(duration: 0.3)) {
                    showBubble = false
                }
            }
        }
        .onChange(of: hideAllBubbles) { _, newValue in
            if newValue {
                withAnimation(.easeOut(duration: 0.2)) {
                    showBubble = false
                }
            }
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                showBubble.toggle()
            }
        }
    }
}

// MARK: - Subway Station Marker

struct SubwayStationMarker: View {
    let station: SubwayStationInfo
    let isCurrent: Bool
    @Binding var hideAllLabels: Bool
    @State private var showLabel = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Station label
            if showLabel && !hideAllLabels {
                Text(station.name)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue)
                            .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                    )
                    .transition(.scale.combined(with: .opacity))
            }
            
            // Station marker
            ZStack {
                // Outer ring for current station
                if isCurrent {
                    Circle()
                        .stroke(Color.blue, lineWidth: 3)
                        .frame(width: 32, height: 32)
                        .scaleEffect(pulseScale)
                }
                
                Circle()
                    .fill(isCurrent ? Color.blue : Color.white)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Circle()
                            .stroke(Color.blue, lineWidth: 2)
                    )
                    .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                
                if isCurrent {
                    Image(systemName: "tram.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
        .onAppear {
            if isCurrent {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    showLabel = true
                }
                startPulseAnimation()
            }
        }
        .onChange(of: isCurrent) { _, newValue in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                showLabel = newValue
            }
            if newValue {
                startPulseAnimation()
            }
        }
        .onChange(of: hideAllLabels) { _, newValue in
            if newValue {
                withAnimation(.easeOut(duration: 0.2)) {
                    showLabel = false
                }
            }
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                showLabel.toggle()
            }
        }
    }
    
    @State private var pulseScale: CGFloat = 1.0
    
    private func startPulseAnimation() {
        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            pulseScale = 1.3
        }
    }
}

// MARK: - Subway Station Toast

struct SubwayStationToast: View {
    let station: SubwayStationInfo
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 40, height: 40)
                
                Image(systemName: "tram.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
            }
            .shadow(color: Color.blue.opacity(0.5), radius: 8, x: 0, y: 4)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(L("subway.arriving"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text(station.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.blue.opacity(0.5), lineWidth: 2)
                )
        )
        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
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
            startTime: Date(),
            subwayStations: nil
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
