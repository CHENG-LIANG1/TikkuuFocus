//
//  JourneyManager.swift
//  Tikkuu Focus
//
//  Created by Tikkuu on 2026/2/8.
//

import Foundation
import CoreLocation
import MapKit
import Combine
import UIKit

/// Manages the journey logic: destination generation, routing, and progress tracking
@MainActor
class JourneyManager: ObservableObject {
    @Published var state: JourneyState = .idle
    @Published var currentPosition: VirtualPosition?
    @Published var discoveredPOIs: [DiscoveredPOI] = []
    @Published var pendingSummaryPayload: JourneySummaryPayload?
    
    private var timer: Timer?
    private var lastPOICheckTime: Date?
    private var pausedAt: Date?
    private var startLocationPOIs: Set<String> = [] // POIs near start location (excluded)
    private var lastCheckedCoordinate: CLLocationCoordinate2D?
    private let poiCheckInterval: TimeInterval = 300 // Check for POIs every 300 seconds (5 minutes) - 性能优化
    private let minimumTravelDistance: Double = 200 // Must travel at least 200m from start before discovering POIs
    private let discoveryRadius: CLLocationDistance = 100 // Reduced from 500m to 100m
    

    private var hasPrewarmedMapServices = false
    private var didEnterBackgroundObserver: NSObjectProtocol?
    private var didBecomeActiveObserver: NSObjectProtocol?

