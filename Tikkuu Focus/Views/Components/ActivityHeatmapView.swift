//
//  ActivityHeatmapView.swift
//  Tikkuu Focus
//
//  Created by Tikkuu on 2026/2/10.
//

import SwiftUI

/// Activity heatmap showing daily journey activity
struct ActivityHeatmapView: View {
    let data: [Date: Int] // Date -> journey count
    let maxWeeks: Int = 12 // Show last 12 weeks
    
    @State private var selectedDate: Date?
    @State private var selectedCount: Int = 0
    
    // MARK: - Performance Optimization
    
    // Cache computed values to avoid recalculation
    @State private var cachedWeeks: [[Date?]] = []
    @State private var cachedMaxCount: Int = 1
    
    private var calendar: Calendar {
        Calendar.current
    }
    
    private var weeks: [[Date?]] {
        if cachedWeeks.isEmpty {
            return generateWeeks()
        }
        return cachedWeeks
    }
    
    private var maxCount: Int {
        cachedMaxCount
    }
    
    private func updateCache() {
        cachedWeeks = generateWeeks()
        cachedMaxCount = data.values.max() ?? 1
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Legend
            HStack(spacing: 8) {
                Text(L("heatmap.less"))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                
                HStack(spacing: 3) {
                    ForEach(0..<5) { level in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(colorForLevel(level, maxLevel: 4))
                            .frame(width: 12, height: 12)
                    }
                }
                
                Text(L("heatmap.more"))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if selectedDate != nil {
                    Text("\(selectedCount) \(selectedCount == 1 ? L("common.journey") : L("common.journeys"))")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.primary)
                }
            }
            
            // Heatmap grid
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 3) {
                    // Weekday labels
                    HStack(spacing: 3) {
                        // Empty space for alignment
                        Color.clear
                            .frame(width: 20)
                        
                        ForEach(weeks.indices, id: \.self) { weekIndex in
                            VStack(spacing: 3) {
                                ForEach(0..<7) { dayIndex in
                                    if dayIndex == 0 || dayIndex == 3 || dayIndex == 6 {
                                        Text(weekdayLabel(for: dayIndex))
                                            .font(.system(size: 9, weight: .medium))
                                            .foregroundColor(.secondary)
                                            .frame(width: 14, height: 14)
                                    } else {
                                        Color.clear
                                            .frame(width: 14, height: 14)
                                    }
                                }
                            }
                            .opacity(weekIndex == 0 ? 1 : 0)
                        }
                    }
                    
                    // Heatmap cells
                    HStack(alignment: .top, spacing: 3) {
                        // Month labels
                        VStack(alignment: .trailing, spacing: 3) {
                            ForEach(0..<7) { dayIndex in
                                if dayIndex == 0 {
                                    Text(monthLabel(for: weeks.first?.first ?? Date()))
                                        .font(.system(size: 9, weight: .medium))
                                        .foregroundColor(.secondary)
                                        .frame(width: 20, height: 14, alignment: .trailing)
                                } else {
                                    Color.clear
                                        .frame(width: 20, height: 14)
                                }
                            }
                        }
                        
                        ForEach(weeks.indices, id: \.self) { weekIndex in
                            VStack(spacing: 3) {
                                ForEach(0..<7) { dayIndex in
                                    if let date = weeks[weekIndex][dayIndex] {
                                        heatmapCell(for: date)
                                    } else {
                                        Color.clear
                                            .frame(width: 14, height: 14)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .onAppear {
            updateCache()
        }
    }
    
    // MARK: - Heatmap Cell
    
    private func heatmapCell(for date: Date) -> some View {
        let count = data[calendar.startOfDay(for: date)] ?? 0
        let level = calculateLevel(count: count, maxCount: maxCount)
        let isSelected = selectedDate != nil && calendar.isDate(date, inSameDayAs: selectedDate!)
        
        return RoundedRectangle(cornerRadius: 2)
            .fill(colorForLevel(level, maxLevel: 4))
            .frame(width: 14, height: 14)
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .strokeBorder(isSelected ? Color.primary : Color.clear, lineWidth: 1.5)
            )
            .onTapGesture {
                HapticManager.light()
                selectedDate = date
                selectedCount = count
            }
    }
    
    // MARK: - Helper Functions
    
    private func generateWeeks() -> [[Date?]] {
        let today = Date()
        let startDate = calendar.date(byAdding: .weekOfYear, value: -maxWeeks + 1, to: today)!
        
        var weeks: [[Date?]] = []
        var currentDate = calendar.startOfDay(for: startDate)
        
        // Adjust to start from Sunday
        let weekday = calendar.component(.weekday, from: currentDate)
        if weekday != 1 { // 1 = Sunday
            currentDate = calendar.date(byAdding: .day, value: -(weekday - 1), to: currentDate)!
        }
        
        for _ in 0..<maxWeeks {
            var week: [Date?] = []
            for _ in 0..<7 {
                if currentDate <= today {
                    week.append(currentDate)
                } else {
                    week.append(nil)
                }
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
            }
            weeks.append(week)
        }
        
        return weeks
    }
    
    private func calculateLevel(count: Int, maxCount: Int) -> Int {
        guard maxCount > 0 else { return 0 }
        
        if count == 0 {
            return 0
        } else if count == 1 {
            return 1
        } else {
            let percentage = Double(count) / Double(maxCount)
            if percentage <= 0.33 {
                return 2
            } else if percentage <= 0.66 {
                return 3
            } else {
                return 4
            }
        }
    }
    
    private func colorForLevel(_ level: Int, maxLevel: Int) -> Color {
        switch level {
        case 0:
            return Color.gray.opacity(0.1)
        case 1:
            return Color.green.opacity(0.3)
        case 2:
            return Color.green.opacity(0.5)
        case 3:
            return Color.green.opacity(0.7)
        case 4:
            return Color.green.opacity(0.9)
        default:
            return Color.gray.opacity(0.1)
        }
    }
    
    private func weekdayLabel(for index: Int) -> String {
        let weekdays = ["S", "M", "T", "W", "T", "F", "S"]
        return weekdays[index]
    }
    
    private func monthLabel(for date: Date?) -> String {
        guard let date = date else { return "" }
        return FormatUtilities.formatMonthShort(
            date,
            localeIdentifier: Locale.autoupdatingCurrent.identifier
        )
    }
}

#Preview {
    let calendar = Calendar.current
    let today = Date()
    
    // Generate sample data
    var sampleData: [Date: Int] = [:]
    for i in 0..<84 { // Last 12 weeks
        if let date = calendar.date(byAdding: .day, value: -i, to: today) {
            let startOfDay = calendar.startOfDay(for: date)
            sampleData[startOfDay] = Int.random(in: 0...5)
        }
    }
    
    return VStack {
        ActivityHeatmapView(data: sampleData)
            .padding()
            .glassCard(cornerRadius: 20)
            .padding()
    }
}
