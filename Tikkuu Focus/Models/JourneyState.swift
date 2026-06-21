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

    var isPaused: Bool {
        if case .paused = self { return true }
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
    let startLocationName: String
    let destinationName: String

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
        startTime: Date,
        startLocationName: String = "",
        destinationName: String = ""
    ) {
        self.id = id
        self.startLocation = startLocation
        self.destinationLocation = destinationLocation
        self.route = JourneySession.normalizedRoute(
            route,
            startLocation: startLocation,
            destinationLocation: destinationLocation
        )
        self.totalDistance = totalDistance
        self.duration = duration
        self.transportMode = transportMode
        self.startTime = startTime
        self.startLocationName = startLocationName
        self.destinationName = destinationName

        let cumulative = JourneySession.buildCumulativeRouteDistances(self.route)
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

    /// Returns the coordinate on the route for a given progress value.
    func coordinate(atProgress progress: Double) -> CLLocationCoordinate2D {
        interpolatePosition(progress: min(max(progress, 0), 1.0))
    }

    /// Returns the traveled portion of the route through the given progress value.
    func route(upToProgress progress: Double) -> [CLLocationCoordinate2D] {
        let safeProgress = min(max(progress, 0), 1.0)
        let source = route.isEmpty ? [startLocation, destinationLocation] : route

        guard source.count >= 2 else {
            return source.isEmpty ? [startLocation] : source
        }

        guard safeProgress > 0 else {
            return [source[0]]
        }

        guard safeProgress < 1 else {
            return source
        }

        guard cumulativeRouteDistances.count >= 2, routeDistanceForInterpolation > 0 else {
            let endCoordinate = coordinate(atProgress: safeProgress)
            return JourneySession.appendingCoordinateIfNeeded(to: [source[0]], coordinate: endCoordinate)
        }

        let targetDistance = routeDistanceForInterpolation * safeProgress
        let index = segmentIndex(for: targetDistance)
        let endCoordinate = coordinate(atProgress: safeProgress)
        let prefix = Array(source.prefix(index))

        return JourneySession.appendingCoordinateIfNeeded(to: prefix, coordinate: endCoordinate)
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

    private static func normalizedRoute(
        _ route: [CLLocationCoordinate2D],
        startLocation: CLLocationCoordinate2D,
        destinationLocation: CLLocationCoordinate2D
    ) -> [CLLocationCoordinate2D] {
        var normalized = route
        if normalized.isEmpty {
            normalized = [startLocation, destinationLocation]
        }

        if let first = normalized.first, first.distance(to: startLocation) > 1 {
            normalized.insert(startLocation, at: 0)
        }

        if let last = normalized.last, last.distance(to: destinationLocation) > 1 {
            normalized.append(destinationLocation)
        }

        return normalized
    }

    private static func appendingCoordinateIfNeeded(
        to route: [CLLocationCoordinate2D],
        coordinate: CLLocationCoordinate2D
    ) -> [CLLocationCoordinate2D] {
        guard let last = route.last else { return [coordinate] }
        guard last.distance(to: coordinate) > 0.5 else { return route }
        return route + [coordinate]
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

/// Mode-specific virtual metrics shown during and after a journey.
struct VirtualJourneyMetrics: Equatable {
    let transportMode: TransportMode
    let stepCount: Int?
    let calories: Int?
    let fuelLiters: Double?
    let fallCount: Int?

    init(
        distanceMeters: Double,
        duration: TimeInterval,
        transportMode: TransportMode,
        sessionID: UUID
    ) {
        let safeDistance = max(distanceMeters, 0)
        let safeDuration = max(duration, 0)
        let distanceKm = safeDistance / 1000.0
        let durationHours = safeDuration / 3600.0

        self.transportMode = transportMode

        switch transportMode {
        case .walking:
            stepCount = Int((safeDistance * 1.3 * Self.multiplier(sessionID: sessionID, salt: 11)).rounded())
            calories = Int((durationHours * 200 * Self.multiplier(sessionID: sessionID, salt: 12)).rounded())
            fuelLiters = nil
            fallCount = nil
        case .cycling:
            stepCount = nil
            calories = Int((durationHours * 400 * Self.multiplier(sessionID: sessionID, salt: 21)).rounded())
            fuelLiters = nil
            fallCount = nil
        case .driving:
            stepCount = nil
            calories = nil
            fuelLiters = distanceKm * 8.0 / 100.0 * Self.multiplier(sessionID: sessionID, salt: 31)
            fallCount = nil
        case .skateboard:
            stepCount = nil
            calories = Int((durationHours * 300 * Self.multiplier(sessionID: sessionID, salt: 41)).rounded())
            fuelLiters = nil
            let baseFalls = Int(floor(distanceKm / 5.0))
            let randomBonus = safeDistance > 100 ? min(Int(Self.unitRandom(sessionID: sessionID, salt: 42) * 2.0), 1) : 0
            fallCount = max(baseFalls + randomBonus, 0)
        }
    }

    var cardItems: [VirtualJourneyMetricCardItem] {
        var items: [VirtualJourneyMetricCardItem] = []

        switch transportMode {
        case .walking:
            if let formattedStepsValue {
                items.append(VirtualJourneyMetricCardItem(
                    id: "steps",
                    icon: "shoeprints.fill",
                    title: L("virtual.metrics.title.steps"),
                    value: formattedStepsValue
                ))
            }
            if let formattedCaloriesValue {
                items.append(VirtualJourneyMetricCardItem(
                    id: "calories",
                    icon: "flame.fill",
                    title: L("virtual.metrics.title.calories"),
                    value: formattedCaloriesValue
                ))
            }
        case .cycling:
            if let formattedCaloriesValue {
                items.append(VirtualJourneyMetricCardItem(
                    id: "calories",
                    icon: "flame.fill",
                    title: L("virtual.metrics.title.calories"),
                    value: formattedCaloriesValue
                ))
            }
        case .driving:
            if let formattedFuelLitersValue {
                items.append(VirtualJourneyMetricCardItem(
                    id: "fuelLiters",
                    icon: "fuelpump.fill",
                    title: L("virtual.metrics.title.fuelLiters"),
                    value: formattedFuelLitersValue
                ))
            }
            items.append(VirtualJourneyMetricCardItem(
                id: "fuelPrice",
                icon: "dollarsign.circle.fill",
                title: L("virtual.metrics.title.fuelPrice"),
                value: formattedFuelPriceValue
            ))
        case .skateboard:
            if let formattedCaloriesValue {
                items.append(VirtualJourneyMetricCardItem(
                    id: "calories",
                    icon: "flame.fill",
                    title: L("virtual.metrics.title.calories"),
                    value: formattedCaloriesValue
                ))
            }
            if let formattedFallCountValue {
                items.append(VirtualJourneyMetricCardItem(
                    id: "fallCount",
                    icon: "figure.fall",
                    title: L("virtual.metrics.title.fallCount"),
                    value: formattedFallCountValue
                ))
            }
        }

        return items
    }

    private var formattedStepsValue: String? {
        guard let stepCount else { return nil }
        return String(format: L("virtual.metrics.steps"), FormatUtilities.formatNumber(stepCount))
    }

    private var formattedCaloriesValue: String? {
        guard let calories else { return nil }
        return String(format: L("virtual.metrics.calories"), FormatUtilities.formatNumber(calories))
    }

    private var formattedFuelLitersValue: String? {
        guard let fuelLiters else { return nil }
        return String(format: L("virtual.metrics.fuelLiters"), fuelLiters)
    }

    private var formattedFuelPriceValue: String {
        String(format: L("virtual.metrics.fuelPrice"), Self.localizedFuelPrice())
    }

    private var formattedFallCountValue: String? {
        guard let fallCount else { return nil }
        return String(format: L("virtual.metrics.fallCount"), FormatUtilities.formatNumber(fallCount))
    }

    private static func multiplier(sessionID: UUID, salt: UInt64) -> Double {
        0.92 + unitRandom(sessionID: sessionID, salt: salt) * 0.16
    }

    private static func localizedFuelPrice() -> String {
        let locale = Locale.autoupdatingCurrent
        let regionCode = locale.region?.identifier.uppercased()
        let currencyCode = locale.currency?.identifier.uppercased()
        let canUseLocaleCurrency = currencyCode != nil && currencySymbol(for: currencyCode) != nil
        let rate = canUseLocaleCurrency ? cnyExchangeRate(forCurrency: currencyCode, regionCode: regionCode) : 1.0
        let symbol = canUseLocaleCurrency ? (currencySymbol(for: currencyCode) ?? locale.currencySymbol ?? "¥") : "¥"
        let displayCurrencyCode = canUseLocaleCurrency ? currencyCode : "CNY"
        let convertedPrice = 7.8 * rate

        return "\(symbol)\(formattedFuelPriceValue(convertedPrice, currencyCode: displayCurrencyCode))"
    }

    private static func currencySymbol(for currencyCode: String?) -> String? {
        switch currencyCode {
        case "CNY", "JPY":
            return "¥"
        case "USD":
            return "$"
        case "CAD":
            return "CA$"
        case "AUD":
            return "A$"
        case "HKD":
            return "HK$"
        case "TWD":
            return "NT$"
        case "SGD":
            return "S$"
        case "EUR":
            return "€"
        case "GBP":
            return "£"
        case "KRW":
            return "₩"
        default:
            return nil
        }
    }

    private static func cnyExchangeRate(forCurrency currencyCode: String?, regionCode: String?) -> Double {
        switch currencyCode {
        case "CNY":
            return 1.0
        case "USD":
            return 0.14
        case "EUR":
            return 0.13
        case "GBP":
            return 0.11
        case "JPY":
            return 21.8
        case "KRW":
            return 190.0
        case "CAD":
            return 0.19
        case "AUD":
            return 0.21
        case "HKD":
            return 1.1
        case "TWD":
            return 4.5
        case "SGD":
            return 0.19
        default:
            return fallbackCNYExchangeRate(forRegion: regionCode)
        }
    }

    private static func fallbackCNYExchangeRate(forRegion regionCode: String?) -> Double {
        switch regionCode {
        case "US":
            return 0.14
        case "GB":
            return 0.11
        case "JP":
            return 21.8
        case "KR":
            return 190.0
        default:
            return 1.0
        }
    }

    private static func formattedFuelPriceValue(_ price: Double, currencyCode: String?) -> String {
        switch currencyCode {
        case "JPY", "KRW":
            return String(format: "%.0f", price)
        default:
            return String(format: "%.1f", price)
        }
    }

    private static func unitRandom(sessionID: UUID, salt: UInt64) -> Double {
        var hash: UInt64 = 14_695_981_039_346_656_037
        let prime: UInt64 = 1_099_511_628_211

        for byte in sessionID.uuidString.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* prime
        }

        hash ^= salt
        hash = hash &* prime

        return Double(hash % 10_000) / 9_999.0
    }
}

struct VirtualJourneyMetricCardItem: Identifiable, Equatable {
    let id: String
    let icon: String
    let title: String
    let value: String
}

/// Point of Interest discovered during the journey
struct DiscoveredPOI: Identifiable, Equatable {
    let id: UUID
    let name: String
    let category: String
    let coordinate: CLLocationCoordinate2D
    let discoveredAt: Date
    let rarity: POIRarity // New rarity field
    
    init(id: UUID = UUID(), name: String, category: String, coordinate: CLLocationCoordinate2D, discoveredAt: Date = Date(), rarity: POIRarity = .common) {
        self.id = id
        self.name = name
        self.category = category
        self.coordinate = coordinate
        self.discoveredAt = discoveredAt
        self.rarity = rarity
    }
    
    static func == (lhs: DiscoveredPOI, rhs: DiscoveredPOI) -> Bool {
        lhs.id == rhs.id
    }
}

/// Rarity level of a POI
enum POIRarity: String, Codable, CaseIterable {
    case common
    case rare
    case epic
    case legendary
    
    var color: String {
        switch self {
        case .common: return "gray"
        case .rare: return "blue"
        case .epic: return "purple"
        case .legendary: return "orange"
        }
    }
    
    var probability: Double {
        switch self {
        case .common: return 0.60
        case .rare: return 0.25
        case .epic: return 0.10
        case .legendary: return 0.05
        }
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
