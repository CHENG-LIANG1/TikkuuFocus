//
//  JourneyHeatmapView.swift
//  Tikkuu Focus
//

import SwiftUI

// MARK: - Period Enum

enum HeatmapPeriod: String, CaseIterable, Identifiable {
    case week, month, year
    var id: String { rawValue }

    var label: String {
        switch self {
        case .week:  return L("heatmap.period.week")
        case .month: return L("heatmap.period.month")
        case .year:  return L("heatmap.period.year")
        }
    }
}

// MARK: - Time Formatting Helper

private func formatTimeShort(_ t: TimeInterval) -> String {
    guard t > 0 else { return "" }
    let totalSeconds = Int(t)
    let hours = totalSeconds / 3600
    let minutes = (totalSeconds % 3600) / 60
    if hours > 0 && minutes > 0 {
        return "\(hours)h\(minutes)m"
    } else if hours > 0 {
        return "\(hours)h"
    } else if minutes > 0 {
        return "\(minutes)m"
    } else {
        return "<1m"
    }
}

// MARK: - Heatmap Tooltip

private struct HeatmapTooltip: View {
    let date: Date
    let duration: TimeInterval

    private var dateText: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f.string(from: date)
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(dateText)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.primary)
            Text(duration > 0 ? FormatUtilities.formatTime(duration) : L("heatmap.noActivity"))
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Navigation Header

private struct HeatmapNavHeader: View {
    let title: String
    let canGoForward: Bool
    let onBack: () -> Void
    let onForward: () -> Void

    var body: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary.opacity(0.7))
                    .frame(width: 32, height: 32)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
            }

            Spacer()

            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)

            Spacer()

            Button(action: onForward) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(canGoForward ? .primary.opacity(0.7) : .primary.opacity(0.2))
                    .frame(width: 32, height: 32)
                    .background(Color.white.opacity(canGoForward ? 0.08 : 0.03))
                    .clipShape(Circle())
            }
            .disabled(!canGoForward)
        }
    }
}

// MARK: - Week Bar Chart

struct WeekBarChartView: View {
    let data: [Date: TimeInterval]
    let weekStartDate: Date

    @State private var selectedDate: Date?

    private let calendar = Calendar.current
    private let barMaxHeight: CGFloat = 100

    private var weekDays: [Date] {
        (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: weekStartDate) }
    }

    private var maxDuration: TimeInterval {
        weekDays.map { data[calendar.startOfDay(for: $0)] ?? 0 }.max() ?? 1
    }

    private var totalDuration: TimeInterval {
        weekDays.reduce(0) { $0 + (data[calendar.startOfDay(for: $1)] ?? 0) }
    }

    private var weekRangeText: String {
        let end = calendar.date(byAdding: .day, value: 6, to: weekStartDate) ?? weekStartDate
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return "\(f.string(from: weekStartDate)) – \(f.string(from: end))"
    }

    private func dayLabel(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return String(f.string(from: date).prefix(1))
    }

    private func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }

    private func isFuture(_ date: Date) -> Bool {
        calendar.startOfDay(for: date) > calendar.startOfDay(for: Date())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header: total + range
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(totalDuration > 0 ? FormatUtilities.formatTime(totalDuration) : "--")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                Text(weekRangeText)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }

            // Bars
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(weekDays, id: \.self) { date in
                    let day = calendar.startOfDay(for: date)
                    let duration = data[day] ?? 0
                    let fraction = maxDuration > 0 ? CGFloat(duration) / CGFloat(maxDuration) : 0
                    let isSelected = selectedDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false
                    let future = isFuture(date)

                    VStack(spacing: 4) {
                        // Duration label above bar
                        if duration > 0 {
                            Text(formatTimeShort(duration))
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(isToday(date) ? Color(red: 0.415, green: 0.607, blue: 0.800) : .secondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        } else {
                            Text("")
                                .font(.system(size: 9))
                        }

                        ZStack(alignment: .bottom) {
                            // Background track
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.white.opacity(0.06))
                                .frame(height: barMaxHeight)

                            // Active bar
                            if !future && duration > 0 {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(
                                        isToday(date)
                                        ? LinearGradient(
                                            colors: [
                                                Color(red: 0.415, green: 0.607, blue: 0.800),
                                                Color(red: 0.3, green: 0.5, blue: 0.75)
                                            ],
                                            startPoint: .bottom, endPoint: .top
                                        )
                                        : LinearGradient(
                                            colors: [
                                                Color(red: 0.415, green: 0.607, blue: 0.800).opacity(0.55),
                                                Color(red: 0.415, green: 0.607, blue: 0.800).opacity(0.3)
                                            ],
                                            startPoint: .bottom, endPoint: .top
                                        )
                                    )
                                    .frame(height: max(4, barMaxHeight * fraction))
                            }
                        }
                        .overlay(
                            isSelected
                            ? RoundedRectangle(cornerRadius: 6)
                                .strokeBorder(Color(red: 0.415, green: 0.607, blue: 0.800), lineWidth: 1.5)
                            : nil
                        )
                        .onTapGesture {
                            guard !future else { return }
                            HapticManager.light()
                            withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                                selectedDate = isSelected ? nil : date
                            }
                        }

                        // Day label
                        Text(dayLabel(date))
                            .font(.system(size: 11, weight: isToday(date) ? .bold : .medium))
                            .foregroundColor(isToday(date) ? Color(red: 0.415, green: 0.607, blue: 0.800) : .secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: barMaxHeight + 40)

            // Tooltip
            if let sel = selectedDate {
                let day = calendar.startOfDay(for: sel)
                let dur = data[day] ?? 0
                HeatmapTooltip(date: sel, duration: dur)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
    }
}

