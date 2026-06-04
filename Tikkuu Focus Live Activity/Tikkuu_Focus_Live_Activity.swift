//
//  Tikkuu_Focus_Live_Activity.swift
//  Tikkuu Focus Live Activity
//

import ActivityKit
import AppIntents
import Foundation
import SwiftUI
import WidgetKit

private enum WidgetSharedConfig {
    static let appGroupIdentifier = "group.com.liuwanzhu.Tikkuu-Focus"
    static let snapshotFileName = "widget-snapshot.json"

    static let hasCompletedOnboardingKey = "widget.hasCompletedOnboarding"
    static let preferredTransportModeKey = "widget.preferredTransportMode"
    static let preferredDurationKey = "widget.preferredDuration"
    static let pendingQuickStartTransportKey = "widget.pendingQuickStartTransportMode"
    static let pendingQuickStartDurationKey = "widget.pendingQuickStartDuration"
    static let pendingQuickStartTriggeredAtKey = "widget.pendingQuickStartTriggeredAt"
}

private struct HomeLastJourneySummary: Codable {
    let transportModeRawValue: String
    let startLocationName: String
    let destinationName: String
    let duration: TimeInterval
    let distance: Double
    let discoveredPOICount: Int
    let completedAt: Date
    let isCompleted: Bool
}

private struct HomeWidgetSnapshot: Codable {
    let hasCompletedOnboarding: Bool
    let preferredTransportModeRawValue: String
    let preferredDuration: Int
    let weeklyFocusDuration: TimeInterval
    let weeklyCompletedCount: Int
    let currentStreakDays: Int
    let dailyActivityCounts: [String: Int]
    let lastJourneySummary: HomeLastJourneySummary?
    let lastUpdatedAt: Date

    static let placeholder = HomeWidgetSnapshot(
        hasCompletedOnboarding: true,
        preferredTransportModeRawValue: "cycling",
        preferredDuration: 25,
        weeklyFocusDuration: 3 * 3600 + 25 * 60,
        weeklyCompletedCount: 6,
        currentStreakDays: 4,
        dailyActivityCounts: [:],
        lastJourneySummary: HomeLastJourneySummary(
            transportModeRawValue: "cycling",
            startLocationName: "Shanghai",
            destinationName: "Jing'an Park",
            duration: 25 * 60,
            distance: 8200,
            discoveredPOICount: 5,
            completedAt: Date(),
            isCompleted: true
        ),
        lastUpdatedAt: Date()
    )
}

private struct HomeWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: HomeWidgetSnapshot
}

private struct QuickStartWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: HomeWidgetSnapshot
    let configuration: QuickStartWidgetConfigurationIntent
}

enum QuickStartTransportOption: String, AppEnum {
    case walking
    case cycling
    case driving
    case skateboard

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Transport"
    static var caseDisplayRepresentations: [QuickStartTransportOption: DisplayRepresentation] = [
        .walking: "Walking",
        .cycling: "Cycling",
        .driving: "Driving",
        .skateboard: "Skateboard"
    ]
}

enum QuickStartDurationOption: Int, AppEnum {
    case fifteen = 15
    case twentyFive = 25
    case fortyFive = 45
    case sixty = 60
    case ninety = 90

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Focus Time"
    static var caseDisplayRepresentations: [QuickStartDurationOption: DisplayRepresentation] = [
        .fifteen: "15 min",
        .twentyFive: "25 min",
        .fortyFive: "45 min",
        .sixty: "60 min",
        .ninety: "90 min"
    ]
}

struct QuickStartWidgetConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Quick Start Settings"
    static var description = IntentDescription("Choose the transport mode and focus time for this widget.")

    @Parameter(title: "Transport")
    var transport: QuickStartTransportOption?

    @Parameter(title: "Focus Time")
    var duration: QuickStartDurationOption?

    init() {
        transport = .cycling
        duration = .twentyFive
    }

    static var parameterSummary: some ParameterSummary {
        Summary("Start \(\.$transport) for \(\.$duration)")
    }
}

