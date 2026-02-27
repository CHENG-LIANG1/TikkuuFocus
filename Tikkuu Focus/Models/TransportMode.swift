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
    case skateboard
    
    var id: String { rawValue }
    
    /// Speed in kilometers per hour
    var speedKmh: Double {
        switch self {
        case .walking: return 5.0       // 步行：5 km/h（正常步行速度）
        case .cycling: return 18.0      // 骑行：18 km/h（城市骑行平均速度）
        case .driving: return 50.0      // 驾车：50 km/h（城市道路平均速度，考虑红绿灯和拥堵）
        case .skateboard: return 20.0   // 滑板：20 km/h（平均速度，范围 10-30 km/h）
        }
    }
    
    /// Speed in meters per second
    var speedMps: Double {
        speedKmh * 1000.0 / 3600.0
    }
    
    /// Localized display name
    var localizedName: String {
        switch self {
        case .walking: return L("transport.walking")
        case .cycling: return L("transport.cycling")
        case .driving: return L("transport.driving")
        case .skateboard: return L("transport.skateboard")
        }
    }
    
    /// Icon name for SF Symbols
    var iconName: String {
        switch self {
        case .walking: return "figure.walk"
        case .cycling: return "bicycle"
        case .driving: return "car.fill"
        case .skateboard: return "figure.skateboarding"
        }
    }
    
    /// Suggested focus durations in minutes
    var suggestedDurations: [Int] {
        switch self {
        case .walking: return [25, 45, 90]
        case .cycling: return [25, 45, 90]
        case .driving: return [25, 45, 90]
        case .skateboard: return [25, 45, 90]
        }
    }
}
