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

    // Precomputed route distances for fast interpolation during timer updates.
    private let cumulativeRouteDistances: [Double]
    private let routeDistanceForInterpolation: Double

    init(
        id: UUID,
        startLocation: CLLocationCoordinate2D,
        destinationLocation: CLLocationCoordinate2D,
        route: [CLLocationCoordinate2D],
        totalDistance: Double,
        duration: TimeInterval,
        transportMode: TransportMode,
        startTime: Date
    ) {
        self.id = id
        self.startLocation = startLocation
        self.destinationLocation = destinationLocation
        self.route = route
        self.totalDistance = totalDistance
        self.duration = duration
        self.transportMode = transportMode
        self.startTime = startTime

        let cumulative = JourneySession.buildCumulativeRouteDistances(route)
        self.cumulativeRouteDistances = cumulative
        self.routeDistanceForInterpolation = cumulative.last ?? totalDistance
    }
    
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

        guard cumulativeRouteDistances.count >= 2 else {
            return route.last ?? destinationLocation
        }

        let targetDistance = routeDistanceForInterpolation * progress
        let index = segmentIndex(for: targetDistance)
        let segmentStart = cumulativeRouteDistances[index - 1]
        let segmentEnd = cumulativeRouteDistances[index]
        let segmentLength = segmentEnd - segmentStart

        // Avoid division by zero
        guard segmentLength > 0 else {
            return route[index - 1]
        }

        let segmentProgress = (targetDistance - segmentStart) / segmentLength

        // Interpolate along this specific road segment
        return route[index - 1].interpolate(to: route[index], fraction: segmentProgress)
    }

    private static func buildCumulativeRouteDistances(_ route: [CLLocationCoordinate2D]) -> [Double] {
        guard !route.isEmpty else { return [] }
        guard route.count > 1 else { return [0] }

        var cumulative: [Double] = [0]
        cumulative.reserveCapacity(route.count)

        for i in 1..<route.count {
            let segmentDistance = route[i - 1].distance(to: route[i])
            cumulative.append(cumulative[i - 1] + segmentDistance)
        }

        return cumulative
    }

    private func segmentIndex(for targetDistance: Double) -> Int {
        var low = 1
        var high = cumulativeRouteDistances.count - 1

        while low < high {
            let mid = (low + high) / 2
            if cumulativeRouteDistances[mid] < targetDistance {
                low = mid + 1
            } else {
                high = mid
            }
        }

        return low
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