    init() {
        didEnterBackgroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handleDidEnterBackground()
            }
        }

        didBecomeActiveObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handleDidBecomeActive()
            }
        }
    }

    deinit {
        if let observer = didEnterBackgroundObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = didBecomeActiveObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // MARK: - Journey Creation
    
    /// Start a new journey from the given location
    func startJourney(from location: CLLocationCoordinate2D, 
                     transportMode: TransportMode, 
                     duration: TimeInterval,
                     isPresetCity: Bool = false,
                     presetLocation: PresetLocation? = nil) async {
        state = .preparing
        discoveredPOIs.removeAll()
        startLocationPOIs.removeAll()
        lastCheckedCoordinate = nil
        pausedAt = nil
        
        do {
            let resolvedStart = await resolveRoutableStartCoordinate(
                from: location,
                transportMode: transportMode
            )

            // Calculate distance based on speed and duration
            let distance = transportMode.speedMps * duration
            
            // Normal routing for all transport modes (including skateboard)
            // Generate random destination
            let destination = try await generateRandomDestination(from: resolvedStart, distance: distance)
            
            // Calculate route
            let route = try await calculateRoute(from: resolvedStart, to: destination, transportMode: transportMode)
            
            // Create session
            let session = JourneySession(
                id: UUID(),
                startLocation: resolvedStart,
                destinationLocation: destination,
                route: route.coordinates,
                totalDistance: route.distance,
                duration: duration,
                transportMode: transportMode,
                startTime: Date()
            )
            
            state = .active(session)
            startTimer()

            // Run start-area POI cache in background to avoid delaying journey start.
            Task(priority: .utility) {
                await self.recordStartLocationPOIs(at: resolvedStart)
            }
            
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    /// Pre-warm MapKit services to reduce first-start latency.
    func prewarmMapServices(near coordinate: CLLocationCoordinate2D) {
        guard !hasPrewarmedMapServices else { return }
        hasPrewarmedMapServices = true

        Task(priority: .utility) {
            // 1) Warm local search pipeline.
            let searchRequest = MKLocalSearch.Request()
            searchRequest.naturalLanguageQuery = "landmark"
            searchRequest.region = MKCoordinateRegion(
                center: coordinate,
                latitudinalMeters: 1200,
                longitudinalMeters: 1200
            )
            searchRequest.resultTypes = .pointOfInterest
            let search = MKLocalSearch(request: searchRequest)
            _ = try? await search.start()

            // 2) Warm directions pipeline with a tiny local request.
            let destination = coordinate.coordinate(at: 300, bearing: 30)
            let directionsRequest = MKDirections.Request()
            directionsRequest.source = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
            directionsRequest.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
            directionsRequest.transportType = .walking
            let directions = MKDirections(request: directionsRequest)
            _ = try? await directions.calculate()
        }
    }
    
    /// Generate a random destination at the specified distance
    private func generateRandomDestination(from start: CLLocationCoordinate2D, 
                                          distance: Double) async throws -> CLLocationCoordinate2D {
        // Skip pre-validation network calls and rely on route calculation fallback.
        let bearing = Double.random(in: 0..<360)
        return start.coordinate(at: distance, bearing: bearing)
    }

    /// If the selected start point is unroutable (e.g. sea), snap to nearest routable land road.
    private func resolveRoutableStartCoordinate(
        from coordinate: CLLocationCoordinate2D,
        transportMode: TransportMode
    ) async -> CLLocationCoordinate2D {
        // Fast path: current point is already routable.
        if await hasNearbyRoute(at: coordinate, transportMode: transportMode) {
            return coordinate
        }

        if let candidate = await findNearestAddressCandidate(
            around: coordinate,
            transportMode: transportMode
        ) {
            return candidate
        }

        if let radialCandidate = await findNearestRoutableByRadialScan(
            around: coordinate,
            transportMode: transportMode
        ) {
            return radialCandidate
        }

        // Fallback to original coordinate when no better candidate is found.
        return coordinate
    }

    private func findNearestAddressCandidate(
        around coordinate: CLLocationCoordinate2D,
        transportMode: TransportMode
    ) async -> CLLocationCoordinate2D? {
        let radii: [CLLocationDistance] = [600, 1500, 3000, 6000, 10000]
        let queries: [String] = ["road", "street", "路", "道路", "街道"]
        var seenKeys: Set<String> = []

        for radius in radii {
            var candidates: [CLLocationCoordinate2D] = []

            for query in queries {
                let request = MKLocalSearch.Request()
                request.naturalLanguageQuery = query
                request.region = MKCoordinateRegion(
                    center: coordinate,
                    latitudinalMeters: radius * 2,
                    longitudinalMeters: radius * 2
                )
                request.resultTypes = .address

                if let response = try? await MKLocalSearch(request: request).start() {
                    for item in response.mapItems {
                        let candidate = item.placemark.coordinate
                        guard CLLocationCoordinate2DIsValid(candidate) else { continue }
                        let key = String(format: "%.5f,%.5f", candidate.latitude, candidate.longitude)
                        guard seenKeys.insert(key).inserted else { continue }
                        candidates.append(candidate)
                    }
                }

                if candidates.count >= 12 {
                    break
                }
            }

            guard !candidates.isEmpty else { continue }

            let sortedCandidates = candidates.sorted {
                coordinate.distance(to: $0) < coordinate.distance(to: $1)
            }

            for candidate in sortedCandidates.prefix(8) {
                if await hasNearbyRoute(at: candidate, transportMode: transportMode) {
                    return candidate
                }
            }
        }

        return nil
    }

    private func findNearestRoutableByRadialScan(
        around coordinate: CLLocationCoordinate2D,
        transportMode: TransportMode
    ) async -> CLLocationCoordinate2D? {
        let radii: [Double] = [400, 900, 1600, 2800, 4500, 7000]
        let bearings: [Double] = [0, 45, 90, 135, 180, 225, 270, 315]

        for radius in radii {
            for bearing in bearings {
                let candidate = coordinate.coordinate(at: radius, bearing: bearing)
                if await hasNearbyRoute(at: candidate, transportMode: transportMode) {
                    return candidate
                }
            }
        }

        return nil
    }

    private func hasNearbyRoute(
        at coordinate: CLLocationCoordinate2D,
        transportMode: TransportMode
    ) async -> Bool {
        let probeDistance: Double = transportMode == .driving ? 700 : 350
        let probeBearings: [Double] = [45, 225]

        for bearing in probeBearings {
            let probeDestination = coordinate.coordinate(at: probeDistance, bearing: bearing)
            if await canCalculateRoute(
                from: coordinate,
                to: probeDestination,
                transportMode: transportMode
            ) {
                return true
            }
        }

        return false
    }

    private func canCalculateRoute(
        from start: CLLocationCoordinate2D,
        to destination: CLLocationCoordinate2D,
        transportMode: TransportMode
    ) async -> Bool {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: start))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.transportType = mapTransportType(for: transportMode)

        do {
            let response = try await MKDirections(request: request).calculate()
            guard let route = response.routes.first else { return false }
            return route.polyline.pointCount > 1 && route.distance > 0
        } catch {
            return false
        }
    }
    
    /// Calculate route from start to destination
    private func calculateRoute(from start: CLLocationCoordinate2D,
                               to destination: CLLocationCoordinate2D,
                               transportMode: TransportMode) async throws -> RouteResult {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: start))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.transportType = mapTransportType(for: transportMode)
        
        let directions = MKDirections(request: request)
        
        do {
            let response = try await directions.calculate()
            
            guard let route = response.routes.first else {
                throw JourneyError.noRouteFound
            }
            
            // Extract coordinates from polyline
            let coordinates = route.polyline.coordinates()
            
            return RouteResult(
                coordinates: coordinates,
                distance: route.distance
            )
            
        } catch {
            // Fallback: create a straight line route
            return RouteResult(
                coordinates: [start, destination],
                distance: start.distance(to: destination)
            )
        }
    }

    private func mapTransportType(for transportMode: TransportMode) -> MKDirectionsTransportType {
        switch transportMode {
        case .walking:
            return .walking
        case .cycling:
            return .walking // MapKit doesn't have cycling, use walking
        case .driving:
            return .automobile
        case .skateboard:
            return .walking // Use walking for skateboard
        }
    }
    
    // MARK: - Journey Control
    
    /// Pause the current journey
    func pauseJourney() {
        guard case .active(let session) = state else { return }
        stopTimer()
        pausedAt = Date()
        state = .paused(session)
    }
    
    /// Resume a paused journey
    func resumeJourney() {
        guard case .paused(let session) = state else { return }

        let pauseDuration = Date().timeIntervalSince(pausedAt ?? Date())
        pausedAt = nil

        // Shift start time forward by pause duration to exclude paused time.
        let newSession = JourneySession(
            id: session.id,
            startLocation: session.startLocation,
            destinationLocation: session.destinationLocation,
            route: session.route,
            totalDistance: session.totalDistance,
            duration: session.duration,
            transportMode: session.transportMode,
            startTime: session.startTime.addingTimeInterval(pauseDuration)
        )
        
        state = .active(newSession)
        startTimer()
    }
    
    /// Cancel the current journey
    func cancelJourney() {
        stopTimer()
        pausedAt = nil
        state = .idle
        currentPosition = nil
        discoveredPOIs.removeAll()
        startLocationPOIs.removeAll()
        lastCheckedCoordinate = nil
    }
    
    /// Complete the journey
    private func completeJourney() {
        guard case .active(let session) = state else { return }
        stopTimer()
        pausedAt = nil
        state = .completed(session)
    }
    
    // MARK: - Timer Management
    
    private func startTimer() {
        stopTimer()

        let interval = PerformanceOptimizer.shared.journeyUpdateInterval
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.updateJourney()
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateJourney() async {
        guard case .active(let session) = state else { return }
        
        let position = session.currentPosition()
        currentPosition = position
        
        // Check if journey is complete
        if position.remainingTime <= 0 {
            completeJourney()
            return
        }
        
        // Check for POIs periodically
        if shouldCheckForPOIs() {
            await checkForPOIs(at: position.coordinate)
            lastPOICheckTime = Date()
        }
    }
    
    private func shouldCheckForPOIs() -> Bool {
        guard let lastCheck = lastPOICheckTime else { return true }
        
        // Check if enough time has passed
        guard Date().timeIntervalSince(lastCheck) >= poiCheckInterval else { return false }
        
        // Check if we've moved enough distance from last check
        if let lastCoord = lastCheckedCoordinate, let currentCoord = currentPosition?.coordinate {
            let distanceMoved = lastCoord.distance(to: currentCoord)
            // Only check if moved at least 50m from last check
            return distanceMoved >= 50
        }
        
        return true
    }

    private func handleDidEnterBackground() {
        // Pause periodic updates in background to save battery.
        stopTimer()
    }

    private func handleDidBecomeActive() {
        // Resume timer only if journey is running/paused context exists.
        if case .active = state {
            startTimer()
            Task { @MainActor [weak self] in
                await self?.updateJourney()
            }
        }
    }
    
    // MARK: - POI Detection
    
    /// Record POIs near start location to exclude them from discovery
    private func recordStartLocationPOIs(at coordinate: CLLocationCoordinate2D) async {
        let queries = ["restaurant", "landmark", "park", "cafe", "museum"]
        
        for query in queries {
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = query
            request.region = MKCoordinateRegion(
                center: coordinate,
                latitudinalMeters: minimumTravelDistance * 2,
                longitudinalMeters: minimumTravelDistance * 2
            )
            request.resultTypes = .pointOfInterest
            
            let search = MKLocalSearch(request: request)
            
            do {
                let response = try await search.start()
                for item in response.mapItems {
                    if let name = item.name {
                        startLocationPOIs.insert(name)
                    }
                }
            } catch {
                // Silently fail
            }
            
            // Small delay to avoid throttling
            try? await Task.sleep(nanoseconds: 300_000_000)
        }
    }
    
    private func checkForPOIs(at coordinate: CLLocationCoordinate2D) async {
        // Check if we've traveled far enough from start
        guard case .active(let session) = state else { return }
        let distanceFromStart = session.startLocation.distance(to: coordinate)
        
        guard distanceFromStart >= minimumTravelDistance else {
            print("📍 Too close to start location (\(Int(distanceFromStart))m), skipping POI check")
            return
        }
        
        // Update last checked coordinate
        lastCheckedCoordinate = coordinate
        
        // 性能优化：减少查询类型从 3 个到 1 个，降低网络和 CPU 负载
        let queries = [
            "landmark"  // 只保留最重要的地标查询
        ]
        
        for query in queries {
            await searchPOI(query: query, near: coordinate, radius: discoveryRadius)
            // 性能优化：增加延迟从 0.5s 到 2s，避免 MapKit 限流
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 second delay
        }
    }
    
    private func searchPOI(query: String, near coordinate: CLLocationCoordinate2D, radius: CLLocationDistance) async {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: radius * 2,
            longitudinalMeters: radius * 2
        )
        request.resultTypes = .pointOfInterest // Only search for POIs, not addresses
        
        let search = MKLocalSearch(request: request)
        
        do {
            let response = try await search.start()
            
            for item in response.mapItems.prefix(2) { // Limit to 2 results per query to reduce load
                guard let name = item.name else { continue }
                
                // Skip if this POI was near the start location
                if startLocationPOIs.contains(name) {
                    print("🚫 Skipping start location POI: \(name)")
                    continue
                }
                
                // Check if POI is actually within discovery radius
                let poiDistance = coordinate.distance(to: item.placemark.coordinate)
                guard poiDistance <= radius else {
                    print("📏 POI too far: \(name) (\(Int(poiDistance))m)")
                    continue
                }
                
                let poi = DiscoveredPOI(
                    name: name,
                    category: query,
                    coordinate: item.placemark.coordinate
                )
                
                // Avoid duplicates
                if !discoveredPOIs.contains(where: { $0.name == poi.name }) {
                    print("✨ Discovered POI: \(name) at \(Int(poiDistance))m")
                    discoveredPOIs.append(poi)
                }
            }
        } catch let error as NSError {
            // Log throttling errors but don't crash
            if error.domain == "GEOErrorDomain" && error.code == -3 {
                print("⚠️ MapKit throttling detected, skipping POI search")
            }
            // Silently fail - POI discovery is not critical
        }
    }
}