private struct SharedSnapshotReader {
    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: WidgetSharedConfig.appGroupIdentifier)
    }

    private var snapshotURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: WidgetSharedConfig.appGroupIdentifier)?
            .appendingPathComponent(WidgetSharedConfig.snapshotFileName)
    }

    func readSnapshot() -> HomeWidgetSnapshot {
        if let snapshotURL,
           let data = try? Data(contentsOf: snapshotURL),
           let snapshot = try? JSONDecoder().decode(HomeWidgetSnapshot.self, from: data) {
            return snapshot
        }

        return HomeWidgetSnapshot(
            hasCompletedOnboarding: sharedDefaults?.bool(forKey: WidgetSharedConfig.hasCompletedOnboardingKey) ?? false,
            preferredTransportModeRawValue: sharedDefaults?.string(forKey: WidgetSharedConfig.preferredTransportModeKey) ?? "cycling",
            preferredDuration: max(sharedDefaults?.integer(forKey: WidgetSharedConfig.preferredDurationKey) ?? 25, 5),
            weeklyFocusDuration: 0,
            weeklyCompletedCount: 0,
            currentStreakDays: 0,
            dailyActivityCounts: [:],
            lastJourneySummary: nil,
            lastUpdatedAt: .distantPast
        )
    }
}

private struct HomeWidgetProvider: TimelineProvider {
    private let reader = SharedSnapshotReader()

    func placeholder(in context: Context) -> HomeWidgetEntry {
        HomeWidgetEntry(date: Date(), snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (HomeWidgetEntry) -> Void) {
        let snapshot = context.isPreview ? HomeWidgetSnapshot.placeholder : reader.readSnapshot()
        completion(HomeWidgetEntry(date: Date(), snapshot: snapshot))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HomeWidgetEntry>) -> Void) {
        let entry = HomeWidgetEntry(date: Date(), snapshot: reader.readSnapshot())
        let nextRefresh = Calendar.autoupdatingCurrent.date(byAdding: .hour, value: 1, to: Date()) ?? Date().addingTimeInterval(3600)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }
}

private struct QuickStartWidgetProvider: AppIntentTimelineProvider {
    typealias Intent = QuickStartWidgetConfigurationIntent

    private let reader = SharedSnapshotReader()

    func placeholder(in context: Context) -> QuickStartWidgetEntry {
        QuickStartWidgetEntry(
            date: Date(),
            snapshot: .placeholder,
            configuration: QuickStartWidgetConfigurationIntent()
        )
    }

    func snapshot(for configuration: QuickStartWidgetConfigurationIntent, in context: Context) async -> QuickStartWidgetEntry {
        QuickStartWidgetEntry(
            date: Date(),
            snapshot: context.isPreview ? .placeholder : reader.readSnapshot(),
            configuration: configuration
        )
    }

    func timeline(for configuration: QuickStartWidgetConfigurationIntent, in context: Context) async -> Timeline<QuickStartWidgetEntry> {
        let entry = QuickStartWidgetEntry(
            date: Date(),
            snapshot: reader.readSnapshot(),
            configuration: configuration
        )
        let nextRefresh = Calendar.autoupdatingCurrent.date(byAdding: .hour, value: 1, to: Date()) ?? Date().addingTimeInterval(3600)
        return Timeline(entries: [entry], policy: .after(nextRefresh))
    }
}

struct QuickStartIntent: AppIntent {
    static var title: LocalizedStringResource = "Quick Start Focus"
    static var openAppWhenRun = true

    @Parameter(title: "Transport")
    var transport: QuickStartTransportOption

    @Parameter(title: "Focus Time")
    var duration: QuickStartDurationOption

    func perform() async throws -> some IntentResult {
        return .result()
    }
}

private struct QuickStartWidget: Widget {
    let kind = "QuickStartWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: QuickStartWidgetConfigurationIntent.self, provider: QuickStartWidgetProvider()) { entry in
            QuickStartWidgetView(entry: entry)
        }
        .configurationDisplayName("Quick Start")
        .description("Launch a focus journey with your chosen transport mode and focus time.")
        .supportedFamilies([.systemSmall])
        .contentMarginsDisabled()
    }
}

private struct FocusStatsWidget: Widget {
    let kind = "FocusStatsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HomeWidgetProvider()) { entry in
            FocusStatsWidgetView(entry: entry)
        }
        .configurationDisplayName("Focus Stats")
        .description("Keep weekly focus progress on your Home Screen.")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}

private struct JourneySnapshotWidget: Widget {
    let kind = "JourneySnapshotWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HomeWidgetProvider()) { entry in
            JourneySnapshotWidgetView(entry: entry)
        }
        .configurationDisplayName("Journey Snapshot")
        .description("See your latest finished focus journey at a glance.")
        .supportedFamilies([.systemMedium])
        .contentMarginsDisabled()
    }
}

