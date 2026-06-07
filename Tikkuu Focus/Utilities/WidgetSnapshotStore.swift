//
//  WidgetSnapshotStore.swift
//  Tikkuu Focus
//

import Foundation
import SwiftData
import WidgetKit

enum WidgetShared {
    static let appGroupIdentifier = "group.com.liuwanzhu.Tikkuu-Focus"
    static let snapshotFileName = "widget-snapshot.json"

    static let hasCompletedOnboardingKey = "widget.hasCompletedOnboarding"
    static let preferredTransportModeKey = "widget.preferredTransportMode"
    static let preferredDurationKey = "widget.preferredDuration"
    static let pendingQuickStartTransportKey = "widget.pendingQuickStartTransportMode"
    static let pendingQuickStartDurationKey = "widget.pendingQuickStartDuration"
    static let pendingQuickStartTriggeredAtKey = "widget.pendingQuickStartTriggeredAt"
}

struct LastJourneySummary: Codable {
    let transportModeRawValue: String
    let startLocationName: String
    let destinationName: String
    let duration: TimeInterval
    let distance: Double
    let discoveredPOICount: Int
    let completedAt: Date
    let isCompleted: Bool
}

struct WidgetSnapshot: Codable {
    let hasCompletedOnboarding: Bool
    let preferredTransportModeRawValue: String
    let preferredDuration: Int
    let weeklyFocusDuration: TimeInterval
    let weeklyCompletedCount: Int
    let currentStreakDays: Int
    let dailyActivityCounts: [String: Int]
    let lastJourneySummary: LastJourneySummary?
    let lastUpdatedAt: Date

    static let empty = WidgetSnapshot(
        hasCompletedOnboarding: false,
        preferredTransportModeRawValue: TransportMode.cycling.rawValue,
        preferredDuration: 25,
        weeklyFocusDuration: 0,
        weeklyCompletedCount: 0,
        currentStreakDays: 0,
        dailyActivityCounts: [:],
        lastJourneySummary: nil,
        lastUpdatedAt: .distantPast
    )
}

struct PendingQuickStartRequest {
    let transportModeRawValue: String
    let duration: Int
}

@MainActor
final class WidgetSnapshotStore {
    static let shared = WidgetSnapshotStore()

