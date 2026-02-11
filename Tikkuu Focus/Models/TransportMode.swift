//
//  TransportMode.swift
//  Tikkuu Focus
//
//  Created by Tikkuu on 2026/2/8.
//

import Foundation

/// Represents different modes of virtual transport during a focus session
enum TransportMode: String, CaseIterable, Identifiable {
    case walking
    case cycling
    case driving
    case subway
    
    var id: String { rawValue }
    
    /// Speed in kilometers per hour
    var speedKmh: Double {
        switch self {
        case .walking: return 5.0      // 步行：5 km/h（正常步行速度）
        case .cycling: return 18.0     // 骑行：18 km/h（城市骑行平均速度）
        case .driving: return 50.0     // 驾车：50 km/h（城市道路平均速度，考虑红绿灯和拥堵）
        case .subway: return 80.0      // 地铁：80 km/h（地铁运行平均速度，含停站时间）
        }
    }
    
    /// Speed in meters per second
    var speedMps: Double {
        speedKmh * 1000.0 / 3600.0
    }
    
    /// Localized display name
    var localizedName: String {
        switch self {
        case .walking: return NSLocalizedString("transport.walking", comment: "Walking")
        case .cycling: return NSLocalizedString("transport.cycling", comment: "Cycling")
        case .driving: return NSLocalizedString("transport.driving", comment: "Driving")
        case .subway: return NSLocalizedString("transport.subway", comment: "Subway")
        }
    }
    
    /// Icon name for SF Symbols
    var iconName: String {
        switch self {
        case .walking: return "figure.walk"
        case .cycling: return "bicycle"
        case .driving: return "car.fill"
        case .subway: return "tram.fill"
        }
    }
    
    /// Suggested focus durations in minutes
    var suggestedDurations: [Int] {
        switch self {
        case .walking: return [25, 45, 90]
        case .cycling: return [25, 45, 90]
        case .driving: return [25, 45, 90]
        case .subway: return [25, 45, 90]
        }
    }
}