private struct HeatmapWidget: Widget {
    let kind = "HeatmapWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HomeWidgetProvider()) { entry in
            HeatmapWidgetView(entry: entry)
        }
        .configurationDisplayName("Heatmap")
        .description("See your recent focus activity across the past 12 weeks.")
        .supportedFamilies([.systemMedium])
        .contentMarginsDisabled()
    }
}

private struct QuickStartWidgetView: View {
    @Environment(\.colorScheme) private var colorScheme
    let entry: QuickStartWidgetEntry

    var body: some View {
        let palette = WidgetPalette.quickStart(accent: transportAccent(for: selectedTransportRawValue), colorScheme: colorScheme)

        ZStack {
            WidgetCardBackground(palette: palette)
            if entry.snapshot.hasCompletedOnboarding {
                VStack(alignment: .leading, spacing: 0) {
                    WidgetHeaderRow(
                        eyebrow: widgetText("quick_start_eyebrow"),
                        title: transportTitle(for: selectedTransportRawValue),
                        symbol: transportSymbol(for: selectedTransportRawValue),
                        palette: palette
                    )

                    Spacer(minLength: 0)

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(selectedDurationMinutes)")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(palette.primaryText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.68)

                        Text(widgetText("minutes_short"))
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(palette.secondaryText)
                            .lineLimit(1)
                    }

                    Text(widgetText("ready_to_begin"))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(palette.tertiaryText)
                        .lineLimit(1)

                    Spacer(minLength: 0)

                    Link(destination: quickStartURL(transportRawValue: selectedTransportRawValue, duration: selectedDurationMinutes)) {
                        HStack(spacing: 6) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 10, weight: .bold))
                            Text(widgetText("start_focus"))
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .lineLimit(1)
                                .minimumScaleFactor(0.82)
                        }
                        .foregroundStyle(palette.primaryText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 32)
                        .background(palette.controlFill, in: Capsule(style: .continuous))
                        .overlay(Capsule(style: .continuous).strokeBorder(palette.controlStroke, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
                .padding(WidgetLayout.quickStartInsets)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            } else {
                WidgetEmptyState(
                    title: widgetText("open_app"),
                    message: widgetText("open_app_to_get_started"),
                    palette: palette,
                    insets: WidgetLayout.quickStartInsets
                )
            }
        }
        .containerBackground(for: .widget) {
            Color.clear
        }
    }

    private var selectedTransportRawValue: String {
        (entry.configuration.transport ?? .cycling).rawValue
    }

    private var selectedDurationMinutes: Int {
        (entry.configuration.duration ?? .twentyFive).rawValue
    }
}

private struct FocusStatsWidgetView: View {
    @Environment(\.widgetFamily) private var family
    @Environment(\.colorScheme) private var colorScheme
    let entry: HomeWidgetEntry

    var body: some View {
        let palette = WidgetPalette.stats(accent: .cyan, colorScheme: colorScheme)

        ZStack {
            WidgetCardBackground(palette: palette)
            if !entry.snapshot.hasCompletedOnboarding {
                WidgetEmptyState(
                    title: widgetText("open_app"),
                    message: widgetText("open_app_to_get_started"),
                    palette: palette,
                    insets: family == .systemSmall ? WidgetLayout.insets : WidgetLayout.mediumContentInsets
                )
            } else if family == .systemSmall {
                VStack(alignment: .leading, spacing: 0) {
                    WidgetSimpleHeader(label: widgetText("this_week_eyebrow"), palette: palette)

                    Spacer(minLength: 0)

                    Text(formatDuration(entry.snapshot.weeklyFocusDuration))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(palette.primaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.68)

                    Text(widgetText("focus_time"))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(palette.tertiaryText)
                        .lineLimit(1)

                    Spacer(minLength: 0)

                    HStack(spacing: 7) {
                        WidgetMiniStat(value: "\(entry.snapshot.weeklyCompletedCount)", label: widgetText("done_short"), palette: palette)
                        WidgetMiniStat(value: "\(entry.snapshot.currentStreakDays)", label: widgetText("streak"), palette: palette)
                    }
                }
                .padding(WidgetLayout.insets)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(widgetText("this_week_eyebrow"))
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .kerning(1.0)
                                .foregroundStyle(palette.tertiaryText)
                                .lineLimit(1)
                            Text(widgetText("focus_summary"))
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .foregroundStyle(palette.primaryText)
                                .lineLimit(1)
                                .minimumScaleFactor(0.82)
                        }

                        Spacer(minLength: 0)

                        WidgetIconBadge(symbol: "chart.bar.fill", palette: palette)
                    }

                    Spacer(minLength: 0)

                    HStack(alignment: .bottom, spacing: 10) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(formatDuration(entry.snapshot.weeklyFocusDuration))
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(palette.primaryText)
                                .lineLimit(1)
                                .minimumScaleFactor(0.56)
                            Text(widgetText("total_focused"))
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(palette.tertiaryText)
                                .lineLimit(1)
                                .minimumScaleFactor(0.78)
                        }
                        .frame(width: 96, alignment: .leading)