    private init() {}

    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: WidgetShared.appGroupIdentifier)
    }

    private var snapshotURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: WidgetShared.appGroupIdentifier)?
            .appendingPathComponent(WidgetShared.snapshotFileName)
    }

    func syncPreferenceMirror(
        hasCompletedOnboarding: Bool,
        preferredTransportModeRawValue: String,
        preferredDuration: Int
    ) {
        guard let sharedDefaults else { return }

        sharedDefaults.set(hasCompletedOnboarding, forKey: WidgetShared.hasCompletedOnboardingKey)
        sharedDefaults.set(preferredTransportModeRawValue, forKey: WidgetShared.preferredTransportModeKey)
        sharedDefaults.set(preferredDuration, forKey: WidgetShared.preferredDurationKey)

        let currentSnapshot = readSnapshot() ?? .empty
        let updatedSnapshot = WidgetSnapshot(
            hasCompletedOnboarding: hasCompletedOnboarding,
            preferredTransportModeRawValue: preferredTransportModeRawValue,
            preferredDuration: preferredDuration,
            weeklyFocusDuration: currentSnapshot.weeklyFocusDuration,
            weeklyCompletedCount: currentSnapshot.weeklyCompletedCount,
            currentStreakDays: currentSnapshot.currentStreakDays,
            dailyActivityCounts: currentSnapshot.dailyActivityCounts,
            lastJourneySummary: currentSnapshot.lastJourneySummary,
            lastUpdatedAt: Date()
        )

        guard let snapshotURL,
              let data = try? JSONEncoder().encode(updatedSnapshot) else {
            return
        }

        try? data.write(to: snapshotURL, options: .atomic)
        WidgetCenter.shared.reloadAllTimelines()
    }

    func readSnapshot() -> WidgetSnapshot? {
        guard let snapshotURL,
              let data = try? Data(contentsOf: snapshotURL) else {
            return nil
        }

        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }

    func refreshSnapshot(using modelContext: ModelContext, settings: AppSettings) {
        let descriptor = FetchDescriptor<JourneyRecord>(
            sortBy: [SortDescriptor(\JourneyRecord.startTime, order: .reverse)]
        )
        let records = (try? modelContext.fetch(descriptor)) ?? []
        let snapshot = Self.makeSnapshot(from: records, settings: settings)

        write(snapshot)
        WidgetCenter.shared.reloadAllTimelines()
    }

    func refreshSnapshot(records: [JourneyRecord], settings: AppSettings) {
        let snapshot = Self.makeSnapshot(from: records, settings: settings)
        write(snapshot)
        WidgetCenter.shared.reloadAllTimelines()
    }

    func consumePendingQuickStartRequest() -> PendingQuickStartRequest? {
        guard let sharedDefaults,
              let transportModeRawValue = sharedDefaults.string(forKey: WidgetShared.pendingQuickStartTransportKey) else {
            return nil
        }

        let duration = sharedDefaults.integer(forKey: WidgetShared.pendingQuickStartDurationKey)

        sharedDefaults.removeObject(forKey: WidgetShared.pendingQuickStartTransportKey)
        sharedDefaults.removeObject(forKey: WidgetShared.pendingQuickStartDurationKey)
        sharedDefaults.removeObject(forKey: WidgetShared.pendingQuickStartTriggeredAtKey)

        return PendingQuickStartRequest(
            transportModeRawValue: transportModeRawValue,
            duration: max(duration, 5)
        )
    }

    private func write(_ snapshot: WidgetSnapshot) {
        syncPreferenceMirror(
            hasCompletedOnboarding: snapshot.hasCompletedOnboarding,
            preferredTransportModeRawValue: snapshot.preferredTransportModeRawValue,
            preferredDuration: snapshot.preferredDuration
        )

        guard let snapshotURL,
              let data = try? JSONEncoder().encode(snapshot) else {
            return
        }

        try? data.write(to: snapshotURL, options: .atomic)
    }

    static func makeSnapshot(from records: [JourneyRecord], settings: AppSettings) -> WidgetSnapshot {
        let calendar = Calendar.autoupdatingCurrent
        let now = Date()
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        let weekRecords = records.filter { $0.startTime >= startOfWeek }
        let weeklyFocusDuration = weekRecords.reduce(0) { $0 + $1.duration }
        let weeklyCompletedCount = weekRecords.filter(\.isCompleted).count
        let lastRecord = records.first

        let lastJourneySummary = lastRecord.map {
            LastJourneySummary(
                transportModeRawValue: $0.transportMode,
                startLocationName: $0.startLocationName,
                destinationName: $0.destinationName,
                duration: $0.duration,
                distance: $0.distanceTraveled,
                discoveredPOICount: $0.discoveredPOICount,
                completedAt: $0.endTime ?? $0.startTime,
                isCompleted: $0.isCompleted
            )
        }

        let dailyActivityCounts = recentDailyActivityCounts(from: records, calendar: calendar)

        return WidgetSnapshot(
            hasCompletedOnboarding: settings.hasCompletedOnboarding,
            preferredTransportModeRawValue: settings.preferredTransportMode.rawValue,
            preferredDuration: settings.preferredDuration,
            weeklyFocusDuration: weeklyFocusDuration,
            weeklyCompletedCount: weeklyCompletedCount,
            currentStreakDays: currentStreakDays(from: records, calendar: calendar),
            dailyActivityCounts: dailyActivityCounts,
            lastJourneySummary: lastJourneySummary,
            lastUpdatedAt: now
        )
    }

    private static func currentStreakDays(from records: [JourneyRecord], calendar: Calendar) -> Int {
        let distinctDays = Array(
            Set(
                records
                    .filter(\.isCompleted)
                    .map { calendar.startOfDay(for: $0.startTime) }
            )
        ).sorted(by: >)

        guard let latestDay = distinctDays.first else { return 0 }

        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today

        guard latestDay == today || latestDay == yesterday else {
            return 0
        }

        var streak = 0
        var expectedDay = latestDay

        for day in distinctDays {
            if day == expectedDay {
                streak += 1
                expectedDay = calendar.date(byAdding: .day, value: -1, to: expectedDay) ?? expectedDay
            } else if day < expectedDay {
                break
            }
        }

        return streak
    }

    private static func recentDailyActivityCounts(from records: [JourneyRecord], calendar: Calendar) -> [String: Int] {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"

        let today = calendar.startOfDay(for: Date())
        let earliest = calendar.date(byAdding: .day, value: -83, to: today) ?? today

        var counts: [String: Int] = [:]
        for record in records where record.startTime >= earliest {
            let day = calendar.startOfDay(for: record.startTime)
            let key = formatter.string(from: day)
            counts[key, default: 0] += 1
        }

        return counts
    }
}
