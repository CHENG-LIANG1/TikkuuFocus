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

/// Manages the journey logic: destination generation, routing, and progress tracking
@MainActor
class JourneyManager: ObservableObject {
    @Published var state: JourneyState = .idle
    @Published var currentPosition: VirtualPosition?
    @Published var discoveredPOIs: [DiscoveredPOI] = []
    
    private var timer: Timer?
    private var lastPOICheckTime: Date?
    private var startLocationPOIs: Set<String> = [] // POIs near start location (excluded)
    private var lastCheckedCoordinate: CLLocationCoordinate2D?
    private let poiCheckInterval: TimeInterval = 300 // Check for POIs every 300 seconds (5 minutes) - 性能优化
    private let minimumTravelDistance: Double = 200 // Must travel at least 200m from start before discovering POIs
    private let discoveryRadius: CLLocationDistance = 100 // Reduced from 500m to 100m
    
    private let subwayManager = SubwayManager()
    
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
        
        do {
            // Calculate distance based on speed and duration
            let distance = transportMode.speedMps * duration
            
            // Handle subway mode differently
            if transportMode == .subway {
                print("🚇 Starting subway journey search...")
                print("📍 Location: \(location.latitude), \(location.longitude)")
                print("📏 Target distance: \(Int(distance))m")
                
                let subwayRoute: SubwayRoute
                
                do {
                    if isPresetCity, let preset = presetLocation {
                        print("🏙️ Using preset city subway stations: \(preset.localizedName)")
                        print("🚇 Available stations: \(preset.subwayStations.count)")
                        
                        // Use preset subway stations
                        subwayRoute = try await subwayManager.findRandomSubwayRoute(
                            in: location, 
                            distance: distance,
                            presetStations: preset.subwayStations
                        )
                    } else {
                        print("📍 Searching for nearest subway from current location...")
                        // For current location, find nearest subway
                        subwayRoute = try await subwayManager.findSubwayRoute(from: location, distance: distance)
                    }
                    
                    print("✅ Subway route found with \(subwayRoute.stations.count) stations")
                    
                } catch SubwayError.noNearbyLine {
                    print("❌ No subway line found within 10km")
                    state = .failed(NSLocalizedString("error.subway.noNearbyLine.detailed", 
                                                     value: "未找到附近的地铁线路（搜索范围：10公里）。请确认您的位置附近有地铁站，或尝试选择其他交通方式。", 
                                                     comment: "No nearby subway line detailed"))
                    return
                } catch {
                    print("❌ Subway search error: \(error.localizedDescription)")
                    state = .failed(error.localizedDescription)
                    return
                }
                
                // Use the first coordinate as start location
                let startLocation = subwayRoute.coordinates.first ?? location
                let destination = subwayRoute.coordinates.last ?? location
                
                // Convert subway stations to SubwayStationInfo
                let stationInfos = subwayRoute.stations.map { station in
                    SubwayStationInfo(name: station.name, coordinate: station.coordinate)
                }
                
                // Record POIs near start location
                await recordStartLocationPOIs(at: startLocation)
                
                // Create session with subway route
                let session = JourneySession(
                    id: UUID(),
                    startLocation: startLocation,
                    destinationLocation: destination,
                    route: subwayRoute.coordinates,
                    totalDistance: subwayRoute.totalDistance,
                    duration: duration,
                    transportMode: transportMode,
                    startTime: Date(),
                    subwayStations: stationInfos
                )
                
                state = .active(session)
                startTimer()
                
            } else {
                // Normal routing for other transport modes
                // Generate random destination
                let destination = try await generateRandomDestination(from: location, distance: distance)
                
                // Calculate route
                let route = try await calculateRoute(from: location, to: destination, transportMode: transportMode)
                
                // Record POIs near start location (to exclude them from discovery)
                await recordStartLocationPOIs(at: location)
                
                // Create session
                let session = JourneySession(
                    id: UUID(),
                    startLocation: location,
                    destinationLocation: destination,
                    route: route.coordinates,
                    totalDistance: route.distance,
                    duration: duration,
                    transportMode: transportMode,
                    startTime: Date(),
                    subwayStations: nil
                )
                
                state = .active(session)
                startTimer()
            }
            
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
    
    /// Generate a random destination at the specified distance
    private func generateRandomDestination(from start: CLLocationCoordinate2D, 
                                          distance: Double,
                                          maxAttempts: Int = 5) async throws -> CLLocationCoordinate2D {
        for _ in 0..<maxAttempts {
            // Generate random bearing (0-360 degrees)
            let bearing = Double.random(in: 0..<360)
            let destination = start.coordinate(at: distance, bearing: bearing)
            
            // Validate destination (basic check - not in ocean, etc.)
            if await isValidDestination(destination) {
                return destination
            }
        }
        
        // Fallback: return a destination even if validation fails
        let bearing = Double.random(in: 0..<360)
        return start.coordinate(at: distance, bearing: bearing)
    }
    
    /// Check if destination is valid (has roads nearby)
    private func isValidDestination(_ coordinate: CLLocationCoordinate2D) async -> Bool {
        // Simple validation: check if we can find any roads nearby
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "road"
        request.region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: 1000,
            longitudinalMeters: 1000
        )
        
        let search = MKLocalSearch(request: request)
        
        do {
            let response = try await search.start()
            return !response.mapItems.isEmpty
        } catch {
            // If search fails, assume it's valid (better than blocking)
            return true
        }
    }
    
    /// Calculate route from start to destination
    private func calculateRoute(from start: CLLocationCoordinate2D,
                               to destination: CLLocationCoordinate2D,
                               transportMode: TransportMode) async throws -> RouteResult {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: start))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        
        // Set transport type based on mode
        switch transportMode {
        case .walking:
            request.transportType = .walking
        case .cycling:
            request.transportType = .walking // MapKit doesn't have cycling, use walking
        case .driving:
            request.transportType = .automobile
        case .subway:
            request.transportType = .transit
        }
        
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
    
    // MARK: - Journey Control
    
    /// Pause the current journey
    func pauseJourney() {
        guard case .active(let session) = state else { return }
        stopTimer()
        state = .paused(session)
    }
    
    /// Resume a paused journey
    func resumeJourney() {
        guard case .paused(let session) = state else { return }
        
        // Create a new session with adjusted start time
        let elapsed = Date().timeIntervalSince(session.startTime)
        let newSession = JourneySession(
            id: session.id,
            startLocation: session.startLocation,
            destinationLocation: session.destinationLocation,
            route: session.route,
            totalDistance: session.totalDistance,
            duration: session.duration,
            transportMode: session.transportMode,
            startTime: Date().addingTimeInterval(-elapsed),
            subwayStations: session.subwayStations
        )
        
        state = .active(newSession)
        startTimer()
    }
    
    /// Cancel the current journey
    func cancelJourney() {
        stopTimer()
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
        state = .completed(session)
    }
    
    // MARK: - Timer Management
    
    private func startTimer() {
        stopTimer()
        
        // 性能优化：降低更新频率从 0.5s 到 2.0s，减少 CPU 占用
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
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
            return NSLocalizedString("error.journey.noRoute", comment: "No route found")
        case .invalidDestination:
            return NSLocalizedString("error.journey.invalidDestination", comment: "Invalid destination")
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