// MARK: - Supporting Types

struct RouteResult {
    let coordinates: [CLLocationCoordinate2D]
    let distance: Double
}

enum JourneyError: LocalizedError {
    case noRouteFound
    case invalidDestination
    
    var errorDescription: String? {
        switch self {
        case .noRouteFound:
            return L("error.journey.noRoute")
        case .invalidDestination:
            return L("error.journey.invalidDestination")
        }
    }
}

// MARK: - CLLocationCoordinate2D Utilities

extension CLLocationCoordinate2D {
    /// Calculate a new coordinate at a given distance and bearing
    /// - Parameters:
    ///   - distance: Distance in meters
    ///   - bearing: Bearing in degrees (0-360)
    func coordinate(at distance: Double, bearing: Double) -> CLLocationCoordinate2D {
        let earthRadius = 6371000.0 // Earth's radius in meters
        
        let bearingRadians = bearing * .pi / 180.0
        let latRadians = latitude * .pi / 180.0
        let lonRadians = longitude * .pi / 180.0
        
        let angularDistance = distance / earthRadius
        
        let newLatRadians = asin(
            sin(latRadians) * cos(angularDistance) +
            cos(latRadians) * sin(angularDistance) * cos(bearingRadians)
        )
        
        let newLonRadians = lonRadians + atan2(
            sin(bearingRadians) * sin(angularDistance) * cos(latRadians),
            cos(angularDistance) - sin(latRadians) * sin(newLatRadians)
        )
        
        return CLLocationCoordinate2D(
            latitude: newLatRadians * 180.0 / .pi,
            longitude: newLonRadians * 180.0 / .pi
        )
    }
}

// MARK: - MKPolyline Extension

extension MKPolyline {
    /// Extract coordinates from polyline
    func coordinates() -> [CLLocationCoordinate2D] {
        var coords = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid, count: pointCount)
        getCoordinates(&coords, range: NSRange(location: 0, length: pointCount))
        return coords
    }
}
