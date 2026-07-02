//
//  Trophy.swift
//  Tikkuu Focus
//
//  Created by Tikkuu on 2026/2/8.
//

import SwiftUI
import Combine

struct Trophy: Identifiable, Equatable, Codable {
    let id: String
    let category: TrophyCategory
    let tier: TrophyTier
    let requirement: Int
    var isUnlocked: Bool = false
    var progress: Int = 0
    var unlockedDate: Date?

    var localizedTitle: String { L("trophy.\(id).title") }
    var localizedDescription: String { L("trophy.\(id).description") }
    var icon: String { isUnlocked ? category.unlockedIcon : "lock.fill" }
    var color: Color { tier.color }
    var progressPercentage: Double { min(Double(progress) / Double(max(requirement, 1)), 1.0) }
}

enum TrophyCategory: String, CaseIterable, Codable {
    case journey
    case time
    case distance
    case poi
    case streak
    case route

    var icon: String {
        switch self {
        case .journey: return "flag.checkered"
        case .time: return "clock.fill"
        case .distance: return "location.fill"
        case .poi: return "star.fill"
        case .streak: return "flame.fill"
        case .route: return "map.fill"
        }
    }

    var unlockedIcon: String {
        switch self {
        case .journey: return "flag.checkered.2.crossed"
        case .time: return "hourglass"
        case .distance: return "figure.walk.motion"
        case .poi: return "star.circle.fill"
        case .streak: return "flame.fill"
        case .route: return "point.topleft.down.curvedto.point.bottomright.up"
        }
    }

    var localizedName: String { L("trophy.category.\(rawValue)") }
}

enum TrophyTier: String, CaseIterable, Codable {
    case bronze
    case silver
    case gold
    case platinum

    var color: Color {
        switch self {
        case .bronze: return Color(red: 0.8, green: 0.5, blue: 0.2)
        case .silver: return Color(red: 0.75, green: 0.75, blue: 0.75)
        case .gold: return Color(red: 1.0, green: 0.84, blue: 0.0)
        case .platinum: return Color(red: 0.65, green: 0.85, blue: 1.0)
        }
    }

    var icon: String {
        switch self {
        case .bronze, .silver, .gold: return "medal.fill"
        case .platinum: return "crown.fill"
        }
    }

    var localizedName: String { L("trophy.tier.\(rawValue)") }

    var sortOrder: Int {
        switch self {
        case .bronze: return 0
        case .silver: return 1
        case .gold: return 2
        case .platinum: return 3
        }
    }
}

struct TrophyUnlockMessage: Identifiable, Codable, Equatable {
    let id: String
    let trophyID: String
    let title: String
    let detail: String
    let unlockedAt: Date
}

@MainActor
final class TrophyInboxStore: ObservableObject {
    static let shared = TrophyInboxStore()

    private let messagesKey = "trophy.inbox.messages"
    private let unreadKey = "trophy.inbox.unreadCount"
    @Published private(set) var messages: [TrophyUnlockMessage]
    @Published private(set) var unreadCount: Int

    private init() {
        if let data = UserDefaults.standard.data(forKey: messagesKey),
           let decoded = try? JSONDecoder().decode([TrophyUnlockMessage].self, from: data) {
            messages = decoded
        } else {
            messages = []
        }
        unreadCount = UserDefaults.standard.integer(forKey: unreadKey)
    }

    func add(_ trophy: Trophy) {
        let message = TrophyUnlockMessage(
            id: UUID().uuidString,
            trophyID: trophy.id,
            title: trophy.localizedTitle,
            detail: trophy.localizedDescription,
            unlockedAt: trophy.unlockedDate ?? Date()
        )
        messages.insert(message, at: 0)
        messages = Array(messages.prefix(50))
        unreadCount += 1
        persist()
    }

    func markAllRead() {
        unreadCount = 0
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(messages) {
            UserDefaults.standard.set(data, forKey: messagesKey)
        }
        UserDefaults.standard.set(unreadCount, forKey: unreadKey)
    }
}

