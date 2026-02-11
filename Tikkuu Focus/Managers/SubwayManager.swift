//
//  SubwayManager.swift
//  Tikkuu Focus
//
//  Created by Tikkuu on 2026/2/8.
//

import Foundation
import CoreLocation
import MapKit

/// Manages subway line detection and route generation
@MainActor
class SubwayManager {
    
    private let maxSearchRadius: CLLocationDistance = 10000 // 10 km
    private let minSearchRadius: CLLocationDistance = 500 // 500 m
    
    /// Find nearest subway station and generate a subway route
    func findSubwayRoute(from startLocation: CLLocationCoordinate2D, 
                        distance: Double) async throws -> SubwayRoute {
        
        print("🚇 Searching for subway stations within \(Int(maxSearchRadius))m...")
        
        // Search for nearby subway stations
        let stations = try await searchSubwayStations(near: startLocation, radius: maxSearchRadius)
        
        print("🚇 Initial search found \(stations.count) stations")
        
        guard !stations.isEmpty else {
            print("❌ No subway stations found within \(Int(maxSearchRadius))m")
            throw SubwayError.noNearbyLine
        }
        
        // Find the nearest station
        guard let nearestStation = stations.min(by: { station1, station2 in
            let dist1 = startLocation.distance(to: station1.coordinate)
            let dist2 = startLocation.distance(to: station2.coordinate)
            return dist1 < dist2
        }) else {
            throw SubwayError.noNearbyLine
        }
        
        let nearestDistance = startLocation.distance(to: nearestStation.coordinate)
        print("🚇 Nearest station: \(nearestStation.name) at \(Int(nearestDistance))m")
        
        // Get all stations on the same line
        let lineStations = try await getStationsOnLine(near: nearestStation.coordinate)
        
        guard lineStations.count >= 2 else {
            print("❌ Not enough stations on the line (found \(lineStations.count))")
            throw SubwayError.noNearbyLine
        }
        
        print("✅ Found \(lineStations.count) stations on the line")
        
        // Sort stations by distance to create a line
        let sortedStations = sortStationsIntoLine(stations: lineStations, startingFrom: nearestStation)
        
        // Find the starting station index
        guard let startIndex = sortedStations.firstIndex(where: { 
            $0.coordinate.distance(to: nearestStation.coordinate) < 100 
        }) else {
            throw SubwayError.noNearbyLine
        }
        
        // Generate route coordinates along the subway line
        let routeCoordinates = generateSubwayRoute(
            stations: sortedStations,
            startIndex: startIndex,
            targetDistance: distance
        )
        
        print("✅ Generated subway route with \(routeCoordinates.count) coordinates")
        
        return SubwayRoute(
            stations: sortedStations,
            startStationIndex: startIndex,
            coordinates: routeCoordinates,
            totalDistance: distance
        )
    }
    
