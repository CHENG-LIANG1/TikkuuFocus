//
//  JourneyRecord.swift
//  Tikkuu Focus
//
//  Created by Tikkuu on 2026/2/8.
//

import Foundation
import SwiftData
import CoreLocation

/// Journey record for history tracking
@Model
final class JourneyRecord {
    var id: UUID
    var startTime: Date
    var endTime: Date?
    var duration: TimeInterval // Actual duration (may be less than planned)
    var plannedDuration: TimeInterval
    var transportMode: String
    var startLocationName: String
    var startLatitude: Double
    var startLongitude: Double
    var destinationName: String
    var destinationLatitude: Double
    var destinationLongitude: Double
    var totalDistance: Double
    var distanceTraveled: Double
    var progress: Double
    var discoveredPOICount: Int
    var discoveredPOIsJSON: String
    var isCompleted: Bool
    
    init(
        id: UUID = UUID(),
        startTime: Date,
        endTime: Date? = nil,
        duration: TimeInterval,
        plannedDuration: TimeInterval,
        transportMode: String,
        startLocationName: String,
        startLatitude: Double,
        startLongitude: Double,
        destinationName: String,
        destinationLatitude: Double,
        destinationLongitude: Double,
        totalDistance: Double,
        distanceTraveled: Double,
        progress: Double,
        discoveredPOICount: Int,
        discoveredPOIsJSON: String = "[]",
        isCompleted: Bool
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.duration = duration
        self.plannedDuration = plannedDuration
        self.transportMode = transportMode
        self.startLocationName = startLocationName
        self.startLatitude = startLatitude
        self.startLongitude = startLongitude
        self.destinationName = destinationName
        self.destinationLatitude = destinationLatitude
        self.destinationLongitude = destinationLongitude
        self.totalDistance = totalDistance
        self.distanceTraveled = distanceTraveled
        self.progress = progress
        self.discoveredPOICount = discoveredPOICount
        self.discoveredPOIsJSON = discoveredPOIsJSON
        self.isCompleted = isCompleted
    }
    
    var startCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: startLatitude, longitude: startLongitude)
    }
    
    var destinationCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: destinationLatitude, longitude: destinationLongitude)
    }
    
    var formattedDuration: String {
        FormatUtilities.formatTime(duration)
    }
    
    var formattedDistance: String {
        FormatUtilities.formatDistance(distanceTraveled)
    }

    var discoveredPOIs: [StoredDiscoveredPOI] {
        guard let data = discoveredPOIsJSON.data(using: .utf8) else { return [] }
        return (try? JSONDecoder().decode([StoredDiscoveredPOI].self, from: data)) ?? []
    }

    static func encodePOIs(_ pois: [DiscoveredPOI]) -> String {
        let stored = pois.map { poi in
            StoredDiscoveredPOI(
                id: poi.id,
                name: poi.name,
                category: poi.category,
                latitude: poi.coordinate.latitude,
                longitude: poi.coordinate.longitude,
                discoveredAt: poi.discoveredAt
            )
        }

        guard let data = try? JSONEncoder().encode(stored),
              let json = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return json
    }
}

struct StoredDiscoveredPOI: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let category: String
    let latitude: Double
    let longitude: Double
    let discoveredAt: Date

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