final class TrophyManager: ObservableObject {
    @Published var trophies: [Trophy] = []

    private let unlockedKey = "trophy.unlocked.v2"

    init() {
        setupTrophies()
    }

    private func setupTrophies() {
        trophies = [
            Trophy(id: "journey_1", category: .journey, tier: .bronze, requirement: 1),
            Trophy(id: "journey_5", category: .journey, tier: .bronze, requirement: 5),
            Trophy(id: "journey_10", category: .journey, tier: .silver, requirement: 10),
            Trophy(id: "journey_25", category: .journey, tier: .silver, requirement: 25),
            Trophy(id: "journey_50", category: .journey, tier: .gold, requirement: 50),
            Trophy(id: "journey_100", category: .journey, tier: .platinum, requirement: 100),
            Trophy(id: "time_30min", category: .time, tier: .bronze, requirement: 1800),
            Trophy(id: "time_1h", category: .time, tier: .bronze, requirement: 3600),
            Trophy(id: "time_5h", category: .time, tier: .silver, requirement: 18000),
            Trophy(id: "time_10h", category: .time, tier: .silver, requirement: 36000),
            Trophy(id: "time_25h", category: .time, tier: .gold, requirement: 90000),
            Trophy(id: "time_50h", category: .time, tier: .gold, requirement: 180000),
            Trophy(id: "time_100h", category: .time, tier: .platinum, requirement: 360000),
            Trophy(id: "distance_5km", category: .distance, tier: .bronze, requirement: 5000),
            Trophy(id: "distance_10km", category: .distance, tier: .bronze, requirement: 10000),
            Trophy(id: "distance_25km", category: .distance, tier: .silver, requirement: 25000),
            Trophy(id: "distance_100km", category: .distance, tier: .silver, requirement: 100000),
            Trophy(id: "distance_250km", category: .distance, tier: .gold, requirement: 250000),
            Trophy(id: "distance_500km", category: .distance, tier: .gold, requirement: 500000),
            Trophy(id: "distance_1000km", category: .distance, tier: .platinum, requirement: 1000000),
            Trophy(id: "poi_5", category: .poi, tier: .bronze, requirement: 5),
            Trophy(id: "poi_10", category: .poi, tier: .bronze, requirement: 10),
            Trophy(id: "poi_25", category: .poi, tier: .silver, requirement: 25),
            Trophy(id: "poi_50", category: .poi, tier: .silver, requirement: 50),
            Trophy(id: "poi_100", category: .poi, tier: .gold, requirement: 100),
            Trophy(id: "streak_2", category: .streak, tier: .bronze, requirement: 2),
            Trophy(id: "streak_3", category: .streak, tier: .bronze, requirement: 3),
            Trophy(id: "streak_7", category: .streak, tier: .silver, requirement: 7),
            Trophy(id: "streak_14", category: .streak, tier: .gold, requirement: 14),
            Trophy(id: "streak_30", category: .streak, tier: .platinum, requirement: 30),
            Trophy(id: "route_first", category: .route, tier: .bronze, requirement: 1),
            Trophy(id: "route_5", category: .route, tier: .silver, requirement: 5),
            Trophy(id: "route_half", category: .route, tier: .silver, requirement: 50),
            Trophy(id: "route_90", category: .route, tier: .gold, requirement: 90),
            Trophy(id: "route_complete", category: .route, tier: .platinum, requirement: 100)
        ]
    }

