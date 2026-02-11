//
//  PreviewHelpers.swift
//  Tikkuu Focus
//
//  Created by Tikkuu on 2026/2/8.
//

import Foundation
import CoreLocation

#if DEBUG
/// Helper utilities for SwiftUI previews and testing
extension JourneyManager {
    /// Create a mock active journey for previews
    static func mockActiveJourney() -> JourneyManager {
        let manager = JourneyManager()
        
        // Mock San Francisco location
        let start = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        let destination = CLLocationCoordinate2D(latitude: 37.8049, longitude: -122.4494)
        
        // Create mock route
        let route = [
            start,
            CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4244),
            CLLocationCoordinate2D(latitude: 37.7949, longitude: -122.4344),
            destination
        ]
        
        let session = JourneySession(
            id: UUID(),
            startLocation: start,
            destinationLocation: destination,
            route: route,
            totalDistance: 5000, // 5km
            duration: 1500, // 25 minutes
            transportMode: .cycling,
            startTime: Date().addingTimeInterval(-300), // Started 5 minutes ago
            subwayStations: nil
        )
        
        manager.state = .active(session)
        
        // Add mock POIs
        manager.discoveredPOIs = [
            DiscoveredPOI(
                name: "Golden Gate Park",
                category: "park",
                coordinate: CLLocationCoordinate2D(latitude: 37.7694, longitude: -122.4862)
            ),
            DiscoveredPOI(
                name: "Starbucks",
                category: "coffee",
                coordinate: CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4244)
            )
        ]
        
        return manager
    }
    
    /// Create a mock completed journey for previews
    static func mockCompletedJourney() -> JourneyManager {
        let manager = JourneyManager()
        
        let start = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        let destination = CLLocationCoordinate2D(latitude: 37.8049, longitude: -122.4494)
        
        let route = [start, destination]
        
        let session = JourneySession(
            id: UUID(),
            startLocation: start,
            destinationLocation: destination,
            route: route,
            totalDistance: 5000,
            duration: 1500,
            transportMode: .cycling,
            startTime: Date().addingTimeInterval(-1500), // Completed
            subwayStations: nil
        )
        
        manager.state = .completed(session)
        
        return manager
    }
}

extension LocationManager {
    /// Create a mock location manager with permission granted
    static func mockAuthorized() -> LocationManager {
        let manager = LocationManager()
        // Note: In real preview, this won't actually grant permission
        // but it helps visualize the UI state
        manager.currentLocation = CLLocation(
            latitude: 37.7749,
            longitude: -122.4194
        )
        return manager
    }
}
#endif
