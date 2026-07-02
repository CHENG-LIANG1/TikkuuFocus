//
//  ScenicRoute.swift
//  Tikkuu Focus
//
//  Created by Codex on 2026/6/27.
//

import Foundation
import CoreLocation
import Combine

struct ScenicRoute: Identifiable, Equatable {
    let id: String
    let name: String
    let nameZh: String
    let subtitle: String
    let subtitleZh: String
    let emoji: String
    let coordinates: [CLLocationCoordinate2D]

    var localizedName: String {
        AppSettings.shared.currentLanguage.hasPrefix("zh") ? nameZh : name
    }

    var localizedSubtitle: String {
        AppSettings.shared.currentLanguage.hasPrefix("zh") ? subtitleZh : subtitle
    }

    var totalDistance: Double {
        Self.distance(of: coordinates)
    }

    var savedProgress: Double {
        ScenicRouteProgressStore.shared.progress(for: id)
    }

    var startCoordinateForNextSession: CLLocationCoordinate2D {
        coordinate(atProgress: savedProgress)
    }

    var displayProgressText: String {
        "\(Int(savedProgress * 100))%"
    }

    func coordinate(atProgress progress: Double) -> CLLocationCoordinate2D {
        let safeProgress = min(max(progress, 0), 1)
        guard coordinates.count >= 2 else { return coordinates.first ?? .init(latitude: 0, longitude: 0) }
        guard safeProgress > 0 else { return coordinates[0] }
        guard safeProgress < 1 else { return coordinates[coordinates.count - 1] }

        let target = totalDistance * safeProgress
        var traveled: Double = 0

        for index in 1..<coordinates.count {
            let start = coordinates[index - 1]
            let end = coordinates[index]
            let segment = start.distance(to: end)
            if traveled + segment >= target {
                let fraction = segment > 0 ? (target - traveled) / segment : 0
                return start.interpolate(to: end, fraction: fraction)
            }
            traveled += segment
        }

        return coordinates[coordinates.count - 1]
    }

    func segment(fromProgress progress: Double, distance requestedDistance: Double) -> ScenicRouteSegment {
        let routeDistance = totalDistance
        let startProgress = min(max(progress, 0), 1)
        let remainingDistance = max(routeDistance * (1 - startProgress), 0)
        let segmentDistance = min(max(requestedDistance, 1), remainingDistance)
        let endProgress = routeDistance > 0
            ? min(startProgress + segmentDistance / routeDistance, 1)
            : 1
        let start = coordinate(atProgress: startProgress)
        let end = coordinate(atProgress: endProgress)
        let path = routeSlice(from: startProgress, to: endProgress, start: start, end: end)

        return ScenicRouteSegment(
            startProgress: startProgress,
            endProgress: endProgress,
            start: start,
            end: end,
            coordinates: path,
            distance: max(Self.distance(of: path), start.distance(to: end))
        )
    }

    private func routeSlice(
        from startProgress: Double,
        to endProgress: Double,
        start: CLLocationCoordinate2D,
        end: CLLocationCoordinate2D
    ) -> [CLLocationCoordinate2D] {
        guard coordinates.count >= 2 else { return [start, end] }
        let routeDistance = totalDistance
        let startDistance = routeDistance * startProgress
        let endDistance = routeDistance * endProgress
        var traveled: Double = 0
        var result: [CLLocationCoordinate2D] = [start]

        for index in 1..<coordinates.count {
            let previous = coordinates[index - 1]
            let current = coordinates[index]
            let segment = previous.distance(to: current)
            let segmentStart = traveled
            let segmentEnd = traveled + segment

            if segmentEnd > startDistance, segmentStart < endDistance {
                if current.distance(to: result.last ?? current) > 1 {
                    result.append(current)
                }
            }
            traveled = segmentEnd
        }

        if end.distance(to: result.last ?? end) > 1 {
            result.append(end)
        }
        return result.count >= 2 ? result : [start, end]
    }

    static func distance(of coordinates: [CLLocationCoordinate2D]) -> Double {
        guard coordinates.count > 1 else { return 0 }
        var total: Double = 0
        for index in 1..<coordinates.count {
            total += coordinates[index - 1].distance(to: coordinates[index])
        }
        return total
    }
}

struct ScenicRouteSegment: Equatable {
    let startProgress: Double
    let endProgress: Double
    let start: CLLocationCoordinate2D
    let end: CLLocationCoordinate2D
    let coordinates: [CLLocationCoordinate2D]
    let distance: Double
}

final class ScenicRouteProgressStore: ObservableObject {
    static let shared = ScenicRouteProgressStore()

    private let key = "scenicRoute.progressByID"
    @Published private(set) var progressByID: [String: Double]

    private init() {
        progressByID = UserDefaults.standard.dictionary(forKey: key) as? [String: Double] ?? [:]
    }

    func progress(for routeID: String) -> Double {
        min(max(progressByID[routeID] ?? 0, 0), 1)
    }

    func update(routeID: String, progress: Double) {
        let value = min(max(progress, 0), 1)
        guard value >= self.progress(for: routeID) else { return }
        progressByID[routeID] = value
        UserDefaults.standard.set(progressByID, forKey: key)
    }

    func reset(routeID: String) {
        progressByID[routeID] = 0
        UserDefaults.standard.set(progressByID, forKey: key)
    }
}