                        HStack(spacing: 8) {
                            StatsMetricCard(value: "\(entry.snapshot.weeklyCompletedCount)", label: widgetText("sessions"), palette: palette)
                            StatsMetricCard(value: "\(entry.snapshot.currentStreakDays)", label: widgetText("streak"), palette: palette)
                            StatsMetricCard(value: averageFocusLabel, label: widgetText("average"), palette: palette)
                        }
                    }
                }
                .padding(WidgetLayout.mediumStatsInsets)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .containerBackground(for: .widget) {
            Color.clear
        }
    }

    private var averageFocusLabel: String {
        guard entry.snapshot.weeklyCompletedCount > 0 else { return "0m" }
        let avgMinutes = Int((entry.snapshot.weeklyFocusDuration / Double(entry.snapshot.weeklyCompletedCount)) / 60)
        return "\(avgMinutes)m"
    }
}

private struct JourneySnapshotWidgetView: View {
    @Environment(\.colorScheme) private var colorScheme
    let entry: HomeWidgetEntry

    var body: some View {
        let palette = WidgetPalette.journey(accent: .mint, colorScheme: colorScheme)

        ZStack {
            WidgetCardBackground(palette: palette)
            if !entry.snapshot.hasCompletedOnboarding {
                WidgetEmptyState(
                    title: widgetText("open_app"),
                    message: widgetText("open_app_to_get_started"),
                    palette: palette,
                    insets: WidgetLayout.mediumContentInsets
                )
            } else if let summary = entry.snapshot.lastJourneySummary {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(widgetText("latest_journey_eyebrow"))
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .kerning(1.0)
                                .foregroundStyle(palette.tertiaryText)

                            Text(summary.destinationName.isEmpty ? summary.startLocationName : summary.destinationName)
                                .font(.system(size: 19, weight: .bold, design: .rounded))
                                .foregroundStyle(palette.primaryText)
                                .lineLimit(1)
                        }

                        Spacer(minLength: 0)

                        WidgetIconBadge(
                            symbol: transportSymbol(for: summary.transportModeRawValue),
                            palette: WidgetPalette.journey(accent: transportAccent(for: summary.transportModeRawValue), colorScheme: colorScheme)
                        )
                    }

                    HStack(spacing: 8) {
                        Text(summary.startLocationName)
                            .lineLimit(1)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white.opacity(0.42))
                        Text(summary.destinationName.isEmpty ? "Destination" : summary.destinationName)
                            .lineLimit(1)
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(palette.secondaryText)
                    .padding(.top, 6)

                    Spacer(minLength: 0)

                    HStack(spacing: 10) {
                        StatsMetricCard(value: formatDuration(summary.duration), label: widgetText("time"), palette: palette)
                        StatsMetricCard(value: formatDistance(summary.distance), label: widgetText("distance"), palette: palette)
                        StatsMetricCard(value: "\(summary.discoveredPOICount)", label: widgetText("pois"), palette: palette)
                    }
                }
                .padding(WidgetLayout.mediumContentInsets)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            } else {
                WidgetEmptyState(
                    title: widgetText("no_journeys_yet"),
                    message: widgetText("start_your_first_journey"),
                    palette: palette,
                    insets: WidgetLayout.mediumContentInsets
                )
            }
        }
        .containerBackground(for: .widget) {
            Color.clear
        }
    }
}

private struct HeatmapWidgetView: View {
    @Environment(\.colorScheme) private var colorScheme
    let entry: HomeWidgetEntry