    /// Find a random subway station in a preset city and generate route
    func findRandomSubwayRoute(in cityCoordinate: CLLocationCoordinate2D,
                              distance: Double,
                              presetStations: [PresetSubwayStation]? = nil) async throws -> SubwayRoute {
        
        // If preset stations are provided, use them directly
        if let presetStations = presetStations, !presetStations.isEmpty {
            print("🚇 Using \(presetStations.count) preset subway stations")
            
            // Convert preset stations to SubwayStation
            let stations = presetStations.map { preset in
                SubwayStation(name: preset.localizedName, coordinate: preset.coordinate)
            }
            
            // Pick a random starting station
            guard let randomStation = stations.randomElement() else {
                throw SubwayError.noNearbyLine
            }
            
            print("🚇 Starting from: \(randomStation.name)")
            
            // Use all stations as the line
            let sortedStations = sortStationsIntoLine(stations: stations, startingFrom: randomStation)
            
            // Find random starting station index
            let startIndex = Int.random(in: 0..<sortedStations.count)
            
            // Generate route
            let routeCoordinates = generateSubwayRoute(
                stations: sortedStations,
                startIndex: startIndex,
                targetDistance: distance
            )
            
            print("✅ Generated preset subway route with \(routeCoordinates.count) coordinates")
            
            return SubwayRoute(
                stations: sortedStations,
                startStationIndex: startIndex,
                coordinates: routeCoordinates,
                totalDistance: distance
            )
        }
        
        // Fallback to search if no preset stations
        print("🚇 No preset stations, searching...")
        
        // Search for subway stations in the city
        let stations = try await searchSubwayStations(near: cityCoordinate, radius: 5000)
        
        guard !stations.isEmpty else {
            throw SubwayError.noNearbyLine
        }
        
        // Pick a random station
        guard let randomStation = stations.randomElement() else {
            throw SubwayError.noNearbyLine
        }
        
        // Get all stations on the same line
        let lineStations = try await getStationsOnLine(near: randomStation.coordinate)
        
        guard lineStations.count >= 2 else {
            throw SubwayError.noNearbyLine
        }
        
        // Sort stations into a line
        let sortedStations = sortStationsIntoLine(stations: lineStations, startingFrom: randomStation)
        
        // Find random starting station index
        let startIndex = Int.random(in: 0..<sortedStations.count)
        
        // Generate route
        let routeCoordinates = generateSubwayRoute(
            stations: sortedStations,
            startIndex: startIndex,
            targetDistance: distance
        )
        
        return SubwayRoute(
            stations: sortedStations,
            startStationIndex: startIndex,
            coordinates: routeCoordinates,
            totalDistance: distance
        )
    }
    
    // MARK: - Private Methods
    
    /// Search for subway stations near a location
    private func searchSubwayStations(near coordinate: CLLocationCoordinate2D,
                                     radius: CLLocationDistance) async throws -> [SubwayStation] {
        
        print("🔍 Searching for subway stations...")
        print("📍 Center: \(coordinate.latitude), \(coordinate.longitude)")
        print("📏 Radius: \(Int(radius))m")
        
        // Expanded search terms for better coverage
        let searchTerms = [
            "subway station",
            "metro station", 
            "underground station",
            "地铁站",
            "轨道交通",
            "捷运站",
            "transit station"
        ]
        var allStations: [SubwayStation] = []
        
        for term in searchTerms {
            print("🔍 Searching for: \(term)")
            
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = term
            request.region = MKCoordinateRegion(
                center: coordinate,
                latitudinalMeters: radius * 2,
                longitudinalMeters: radius * 2
            )
            request.resultTypes = [.pointOfInterest]
            
            let search = MKLocalSearch(request: request)
            
            do {
                let response = try await search.start()
                
                print("   Found \(response.mapItems.count) results for '\(term)'")
                
                for item in response.mapItems {
                    guard let name = item.name else { continue }
                    
                    // More lenient filtering - check if it's a transit station
                    let lowerName = name.lowercased()
                    let isSubwayStation = lowerName.contains("subway") || 
                                         lowerName.contains("metro") || 
                                         lowerName.contains("underground") ||
                                         lowerName.contains("station") ||
                                         lowerName.contains("地铁") ||
                                         lowerName.contains("站") ||
                                         lowerName.contains("轨道") ||
                                         lowerName.contains("捷运") ||
                                         item.pointOfInterestCategory == .publicTransport
                    
                    if isSubwayStation {
                        let station = SubwayStation(
                            name: name,
                            coordinate: item.placemark.coordinate
                        )
                        
                        // Avoid duplicates (check both name and proximity)
                        let isDuplicate = allStations.contains { existing in
                            existing.name == station.name || 
                            existing.coordinate.distance(to: station.coordinate) < 50
                        }
                        
                        if !isDuplicate {
                            let distance = coordinate.distance(to: station.coordinate)
                            print("   ✓ \(name) at \(Int(distance))m")
                            allStations.append(station)
                        }
                    }
                }
                
                // Small delay to avoid throttling
                try? await Task.sleep(nanoseconds: 200_000_000)
                
            } catch {
                // Continue with next search term
                print("   ⚠️ Search failed for '\(term)': \(error.localizedDescription)")
                continue
            }
        }
        
        // Filter stations within the search radius
        let nearbyStations = allStations.filter { station in
            coordinate.distance(to: station.coordinate) <= radius
        }
        
        print("🚇 Total found: \(allStations.count) stations")
        print("🚇 Within \(Int(radius))m: \(nearbyStations.count) stations")
        
        return nearbyStations
    }
    