extension ScenicRoute {
    static let all: [ScenicRoute] = [
        ScenicRoute(
            id: "g318-sichuan-tibet",
            name: "G318 Sichuan-Tibet Line",
            nameZh: "318 川藏线",
            subtitle: "Chengdu to Lhasa classic plateau route",
            subtitleZh: "成都到拉萨的经典高原路线",
            emoji: "🏔️",
            coordinates: [
                .init(latitude: 30.6595, longitude: 104.0657), // Chengdu
                .init(latitude: 29.9877, longitude: 103.0010), // Ya'an
                .init(latitude: 30.0495, longitude: 101.9600), // Kangding
                .init(latitude: 30.0047, longitude: 100.2697), // Litang
                .init(latitude: 30.0053, longitude: 99.1090),  // Batang
                .init(latitude: 29.6863, longitude: 98.5937),  // Markam
                .init(latitude: 29.8580, longitude: 95.7681),  // Bomi
                .init(latitude: 29.6547, longitude: 94.3615),  // Nyingchi
                .init(latitude: 29.6520, longitude: 91.1721)   // Lhasa
            ]
        ),
        ScenicRoute(
            id: "hainan-ring-road",
            name: "Hainan Island Ring",
            nameZh: "海南环岛路线",
            subtitle: "Coastal loop across Haikou, Sanya and Wanning",
            subtitleZh: "海口、三亚、万宁海岸环线",
            emoji: "🏝️",
            coordinates: [
                .init(latitude: 20.0442, longitude: 110.1999), // Haikou
                .init(latitude: 19.6129, longitude: 110.7535), // Wenchang
                .init(latitude: 19.2460, longitude: 110.4642), // Qionghai
                .init(latitude: 18.7937, longitude: 110.3888), // Wanning
                .init(latitude: 18.5055, longitude: 110.0372), // Lingshui
                .init(latitude: 18.2528, longitude: 109.5119), // Sanya
                .init(latitude: 19.0953, longitude: 108.6538), // Dongfang
                .init(latitude: 19.5209, longitude: 109.5807), // Danzhou
                .init(latitude: 20.0442, longitude: 110.1999)  // Haikou
            ]
        ),
        ScenicRoute(
            id: "dushanzi-kuqa-highway",
            name: "Duku Highway",
            nameZh: "独库公路",
            subtitle: "Tianshan mountain pass from Dushanzi to Kuqa",
            subtitleZh: "穿越天山的独山子到库车路线",
            emoji: "🛣️",
            coordinates: [
                .init(latitude: 44.3330, longitude: 84.8864), // Dushanzi
                .init(latitude: 43.8132, longitude: 84.6682), // Qolma area
                .init(latitude: 43.4430, longitude: 84.2617), // Nalati
                .init(latitude: 42.9576, longitude: 84.1296), // Bayinbuluke
                .init(latitude: 42.2404, longitude: 83.7813), // Big Dragon Pool area
                .init(latitude: 41.7179, longitude: 82.9620)  // Kuqa
            ]
        ),
        ScenicRoute(
            id: "california-pacific-coast",
            name: "Pacific Coast Highway",
            nameZh: "加州一号公路",
            subtitle: "San Francisco to Los Angeles coastline",
            subtitleZh: "旧金山到洛杉矶海岸线",
            emoji: "🌊",
            coordinates: [
                .init(latitude: 37.7749, longitude: -122.4194), // San Francisco
                .init(latitude: 36.9741, longitude: -122.0308), // Santa Cruz
                .init(latitude: 36.6002, longitude: -121.8947), // Monterey
                .init(latitude: 35.8848, longitude: -121.4550), // Big Sur
                .init(latitude: 35.2828, longitude: -120.6596), // San Luis Obispo
                .init(latitude: 34.4208, longitude: -119.6982), // Santa Barbara
                .init(latitude: 34.0522, longitude: -118.2437)  // Los Angeles
            ]
        ),
        ScenicRoute(
            id: "route-66",
            name: "Route 66",
            nameZh: "美国 66 号公路",
            subtitle: "Chicago to Santa Monica, the mother road",
            subtitleZh: "芝加哥到圣莫尼卡的母亲之路",
            emoji: "🛣️",
            coordinates: [
                .init(latitude: 41.8781, longitude: -87.6298),   // Chicago
                .init(latitude: 39.7817, longitude: -89.6501),   // Springfield, IL
                .init(latitude: 38.6270, longitude: -90.1994),   // St. Louis
                .init(latitude: 37.2090, longitude: -93.2923),   // Springfield, MO
                .init(latitude: 36.1540, longitude: -95.9928),   // Tulsa
                .init(latitude: 35.4676, longitude: -97.5164),   // Oklahoma City
                .init(latitude: 35.2220, longitude: -101.8313),  // Amarillo
                .init(latitude: 35.6870, longitude: -105.9378),  // Santa Fe
                .init(latitude: 35.0844, longitude: -106.6504),  // Albuquerque
                .init(latitude: 35.1983, longitude: -111.6513),  // Flagstaff
                .init(latitude: 34.4839, longitude: -114.3225),  // Lake Havasu City
                .init(latitude: 34.0195, longitude: -118.4912)   // Santa Monica
            ]
        )
    ]

    static func route(id: String) -> ScenicRoute? {
        all.first { $0.id == id }
    }
}