    var body: some View {
        let palette = WidgetPalette.heatmap(accent: .green, colorScheme: colorScheme)

        ZStack {
            WidgetCardBackground(palette: palette)
            if !entry.snapshot.hasCompletedOnboarding {
                WidgetEmptyState(
                    title: widgetText("open_app"),
                    message: widgetText("open_app_to_get_started"),
                    palette: palette,
                    insets: WidgetLayout.mediumContentInsets
                )
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(widgetText("heatmap_eyebrow"))
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .kerning(1.0)
                                .foregroundStyle(palette.tertiaryText)
                            Text(widgetText("heatmap_title"))
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundStyle(palette.primaryText)
                        }

                        Spacer(minLength: 0)

                        Text("\(entry.snapshot.currentStreakDays)")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(palette.primaryText)
                    }

                    Text(widgetText("heatmap_subtitle"))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(palette.secondaryText)
                        .lineLimit(1)
                        .padding(.top, 5)

                    Spacer(minLength: 0)

                    WidgetHeatmapGrid(counts: entry.snapshot.dailyActivityCounts, palette: palette)
                }
                .padding(WidgetLayout.mediumContentInsets)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .containerBackground(for: .widget) {
            Color.clear
        }
    }
}

private struct StatsMetricCard: View {
    let value: String
    let label: String
    let palette: WidgetPalette

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(palette.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.62)

            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(palette.tertiaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        .background(palette.panelFill, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(palette.panelStroke, lineWidth: 1)
        )
        .frame(minHeight: 48, alignment: .topLeading)
    }
}

private struct WidgetEmptyState: View {
    let title: String
    let message: String
    let palette: WidgetPalette
    let insets: EdgeInsets

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(palette.primaryText)

            Text(title)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(palette.primaryText)
                .lineLimit(2)
                .minimumScaleFactor(0.82)

            Text(message)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(palette.secondaryText)
                .lineLimit(2)
                .minimumScaleFactor(0.86)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(insets)
    }
}

private struct WidgetCardBackground: View {
    let palette: WidgetPalette

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 28, style: .continuous)

        shape
            .fill(palette.background)
            .overlay(alignment: .topTrailing) {
                Circle()
                    .fill(palette.accentGlow)
                    .frame(width: 138, height: 138)
                    .blur(radius: 18)
                    .offset(x: 22, y: -20)
            }
            .clipShape(shape)
            .overlay(
                shape.strokeBorder(palette.border, lineWidth: 1)
            )
    }
}

private enum WidgetLayout {
    static let insets = EdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16)
    static let quickStartInsets = EdgeInsets(top: 14, leading: 16, bottom: 12, trailing: 16)
    static let mediumContentInsets = EdgeInsets(top: 16, leading: 20, bottom: 14, trailing: 20)
    static let mediumStatsInsets = EdgeInsets(top: 14, leading: 20, bottom: 14, trailing: 20)
}

private struct WidgetHeaderRow: View {
    let eyebrow: String
    let title: String
    let symbol: String
    let palette: WidgetPalette

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                Text(eyebrow)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .kerning(1.0)
                    .foregroundStyle(palette.tertiaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Text(title)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(palette.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }

            Spacer(minLength: 0)

            WidgetIconBadge(symbol: symbol, palette: palette)
        }
    }
}

private struct WidgetSimpleHeader: View {
    let label: String
    let palette: WidgetPalette

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .kerning(1.0)
                .foregroundStyle(palette.tertiaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Spacer(minLength: 0)
            Circle()
                .fill(palette.accent)
                .frame(width: 8, height: 8)
        }
    }
}

private struct WidgetIconBadge: View {
    let symbol: String
    let palette: WidgetPalette
    let size: CGFloat
    let symbolSize: CGFloat
    let cornerRadius: CGFloat

    init(symbol: String, palette: WidgetPalette, size: CGFloat = 36, symbolSize: CGFloat = 16, cornerRadius: CGFloat = 14) {
        self.symbol = symbol
        self.palette = palette
        self.size = size
        self.symbolSize = symbolSize
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: symbolSize, weight: .semibold))
            .foregroundStyle(palette.primaryText)
            .frame(width: size, height: size)
            .background(palette.panelFill, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(palette.panelStroke, lineWidth: 1)
            )
            .shadow(color: palette.accentGlow.opacity(0.8), radius: 10, x: 0, y: 5)
    }
}

private struct WidgetMiniStat: View {
    let value: String
    let label: String
    let palette: WidgetPalette

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(palette.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(palette.tertiaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(palette.panelFill, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(palette.panelStroke, lineWidth: 1)
        )
        .frame(minHeight: 46, alignment: .topLeading)
    }
}

private struct WidgetHeatmapGrid: View {
    let counts: [String: Int]
    let palette: WidgetPalette

