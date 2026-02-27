//
//  PresetLocation.swift
//  Tikkuu Focus
//
//  Created by Tikkuu on 2026/2/8.
//

import Foundation
import CoreLocation

/// Preset famous locations around the world
struct PresetLocation: Identifiable, Equatable {
    let id: UUID
    let name: String
    let nameZh: String
    let coordinate: CLLocationCoordinate2D
    let country: String
    let emoji: String
    
    init(id: UUID = UUID(), name: String, nameZh: String, coordinate: CLLocationCoordinate2D, country: String, emoji: String) {
        self.id = id
        self.name = name
        self.nameZh = nameZh
        self.coordinate = coordinate
        self.country = country
        self.emoji = emoji
    }
    
    var localizedName: String {
        if AppSettings.shared.currentLanguage.hasPrefix("zh") {
            return nameZh
        }
        return name
    }
    
    static func == (lhs: PresetLocation, rhs: PresetLocation) -> Bool {
        lhs.id == rhs.id
    }
}


// MARK: - Preset Locations

extension PresetLocation {
    static let presets: [PresetLocation] = [
        // Asia
        PresetLocation(
            name: "Tokyo, Japan",
            nameZh: "日本东京",
            coordinate: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503),
            country: "Japan",
            emoji: "🗼"
        ),
        PresetLocation(
            name: "Seoul, South Korea",
            nameZh: "韩国首尔",
            coordinate: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780),
            country: "South Korea",
            emoji: "🏯"
        ),
        PresetLocation(
            name: "Beijing, China",
            nameZh: "中国北京",
            coordinate: CLLocationCoordinate2D(latitude: 39.9042, longitude: 116.4074),
            country: "China",
            emoji: "🏛️"
        ),
        PresetLocation(
            name: "Shanghai, China",
            nameZh: "中国上海",
            coordinate: CLLocationCoordinate2D(latitude: 31.2304, longitude: 121.4737),
            country: "China",
            emoji: "🌃"
        ),
        PresetLocation(
            name: "Nanjing, China",
            nameZh: "中国南京",
            coordinate: CLLocationCoordinate2D(latitude: 32.0603, longitude: 118.7969),
            country: "China",
            emoji: "🏯"
        ),
        
        // Americas
        PresetLocation(
            name: "New York, USA",
            nameZh: "美国纽约",
            coordinate: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
            country: "USA",
            emoji: "🗽"
        ),
        PresetLocation(
            name: "San Francisco, USA",
            nameZh: "美国旧金山",
            coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            country: "USA",
            emoji: "🌉"
        ),
        PresetLocation(
            name: "Los Angeles, USA",
            nameZh: "美国洛杉矶",
            coordinate: CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437),
            country: "USA",
            emoji: "🎬"
        ),
        
        // Europe
        PresetLocation(
            name: "London, UK",
            nameZh: "英国伦敦",
            coordinate: CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278),
            country: "UK",
            emoji: "🎡"
        ),
        PresetLocation(
            name: "Paris, France",
            nameZh: "法国巴黎",
            coordinate: CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522),
            country: "France",
            emoji: "🗼"
        ),
        PresetLocation(
            name: "Rome, Italy",
            nameZh: "意大利罗马",
            coordinate: CLLocationCoordinate2D(latitude: 41.9028, longitude: 12.4964),
            country: "Italy",
            emoji: "🏛️"
        ),
        
        // Oceania
        PresetLocation(
            name: "Sydney, Australia",
            nameZh: "澳大利亚悉尼",
            coordinate: CLLocationCoordinate2D(latitude: -33.8688, longitude: 151.2093),
            country: "Australia",
            emoji: "🦘"
        )
    ]
}

/// Location source type
enum LocationSource: Equatable {
    case currentLocation
    case preset(PresetLocation)
    case custom(CLLocationCoordinate2D, String)
    
    var coordinate: CLLocationCoordinate2D? {
        switch self {
        case .currentLocation:
            return nil // Will be determined at runtime
        case .preset(let location):
            return location.coordinate
        case .custom(let coordinate, _):
            return coordinate
        }
    }
    
    var displayName: String {
        switch self {
        case .currentLocation:
            return L("location.current")
        case .preset(let location):
            return location.localizedName
        case .custom(_, let name):
            return name
        }
    }
}
