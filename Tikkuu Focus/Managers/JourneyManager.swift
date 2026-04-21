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

// Configuration Constants
fileprivate struct JourneyConfig {
    static let poiCheckInterval: TimeInterval = 300 // 5 minutes
    static let minimumTravelDistance: Double = 200 // meters
    static let discoveryRadius: CLLocationDistance = 100 // meters
    static let poiQueryDelay: UInt64 = 2_000_000_000 // 2 seconds in nanoseconds
    static let startPoiQueryDelay: UInt64 = 300_000_000 // 300ms in nanoseconds
    static let retryDelay: UInt64 = 100_000_000 // 100ms in nanoseconds
    static let prewarmThrottleDistance: Double = 5000 // meters
    static let prewarmThrottleTime: TimeInterval = 300 // seconds
    static let preparedPlanMaxAge: TimeInterval = 180 // seconds
    static let preparationMatchDistance: CLLocationDistance = 220 // meters
    static let poiMovementThreshold: Double = 50 // meters
    static let routeDistanceAcceptanceRatio: Double = 0.15 // 15%
    static let routeDistanceReasonableRatio: Double = 0.60 // 60%
    static let routeDistanceHardMinRatio: Double = 0.30 // 30%
    static let routeDistanceHardMaxRatio: Double = 1.80 // 180%
}

/// Manages the journey logic: destination generation, routing, and progress tracking
@MainActor
class JourneyManager: ObservableObject {
    @Published var state: JourneyState = .idle
    @Published var currentPosition: VirtualPosition?
    @Published var discoveredPOIs: [DiscoveredPOI] = []
    @Published var pendingSummaryPayload: JourneySummaryPayload?
    @Published private(set) var preparedDestination: CLLocationCoordinate2D?
    
    private var journeyTask: Task<Void, Never>?
    private var lastPOICheckTime: Date?
    private var pausedAt: Date?
    private var startLocationPOIs: Set<String> = [] // POIs near start location (excluded)
    private var lastCheckedCoordinate: CLLocationCoordinate2D?
    
    private var prewarmTask: Task<Void, Never>?
    private var lastPrewarmedCoordinate: CLLocationCoordinate2D?
    private var lastPrewarmDate: Date = .distantPast
    private var journeyPreparationTask: Task<Void, Never>?
    private var preparedJourneyPlan: PreparedJourneyPlan?
    private var preparationGeneration: Int = 0
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
        prewarmTask?.cancel()
        journeyPreparationTask?.cancel()

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
        let request = JourneyPreparationRequest(
            requestedStart: location,
            transportMode: transportMode,
            duration: duration,
            isPresetCity: isPresetCity,
            presetCoordinate: presetLocation?.coordinate
        )

        resetJourneyRuntimeState()

        if let preparedPlan = consumePreparedJourneyPlan(matching: request) {
            activateJourney(
                start: preparedPlan.resolvedStart,
                destination: preparedPlan.destination,
                route: preparedPlan.route,
                duration: duration,
                transportMode: transportMode
            )
            return
        }

        state = .preparing
        journeyPreparationTask?.cancel()
        