    private let weeks = 12
    private let cellSize: CGFloat = 7
    private let cellSpacing: CGFloat = 3
    private var rows: [GridItem] {
        Array(repeating: GridItem(.fixed(cellSize), spacing: cellSpacing), count: 7)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            LazyHGrid(rows: rows, spacing: cellSpacing) {
                ForEach(heatmapDays, id: \.self) { day in
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(levelColor(for: day))
                        .frame(width: cellSize, height: cellSize)
                }
            }

            HStack(spacing: 5) {
                Text(widgetText("less"))
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(palette.tertiaryText)
                ForEach(0..<4, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(levelColor(forLevel: index))
                        .frame(width: cellSize, height: cellSize)
                }
                Text(widgetText("more"))
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(palette.tertiaryText)
                Spacer(minLength: 0)
            }
        }
    }

    private var heatmapDays: [String] {
        let calendar = Calendar.autoupdatingCurrent
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"

        let today = calendar.startOfDay(for: Date())
        let start = calendar.date(byAdding: .day, value: -(weeks * 7) + 1, to: today) ?? today

        return (0..<(weeks * 7)).compactMap {
            calendar.date(byAdding: .day, value: $0, to: start).map { formatter.string(from: $0) }
        }
    }

    private func levelColor(for key: String) -> Color {
        let count = counts[key, default: 0]
        let maxCount = max(counts.values.max() ?? 1, 1)
        if count == 0 { return palette.quietCell }
        let normalized = Double(count) / Double(maxCount)
        if normalized < 0.34 { return palette.level1 }
        if normalized < 0.67 { return palette.level2 }
        return palette.level3
    }

    private func levelColor(forLevel level: Int) -> Color {
        switch level {
        case 0: return palette.quietCell
        case 1: return palette.level1
        case 2: return palette.level2
        default: return palette.level3
        }
    }
}

private struct WidgetPalette {
    let accent: Color
    let background: LinearGradient
    let accentGlow: Color
    let border: Color
    let panelFill: Color
    let panelStroke: Color
    let controlFill: Color
    let controlStroke: Color
    let primaryText: Color
    let secondaryText: Color
    let tertiaryText: Color
    let quietCell: Color
    let level1: Color
    let level2: Color
    let level3: Color

    static func quickStart(accent: Color, colorScheme: ColorScheme) -> WidgetPalette {
        palette(accent: accent, colorScheme: colorScheme)
    }

    static func stats(accent: Color, colorScheme: ColorScheme) -> WidgetPalette {
        palette(accent: accent, colorScheme: colorScheme)
    }

    static func journey(accent: Color, colorScheme: ColorScheme) -> WidgetPalette {
        palette(accent: accent, colorScheme: colorScheme)
    }

    static func heatmap(accent: Color, colorScheme: ColorScheme) -> WidgetPalette {
        palette(accent: accent, colorScheme: colorScheme)
    }