// MARK: - Month Heatmap

struct MonthHeatmapView: View {
    let data: [Date: TimeInterval]
    let monthDate: Date

    @State private var selectedDate: Date?

    private let calendar = Calendar.current
    private let cellSize: CGFloat = 36

    private var monthStart: Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: monthDate))!
    }

    private var daysInMonth: Int {
        calendar.range(of: .day, in: .month, for: monthDate)!.count
    }

    // Offset of month start in week (0=Sun)
    private var startWeekday: Int {
        (calendar.component(.weekday, from: monthStart) - 1)
    }

    private var totalDays: [Date?] {
        var result: [Date?] = Array(repeating: nil, count: startWeekday)
        for d in 0..<daysInMonth {
            if let date = calendar.date(byAdding: .day, value: d, to: monthStart) {
                result.append(date)
            }
        }
        // Pad to multiple of 7
        while result.count % 7 != 0 { result.append(nil) }
        return result
    }

    private var totalDuration: TimeInterval {
        (0..<daysInMonth).reduce(0) {
            guard let d = calendar.date(byAdding: .day, value: $1, to: monthStart) else { return $0 }
            return $0 + (data[calendar.startOfDay(for: d)] ?? 0)
        }
    }

    private var maxDuration: TimeInterval {
        (0..<daysInMonth).compactMap {
            guard let d = calendar.date(byAdding: .day, value: $0, to: monthStart) else { return nil }
            return data[calendar.startOfDay(for: d)]
        }.max() ?? 1
    }

    private func intensity(for date: Date) -> Int {
        let dur = data[calendar.startOfDay(for: date)] ?? 0
        guard dur > 0, maxDuration > 0 else { return 0 }
        let ratio = dur / maxDuration
        switch ratio {
        case ..<0.25: return 1
        case ..<0.50: return 2
        case ..<0.75: return 3
        default: return 4
        }
    }

    private func cellColor(_ level: Int) -> Color {
        switch level {
        case 0: return Color.white.opacity(0.06)
        case 1: return Color(red: 0.415, green: 0.607, blue: 0.800).opacity(0.2)
        case 2: return Color(red: 0.415, green: 0.607, blue: 0.800).opacity(0.4)
        case 3: return Color(red: 0.415, green: 0.607, blue: 0.800).opacity(0.65)
        case 4: return Color(red: 0.415, green: 0.607, blue: 0.800).opacity(0.9)
        default: return Color.white.opacity(0.06)
        }
    }

    private var monthTitle: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: monthDate)
    }

    private let weekdayLetters = ["S","M","T","W","T","F","S"]

    private var rows: [[Date?]] {
        stride(from: 0, to: totalDays.count, by: 7).map {
            Array(totalDays[$0..<min($0+7, totalDays.count)])
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(totalDuration > 0 ? FormatUtilities.formatTime(totalDuration) : "--")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                Text(monthTitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }

            // Weekday labels
            HStack(spacing: 4) {
                ForEach(weekdayLetters.indices, id: \.self) { i in
                    Text(weekdayLetters[i])
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Grid
            VStack(spacing: 4) {
                ForEach(rows.indices, id: \.self) { rowIdx in
                    HStack(spacing: 4) {
                        ForEach(0..<7) { colIdx in
                            if let date = rows[rowIdx][colIdx] {
                                let isFuture = calendar.startOfDay(for: date) > calendar.startOfDay(for: Date())
                                let isSelected = selectedDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false
                                let level = isFuture ? 0 : intensity(for: date)

                                ZStack {
                                    RoundedRectangle(cornerRadius: 7)
                                        .fill(cellColor(level))
                                    Text("\(calendar.component(.day, from: date))")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(level > 2 ? .white.opacity(0.9) : .primary.opacity(0.7))
                                }
                                .frame(maxWidth: .infinity)
                                .aspectRatio(1, contentMode: .fit)
                                .overlay(
                                    isSelected
                                    ? RoundedRectangle(cornerRadius: 7)
                                        .strokeBorder(Color(red: 0.415, green: 0.607, blue: 0.800), lineWidth: 1.5)
                                    : nil
                                )
                                .onTapGesture {
                                    guard !isFuture else { return }
                                    HapticManager.light()
                                    withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                                        selectedDate = isSelected ? nil : date
                                    }
                                }
                            } else {
                                Color.clear
                                    .frame(maxWidth: .infinity)
                                    .aspectRatio(1, contentMode: .fit)
                            }
                        }
                    }
                }
            }

            // Tooltip
            if let sel = selectedDate {
                let dur = data[calendar.startOfDay(for: sel)] ?? 0
                HeatmapTooltip(date: sel, duration: dur)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
    }
}

// MARK: - Year Heatmap

struct YearHeatmapView: View {
    let data: [Date: TimeInterval]
    let year: Int

    @State private var selectedDate: Date?

    private let calendar = Calendar.current
    private let cellSize: CGFloat = 12
    private let cellSpacing: CGFloat = 3

    private var yearStart: Date {
        calendar.date(from: DateComponents(year: year, month: 1, day: 1))!
    }
    private var yearEnd: Date {
        calendar.date(from: DateComponents(year: year, month: 12, day: 31))!
    }

    // Build weeks: array of 7-element arrays (Sun=0)
    private var weeks: [[Date?]] {
        var result: [[Date?]] = []
        var current = yearStart
        // Pad start to Sunday
        let startWd = calendar.component(.weekday, from: current) - 1 // 0=Sun
        var week: [Date?] = Array(repeating: nil, count: startWd)

        while current <= yearEnd {
            week.append(current)
            if week.count == 7 {
                result.append(week)
                week = []
            }
            current = calendar.date(byAdding: .day, value: 1, to: current)!
        }
        if !week.isEmpty {
            while week.count < 7 { week.append(nil) }
            result.append(week)
        }
        return result
    }

    private var maxDuration: TimeInterval {
        data.values.max() ?? 1
    }

    private var totalDuration: TimeInterval {
        let start = yearStart
        let end = min(yearEnd, Date())
        return data.filter { $0.key >= start && $0.key <= end }.values.reduce(0, +)
    }

    private var activeDays: Int {
        let start = yearStart
        let end = min(yearEnd, Date())
        return data.filter { $0.key >= start && $0.key <= end && $0.value > 0 }.count
    }

    private func intensity(for date: Date) -> Int {
        guard date <= Date() else { return 0 }
        guard date >= yearStart, date <= yearEnd else { return 0 }
        let dur = data[calendar.startOfDay(for: date)] ?? 0
        guard dur > 0, maxDuration > 0 else { return 0 }
        let ratio = dur / maxDuration
        switch ratio {
        case ..<0.25: return 1
        case ..<0.50: return 2
        case ..<0.75: return 3
        default: return 4
        }
    }

    private func cellColor(_ level: Int) -> Color {
        switch level {
        case 0: return Color.white.opacity(0.06)
        case 1: return Color(red: 0.415, green: 0.607, blue: 0.800).opacity(0.2)
        case 2: return Color(red: 0.415, green: 0.607, blue: 0.800).opacity(0.4)
        case 3: return Color(red: 0.415, green: 0.607, blue: 0.800).opacity(0.65)
        case 4: return Color(red: 0.415, green: 0.607, blue: 0.800).opacity(0.9)
        default: return Color.white.opacity(0.06)
        }
    }

    // Month label positions: (weekIndex, monthName)
    private var monthLabels: [(Int, String)] {
        var labels: [(Int, String)] = []
        var seenMonths: Set<Int> = []
        for (wIdx, week) in weeks.enumerated() {
            for date in week.compactMap({ $0 }) {
                let month = calendar.component(.month, from: date)
                if !seenMonths.contains(month) {
                    seenMonths.insert(month)
                    let f = DateFormatter()
                    f.dateFormat = "MMM"
                    labels.append((wIdx, f.string(from: date)))
                }
            }
        }
        return labels
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(totalDuration > 0 ? FormatUtilities.formatTime(totalDuration) : "--")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Text("\(year)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(activeDays)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.415, green: 0.607, blue: 0.800))
                    Text(L("heatmap.activeDays"))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 3) {
                    // Month labels row
                    ZStack(alignment: .topLeading) {
                        Color.clear.frame(height: 16)
                        ForEach(monthLabels, id: \.0) { wIdx, label in
                            Text(label)
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.secondary)
                                .offset(x: CGFloat(wIdx) * (cellSize + cellSpacing))
                        }
                    }

                    // Grid: rows = weekdays (Sun–Sat), cols = weeks
                    HStack(alignment: .top, spacing: cellSpacing) {
                        // Weekday labels
                        VStack(spacing: cellSpacing) {
                            ForEach(["S","M","T","W","T","F","S"], id: \.self) { lbl in
                                Text(lbl)
                                    .font(.system(size: 8, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .frame(width: 10, height: cellSize)
                            }
                        }

                        ForEach(weeks.indices, id: \.self) { wIdx in
                            VStack(spacing: cellSpacing) {
                                ForEach(0..<7) { dIdx in
                                    if let date = weeks[wIdx][dIdx] {
                                        let lvl = intensity(for: date)
                                        let isSel = selectedDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(cellColor(lvl))
                                            .frame(width: cellSize, height: cellSize)
                                            .overlay(
                                                isSel
                                                ? RoundedRectangle(cornerRadius: 2)
                                                    .strokeBorder(Color(red: 0.415, green: 0.607, blue: 0.800), lineWidth: 1.2)
                                                : nil
                                            )
                                            .onTapGesture {
                                                guard date <= Date() else { return }
                                                HapticManager.light()
                                                withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                                                    selectedDate = isSel ? nil : date
                                                }
                                            }
                                    } else {
                                        Color.clear.frame(width: cellSize, height: cellSize)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 4)
            }

            // Tooltip
            if let sel = selectedDate {
                let dur = data[calendar.startOfDay(for: sel)] ?? 0
                HeatmapTooltip(date: sel, duration: dur)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }

            // Legend
            HStack(spacing: 6) {
                Text(L("heatmap.less"))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                HStack(spacing: 3) {
                    ForEach(0..<5) { lvl in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(cellColor(lvl))
                            .frame(width: 11, height: 11)
                    }
                }
                Text(L("heatmap.more"))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Main Section

struct JourneyHeatmapSection: View {
    let data: [Date: TimeInterval]

    @State private var selectedPeriod: HeatmapPeriod = .week
    @State private var currentDate: Date = Date()

    private let calendar = Calendar.current

    // MARK: Navigation helpers

    private var navTitle: String {
        switch selectedPeriod {
        case .week:
            let start = weekStart(for: currentDate)
            let end = calendar.date(byAdding: .day, value: 6, to: start) ?? start
            let f = DateFormatter()
            f.dateFormat = "MMM d"
            let isCurrentWeek = calendar.isDate(start, equalTo: weekStart(for: Date()), toGranularity: .weekOfYear)
            if isCurrentWeek {
                return L("heatmap.thisWeek")
            }
            return "\(f.string(from: start)) – \(f.string(from: end))"
        case .month:
            let f = DateFormatter()
            f.dateFormat = "MMMM yyyy"
            return f.string(from: currentDate)
        case .year:
            return "\(calendar.component(.year, from: currentDate))"
        }
    }

    private var canGoForward: Bool {
        switch selectedPeriod {
        case .week:
            let nextWeekStart = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStart(for: currentDate))!
            return nextWeekStart <= weekStart(for: Date())
        case .month:
            let nextMonth = calendar.date(byAdding: .month, value: 1, to: monthStart(for: currentDate))!
            return nextMonth <= monthStart(for: Date())
        case .year:
            let currentYear = calendar.component(.year, from: Date())
            return calendar.component(.year, from: currentDate) < currentYear
        }
    }

    private func goBack() {
        HapticManager.selection()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            switch selectedPeriod {
            case .week:
                currentDate = calendar.date(byAdding: .weekOfYear, value: -1, to: currentDate)!
            case .month:
                currentDate = calendar.date(byAdding: .month, value: -1, to: currentDate)!
            case .year:
                currentDate = calendar.date(byAdding: .year, value: -1, to: currentDate)!
            }
        }
    }

    private func goForward() {
        guard canGoForward else { return }
        HapticManager.selection()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            switch selectedPeriod {
            case .week:
                currentDate = calendar.date(byAdding: .weekOfYear, value: 1, to: currentDate)!
            case .month:
                currentDate = calendar.date(byAdding: .month, value: 1, to: currentDate)!
            case .year:
                currentDate = calendar.date(byAdding: .year, value: 1, to: currentDate)!
            }
        }
    }

    private func weekStart(for date: Date) -> Date {
        var comps = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        comps.weekday = 2 // Monday
        return calendar.date(from: comps) ?? date
    }

    private func monthStart(for date: Date) -> Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
    }

    // MARK: Body

    var body: some View {
        VStack(spacing: 16) {
            // Period picker
            HStack(spacing: 0) {
                ForEach(HeatmapPeriod.allCases) { period in
                    Button {
                        HapticManager.selection()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                            selectedPeriod = period
                            currentDate = Date()
                        }
                    } label: {
                        Text(period.label)
                            .font(.system(size: 13, weight: selectedPeriod == period ? .semibold : .medium))
                            .foregroundColor(selectedPeriod == period ? .primary : .secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 7)
                            .background(
                                selectedPeriod == period
                                ? RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.white.opacity(0.12))
                                : nil
                            )
                    }
                }
            }
            .padding(4)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 14))

            // Navigation
            HeatmapNavHeader(
                title: navTitle,
                canGoForward: canGoForward,
                onBack: goBack,
                onForward: goForward
            )

            // Content
            Group {
                switch selectedPeriod {
                case .week:
                    WeekBarChartView(data: data, weekStartDate: weekStart(for: currentDate))
                case .month:
                    MonthHeatmapView(data: data, monthDate: currentDate)
                case .year:
                    YearHeatmapView(data: data, year: calendar.component(.year, from: currentDate))
                }
            }
            .id("\(selectedPeriod.rawValue)-\(currentDate.timeIntervalSince1970)")
            .transition(.opacity)
        }
        .padding(20)
        .glassCard(cornerRadius: 24)
    }
}