        do {
            let resolvedStart = await resolveRoutableStartCoordinate(
                from: location,
                transportMode: transportMode,
                validateForPreset: isPresetCity
            )

            // Calculate distance based on speed and duration
            let distance = transportMode.speedMps * duration
            
            // Generate routable destination with retry logic
            let (destination, route) = try await generateRoutableDestination(
                from: resolvedStart,
                distance: distance,
                transportMode: transportMode
            )
            
            activateJourney(
                start: resolvedStart,
                destination: destination,
                route: route,
                duration: duration,
                transportMode: transportMode
            )
            
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    /// Pre-calculate a journey route in background so tapping start can enter roaming faster.
    func prepareJourney(
        from location: CLLocationCoordinate2D,
        transportMode: TransportMode,
        duration: TimeInterval,
        isPresetCity: Bool = false,
        presetLocation: PresetLocation? = nil
    ) {
        let request = JourneyPreparationRequest(
            requestedStart: location,
            transportMode: transportMode,
            duration: duration,
            isPresetCity: isPresetCity,
            presetCoordinate: presetLocation?.coordinate
        )

        if let existing = preparedJourneyPlan,
           existing.request.matches(request, tolerance: JourneyConfig.preparationMatchDistance),
           existing.isFresh(maxAge: JourneyConfig.preparedPlanMaxAge) {
            return
        }

        preparationGeneration += 1
        let generation = preparationGeneration
        journeyPreparationTask?.cancel()

        journeyPreparationTask = Task(priority: .utility) { [weak self] in
            guard let self else { return }
            let plan = await self.buildPreparedJourneyPlan(for: request)
            guard !Task.isCancelled else { return }

            await MainActor.run {
                guard generation == self.preparationGeneration else { return }
                self.preparedJourneyPlan = plan
                self.preparedDestination = plan?.destination
            }
        }
    }

    /// Pre-warm MapKit services to reduce first-start latency.
    /// Only warms local search - directions will be warmed during route preparation.
    func prewarmMapServices(near coordinate: CLLocationCoordinate2D) {
        let now = Date()
        if let lastCoordinate = lastPrewarmedCoordinate {
            let movedDistance = lastCoordinate.distance(to: coordinate)
            let elapsed = now.timeIntervalSince(lastPrewarmDate)
            // More aggressive throttling to avoid rate limits
            if movedDistance < JourneyConfig.prewarmThrottleDistance && elapsed < JourneyConfig.prewarmThrottleTime {
                return
            }
        }

        lastPrewarmedCoordinate = coordinate
        lastPrewarmDate = now
        prewarmTask?.cancel()

        prewarmTask = Task(priority: .utility) {
            // Only warm local search pipeline - skip directions to avoid rate limits
            let searchRequest = MKLocalSearch.Request()
            searchRequest.naturalLanguageQuery = "cafe"
            searchRequest.region = MKCoordinateRegion(
                center: coordinate,
                latitudinalMeters: 2000,
                longitudinalMeters: 2000
            )
            searchRequest.resultTypes = .pointOfInterest
            let search = MKLocalSearch(request: searchRequest)
            _ = try? await search.start()
        }
    }
    
    /// Generate a random destination at the specified distance
    /// Tries multiple bearings to find a routable destination
    private func generateRandomDestination(from start: CLLocationCoordinate2D, 
                                          distance: Double) async throws -> CLLocationCoordinate2D {
        // Just generate a random bearing - route validation happens in calculateRoute
        let bearing = Double.random(in: 0..<360)
        return start.coordinate(at: distance, bearing: bearing)
    }
    
    /// Generate destination and calculate route with retry logic
    private func generateRoutableDestination(
        from start: CLLocationCoordinate2D,
        distance: Double,
        transportMode: TransportMode
    ) async throws -> (destination: CLLocationCoordinate2D, route: RouteResult) {
        let maxAttempts = 6
        let targetDistance = max(distance, 1)
        var lastError: Error = JourneyError.noRouteFound
        var bestCandidate: (destination: CLLocationCoordinate2D, route: RouteResult, distanceErrorRatio: Double)?
        
        // Try different bearings
        let bearings = [
            Double.random(in: 0..<360),
            Double.random(in: 0..<360),
            45.0, 135.0, 225.0, 315.0 // Cardinal directions as fallback
        ]
        
        for (index, bearing) in bearings.prefix(maxAttempts).enumerated() {
            let destination = start.coordinate(at: distance, bearing: bearing)
            guard isCoordinateValidForRouting(destination) else { continue }
            
            do {
                let route = try await calculateRouteStrict(
                    from: start,
                    to: destination,
                    transportMode: transportMode,
                    targetDistance: distance
                )
                let distanceErrorRatio = abs(route.distance - targetDistance) / targetDistance
                if bestCandidate == nil || distanceErrorRatio < (bestCandidate?.distanceErrorRatio ?? .greatestFiniteMagnitude) {
                    bestCandidate = (destination, route, distanceErrorRatio)
                }

                // Early-return once we find a route close enough to requested distance.
                if distanceErrorRatio <= JourneyConfig.routeDistanceAcceptanceRatio {
                    return (destination, route)
                }
            } catch {
                lastError = error
            }

            // Small delay between retries to avoid rate limiting
            if index < maxAttempts - 1 {
                try? await Task.sleep(nanoseconds: JourneyConfig.retryDelay)
            }
        }

        if let bestCandidate,
           bestCandidate.distanceErrorRatio <= JourneyConfig.routeDistanceReasonableRatio {
            return (bestCandidate.destination, bestCandidate.route)
        }

        if let fallback = makeFallbackRoute(
            from: start,
            preferredDestination: bestCandidate?.destination,
            targetDistance: targetDistance
        ) {
            return fallback
        }

        throw lastError
    }

    /// If the selected start point is unroutable (e.g. sea), snap to nearest routable land road.
    /// Optimized to minimize API calls.
    private func resolveRoutableStartCoordinate(
        from coordinate: CLLocationCoordinate2D,
        transportMode: TransportMode,
        validateForPreset: Bool
    ) async -> CLLocationCoordinate2D {
        // Keep current-location and custom picks fast; only validate pre-defined preset starts.
        guard validateForPreset else { return coordinate }

        if await hasNearbyRoute(at: coordinate, transportMode: transportMode) {
            return coordinate
        }

        if let nearbyAddress = await findNearestAddressCandidate(around: coordinate, transportMode: transportMode) {
            return nearbyAddress
        }

        if let radialCandidate = await findNearestRoutableByRadialScan(around: coordinate, transportMode: transportMode) {
            return radialCandidate
        }

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
    
    /// Calculate route from start to destination (strict - throws on failure)
    private func calculateRouteStrict(from start: CLLocationCoordinate2D,
                                      to destination: CLLocationCoordinate2D,
                                      transportMode: TransportMode,
                                      targetDistance: Double? = nil) async throws -> RouteResult {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: start))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.transportType = mapTransportType(for: transportMode)
        request.requestsAlternateRoutes = true
        
        let directions = MKDirections(request: request)
        let response = try await directions.calculate()

        let validRoutes = response.routes.filter { $0.polyline.pointCount > 1 && $0.distance > 0 }
        guard !validRoutes.isEmpty else {
            throw JourneyError.noRouteFound
        }

        let route: MKRoute
        if let targetDistance {
            route = validRoutes.min {
                abs($0.distance - targetDistance) < abs($1.distance - targetDistance)
            } ?? validRoutes[0]
        } else {
            route = validRoutes[0]
        }
        
        let coordinates = route.polyline.coordinates()
        
        return RouteResult(
            coordinates: coordinates,
            distance: route.distance
        )
    }
    
