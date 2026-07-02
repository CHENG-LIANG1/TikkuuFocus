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
    var id: UUID = UUID()
    var startTime: Date = Date()
    var endTime: Date? = nil
    var duration: TimeInterval = 0 // Actual duration (may be less than planned)
    var plannedDuration: TimeInterval = 0
    var transportMode: String = ""
    var focusGoal: String = ""
    var vehicleBrand: String = ""
    var vehicleModel: String = ""
    var vehicleEnergyType: String = ""
    var vehiclePlate: String = ""
    var scenicRouteID: String = ""
    var scenicRouteName: String = ""
    var scenicRouteTotalDistance: Double = 0
    var scenicRouteProgress: Double = 0
    var startLocationName: String = ""
    var startLatitude: Double = 0
    var startLongitude: Double = 0
    var destinationName: String = ""
    var destinationLatitude: Double = 0
    var destinationLongitude: Double = 0
    var totalDistance: Double = 0
    var distanceTraveled: Double = 0
    var progress: Double = 0
    var discoveredPOICount: Int = 0
    var discoveredPOIsJSON: String = "[]"
    var isCompleted: Bool = false
    
    init(
        id: UUID = UUID(),
        startTime: Date,
        endTime: Date? = nil,
        duration: TimeInterval,
        plannedDuration: TimeInterval,
        transportMode: String,
        focusGoal: String = "",
        vehicleBrand: String = "",
        vehicleModel: String = "",
        vehicleEnergyType: String = "",
        vehiclePlate: String = "",
        scenicRouteID: String = "",
        scenicRouteName: String = "",
        scenicRouteTotalDistance: Double = 0,
        scenicRouteProgress: Double = 0,
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
        self.focusGoal = focusGoal
        self.vehicleBrand = vehicleBrand
        self.vehicleModel = vehicleModel
        self.vehicleEnergyType = vehicleEnergyType
        self.vehiclePlate = vehiclePlate
        self.scenicRouteID = scenicRouteID
        self.scenicRouteName = scenicRouteName
        self.scenicRouteTotalDistance = scenicRouteTotalDistance
        self.scenicRouteProgress = scenicRouteProgress
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

    var focusGoalDisplayName: String {
        focusGoal.isEmpty ? L("focus.goal.default") : focusGoal
    }

    var hasVehicle: Bool {
        !vehicleBrand.isEmpty || !vehicleModel.isEmpty || !vehiclePlate.isEmpty
    }

    /// Prefer the model name in history cards; fall back to brand + model for legacy records.
    var vehicleDisplayName: String {
        let trimmedModel = vehicleModel.trimmingCharacters(in: .whitespaces)
        if !trimmedModel.isEmpty {
            return trimmedModel
        }
        return [vehicleBrand, vehicleModel]
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    var vehicleEnergyTypeEnum: VehicleEnergyType? {
        VehicleEnergyType(rawValue: vehicleEnergyType)
    }

    var hasScenicRoute: Bool {
        !scenicRouteID.isEmpty
    }

    var scenicRouteDisplayName: String {
        scenicRouteName.isEmpty ? L("route.scenic.title") : scenicRouteName
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
                discoveredAt: poi.discoveredAt,
                rarity: poi.rarity.rawValue // Store rarity
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
    var rarity: String? // Optional for backward compatibility

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var rarityEnum: POIRarity {
        if let rarity = rarity, let enumValue = POIRarity(rawValue: rarity) {
            return enumValue
        }
        return .common
    }
}