    @discardableResult
    func updateProgress(with records: [JourneyRecord], notifyNewUnlocks: Bool = false) -> [Trophy] {
        let previousUnlocked = storedUnlockedIDs()
        let totalJourneys = records.count
        let totalTime = Int(records.reduce(0.0) { $0 + $1.duration })
        let totalDistance = Int(records.reduce(0.0) { $0 + $1.distanceTraveled })
        let totalPOIs = records.reduce(0) { $0 + $1.discoveredPOICount }
        let streak = calculateStreak(from: records)
        let routeJourneys = records.filter { $0.hasScenicRoute }.count
        let bestRouteProgress = Int((records.map { $0.scenicRouteProgress }.max() ?? 0) * 100)

        var newlyUnlocked: [Trophy] = []

        for index in trophies.indices {
            let id = trophies[index].id
            switch id {
            case let value where value.hasPrefix("journey_"):
                trophies[index].progress = totalJourneys
            case let value where value.hasPrefix("time_"):
                trophies[index].progress = totalTime
            case let value where value.hasPrefix("distance_"):
                trophies[index].progress = totalDistance
            case let value where value.hasPrefix("poi_"):
                trophies[index].progress = totalPOIs
            case let value where value.hasPrefix("streak_"):
                trophies[index].progress = streak
            case "route_first":
                trophies[index].progress = routeJourneys
            case "route_5":
                trophies[index].progress = routeJourneys
            case "route_half", "route_complete":
                trophies[index].progress = bestRouteProgress
            case "route_90":
                trophies[index].progress = bestRouteProgress
            default:
                trophies[index].progress = 0
            }

            if previousUnlocked.contains(id) || trophies[index].progress >= trophies[index].requirement {
                let wasUnlocked = previousUnlocked.contains(id)
                trophies[index].isUnlocked = true
                trophies[index].unlockedDate = storedUnlockDate(for: id) ?? Date()
                if !wasUnlocked {
                    trophies[index].unlockedDate = Date()
                    newlyUnlocked.append(trophies[index])
                }
            }
        }

        if !newlyUnlocked.isEmpty {
            persistUnlocked(trophies.filter(\.isUnlocked))
            if notifyNewUnlocks {
                Task { @MainActor in
                    for trophy in newlyUnlocked {
                        TrophyInboxStore.shared.add(trophy)
                        NotificationManager.shared.notifyTrophyUnlocked(trophy: trophy)
                    }
                }
            }
        }

        return newlyUnlocked
    }

    private func storedUnlockedIDs() -> Set<String> {
        guard let data = UserDefaults.standard.data(forKey: unlockedKey),
              let unlocked = try? JSONDecoder().decode([String: Date].self, from: data) else {
            return []
        }
        return Set(unlocked.keys)
    }

    private func storedUnlockDate(for id: String) -> Date? {
        guard let data = UserDefaults.standard.data(forKey: unlockedKey),
              let unlocked = try? JSONDecoder().decode([String: Date].self, from: data) else {
            return nil
        }
        return unlocked[id]
    }

    private func persistUnlocked(_ unlockedTrophies: [Trophy]) {
        var stored: [String: Date] = [:]
        if let data = UserDefaults.standard.data(forKey: unlockedKey),
           let decoded = try? JSONDecoder().decode([String: Date].self, from: data) {
            stored = decoded
        }
        for trophy in unlockedTrophies where trophy.isUnlocked {
            stored[trophy.id] = trophy.unlockedDate ?? Date()
        }
        if let data = try? JSONEncoder().encode(stored) {
            UserDefaults.standard.set(data, forKey: unlockedKey)
        }
    }

    private func calculateStreak(from records: [JourneyRecord]) -> Int {
        guard !records.isEmpty else { return 0 }
        let calendar = Calendar.current
        let days = Set(records.map { calendar.startOfDay(for: $0.startTime) })
        var streak = 0
        var current = calendar.startOfDay(for: Date())
        while days.contains(current) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: current) else { break }
            current = previous
        }
        return streak
    }

    var unlockedCount: Int { trophies.filter(\.isUnlocked).count }
    var totalCount: Int { trophies.count }
    var unlockedPercentage: Double {
        guard totalCount > 0 else { return 0 }
        return Double(unlockedCount) / Double(totalCount)
    }
}