    /// Calculate route from start to destination (with fallback for compatibility)
    private func calculateRoute(from start: CLLocationCoordinate2D,
                               to destination: CLLocationCoordinate2D,
                               transportMode: TransportMode) async throws -> RouteResult {
        do {
            return try await calculateRouteStrict(from: start, to: destination, transportMode: transportMode)
        } catch {
            // Fallback: create a straight line route (only for edge cases)
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

    private func resetJourneyRuntimeState() {
        currentPosition = nil
        discoveredPOIs.removeAll()
        startLocationPOIs.removeAll()
        lastCheckedCoordinate = nil
        lastPOICheckTime = nil
        pausedAt = nil
    }

    private func activateJourney(
        start: CLLocationCoordinate2D,
        destination: CLLocationCoordinate2D,
        route: RouteResult,
        duration: TimeInterval,
        transportMode: TransportMode
    ) {
        let targetDistance = max(transportMode.speedMps * duration, 1)
        let safeRoute = sanitizeRouteResult(
            route,
            start: start,
            destination: destination,
            targetDistance: targetDistance
        )

        let session = JourneySession(
            id: UUID(),
            startLocation: start,
            destinationLocation: destination,
            route: safeRoute.coordinates,
            totalDistance: safeRoute.distance,
            duration: duration,
            transportMode: transportMode,
            startTime: Date()
        )

        state = .active(session)
        startTimer()

        // Run start-area POI cache in background to avoid delaying journey start.
        Task(priority: .utility) {
            await self.recordStartLocationPOIs(at: start)
        }
    }

    private func consumePreparedJourneyPlan(
        matching request: JourneyPreparationRequest
    ) -> PreparedJourneyPlan? {
        guard let plan = preparedJourneyPlan else { return nil }
        guard plan.isFresh(maxAge: JourneyConfig.preparedPlanMaxAge) else {
            preparedJourneyPlan = nil
            preparedDestination = nil
            return nil
        }
        guard plan.request.matches(request, tolerance: JourneyConfig.preparationMatchDistance) else {
            return nil
        }
        preparedJourneyPlan = nil
        preparedDestination = nil
        return plan
    }

    private func buildPreparedJourneyPlan(
        for request: JourneyPreparationRequest
    ) async -> PreparedJourneyPlan? {
        let resolvedStart = await resolveRoutableStartCoordinate(
            from: request.requestedStart,
            transportMode: request.transportMode,
            validateForPreset: request.isPresetCity
        )

        let distance = request.transportMode.speedMps * request.duration
        guard distance > 0 else { return nil }

        do {
            let (destination, route) = try await generateRoutableDestination(
                from: resolvedStart,
                distance: distance,
                transportMode: request.transportMode
            )

            return PreparedJourneyPlan(
                request: request,
                resolvedStart: resolvedStart,
                destination: destination,
                route: route,
                createdAt: Date()
            )
        } catch {
            return nil
        }
    }

    private func isCoordinateValidForRouting(_ coordinate: CLLocationCoordinate2D) -> Bool {
        guard CLLocationCoordinate2DIsValid(coordinate) else { return false }
        return coordinate.latitude.isFinite && coordinate.longitude.isFinite
    }

    private func makeFallbackRoute(
        from start: CLLocationCoordinate2D,
        preferredDestination: CLLocationCoordinate2D?,
        targetDistance: Double
    ) -> (destination: CLLocationCoordinate2D, route: RouteResult)? {
        let fallbackDistance = max(targetDistance, 50)
        var fallbackDestinations: [CLLocationCoordinate2D] = []

        if let preferredDestination {
            fallbackDestinations.append(preferredDestination)
        }
        fallbackDestinations.append(start.coordinate(at: fallbackDistance, bearing: Double.random(in: 0..<360)))
        fallbackDestinations.append(start.coordinate(at: fallbackDistance, bearing: 45))
        fallbackDestinations.append(start.coordinate(at: fallbackDistance, bearing: 225))

        for destination in fallbackDestinations where isCoordinateValidForRouting(destination) {
            let straightLineDistance = start.distance(to: destination)
            guard straightLineDistance.isFinite, straightLineDistance > 0 else { continue }
            let route = RouteResult(
                coordinates: [start, destination],
                distance: straightLineDistance
            )
            return (destination, route)
        }

        return nil
    }

    private func sanitizeRouteResult(
        _ route: RouteResult,
        start: CLLocationCoordinate2D,
        destination: CLLocationCoordinate2D,
        targetDistance: Double
    ) -> RouteResult {
        let isDistanceFinite = route.distance.isFinite && route.distance > 0
        let ratio = route.distance / max(targetDistance, 1)
        let isRatioReasonable = ratio >= JourneyConfig.routeDistanceHardMinRatio &&
            ratio <= JourneyConfig.routeDistanceHardMaxRatio
        let hasValidCoordinates = route.coordinates.count >= 2 &&
            route.coordinates.allSatisfy { isCoordinateValidForRouting($0) }

        if isDistanceFinite, isRatioReasonable, hasValidCoordinates {
            return route
        }

        if let fallback = makeFallbackRoute(
            from: start,
            preferredDestination: destination,
            targetDistance: targetDistance
        ) {
            return fallback.route
        }

        return RouteResult(
            coordinates: [start, destination],
            distance: max(targetDistance, 1)
        )
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

        journeyTask = Task { @MainActor [weak self] in
            guard let self else { return }
            let interval = UInt64(PerformanceOptimizer.shared.journeyUpdateInterval * 1_000_000_000)
            
            while !Task.isCancelled {
                await self.updateJourney()
                try? await Task.sleep(nanoseconds: interval)
            }
        }
    }
    
    private func stopTimer() {
        journeyTask?.cancel()
        journeyTask = nil
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
        guard Date().timeIntervalSince(lastCheck) >= JourneyConfig.poiCheckInterval else { return false }
        
        // Check if we've moved enough distance from last check
        if let lastCoord = lastCheckedCoordinate, let currentCoord = currentPosition?.coordinate {
            let distanceMoved = lastCoord.distance(to: currentCoord)
            // Only check if moved at least 50m from last check
            return distanceMoved >= JourneyConfig.poiMovementThreshold
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
        
        // Move to background thread
        Task.detached(priority: .utility) { [weak self] in
            guard let self else { return }
            
            for query in queries {
                let request = MKLocalSearch.Request()
                request.naturalLanguageQuery = query
                request.region = MKCoordinateRegion(
                    center: coordinate,
                    latitudinalMeters: JourneyConfig.minimumTravelDistance * 2,
                    longitudinalMeters: JourneyConfig.minimumTravelDistance * 2
                )
                request.resultTypes = .pointOfInterest
                
                let search = MKLocalSearch(request: request)
                
                do {
                    let response = try await search.start()
                    let names = response.mapItems.compactMap { $0.name }
                    
                    await MainActor.run {
                        for name in names {
                            self.startLocationPOIs.insert(name)
                        }
                    }
                } catch {
                    // Silently fail
                }
                
                // Small delay to avoid throttling
                try? await Task.sleep(nanoseconds: JourneyConfig.startPoiQueryDelay)
            }
        }
    }
    
    private func checkForPOIs(at coordinate: CLLocationCoordinate2D) async {
        // Check if we've traveled far enough from start
        guard case .active(let session) = state else { return }
        let distanceFromStart = session.startLocation.distance(to: coordinate)
        
        guard distanceFromStart >= JourneyConfig.minimumTravelDistance else {
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
            await searchPOI(query: query, near: coordinate, radius: JourneyConfig.discoveryRadius)
            // 性能优化：增加延迟从 0.5s 到 2s，避免 MapKit 限流
            try? await Task.sleep(nanoseconds: JourneyConfig.poiQueryDelay)
        }
    }
    
    // Determine rarity based on probability
    private func generateRandomRarity() -> POIRarity {
        let roll = Double.random(in: 0...1)
        
        if roll < POIRarity.legendary.probability {
            return .legendary
        } else if roll < POIRarity.legendary.probability + POIRarity.epic.probability {
            return .epic
        } else if roll < POIRarity.legendary.probability + POIRarity.epic.probability + POIRarity.rare.probability {
            return .rare
        } else {
            return .common
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
                
                let rarity = generateRandomRarity()
                
                let poi = DiscoveredPOI(
                    name: name,
                    category: query,
                    coordinate: item.placemark.coordinate,
                    rarity: rarity
                )
                
                // Avoid duplicates
                if !discoveredPOIs.contains(where: { $0.name == poi.name }) {
                    print("✨ Discovered \(rarity) POI: \(name) at \(Int(poiDistance))m")
                    discoveredPOIs.append(poi)
                    
                    // Haptic feedback for discovery (stronger for rarer items)
                    Task { @MainActor in
                        switch rarity {
                        case .legendary: HapticManager.success()
                        case .epic: HapticManager.heavy()
                        case .rare: HapticManager.medium()
                        case .common: HapticManager.light()
                        }
                    }
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

private struct JourneyPreparationRequest {
    let requestedStart: CLLocationCoordinate2D
    let transportMode: TransportMode
    let duration: TimeInterval
    let isPresetCity: Bool
    let presetCoordinate: CLLocationCoordinate2D?

    func matches(_ other: JourneyPreparationRequest, tolerance: CLLocationDistance) -> Bool {
        guard transportMode == other.transportMode else { return false }
        guard abs(duration - other.duration) <= 1 else { return false }
        guard isPresetCity == other.isPresetCity else { return false }

        if let lhsPreset = presetCoordinate, let rhsPreset = other.presetCoordinate {
            guard lhsPreset.distance(to: rhsPreset) <= tolerance else { return false }
        } else if (presetCoordinate != nil) != (other.presetCoordinate != nil) {
            return false
        }

        return requestedStart.distance(to: other.requestedStart) <= tolerance
    }
}

private struct PreparedJourneyPlan {
    let request: JourneyPreparationRequest
    let resolvedStart: CLLocationCoordinate2D
    let destination: CLLocationCoordinate2D
    let route: RouteResult
    let createdAt: Date

    func isFresh(maxAge: TimeInterval) -> Bool {
        Date().timeIntervalSince(createdAt) <= maxAge
    }
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
        guard distance.isFinite, bearing.isFinite else { return self }

        let earthRadius = 6371000.0 // Earth's radius in meters
        
        let bearingRadians = bearing * .pi / 180.0
        let latRadians = latitude * .pi / 180.0
        let lonRadians = longitude * .pi / 180.0
        
        let angularDistance = max(distance, 0) / earthRadius
        
        let newLatRadians = asin(
            sin(latRadians) * cos(angularDistance) +
            cos(latRadians) * sin(angularDistance) * cos(bearingRadians)
        )
        
        let newLonRadians = lonRadians + atan2(
            sin(bearingRadians) * sin(angularDistance) * cos(latRadians),
            cos(angularDistance) - sin(latRadians) * sin(newLatRadians)
        )
        
        let newLatitude = max(min(newLatRadians * 180.0 / .pi, 90), -90)
        let rawLongitude = newLonRadians * 180.0 / .pi
        let normalizedLongitude = ((rawLongitude + 540).truncatingRemainder(dividingBy: 360)) - 180

        return CLLocationCoordinate2D(latitude: newLatitude, longitude: normalizedLongitude)
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
