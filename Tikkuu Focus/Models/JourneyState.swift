//
//  JourneyState.swift
//  Tikkuu Focus
//
//  Created by Tikkuu on 2026/2/8.
//

import Foundation
import CoreLocation
import MapKit

/// Represents the current state of a focus journey
enum JourneyState: Equatable {
    case idle
    case preparing
    case active(JourneySession)
    case paused(JourneySession)
    case completed(JourneySession)
    case failed(String)
    
    var isActive: Bool {
        if case .active = self { return true }
        return false
    }
    
    var session: JourneySession? {
        switch self {
        case .active(let session), .paused(let session), .completed(let session):
            return session
        default:
            return nil
        }
    }
}

/// Represents an active or completed journey session
struct JourneySession: Equatable, Identifiable {
    let id: UUID
    let startLocation: CLLocationCoordinate2D
    let destinationLocation: CLLocationCoordinate2D
    let route: [CLLocationCoordinate2D]
    let totalDistance: Double // in meters
    let duration: TimeInterval // in seconds
    let transportMode: TransportMode
    let startTime: Date
    let subwayStations: [SubwayStationInfo]? // For subway mode
    
    var endTime: Date {
        startTime.addingTimeInterval(duration)
    }
    
    /// Calculate current virtual position based on elapsed time
    func currentPosition(at date: Date = Date()) -> VirtualPosition {
        let elapsed = date.timeIntervalSince(startTime)
        let progress = min(max(elapsed / duration, 0), 1.0)
        
        let distanceTraveled = totalDistance * progress
        let coordinate = interpolatePosition(progress: progress)
        
        return VirtualPosition(
            coordinate: coordinate,
            progress: progress,
            distanceTraveled: distanceTraveled,
            remainingTime: max(duration - elapsed, 0)
        )
    }
    
    /// Interpolate position along the route based on progress (0.0 to 1.0)
    private func interpolatePosition(progress: Double) -> CLLocationCoordinate2D {
        guard !route.isEmpty else { return startLocation }
        guard progress > 0 else { return route.first ?? startLocation }
        guard progress < 1.0 else { return route.last ?? destinationLocation }
        
        // Calculate cumulative distances along the actual route
        var cumulativeDistances: [Double] = [0]
        for i in 1..<route.count {
            let segmentDistance = route[i-1].distance(to: route[i])
            cumulativeDistances.append(cumulativeDistances.last! + segmentDistance)
        }
        
        // Use actual route distance instead of totalDistance
        let actualRouteDistance = cumulativeDistances.last ?? totalDistance
        let targetDistance = actualRouteDistance * progress
        
        // Find the segment containing the target distance
        for i in 1..<cumulativeDistances.count {
            if targetDistance <= cumulativeDistances[i] {
                let segmentStart = cumulativeDistances[i-1]
                let segmentEnd = cumulativeDistances[i]
                let segmentLength = segmentEnd - segmentStart
                
                // Avoid division by zero
                guard segmentLength > 0 else {
                    return route[i-1]
                }
                
                let segmentProgress = (targetDistance - segmentStart) / segmentLength
                
                // Interpolate along this specific road segment
                return route[i-1].interpolate(to: route[i], fraction: segmentProgress)
            }
        }
        
        return route.last ?? destinationLocation
    }
    
    static func == (lhs: JourneySession, rhs: JourneySession) -> Bool {
        lhs.id == rhs.id
    }
}

/// Represents the virtual avatar's current position during a journey
struct VirtualPosition: Equatable {
    let coordinate: CLLocationCoordinate2D
    let progress: Double // 0.0 to 1.0
    let distanceTraveled: Double // in meters
    let remainingTime: TimeInterval // in seconds
    
    static func == (lhs: VirtualPosition, rhs: VirtualPosition) -> Bool {
        lhs.coordinate.latitude == rhs.coordinate.latitude &&
        lhs.coordinate.longitude == rhs.coordinate.longitude &&
        lhs.progress == rhs.progress
    }
}

/// Point of Interest discovered during the journey
struct DiscoveredPOI: Identifiable, Equatable {
    let id: UUID
    let name: String
    let category: String
    let coordinate: CLLocationCoordinate2D
    let discoveredAt: Date
    
    init(id: UUID = UUID(), name: String, category: String, coordinate: CLLocationCoordinate2D, discoveredAt: Date = Date()) {
        self.id = id
        self.name = name
        self.category = category
        self.coordinate = coordinate
        self.discoveredAt = discoveredAt
    }
    
    static func == (lhs: DiscoveredPOI, rhs: DiscoveredPOI) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - CLLocationCoordinate2D Extensions

extension CLLocationCoordinate2D: @retroactive Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
    
    /// Calculate distance to another coordinate in meters
    func distance(to coordinate: CLLocationCoordinate2D) -> Double {
        let location1 = CLLocation(latitude: latitude, longitude: longitude)
        let location2 = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return location1.distance(from: location2)
    }
    
    /// Interpolate between two coordinates
    func interpolate(to coordinate: CLLocationCoordinate2D, fraction: Double) -> CLLocationCoordinate2D {
        let lat = latitude + (coordinate.latitude - latitude) * fraction
        let lon = longitude + (coordinate.longitude - longitude) * fraction
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
}

// MARK: - Subway Station Info

/// Information about a subway station for display on the map
struct SubwayStationInfo: Equatable, Identifiable {
    let id: UUID
    let name: String
    let coordinate: CLLocationCoordinate2D
    
    init(id: UUID = UUID(), name: String, coordinate: CLLocationCoordinate2D) {
        self.id = id
        self.name = name
        self.coordinate = coordinate
    }
    
    static func == (lhs: SubwayStationInfo, rhs: SubwayStationInfo) -> Bool {
        lhs.id == rhs.id
    }
}