    private static func palette(accent: Color, colorScheme: ColorScheme) -> WidgetPalette {
        if colorScheme == .light {
            return WidgetPalette(
                accent: accent,
                background: LinearGradient(
                    colors: [Color.white, accent.opacity(0.12), Color(red: 0.94, green: 0.96, blue: 0.99)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                accentGlow: accent.opacity(0.16),
                border: Color.black.opacity(0.08),
                panelFill: Color.white.opacity(0.78),
                panelStroke: Color.black.opacity(0.07),
                controlFill: Color.black.opacity(0.08),
                controlStroke: Color.black.opacity(0.08),
                primaryText: Color.black.opacity(0.86),
                secondaryText: Color.black.opacity(0.62),
                tertiaryText: Color.black.opacity(0.48),
                quietCell: Color.black.opacity(0.08),
                level1: accent.opacity(0.36),
                level2: accent.opacity(0.58),
                level3: accent.opacity(0.84)
            )
        }

        return WidgetPalette(
            accent: accent,
            background: LinearGradient(
                colors: [Color(red: 0.11, green: 0.14, blue: 0.21), accent.opacity(0.18), Color(red: 0.07, green: 0.09, blue: 0.14)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            accentGlow: accent.opacity(0.16),
            border: Color.white.opacity(0.12),
            panelFill: Color.white.opacity(0.07),
            panelStroke: Color.white.opacity(0.08),
            controlFill: Color.white.opacity(0.10),
            controlStroke: Color.white.opacity(0.12),
            primaryText: .white,
            secondaryText: Color.white.opacity(0.72),
            tertiaryText: Color.white.opacity(0.56),
            quietCell: Color.white.opacity(0.10),
            level1: accent.opacity(0.38),
            level2: accent.opacity(0.62),
            level3: accent.opacity(0.92)
        )
    }
}

private func transportSymbol(for rawValue: String) -> String {
    switch rawValue {
    case "walking":
        return "figure.walk"
    case "driving":
        return "car.fill"
    case "skateboard":
        return "figure.skateboarding"
    default:
        return "bicycle"
    }
}

private func transportTitle(for rawValue: String) -> String {
    let zh = widgetLanguageCode().hasPrefix("zh")
    switch rawValue {
    case "walking":
        return zh ? "步行" : "Walk"
    case "driving":
        return zh ? "驾车" : "Drive"
    case "skateboard":
        return zh ? "滑板" : "Skate"
    default:
        return zh ? "骑行" : "Ride"
    }
}

private func transportAccent(for rawValue: String) -> Color {
    switch rawValue {
    case "walking":
        return .green
    case "driving":
        return .orange
    case "skateboard":
        return .pink
    default:
        return .blue
    }
}

private func formatDuration(_ duration: TimeInterval) -> String {
    let totalMinutes = Int(duration / 60)
    let hours = totalMinutes / 60
    let minutes = totalMinutes % 60

    if hours > 0 {
        return "\(hours)h \(minutes)m"
    }

    return "\(minutes)m"
}

private func formatDistance(_ distance: Double) -> String {
    if distance >= 1000 {
        return String(format: "%.1fkm", distance / 1000)
    }
    return "\(Int(distance))m"
}

private func quickStartURL(transportRawValue: String, duration: Int) -> URL {
    var components = URLComponents()
    components.scheme = "roamfocus"
    components.host = "quick-start"
    components.queryItems = [
        URLQueryItem(name: "transport", value: transportRawValue),
        URLQueryItem(name: "duration", value: String(duration))
    ]
    return components.url ?? URL(string: "roamfocus://quick-start")!
}

private func widgetLanguageCode() -> String {
    Locale.current.language.languageCode?.identifier ?? "en"
}

private func widgetText(_ key: String) -> String {
    let zh = widgetLanguageCode().hasPrefix("zh")
    switch key {
    case "quick_start_eyebrow": return zh ? "快速开始" : "QUICK START"
    case "minutes_short": return zh ? "分钟" : "min"
    case "ready_to_begin": return zh ? "准备开始专注" : "Ready to begin"
    case "start_focus": return zh ? "开始专注" : "Start Focus"
    case "open_app": return zh ? "打开 App" : "Open app"
    case "open_app_to_get_started": return zh ? "打开 App 后开始使用" : "Open app to get started"
    case "this_week_eyebrow": return zh ? "本周" : "THIS WEEK"
    case "focus_time": return zh ? "专注时长" : "Focus time"
    case "done_short": return zh ? "完成" : "Done"
    case "streak": return zh ? "连续" : "Streak"
    case "focus_summary": return zh ? "专注概览" : "Focus Summary"
    case "total_focused": return zh ? "总专注时长" : "Total focused"
    case "sessions": return zh ? "次数" : "Sessions"
    case "average": return zh ? "平均" : "Average"
    case "latest_journey_eyebrow": return zh ? "最近旅程" : "LATEST JOURNEY"
    case "time": return zh ? "时间" : "Time"
    case "distance": return zh ? "距离" : "Distance"
    case "pois": return zh ? "地点" : "POIs"
    case "no_journeys_yet": return zh ? "还没有旅程" : "No journeys yet"
    case "start_your_first_journey": return zh ? "开始你的第一次旅程" : "Start your first journey"
    case "heatmap_eyebrow": return zh ? "活跃度" : "ACTIVITY"
    case "heatmap_title": return zh ? "专注热力图" : "Focus Heatmap"
    case "heatmap_subtitle": return zh ? "过去 12 周专注分布" : "Past 12 weeks of focus"
    case "less": return zh ? "少" : "Less"
    case "more": return zh ? "多" : "More"
    default: return key
    }
}

struct TikkuuFocusLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusTimerActivityAttributes.self) { context in
            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    transportIcon(symbolName: context.state.transportSymbolName, size: 30)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(context.state.isPaused ? "已暂停" : "专注进行中")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                        Text(context.state.isPaused ? "点击灵动岛返回并继续" : "保持专注，旅程正在推进")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }

                    Spacer(minLength: 0)

                    timeView(for: context.state)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                }

                ProgressView(value: progress(for: context.state))
                    .progressViewStyle(.linear)
                    .tint(context.state.isPaused ? .orange : .blue)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    expandedIconBadge(
                        symbolName: context.state.transportSymbolName,
                        tint: context.state.isPaused ? .orange : .blue
                    )
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(spacing: 3) {
                        progressRing(
                            progress: progress(for: context.state),
                            size: 28,
                            lineWidth: 3,
                            tint: context.state.isPaused ? .orange : .blue
                        )
                        Text("\(Int(progress(for: context.state) * 100))%")
                            .font(.system(size: 9, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    .frame(width: 36)
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 2) {
                        Text("剩余时间")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.secondary)
                        timeView(for: context.state)
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .lineLimit(1)
                            .minimumScaleFactor(0.55)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 7) {
                        HStack(spacing: 6) {
                            Image(systemName: context.state.isPaused ? "pause.circle.fill" : "bolt.circle.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(context.state.isPaused ? .orange : .blue)
                            Text(context.state.isPaused ? "已暂停" : "专注进行中")
                                .font(.caption.weight(.semibold))
                            Spacer(minLength: 8)
                            Text(expandedMessage(for: context.state))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }

                        progressBar(
                            progress: progress(for: context.state),
                            tint: context.state.isPaused ? .orange : .blue
                        )
                    }
                    .padding(.horizontal, 14)
                }
            } compactLeading: {
                transportIcon(symbolName: context.state.transportSymbolName, size: 16)
            } compactTrailing: {
                progressRing(
                    progress: progress(for: context.state),
                    size: 17,
                    lineWidth: 2,
                    tint: context.state.isPaused ? .orange : .blue
                )
            } minimal: {
                progressRing(
                    progress: progress(for: context.state),
                    size: 20,
                    lineWidth: 2.2,
                    tint: context.state.isPaused ? .orange : .blue
                )
            }
            .keylineTint(context.state.isPaused ? .orange : .blue)
        }
    }

    private func timeView(for state: FocusTimerActivityAttributes.ContentState) -> some View {
        Group {
            if state.isPaused {
                Text(timeString(from: state.remainingSeconds))
            } else {
                Text(timerInterval: Date()...state.endTime, countsDown: true)
            }
        }
    }

    private func transportIcon(symbolName: String, size: CGFloat) -> some View {
        Image(systemName: symbolName)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .fontWeight(.semibold)
    }

    private func expandedIconBadge(symbolName: String, tint: Color) -> some View {
        transportIcon(symbolName: symbolName, size: 18)
            .foregroundStyle(tint)
            .frame(width: 34, height: 34)
            .background(tint.opacity(0.18), in: Circle())
    }

    private func progress(for state: FocusTimerActivityAttributes.ContentState) -> Double {
        let total = max(Double(state.totalSeconds), 1)
        let remaining: Double

        if state.isPaused {
            remaining = Double(max(state.remainingSeconds, 0))
        } else {
            remaining = max(state.endTime.timeIntervalSinceNow, 0)
        }

        return min(max(1 - remaining / total, 0), 1)
    }

    @ViewBuilder
    private func progressRing(progress: Double, size: CGFloat, lineWidth: CGFloat, tint: Color) -> some View {
        ZStack {
            Circle()
                .stroke(tint.opacity(0.22), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: size, height: size)
        .accessibilityLabel("进度")
        .accessibilityValue(Text("\(Int(progress * 100))%"))
    }

    private func progressBar(progress: Double, tint: Color) -> some View {
        GeometryReader { proxy in
            let width = max(proxy.size.width * progress, progress > 0 ? 4 : 0)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(tint.opacity(0.2))
                Capsule()
                    .fill(tint)
                    .frame(width: width)
            }
        }
        .frame(height: 6)
        .accessibilityLabel("进度")
        .accessibilityValue(Text("\(Int(progress * 100))%"))
    }

    private func expandedMessage(for state: FocusTimerActivityAttributes.ContentState) -> String {
        state.isPaused ? "点击返回继续旅程" : "保持节奏，旅程推进中"
    }

    private func timeString(from seconds: Int) -> String {
        let clamped = max(seconds, 0)
        let mins = clamped / 60
        let secs = clamped % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

@main
struct TikkuuFocusLiveActivityBundle: WidgetBundle {
    var body: some Widget {
        TikkuuFocusLiveActivity()
        QuickStartWidget()
        FocusStatsWidget()
        JourneySnapshotWidget()
        HeatmapWidget()
    }
}