    /// Get all stations on the same subway line
    private func getStationsOnLine(near coordinate: CLLocationCoordinate2D) async throws -> [SubwayStation] {
        
        // Search in a larger radius to get more stations on the same line
        let stations = try await searchSubwayStations(near: coordinate, radius: 5000)
        
        print("🚇 Found \(stations.count) stations on the line")
        
        return stations
    }
    
    /// Sort stations into a logical line order
    private func sortStationsIntoLine(stations: [SubwayStation], 
                                     startingFrom start: SubwayStation) -> [SubwayStation] {
        
        guard stations.count > 1 else { return stations }
        
        var sortedStations: [SubwayStation] = [start]
        var remainingStations = stations.filter { $0.name != start.name }
        
        // Build the line by always adding the nearest unvisited station
        while !remainingStations.isEmpty {
            guard let lastStation = sortedStations.last else { break }
            
            // Find nearest remaining station
            guard let nearest = remainingStations.min(by: { station1, station2 in
                let dist1 = lastStation.coordinate.distance(to: station1.coordinate)
                let dist2 = lastStation.coordinate.distance(to: station2.coordinate)
                return dist1 < dist2
            }) else { break }
            
            sortedStations.append(nearest)
            remainingStations.removeAll { $0.name == nearest.name }
        }
        
        return sortedStations
    }
    
    /// Generate route coordinates along subway line with back-and-forth movement
    private func generateSubwayRoute(stations: [SubwayStation],
                                    startIndex: Int,
                                    targetDistance: Double) -> [CLLocationCoordinate2D] {
        
        var coordinates: [CLLocationCoordinate2D] = []
        var currentIndex = startIndex
        var direction = 1 // 1 for forward, -1 for backward
        var traveledDistance: Double = 0
        
        coordinates.append(stations[currentIndex].coordinate)
        
        while traveledDistance < targetDistance {
            let nextIndex = currentIndex + direction
            
            // Check if we need to reverse direction
            if nextIndex < 0 || nextIndex >= stations.count {
                direction *= -1
                continue
            }
            
            // Add segment between current and next station
            let segmentDistance = stations[currentIndex].coordinate.distance(to: stations[nextIndex].coordinate)
            
            // Interpolate points between stations for MUCH smoother movement
            // Use 20-50 points per segment depending on distance for ultra-smooth animation
            let interpolationSteps = max(20, Int(segmentDistance / 50)) // One point every ~50m, minimum 20 points
            for i in 1...interpolationSteps {
                let fraction = Double(i) / Double(interpolationSteps)
                let interpolated = interpolateCoordinate(
                    from: stations[currentIndex].coordinate,
                    to: stations[nextIndex].coordinate,
                    fraction: fraction
                )
                coordinates.append(interpolated)
            }
            
            traveledDistance += segmentDistance
            currentIndex = nextIndex
            
            // Safety check to avoid infinite loop
            if coordinates.count > 50000 {
                break
            }
        }
        
        return coordinates
    }
    
    /// Interpolate between two coordinates
    private func interpolateCoordinate(from start: CLLocationCoordinate2D,
                                      to end: CLLocationCoordinate2D,
                                      fraction: Double) -> CLLocationCoordinate2D {
        let lat = start.latitude + (end.latitude - start.latitude) * fraction
        let lon = start.longitude + (end.longitude - start.longitude) * fraction
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
}

// MARK: - Supporting Types

struct SubwayStation {
    let name: String
    let coordinate: CLLocationCoordinate2D
}

struct SubwayRoute {
    let stations: [SubwayStation]
    let startStationIndex: Int
    let coordinates: [CLLocationCoordinate2D]
    let totalDistance: Double
}

enum SubwayError: LocalizedError {
    case noNearbyLine
    case searchFailed
    
    var errorDescription: String? {
        switch self {
        case .noNearbyLine:
            return L("error.subway.noNearbyLine")
        case .searchFailed:
            return L("error.subway.searchFailed")
        }
    }
}
