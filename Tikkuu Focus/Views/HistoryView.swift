//
//  HistoryView.swift
//  Tikkuu Focus
//
//  Created by Tikkuu on 2026/2/8.
//

import SwiftUI
import SwiftData
import MapKit

struct HistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \JourneyRecord.startTime, order: .reverse) private var records: [JourneyRecord]
    @ObservedObject private var settings = AppSettings.shared
    
    @State private var selectedTab: HistoryTab = .overview
    @State private var showingRecordDetail: JourneyRecord?
    @State private var showTimeDetail = false
    @State private var showDistanceDetail = false
    @State private var showCompletedDetail = false
    @State private var showPOIsDetail = false
    @State private var selectedLocation: String?
    @State private var selectedTransportMode: String?
    @State private var showLongestJourneyDetail = false
    @State private var showFarthestDistanceDetail = false
    @State private var showMostPOIsDetail = false
    @State private var showFastestSpeedDetail = false
    @State private var expandedRecordID: UUID?
    @State private var isEditMode = false
    @State private var selectedRecords: Set<UUID> = []
    @State private var showDeleteConfirmation = false
    @State private var recordToDelete: JourneyRecord?
    @State private var deletingRecordIDs: Set<UUID> = []
    
    // MARK: - Cached Computed Properties (Performance Optimization)
    
    @State private var cachedStats: CachedHistoryStats?
    
    private struct CachedHistoryStats {
        let totalTime: TimeInterval
        let totalDistance: Double
        let completedCount: Int
        let totalPOIs: Int
        let topLocations: [(String, Int)]
        let transportModes: [(String, Int)]
        let longestJourney: JourneyRecord?
        let farthestDistance: JourneyRecord?
        let mostPOIs: JourneyRecord?
        let fastestSpeed: JourneyRecord?
        let heatmapData: [Date: Int]
        let uniqueLocationsCount: Int
        let longestStreak: Int
        let estimatedSteps: Int
        let estimatedCalories: Int
        let co2Saved: Double
        let recordsHash: Int
    }
    
    private func updateCachedStats() {
        let hash = records.map { $0.id }.hashValue
        
        // Only recalculate if data changed
        if let cached = cachedStats, cached.recordsHash == hash {
            return
        }
        
        // Calculate all stats once
        let totalTime = records.reduce(0) { $0 + $1.duration }
        let totalDistance = records.reduce(0) { $0 + $1.distanceTraveled }
        let completedCount = records.filter { $0.isCompleted }.count
        let totalPOIs = records.reduce(0) { $0 + $1.discoveredPOICount }
        
        // Top locations
        var locationCounts: [String: Int] = [:]
        for record in records {
            let location = record.startLocationName
            if !location.isEmpty {
                locationCounts[location, default: 0] += 1
            }
        }
        let topLocations = locationCounts.sorted { $0.value > $1.value }.prefix(5).map { ($0.key, $0.value) }
        
        // Transport modes
        var modeCounts: [String: Int] = [:]
        for record in records {
            modeCounts[record.transportMode, default: 0] += 1
        }
        let transportModes = modeCounts.sorted { $0.value > $1.value }.map { ($0.key, $0.value) }
        
        // Records
        let longestJourney = records.max { $0.duration < $1.duration }
        let farthestDistance = records.max { $0.distanceTraveled < $1.distanceTraveled }
        let mostPOIs = records.max { $0.discoveredPOICount < $1.discoveredPOICount }
        let fastestSpeed = records.filter { $0.duration > 0 }.max { 
            ($0.distanceTraveled / $0.duration) < ($1.distanceTraveled / $1.duration)
        }
        
        // Heatmap data
        var heatmapData: [Date: Int] = [:]
        let calendar = Calendar.current
        for record in records {
            let dateComponents = calendar.dateComponents([.year, .month, .day], from: record.startTime)
            if let date = calendar.date(from: dateComponents) {
                heatmapData[date, default: 0] += 1
            }
        }
        
        // Unique locations
        let uniqueLocationsCount = Set(records.map { $0.startLocationName }).count
        
        // Longest streak
        let longestStreak = calculateLongestStreak()
        
        // Estimated steps (walking only)
        let walkingDistance = records.filter { $0.transportMode.lowercased() == "walking" }
            .reduce(0.0) { $0 + $1.distanceTraveled }
        let estimatedSteps = Int(walkingDistance * 1.3)
        
        // Estimated calories
        let estimatedCalories = records.reduce(0) { sum, record in
            let hours = record.duration / 3600.0
            let caloriesPerHour: Double
            switch record.transportMode.lowercased() {
            case "walking": caloriesPerHour = 200
            case "cycling": caloriesPerHour = 400
            case "driving": caloriesPerHour = 100
            default: caloriesPerHour = 150
            }
            return sum + Int(hours * caloriesPerHour)
        }
        
        // CO2 saved
        let nonDrivingDistance = records.filter { $0.transportMode.lowercased() != "driving" }
            .reduce(0.0) { $0 + $1.distanceTraveled }
        let co2Saved = (nonDrivingDistance / 1000.0) * 0.12
        
        cachedStats = CachedHistoryStats(
            totalTime: totalTime,
            totalDistance: totalDistance,
            completedCount: completedCount,
            totalPOIs: totalPOIs,
            topLocations: Array(topLocations),
            transportModes: transportModes,
            longestJourney: longestJourney,
            farthestDistance: farthestDistance,
            mostPOIs: mostPOIs,
            fastestSpeed: fastestSpeed,
            heatmapData: heatmapData,
            uniqueLocationsCount: uniqueLocationsCount,
            longestStreak: longestStreak,
            estimatedSteps: estimatedSteps,
            estimatedCalories: estimatedCalories,
            co2Saved: co2Saved,
            recordsHash: hash
        )
    }
    
    private func calculateLongestStreak() -> Int {
        guard !records.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        let sortedRecords = records.sorted { $0.startTime < $1.startTime }
        
        var maxStreak = 1
        var currentStreak = 1
        var lastDate: Date?
        
        for record in sortedRecords {
            let recordDate = calendar.startOfDay(for: record.startTime)
            
            if let last = lastDate {
                let daysDiff = calendar.dateComponents([.day], from: last, to: recordDate).day ?? 0
                
                if daysDiff == 1 {
                    currentStreak += 1
                    maxStreak = max(maxStreak, currentStreak)
                } else if daysDiff > 1 {
                    currentStreak = 1
                }
            }
            
            lastDate = recordDate
        }
        
        return maxStreak
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedGradientBackground()
                
                VStack(spacing: 0) {
                    // Tab selector
                    tabSelector
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        .padding(.bottom, 16)
                    
                    // Content
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            switch selectedTab {
                            case .overview:
                                overviewContent
                            case .records:
                                recordsContent
                            case .stats:
                                statsContent
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle(L("history.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if selectedTab == .records && !records.isEmpty {
                        Button(isEditMode ? L("common.done") : L("common.edit")) {
                            HapticManager.light()
                            withAnimation(AnimationConfig.smoothSpring) {
                                isEditMode.toggle()
                                if !isEditMode {
                                    selectedRecords.removeAll()
                                }
                            }
                        }
                        .fontWeight(.semibold)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    if isEditMode && !selectedRecords.isEmpty {
                        Button {
                            HapticManager.light()
                            showDeleteConfirmation = true
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    } else {
                        Button(L("common.done")) {
                            dismiss()
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
        }
        .preferredColorScheme(settings.currentColorScheme)
        .onAppear {
            updateCachedStats()
        }
        .onChange(of: records.count) { _, _ in
            updateCachedStats()
        }
        .sheet(item: $showingRecordDetail) { record in
            RecordDetailView(record: record)
        }
        .sheet(isPresented: $showTimeDetail) {
            TimeDetailView(records: records)
        }
        .sheet(isPresented: $showDistanceDetail) {
            DistanceDetailView(records: records)
        }
        .sheet(isPresented: $showCompletedDetail) {
            CompletedDetailView(records: records.filter { $0.isCompleted })
        }
        .sheet(isPresented: $showPOIsDetail) {
            POIsDetailView(records: records)
        }
        .sheet(item: Binding(
            get: { selectedLocation.map { LocationDetailWrapper(location: $0) } },
            set: { selectedLocation = $0?.location }
        )) { wrapper in
            LocationDetailView(location: wrapper.location, records: records)
        }
        .sheet(item: Binding(
            get: { selectedTransportMode.map { TransportModeDetailWrapper(mode: $0) } },
            set: { selectedTransportMode = $0?.mode }
        )) { wrapper in
            TransportModeDetailView(mode: wrapper.mode, records: records)
        }
        .sheet(isPresented: $showLongestJourneyDetail) {
            AchievementDetailView(
                title: L("history.longestJourney"),
                icon: "flame.fill",
                color: .orange,
                records: [longestJourneyRecord].compactMap { $0 }
            )
        }
        .sheet(isPresented: $showFarthestDistanceDetail) {
            AchievementDetailView(
                title: L("history.farthestDistance"),
                icon: "arrow.up.right",
                color: .blue,
                records: [farthestDistanceRecord].compactMap { $0 }
            )
        }
        .sheet(isPresented: $showMostPOIsDetail) {
            AchievementDetailView(
                title: L("history.mostPOIs"),
                icon: "star.fill",
                color: .yellow,
                records: [mostPOIsRecord].compactMap { $0 }
            )
        }
        .sheet(isPresented: $showFastestSpeedDetail) {
            AchievementDetailView(
                title: L("history.stats.fastestJourney"),
                icon: "speedometer",
                color: .purple,
                records: [fastestSpeedRecord].compactMap { $0 }
            )
        }
        .alert(L("history.delete.confirmation"), isPresented: $showDeleteConfirmation) {
            Button(L("common.cancel"), role: .cancel) {}
            Button(L("common.delete"), role: .destructive) {
                deleteSelectedRecords()
            }
        } message: {
            Text(String(format: L("history.delete.message"), selectedRecords.count))
        }
        .alert(L("history.delete.single.confirmation"), isPresented: Binding(
            get: { recordToDelete != nil },
            set: { if !$0 { recordToDelete = nil } }
        )) {
            Button(L("common.cancel"), role: .cancel) {
                recordToDelete = nil
            }
            Button(L("common.delete"), role: .destructive) {
                if let record = recordToDelete {
                    deleteSingleRecord(record)
                }
            }
        } message: {
            Text(L("history.delete.single.message"))
        }
    }
    
    // MARK: - Delete Functions
    
    private func deleteSelectedRecords() {
        HapticManager.success()
        let idsToDelete = selectedRecords

        withAnimation(.spring(response: 0.24, dampingFraction: 0.9)) {
            deletingRecordIDs.formUnion(idsToDelete)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.84)) {
                for recordID in idsToDelete {
                    if let record = records.first(where: { $0.id == recordID }) {
                        modelContext.delete(record)
                    }
                    deletingRecordIDs.remove(recordID)
                }
                selectedRecords.removeAll()
                isEditMode = false
                updateCachedStats()
            }
        }
    }
    
    private func deleteSingleRecord(_ record: JourneyRecord) {
        HapticManager.success()
        let targetID = record.id

        withAnimation(.spring(response: 0.24, dampingFraction: 0.9)) {
            _ = deletingRecordIDs.insert(targetID)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.84)) {
                modelContext.delete(record)
                deletingRecordIDs.remove(targetID)
                recordToDelete = nil
                if expandedRecordID == record.id {
                    expandedRecordID = nil
                }
                updateCachedStats()
            }
        }
    }
    
    // MARK: - Tab Selector
    
    private var tabSelector: some View {
        HStack(spacing: 8) {
            ForEach(HistoryTab.allCases) { tab in
                TabButton(
                    tab: tab,
                    isSelected: selectedTab == tab
                ) {
                    HapticManager.selection()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab
                    }
                }
            }
        }
        .padding(6)
        .themedRoundedBackground(cornerRadius: 14, depth: .inset)
    }
    
    // MARK: - Overview Content
    
    private var overviewContent: some View {
        VStack(spacing: 16) {
            // Summary cards
            HStack(spacing: 12) {
                Button {
                    HapticManager.light()
                    showTimeDetail = true
                } label: {
                    SummaryCard(
                        icon: "clock.fill",
                        title: L("history.totalTime"),
                        value: FormatUtilities.formatTime(totalDuration),
                        gradient: LiquidGlassStyle.primaryGradient
                    )
                }
                
                Button {
                    HapticManager.light()
                    showDistanceDetail = true
                } label: {
                    SummaryCard(
                        icon: "location.fill",
                        title: L("history.totalDistance"),
                        value: FormatUtilities.formatDistance(totalDistance),
                        gradient: LiquidGlassStyle.accentGradient
                    )
                }
            }
            
            HStack(spacing: 12) {
                Button {
                    HapticManager.light()
                    showCompletedDetail = true
                } label: {
                    SummaryCard(
                        icon: "flag.checkered",
                        title: L("history.completed"),
                        value: "\(completedCount)",
                        gradient: LinearGradient(
                            colors: [Color.green, Color.green.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                }
                
                Button {
                    HapticManager.light()
                    showPOIsDetail = true
                } label: {
                    SummaryCard(
                        icon: "star.fill",
                        title: L("history.poisFound"),
                        value: "\(totalPOIs)",
                        gradient: LinearGradient(
                            colors: [Color.yellow, Color.orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                }
            }
            
            // Favorite locations
            if !topLocations.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text(L("history.topLocations"))
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    ForEach(topLocations, id: \.location) { item in
                        Button {
                            HapticManager.light()
                            selectedLocation = item.location
                        } label: {
                            LocationFrequencyRow(
                                location: item.location,
                                count: item.count,
                                totalTime: item.totalTime
                            )
                        }
                    }
                }
                .padding(20)
                .glassCard(cornerRadius: 20)
            }
            
            // Transport mode breakdown
            if !transportModeStats.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text(L("history.transportModes"))
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    ForEach(transportModeStats, id: \.mode) { stat in
                        Button {
                            HapticManager.light()
                            selectedTransportMode = stat.mode
                        } label: {
                            TransportModeRow(
                                mode: stat.mode,
                                count: stat.count,
                                distance: stat.distance
                            )
                        }
                    }
                }
                .padding(20)
                .glassCard(cornerRadius: 20)
            }
        }
    }
    
    // MARK: - Records Content
    
    private var recordsContent: some View {
        VStack(spacing: 12) {
            if records.isEmpty {
                EmptyStateView()
            } else {
                // Use LazyVStack for better performance with large lists
                LazyVStack(spacing: 12) {
                    ForEach(records.prefix(PerformanceConfig.maxDisplayRecords)) { record in
                        let isDeleting = deletingRecordIDs.contains(record.id)
                        HStack(spacing: 0) {
                            // Selection checkbox in edit mode
                            if isEditMode {
                                Button {
                                    HapticManager.selection()
                                    if selectedRecords.contains(record.id) {
                                        selectedRecords.remove(record.id)
                                    } else {
                                        selectedRecords.insert(record.id)
                                    }
                                } label: {
                                    Image(systemName: selectedRecords.contains(record.id) ? "checkmark.circle.fill" : "circle")
                                        .font(.system(size: 24, weight: .semibold))
                                        .foregroundColor(selectedRecords.contains(record.id) ? .blue : .secondary)
                                        .frame(width: 44, height: 44)
                                }
                                .transition(.scale.combined(with: .opacity))
                            }
                            
                            ExpandableRecordCard(
                                record: record,
                                isExpanded: expandedRecordID == record.id && !isEditMode,
                                isEditMode: isEditMode
                            ) {
                                if !isEditMode {
                                    HapticManager.medium()
                                    withAnimation(AnimationConfig.fluidSpring) {
                                        if expandedRecordID == record.id {
                                            expandedRecordID = nil
                                        } else {
                                            expandedRecordID = record.id
                                        }
                                    }
                                }
                            } onDelete: {
                                recordToDelete = record
                            }
                        }
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.95, anchor: .top).combined(with: .opacity),
                            removal: .recordStripPullOut
                        ))
                        .zIndex(expandedRecordID == record.id ? 1 : 0)
                        .scaleEffect(isDeleting ? 0.94 : 1.0, anchor: .topLeading)
                        .opacity(isDeleting ? 0 : 1)
                        .frame(maxHeight: isDeleting ? 0 : .infinity, alignment: .top)
                        .clipped()
                        .animation(.spring(response: 0.28, dampingFraction: 0.9), value: isDeleting)
                        .id(record.id) // Ensure proper identity for animations
                    }
                }
                .animation(
                    .spring(response: 0.34, dampingFraction: 0.84, blendDuration: 0.12),
                    value: records.prefix(PerformanceConfig.maxDisplayRecords).map(\.id)
                )
                
                // Show "Load More" if there are more records
                if records.count > PerformanceConfig.maxDisplayRecords {
                    Text("\(records.count - PerformanceConfig.maxDisplayRecords) more records...")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.vertical, 12)
                }
            }
        }
    }
    
    // MARK: - Stats Content
    
    private var statsContent: some View {
        VStack(spacing: 16) {
            // Average stats
            VStack(alignment: .leading, spacing: 12) {
                Text(L("history.averages"))
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                
                StatRow(label: L("history.detail.duration"), value: FormatUtilities.formatTime(averageDuration))
                StatRow(label: L("history.detail.distanceTraveled"), value: FormatUtilities.formatDistance(averageDistance))
                StatRow(label: L("history.stats.completionRate"), value: "\(Int(completionRate * 100))%")
                StatRow(label: L("history.detail.poisDiscovered"), value: String(format: "%.1f", averagePOIs))
                StatRow(label: L("history.stats.averageSpeed"), value: FormatUtilities.formatSpeed(averageSpeed))
            }
            .padding(20)
            .glassCard(cornerRadius: 20)
            
            // Streaks and achievements
            VStack(alignment: .leading, spacing: 12) {
                Text(L("history.achievements"))
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                
                Button {
                    HapticManager.light()
                    showLongestJourneyDetail = true
                } label: {
                    AchievementRow(
                        icon: "flame.fill",
                        title: L("history.longestJourney"),
                        value: FormatUtilities.formatTime(longestDuration),
                        color: .orange
                    )
                }
                
                Button {
                    HapticManager.light()
                    showFarthestDistanceDetail = true
                } label: {
                    AchievementRow(
                        icon: "arrow.up.right",
                        title: L("history.farthestDistance"),
                        value: FormatUtilities.formatDistance(farthestDistance),
                        color: .blue
                    )
                }
                
                Button {
                    HapticManager.light()
                    showMostPOIsDetail = true
                } label: {
                    AchievementRow(
                        icon: "star.fill",
                        title: L("history.mostPOIs"),
                        value: "\(mostPOIsInJourney)",
                        color: .yellow
                    )
                }
                
                Button {
                    HapticManager.light()
                    showFastestSpeedDetail = true
                } label: {
                    AchievementRow(
                        icon: "speedometer",
                        title: L("history.stats.fastestJourney"),
                        value: FormatUtilities.formatSpeed(fastestSpeed),
                        color: .purple
                    )
                }
            }
            .padding(20)
            .glassCard(cornerRadius: 20)
            
            // Time distribution
            VStack(alignment: .leading, spacing: 12) {
                Text(L("history.stats.timeDistribution"))
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                
                TimeDistributionBar(
                    morning: morningJourneys,
                    afternoon: afternoonJourneys,
                    evening: eveningJourneys,
                    night: nightJourneys
                )
                
                VStack(spacing: 8) {
                    TimeDistributionRow(
                        icon: "sunrise.fill",
                        label: L("history.stats.morning"),
                        count: morningJourneys,
                        color: .orange
                    )
                    TimeDistributionRow(
                        icon: "sun.max.fill",
                        label: L("history.stats.afternoon"),
                        count: afternoonJourneys,
                        color: .yellow
                    )
                    TimeDistributionRow(
                        icon: "sunset.fill",
                        label: L("history.stats.evening"),
                        count: eveningJourneys,
                        color: .pink
                    )
                    TimeDistributionRow(
                        icon: "moon.stars.fill",
                        label: L("history.stats.night"),
                        count: nightJourneys,
                        color: .indigo
                    )
                }
            }
            .padding(20)
            .glassCard(cornerRadius: 20)
            
            // Weekly activity
            if !weeklyActivity.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text(L("history.stats.weeklyActivity"))
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    WeeklyActivityChart(data: weeklyActivity)
                }
                .padding(20)
                .glassCard(cornerRadius: 20)
            }
            
            // Milestones
            VStack(alignment: .leading, spacing: 12) {
                Text(L("history.stats.milestones"))
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                
                // Grid layout for better space utilization
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    MilestoneCard(
                        icon: "calendar.badge.clock",
                        title: L("history.stats.totalDays"),
                        value: "\(totalActiveDays)",
                        subtitle: L("history.stats.daysActive"),
                        color: .cyan
                    )
                    
                    MilestoneCard(
                        icon: "clock.fill",
                        title: L("history.stats.totalTime"),
                        value: FormatUtilities.formatTime(totalDuration),
                        subtitle: L("history.stats.timeSpent"),
                        color: .blue
                    )
                    
                    MilestoneCard(
                        icon: "figure.walk.motion",
                        title: L("history.stats.totalSteps"),
                        value: FormatUtilities.formatNumber(estimatedSteps),
                        subtitle: L("history.stats.stepsEstimated"),
                        color: .green
                    )
                    
                    MilestoneCard(
                        icon: "flame.fill",
                        title: L("history.stats.caloriesBurned"),
                        value: FormatUtilities.formatNumber(estimatedCalories),
                        subtitle: "kcal",
                        color: .red
                    )
                    
                    MilestoneCard(
                        icon: "leaf.fill",
                        title: L("history.stats.co2Saved"),
                        value: String(format: "%.1f", co2Saved),
                        subtitle: "kg CO₂",
                        color: .mint
                    )
                    
                    MilestoneCard(
                        icon: "star.fill",
                        title: L("history.stats.totalPOIs"),
                        value: "\(totalPOIs)",
                        subtitle: L("history.stats.poisDiscovered"),
                        color: .yellow
                    )
                    
                    MilestoneCard(
                        icon: "mappin.and.ellipse",
                        title: L("history.stats.uniqueLocations"),
                        value: "\(uniqueLocationsCount)",
                        subtitle: L("history.stats.placesVisited"),
                        color: .purple
                    )
                    
                    MilestoneCard(
                        icon: "chart.line.uptrend.xyaxis",
                        title: L("history.stats.longestStreak"),
                        value: "\(longestStreak)",
                        subtitle: L("history.stats.daysInRow"),
                        color: .orange
                    )
                }
            }
            .padding(20)
            .glassCard(cornerRadius: 20)
        }
    }
    
    // MARK: - Computed Properties (Using Cached Data for Performance)
    
    private var totalDuration: TimeInterval {
        cachedStats?.totalTime ?? 0
    }
    
    private var totalDistance: Double {
        cachedStats?.totalDistance ?? 0
    }
    
    private var completedCount: Int {
        cachedStats?.completedCount ?? 0
    }
    
    private var totalPOIs: Int {
        cachedStats?.totalPOIs ?? 0
    }
    
    private var averageDuration: TimeInterval {
        records.isEmpty ? 0 : totalDuration / Double(records.count)
    }
    
    private var averageDistance: Double {
        records.isEmpty ? 0 : totalDistance / Double(records.count)
    }
    
    private var completionRate: Double {
        records.isEmpty ? 0 : Double(completedCount) / Double(records.count)
    }
    
    private var averagePOIs: Double {
        records.isEmpty ? 0 : Double(totalPOIs) / Double(records.count)
    }
    
    private var longestDuration: TimeInterval {
        cachedStats?.longestJourney?.duration ?? 0
    }
    
    private var farthestDistance: Double {
        cachedStats?.farthestDistance?.distanceTraveled ?? 0
    }
    
    private var mostPOIsInJourney: Int {
        cachedStats?.mostPOIs?.discoveredPOICount ?? 0
    }
    
    private var longestJourneyRecord: JourneyRecord? {
        cachedStats?.longestJourney
    }
    
    private var farthestDistanceRecord: JourneyRecord? {
        cachedStats?.farthestDistance
    }
    
    private var mostPOIsRecord: JourneyRecord? {
        cachedStats?.mostPOIs
    }
    
    private var fastestSpeedRecord: JourneyRecord? {
        cachedStats?.fastestSpeed
    }
    
    private var topLocations: [(location: String, count: Int, totalTime: TimeInterval)] {
        guard let cached = cachedStats else { return [] }
        return cached.topLocations.map { location, count in
            let locationRecords = records.filter { $0.startLocationName == location }
            let totalTime = locationRecords.reduce(0) { $0 + $1.duration }
            return (location: location, count: count, totalTime: totalTime)
        }
    }
    
    private var transportModeStats: [(mode: String, count: Int, distance: Double)] {
        guard let cached = cachedStats else { return [] }
        return cached.transportModes.map { mode, count in
            let modeRecords = records.filter { $0.transportMode == mode }
            let distance = modeRecords.reduce(0) { $0 + $1.distanceTraveled }
            return (mode: mode, count: count, distance: distance)
        }
    }
    
    // New stats
    private var averageSpeed: Double {
        guard !records.isEmpty else { return 0 }
        let totalSpeed = records.reduce(0.0) { sum, record in
            guard record.duration > 0 else { return sum }
            return sum + (record.distanceTraveled / record.duration)
        }
        return totalSpeed / Double(records.count)
    }
    
    private var fastestSpeed: Double {
        records.map { record in
            guard record.duration > 0 else { return 0 }
            return record.distanceTraveled / record.duration
        }.max() ?? 0
    }
    
    private var morningJourneys: Int {
        records.filter { Calendar.current.component(.hour, from: $0.startTime) < 12 }.count
    }
    
    private var afternoonJourneys: Int {
        records.filter {
            let hour = Calendar.current.component(.hour, from: $0.startTime)
            return hour >= 12 && hour < 18
        }.count
    }
    
    private var eveningJourneys: Int {
        records.filter {
            let hour = Calendar.current.component(.hour, from: $0.startTime)
            return hour >= 18 && hour < 22
        }.count
    }
    
    private var nightJourneys: Int {
        records.filter {
            let hour = Calendar.current.component(.hour, from: $0.startTime)
            return hour >= 22 || hour < 6
        }.count
    }
    
    private var weeklyActivity: [(day: String, count: Int)] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: records) { record in
            calendar.component(.weekday, from: record.startTime)
        }
        
        let weekdays = [
            (1, L("history.stats.sunday")),
            (2, L("history.stats.monday")),
            (3, L("history.stats.tuesday")),
            (4, L("history.stats.wednesday")),
            (5, L("history.stats.thursday")),
            (6, L("history.stats.friday")),
            (7, L("history.stats.saturday"))
        ]
        
        return weekdays.map { (day: $0.1, count: grouped[$0.0]?.count ?? 0) }
    }
    
    private var totalActiveDays: Int {
        let calendar = Calendar.current
        let uniqueDays = Set(records.map { calendar.startOfDay(for: $0.startTime) })
        return uniqueDays.count
    }
    
    private var heatmapData: [Date: Int] {
        cachedStats?.heatmapData ?? [:]
    }
    
    private var estimatedSteps: Int {
        cachedStats?.estimatedSteps ?? 0
    }
    
    private var estimatedCalories: Int {
        cachedStats?.estimatedCalories ?? 0
    }
    
    private var co2Saved: Double {
        cachedStats?.co2Saved ?? 0
    }
    
    private var uniqueLocationsCount: Int {
        cachedStats?.uniqueLocationsCount ?? 0
    }
    
    private var longestStreak: Int {
        cachedStats?.longestStreak ?? 0
    }
}

private struct RecordStripPullOutModifier: ViewModifier {
    let progress: CGFloat

    func body(content: Content) -> some View {
        content
            .scaleEffect(
                x: 1.0 - (progress * 0.2),
                y: 1.0 - (progress * 0.04),
                anchor: .leading
            )
            .offset(x: progress * 220)
            .rotationEffect(.degrees(Double(progress) * 7.0))
            .opacity(1.0 - progress)
            .blur(radius: progress * 2.0)
    }
}

private extension AnyTransition {
    static var recordStripPullOut: AnyTransition {
        .modifier(
            active: RecordStripPullOutModifier(progress: 1.0),
            identity: RecordStripPullOutModifier(progress: 0.0)
        )
    }
}

// MARK: - History Tab

enum HistoryTab: String, CaseIterable, Identifiable {
    case overview
    case records
    case stats
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .overview: return L("history.overview")
        case .records: return L("history.records")
        case .stats: return L("history.stats")
        }
    }
    
    var icon: String {
        switch self {
        case .overview: return "chart.bar.fill"
        case .records: return "list.bullet"
        case .stats: return "chart.line.uptrend.xyaxis"
        }
    }
}

// MARK: - Tab Button

struct TabButton: View {
    let tab: HistoryTab
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: tab.icon)
                    .font(.system(size: 13, weight: .semibold))
                
                Text(tab.displayName)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(isSelected ? .white : .secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .insetSurface(cornerRadius: 10, isActive: isSelected)
        }
    }
}

// MARK: - Summary Card

struct SummaryCard: View {
    let icon: String
    let title: String
    let value: String
    let gradient: LinearGradient
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(gradient)
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .glassCard(cornerRadius: 16)
    }
}

// MARK: - Location Frequency Row

struct LocationFrequencyRow: View {
    let location: String
    let count: Int
    let totalTime: TimeInterval
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(LiquidGlassStyle.accentGradient)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(location)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("\(count) " + L("common.times") + " • \(FormatUtilities.formatTime(totalTime))")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\(count)")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(LiquidGlassStyle.primaryGradient)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Record Card

struct RecordCard: View {
    let record: JourneyRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(record.startLocationName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(FormatUtilities.formatDate(record.startTime))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if record.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "pause.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.orange)
                }
            }
            
            Divider()
            
            HStack(spacing: 16) {
                RecordStat(icon: "clock.fill", value: FormatUtilities.formatTime(record.duration))
                RecordStat(icon: "location.fill", value: FormatUtilities.formatDistance(record.distanceTraveled))
                RecordStat(icon: "star.fill", value: "\(record.discoveredPOICount)")
            }
        }
        .padding(16)
        .glassCard(cornerRadius: 16)
    }
}

// MARK: - Expandable Record Card

struct ExpandableRecordCard: View {
    let record: JourneyRecord
    let isExpanded: Bool
    let isEditMode: Bool
    let onTap: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(colorForTransportMode(record.transportMode).opacity(0.18))
                        .frame(width: 48, height: 48)

                    Image(systemName: iconForTransportMode(record.transportMode))
                        .font(.system(size: 21, weight: .semibold))
                        .foregroundColor(colorForTransportMode(record.transportMode))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(record.startLocationName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        Text(FormatUtilities.formatDate(record.startTime))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)

                        Text("·")
                            .foregroundColor(.secondary)

                        Text(L("transport.\(record.transportMode.lowercased())"))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer(minLength: 0)

                if !isEditMode {
                    Button {
                        HapticManager.light()
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.red)
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(Color.red.opacity(0.12))
                            )
                    }
                    .buttonStyle(.plain)

                    Image(systemName: "chevron.down")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .animation(.spring(response: 0.28, dampingFraction: 0.84), value: isExpanded)
                }
            }
            .padding(16)
            .contentShape(Rectangle())
            .onTapGesture {
                guard !isEditMode else { return }
                onTap()
            }

            if isExpanded {
                Divider()
                    .overlay(Color.white.opacity(0.22))

                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 10) {
                        ExpandedQuickStat(
                            icon: "clock.fill",
                            value: FormatUtilities.formatTime(record.duration),
                            label: L("history.detail.duration"),
                            color: .blue
                        )

                        ExpandedQuickStat(
                            icon: "location.fill",
                            value: FormatUtilities.formatDistance(record.distanceTraveled),
                            label: L("history.detail.distanceTraveled"),
                            color: .green
                        )

                        ExpandedQuickStat(
                            icon: "star.fill",
                            value: "\(record.discoveredPOICount)",
                            label: L("history.detail.poisDiscovered"),
                            color: .orange
                        )
                    }

                    RouteMapPreview(
                        startCoordinate: CLLocationCoordinate2D(
                            latitude: record.startLatitude,
                            longitude: record.startLongitude
                        ),
                        endCoordinate: CLLocationCoordinate2D(
                            latitude: record.destinationLatitude,
                            longitude: record.destinationLongitude
                        )
                    )
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                    )

                    VStack(spacing: 12) {
                        ExpandedDetailRow(
                            icon: "location.circle.fill",
                            label: L("history.detail.start"),
                            value: record.startLocationName,
                            color: .green
                        )

                        ExpandedDetailRow(
                            icon: "flag.circle.fill",
                            label: L("history.detail.destination"),
                            value: record.destinationName,
                            color: .red
                        )

                        ExpandedDetailRow(
                            icon: "gauge.with.dots.needle.67percent",
                            label: L("history.detail.progress"),
                            value: FormatUtilities.formatProgress(record.progress),
                            color: .purple
                        )

                        ExpandedDetailRow(
                            icon: "clock.arrow.circlepath",
                            label: L("history.detail.plannedDuration"),
                            value: FormatUtilities.formatTime(record.plannedDuration),
                            color: .orange
                        )

                        ExpandedDetailRow(
                            icon: "calendar",
                            label: L("history.detail.started"),
                            value: FormatUtilities.formatDateTime(record.startTime),
                            color: .cyan
                        )

                        if let endTime = record.endTime {
                            ExpandedDetailRow(
                                icon: "calendar.badge.checkmark",
                                label: L("history.detail.ended"),
                                value: FormatUtilities.formatDateTime(endTime),
                                color: .cyan
                            )
                        }
                    }
                }
                .padding(16)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .themedRoundedBackground(cornerRadius: 18, depth: .inset)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(
                    isExpanded ? Color.blue.opacity(0.34) : Color.white.opacity(0.16),
                    lineWidth: isExpanded ? 1.5 : 1
                )
        )
        .shadow(
            color: Color.black.opacity(isExpanded ? 0.15 : 0.08),
            radius: isExpanded ? 14 : 8,
            x: 0,
            y: isExpanded ? 8 : 4
        )
        .animation(.spring(response: 0.34, dampingFraction: 0.86), value: isExpanded)
        .disabled(isEditMode)
        .opacity(isEditMode ? 0.75 : 1.0)
        .animation(AnimationConfig.smoothSpring, value: isEditMode)
        }
    
    private func iconForTransportMode(_ mode: String) -> String {
        switch mode.lowercased() {
        case "walking": return "figure.walk"
        case "cycling": return "bicycle"
        case "driving": return "car.fill"
        case "subway": return "tram.fill"
        default: return "figure.walk"
        }
    }
    
    private func colorForTransportMode(_ mode: String) -> Color {
        switch mode.lowercased() {
        case "walking": return .green
        case "cycling": return .blue
        case "driving": return .purple
        case "subway": return .orange
        default: return .blue
        }
    }
}

// MARK: - Expanded Quick Stat

struct ExpandedQuickStat: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(color)
            }
            
            VStack(spacing: 3) {
                Text(value)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(color.opacity(0.08))
        )
    }
}

// MARK: - Expanded Detail Row

struct ExpandedDetailRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
    }
}



// MARK: - Wrapper Structures

struct LocationDetailWrapper: Identifiable {
    let id = UUID()
    let location: String
}

struct TransportModeDetailWrapper: Identifiable {
    let id = UUID()
    let mode: String
}

// MARK: - Location Detail View

struct LocationDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let location: String
    let records: [JourneyRecord]
    
    private var locationRecords: [JourneyRecord] {
        records.filter { $0.startLocationName == location }
            .sorted { $0.startTime > $1.startTime }
    }
    
    private var totalTime: TimeInterval {
        locationRecords.reduce(0) { $0 + $1.duration }
    }
    
    private var totalDistance: Double {
        locationRecords.reduce(0) { $0 + $1.distanceTraveled }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedGradientBackground()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        if locationRecords.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundStyle(LiquidGlassStyle.accentGradient)
                                    .opacity(0.5)
                                
                                Text(L("history.location.empty.title"))
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.primary)
                                
                                Text(String(format: L("history.location.empty.message"), location))
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 60)
                        } else {
                            // Summary stats
                            HStack(spacing: 12) {
                                VStack(spacing: 8) {
                                    Text("\(locationRecords.count)")
                                        .font(.system(size: 28, weight: .bold, design: .rounded))
                                        .foregroundStyle(LiquidGlassStyle.primaryGradient)
                                    
                                    Text(L("common.journeys"))
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                                .glassCard(cornerRadius: 16)
                                
                                VStack(spacing: 8) {
                                    Text(FormatUtilities.formatTime(totalTime))
                                        .font(.system(size: 28, weight: .bold, design: .rounded))
                                        .foregroundStyle(LiquidGlassStyle.primaryGradient)
                                    
                                    Text(L("history.totalTime"))
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                                .glassCard(cornerRadius: 16)
                            }
                            
                            VStack(spacing: 8) {
                                Text(FormatUtilities.formatDistance(totalDistance))
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundStyle(LiquidGlassStyle.accentGradient)
                                
                                Text(L("history.totalDistance"))
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .glassCard(cornerRadius: 16)
                            
                            // Records list
                            VStack(spacing: 12) {
                                ForEach(locationRecords) { record in
                                    TimeRecordRow(record: record)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle(location)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L("common.done")) {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Transport Mode Detail View

struct TransportModeDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let mode: String
    let records: [JourneyRecord]
    
    private var modeRecords: [JourneyRecord] {
        records.filter { $0.transportMode.lowercased() == mode.lowercased() }
            .sorted { $0.startTime > $1.startTime }
    }
    
    private var totalTime: TimeInterval {
        modeRecords.reduce(0) { $0 + $1.duration }
    }
    
    private var totalDistance: Double {
        modeRecords.reduce(0) { $0 + $1.distanceTraveled }
    }
    
    private var averageSpeed: Double {
        guard !modeRecords.isEmpty else { return 0 }
        let totalSpeed = modeRecords.reduce(0.0) { sum, record in
            guard record.duration > 0 else { return sum }
            return sum + (record.distanceTraveled / record.duration)
        }
        return totalSpeed / Double(modeRecords.count)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedGradientBackground()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        if modeRecords.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: iconForMode(mode))
                                    .font(.system(size: 60))
                                    .foregroundStyle(LiquidGlassStyle.primaryGradient)
                                    .opacity(0.5)
                                
                                Text(String(format: L("history.mode.empty.title"), mode.capitalized))
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.primary)
                                
                                Text(String(format: L("history.mode.empty.message"), mode.lowercased()))
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 60)
                        } else {
                            // Summary stats
                            HStack(spacing: 12) {
                                VStack(spacing: 8) {
                                    Text("\(modeRecords.count)")
                                        .font(.system(size: 28, weight: .bold, design: .rounded))
                                        .foregroundStyle(LiquidGlassStyle.primaryGradient)
                                    
                                    Text(L("common.journeys"))
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                                .glassCard(cornerRadius: 16)
                                
                                VStack(spacing: 8) {
                                    Text(FormatUtilities.formatTime(totalTime))
                                        .font(.system(size: 28, weight: .bold, design: .rounded))
                                        .foregroundStyle(LiquidGlassStyle.primaryGradient)
                                    
                                    Text(L("history.totalTime"))
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                                .glassCard(cornerRadius: 16)
                            }
                            
                            HStack(spacing: 12) {
                                VStack(spacing: 8) {
                                    Text(FormatUtilities.formatDistance(totalDistance))
                                        .font(.system(size: 24, weight: .bold, design: .rounded))
                                        .foregroundStyle(LiquidGlassStyle.accentGradient)
                                    
                                    Text(L("history.totalDistance"))
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                                .glassCard(cornerRadius: 16)
                                
                                VStack(spacing: 8) {
                                    Text(FormatUtilities.formatSpeed(averageSpeed))
                                        .font(.system(size: 24, weight: .bold, design: .rounded))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [Color.purple, Color.blue],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                    
                                    Text(L("history.stats.averageSpeed"))
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                                .glassCard(cornerRadius: 16)
                            }
                            
                            // Records list
                            VStack(spacing: 12) {
                                ForEach(modeRecords) { record in
                                    TransportRecordRow(record: record)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle(mode.capitalized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L("common.done")) {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func iconForMode(_ mode: String) -> String {
        switch mode.lowercased() {
        case "walking": return "figure.walk"
        case "cycling": return "bicycle"
        case "driving": return "car.fill"
        case "subway": return "tram.fill"
        default: return "figure.walk"
        }
    }
}

struct TransportRecordRow: View {
    let record: JourneyRecord
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(LiquidGlassStyle.primaryGradient)
                    .frame(width: 44, height: 44)
                
                Image(systemName: iconForMode(record.transportMode))
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(record.startLocationName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                
                HStack(spacing: 8) {
                    Text(FormatUtilities.formatDate(record.startTime))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Text(L("common.bullet"))
                        .foregroundColor(.secondary)
                    
                    Text(FormatUtilities.formatTime(record.duration))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(FormatUtilities.formatDistance(record.distanceTraveled))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                if record.duration > 0 {
                    Text(FormatUtilities.formatSpeed(record.distanceTraveled / record.duration))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .glassCard(cornerRadius: 16)
    }
    
    private func iconForMode(_ mode: String) -> String {
        switch mode.lowercased() {
        case "walking": return "figure.walk"
        case "cycling": return "bicycle"
        case "driving": return "car.fill"
        case "subway": return "tram.fill"
        default: return "figure.walk"
        }
    }
}

// MARK: - Record Stat

struct RecordStat: View {
    let icon: String
    let value: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Stat Row

struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Achievement Row

struct AchievementRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Empty State

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "map.fill")
                .font(.system(size: 60))
                .foregroundStyle(LiquidGlassStyle.primaryGradient)
                .opacity(0.5)
            
            Text(L("history.empty.title"))
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)
            
            Text(L("history.empty.message"))
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - Record Detail View

struct RecordDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let record: JourneyRecord
    
    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedGradientBackground()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Status badge
                        HStack {
                            Spacer()
                            
                            HStack(spacing: 8) {
                                Image(systemName: record.isCompleted ? "checkmark.circle.fill" : "pause.circle.fill")
                                    .font(.system(size: 16))
                                
                                Text(record.isCompleted ? L("history.detail.completed") : L("history.detail.stopped"))
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(record.isCompleted ? Color.green : Color.orange)
                            )
                            
                            Spacer()
                        }
                        
                        // Main stats
                        VStack(spacing: 16) {
                            DetailStatCard(
                                icon: "clock.fill",
                                label: L("history.detail.duration"),
                                value: FormatUtilities.formatTime(record.duration),
                                gradient: LiquidGlassStyle.primaryGradient
                            )
                            
                            DetailStatCard(
                                icon: "location.fill",
                                label: L("history.detail.distanceTraveled"),
                                value: FormatUtilities.formatDistance(record.distanceTraveled),
                                gradient: LiquidGlassStyle.accentGradient
                            )
                            
                            DetailStatCard(
                                icon: "gauge.with.dots.needle.67percent",
                                label: L("history.detail.progress"),
                                value: FormatUtilities.formatProgress(record.progress),
                                gradient: LinearGradient(
                                    colors: [Color.blue, Color.purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            
                            DetailStatCard(
                                icon: "star.fill",
                                label: L("history.detail.poisDiscovered"),
                                value: "\(record.discoveredPOICount)",
                                gradient: LinearGradient(
                                    colors: [Color.yellow, Color.orange],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        }
                        
                        // Location info with map preview
                        VStack(alignment: .leading, spacing: 12) {
                            Text(L("history.detail.routeInfo"))
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            // Mini map preview
                            RouteMapPreview(
                                startCoordinate: CLLocationCoordinate2D(
                                    latitude: record.startLatitude,
                                    longitude: record.startLongitude
                                ),
                                endCoordinate: CLLocationCoordinate2D(
                                    latitude: record.destinationLatitude,
                                    longitude: record.destinationLongitude
                                )
                            )
                            .frame(height: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            
                            VStack(spacing: 12) {
                                LocationInfoRow(
                                    icon: "location.circle.fill",
                                    label: L("history.detail.start"),
                                    value: record.startLocationName,
                                    color: .green
                                )
                                
                                LocationInfoRow(
                                    icon: "flag.circle.fill",
                                    label: L("history.detail.destination"),
                                    value: record.destinationName,
                                    color: .red
                                )
                                
                                LocationInfoRow(
                                    icon: iconForTransportMode(record.transportMode),
                                    label: L("history.detail.transport"),
                                    value: localizedTransportMode(record.transportMode),
                                    color: .blue
                                )
                            }
                        }
                        .padding(20)
                        .glassCard(cornerRadius: 20)
                        
                        // Time info
                        VStack(alignment: .leading, spacing: 12) {
                            Text(L("history.detail.timeInfo"))
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            VStack(spacing: 8) {
                                TimeInfoRow(label: L("history.detail.started"), value: FormatUtilities.formatDateTime(record.startTime))
                                TimeInfoRow(label: L("history.detail.ended"), value: FormatUtilities.formatDateTime(record.endTime ?? record.startTime))
                                TimeInfoRow(label: L("history.detail.plannedDuration"), value: FormatUtilities.formatTime(record.plannedDuration))
                            }
                        }
                        .padding(20)
                        .glassCard(cornerRadius: 20)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle(L("history.detail.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L("common.done")) {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func iconForTransportMode(_ mode: String) -> String {
        switch mode.lowercased() {
        case "walking": return "figure.walk.circle.fill"
        case "cycling": return "bicycle.circle.fill"
        case "driving": return "car.circle.fill"
        default: return "figure.walk.circle.fill"
        }
    }
    
    private func localizedTransportMode(_ mode: String) -> String {
        switch mode.lowercased() {
        case "walking": return L("transport.walking")
        case "cycling": return L("transport.cycling")
        case "driving": return L("transport.driving")
        default: return mode.capitalized
        }
    }
}

// MARK: - Route Map Preview

struct RouteMapPreview: View {
    let startCoordinate: CLLocationCoordinate2D
    let endCoordinate: CLLocationCoordinate2D
    
    @State private var cameraPosition: MapCameraPosition = .automatic
    
    var body: some View {
        Map(position: $cameraPosition) {
            // Start marker
            Annotation("", coordinate: startCoordinate) {
                ZStack {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 24, height: 24)
                    
                    Image(systemName: "location.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
                .shadow(color: Color.green.opacity(0.5), radius: 4, x: 0, y: 2)
            }
            
            // End marker
            Annotation("", coordinate: endCoordinate) {
                ZStack {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 24, height: 24)
                    
                    Image(systemName: "flag.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
                .shadow(color: Color.red.opacity(0.5), radius: 4, x: 0, y: 2)
            }
            
            // Route line
            MapPolyline(coordinates: [startCoordinate, endCoordinate])
                .stroke(
                    LinearGradient(
                        colors: [Color.green, Color.blue, Color.red],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [10, 5])
                )
        }
        .mapStyle(AppSettings.shared.selectedMapMode.style)
        .onAppear {
            // Calculate region to show both points
            let centerLat = (startCoordinate.latitude + endCoordinate.latitude) / 2
            let centerLon = (startCoordinate.longitude + endCoordinate.longitude) / 2
            let latDelta = abs(startCoordinate.latitude - endCoordinate.latitude) * 1.5
            let lonDelta = abs(startCoordinate.longitude - endCoordinate.longitude) * 1.5
            
            let span = MKCoordinateSpan(
                latitudeDelta: max(latDelta, 0.05),
                longitudeDelta: max(lonDelta, 0.05)
            )
            
            let region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
                span: span
            )
            
            cameraPosition = .region(region)
        }
    }
}

// MARK: - Detail Stat Card

struct DetailStatCard: View {
    let icon: String
    let label: String
    let value: String
    let gradient: LinearGradient
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(gradient)
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding(16)
        .glassCard(cornerRadius: 16)
    }
}

// MARK: - Location Info Row

struct LocationInfoRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Time Info Row

struct TimeInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Time Distribution Bar

struct TimeDistributionBar: View {
    let morning: Int
    let afternoon: Int
    let evening: Int
    let night: Int
    
    private var total: Int {
        morning + afternoon + evening + night
    }
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 2) {
                if total > 0 {
                    if morning > 0 {
                        Rectangle()
                            .fill(Color.orange)
                            .frame(width: geometry.size.width * CGFloat(morning) / CGFloat(total))
                    }
                    if afternoon > 0 {
                        Rectangle()
                            .fill(Color.yellow)
                            .frame(width: geometry.size.width * CGFloat(afternoon) / CGFloat(total))
                    }
                    if evening > 0 {
                        Rectangle()
                            .fill(Color.pink)
                            .frame(width: geometry.size.width * CGFloat(evening) / CGFloat(total))
                    }
                    if night > 0 {
                        Rectangle()
                            .fill(Color.indigo)
                            .frame(width: geometry.size.width * CGFloat(night) / CGFloat(total))
                    }
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .frame(height: 12)
    }
}

// MARK: - Time Distribution Row

struct TimeDistributionRow: View {
    let icon: String
    let label: String
    let count: Int
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
            
            Spacer()
            
            Text("\(count)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Weekly Activity Chart

struct WeeklyActivityChart: View {
    let data: [(day: String, count: Int)]
    
    private var maxCount: Int {
        data.map { $0.count }.max() ?? 1
    }
    
    private func weekdayLabel(for day: String) -> String {
        // For Chinese: "周日" -> "日", "周一" -> "一"
        if day.hasPrefix("周") {
            return String(day.suffix(1))
        }
        // For English: "Sunday" -> "S", "Monday" -> "M"
        return String(day.prefix(1))
    }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(data, id: \.day) { item in
                VStack(spacing: 6) {
                    ZStack(alignment: .bottom) {
                        // Background bar
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.1))
                            .frame(height: 80)
                        
                        // Actual bar
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: [Color.blue, Color.purple],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                            .frame(height: maxCount > 0 ? CGFloat(item.count) / CGFloat(maxCount) * 80 : 0)
                    }
                    
                    Text(weekdayLabel(for: item.day))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 110)
    }
}

// MARK: - Milestone Row

struct MilestoneRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Milestone Card

struct MilestoneCard: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(color)
            }
            
            // Value
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            // Title & Subtitle
            VStack(spacing: 2) {
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                
                Text(subtitle)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary.opacity(0.8))
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(color.opacity(0.08))
        )
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: JourneyRecord.self, inMemory: true)
}

// MARK: - Time Detail View

struct HistoryMetricRecordRow: View {
    let record: JourneyRecord
    let value: String
    var showChevron: Bool = true

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(colorForTransportMode(record.transportMode).opacity(0.2))
                    .frame(width: 40, height: 40)

                Image(systemName: iconForTransportMode(record.transportMode))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(colorForTransportMode(record.transportMode))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(record.startLocationName.isEmpty ? L("location.current") : record.startLocationName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text("\(FormatUtilities.formatDate(record.startTime)) · \(FormatUtilities.formatTime(record.duration))")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            HStack(spacing: 8) {
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(LiquidGlassStyle.primaryGradient)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .glassCard(cornerRadius: 16)
    }

    private func iconForTransportMode(_ mode: String) -> String {
        switch mode.lowercased() {
        case "walking": return "figure.walk"
        case "cycling": return "bicycle"
        case "driving": return "car.fill"
        case "subway": return "tram.fill"
        default: return "figure.walk"
        }
    }

    private func colorForTransportMode(_ mode: String) -> Color {
        switch mode.lowercased() {
        case "walking": return .green
        case "cycling": return .blue
        case "driving": return .purple
        case "subway": return .orange
        default: return .blue
        }
    }
}

struct TimeDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let records: [JourneyRecord]
    @State private var selectedRecord: JourneyRecord?
    
    private var sortedRecords: [JourneyRecord] {
        records.sorted { $0.duration > $1.duration }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedGradientBackground()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        if sortedRecords.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "clock.fill")
                                    .font(.system(size: 60))
                                    .foregroundStyle(LiquidGlassStyle.primaryGradient)
                                    .opacity(0.5)
                                
                                Text(L("history.time.empty.title"))
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.primary)
                                
                                Text(L("history.time.empty.message"))
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 60)
                        } else {
                            ForEach(sortedRecords) { record in
                                Button {
                                    HapticManager.light()
                                    selectedRecord = record
                                } label: {
                                    HistoryMetricRecordRow(
                                        record: record,
                                        value: FormatUtilities.formatTime(record.duration)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle(L("history.totalTime"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L("common.done")) {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(item: $selectedRecord) { record in
                RecordDetailView(record: record)
            }
        }
    }
}

// MARK: - Distance Detail View

struct DistanceDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let records: [JourneyRecord]
    @State private var selectedRecord: JourneyRecord?
    
    private var sortedRecords: [JourneyRecord] {
        records.sorted { $0.distanceTraveled > $1.distanceTraveled }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedGradientBackground()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        if sortedRecords.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "location.fill")
                                    .font(.system(size: 60))
                                    .foregroundStyle(LiquidGlassStyle.accentGradient)
                                    .opacity(0.5)
                                
                                Text(L("history.distance.empty.title"))
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.primary)
                                
                                Text(L("history.distance.empty.message"))
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 60)
                        } else {
                            ForEach(sortedRecords) { record in
                                Button {
                                    HapticManager.light()
                                    selectedRecord = record
                                } label: {
                                    HistoryMetricRecordRow(
                                        record: record,
                                        value: FormatUtilities.formatDistance(record.distanceTraveled)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle(L("history.totalDistance"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L("common.done")) {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(item: $selectedRecord) { record in
                RecordDetailView(record: record)
            }
        }
    }
}

// MARK: - Completed Detail View

struct CompletedDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let records: [JourneyRecord]
    @State private var selectedRecord: JourneyRecord?
    
    private var sortedRecords: [JourneyRecord] {
        records.sorted { $0.startTime > $1.startTime }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedGradientBackground()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        if sortedRecords.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "flag.checkered")
                                    .font(.system(size: 60))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color.green, Color.green.opacity(0.7)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .opacity(0.5)
                                
                                Text(L("history.completed.empty.title"))
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.primary)
                                
                                Text(L("history.completed.empty.message"))
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 60)
                        } else {
                            ForEach(sortedRecords) { record in
                                Button {
                                    HapticManager.light()
                                    selectedRecord = record
                                } label: {
                                    HistoryMetricRecordRow(
                                        record: record,
                                        value: FormatUtilities.formatProgress(record.progress)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle(L("history.completed"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L("common.done")) {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(item: $selectedRecord) { record in
                RecordDetailView(record: record)
            }
        }
    }
}

// MARK: - POIs Detail View

struct POIsDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let records: [JourneyRecord]
    @State private var selectedPOI: RecordPOIItem?
    @State private var selectedRecord: JourneyRecord?

    private var poiItems: [RecordPOIItem] {
        records.flatMap { record in
            record.discoveredPOIs.map { poi in
                RecordPOIItem(record: record, poi: poi)
            }
        }
        .sorted { $0.poi.discoveredAt > $1.poi.discoveredAt }
    }

    private var fallbackRecordsWithPOIs: [JourneyRecord] {
        records.filter { $0.discoveredPOICount > 0 }
            .sorted { $0.discoveredPOICount > $1.discoveredPOICount }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedGradientBackground()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        if poiItems.isEmpty && fallbackRecordsWithPOIs.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 60))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color.yellow, Color.orange],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .opacity(0.5)
                                
                                Text(L("history.poi.empty.title"))
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.primary)
                                
                                Text(L("history.poi.empty.message"))
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 60)
                        } else if !poiItems.isEmpty {
                            ForEach(poiItems) { item in
                                Button {
                                    HapticManager.light()
                                    selectedPOI = item
                                } label: {
                                    HistoryPOIRow(item: item)
                                }
                                .buttonStyle(.plain)
                            }
                        } else {
                            // Older records may only have POI count without POI details.
                            ForEach(fallbackRecordsWithPOIs) { record in
                                Button {
                                    HapticManager.light()
                                    selectedRecord = record
                                } label: {
                                    HistoryMetricRecordRow(
                                        record: record,
                                        value: "\(record.discoveredPOICount)"
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle(L("history.poisFound"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L("common.done")) {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(item: $selectedPOI) { item in
                POIItemDetailView(item: item)
            }
            .sheet(item: $selectedRecord) { record in
                RecordDetailView(record: record)
            }
        }
    }
}

struct RecordPOIItem: Identifiable {
    let record: JourneyRecord
    let poi: StoredDiscoveredPOI

    var id: UUID {
        poi.id
    }
}

struct HistoryPOIRow: View {
    let item: RecordPOIItem

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.yellow.opacity(0.2))
                    .frame(width: 40, height: 40)

                Image(systemName: "star.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.yellow)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.poi.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text(item.poi.category)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .padding(16)
        .glassCard(cornerRadius: 16)
    }
}

struct POIItemDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let item: RecordPOIItem
    @State private var cameraPosition: MapCameraPosition = .automatic

    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedGradientBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        Map(position: $cameraPosition) {
                            Annotation(item.poi.name, coordinate: item.poi.coordinate) {
                                ZStack {
                                    Circle()
                                        .fill(Color.yellow)
                                        .frame(width: 28, height: 28)
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .frame(height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )

                        VStack(spacing: 12) {
                            HistoryPOIDetailRow(icon: "star.fill", label: L("poi.title"), value: item.poi.name, color: .yellow)
                            HistoryPOIDetailRow(icon: "tag.fill", label: L("common.category"), value: item.poi.category, color: .orange)
                            HistoryPOIDetailRow(icon: "clock.fill", label: L("history.detail.started"), value: FormatUtilities.formatDateTime(item.poi.discoveredAt), color: .blue)
                            HistoryPOIDetailRow(icon: "location.fill", label: L("history.detail.start"), value: item.record.startLocationName.isEmpty ? L("location.current") : item.record.startLocationName, color: .green)
                        }
                        .padding(20)
                        .glassCard(cornerRadius: 20)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle(item.poi.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L("common.done")) {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                cameraPosition = .region(
                    MKCoordinateRegion(
                        center: item.poi.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )
                )
            }
        }
    }
}

struct HistoryPOIDetailRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
            }
            Spacer()
        }
    }
}

// MARK: - Achievement Detail View

struct AchievementDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    let icon: String
    let color: Color
    let records: [JourneyRecord]
    
    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedGradientBackground()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Achievement header
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(
                                        RadialGradient(
                                            colors: [color.opacity(0.3), color.opacity(0.1)],
                                            center: .center,
                                            startRadius: 0,
                                            endRadius: 60
                                        )
                                    )
                                    .frame(width: 120, height: 120)
                                
                                Circle()
                                    .fill(color)
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: icon)
                                    .font(.system(size: 36, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            .shadow(color: color.opacity(0.3), radius: 20, x: 0, y: 10)
                            
                            Text(title)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, 20)
                        
                        if records.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: icon)
                                    .font(.system(size: 60))
                                    .foregroundColor(color)
                                    .opacity(0.5)
                                
                                Text(L("history.achievement.empty.title"))
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.primary)
                                
                                Text(L("history.achievement.empty.message"))
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            // Achievement value
                            if let record = records.first {
                                VStack(spacing: 12) {
                                    Text(achievementValue(for: record))
                                        .font(.system(size: 48, weight: .bold, design: .rounded))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [color, color.opacity(0.7)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                    
                                    Text(achievementSubtitle())
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 24)
                                .glassCard(cornerRadius: 20)
                            }
                            
                            // Journey details
                            VStack(alignment: .leading, spacing: 12) {
                                Text(L("history.detail.journeyDetails"))
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                ForEach(records) { record in
                                    AchievementRecordCard(record: record, highlightColor: color)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L("common.done")) {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func achievementValue(for record: JourneyRecord) -> String {
        if title.contains(L("history.longestJourney")) {
            return FormatUtilities.formatTime(record.duration)
        } else if title.contains(L("history.farthestDistance")) {
            return FormatUtilities.formatDistance(record.distanceTraveled)
        } else if title.contains(L("history.mostPOIs")) {
            return "\(record.discoveredPOICount)"
        } else if title.contains(L("history.stats.fastestJourney")) {
            let speed = record.duration > 0 ? record.distanceTraveled / record.duration : 0
            return FormatUtilities.formatSpeed(speed)
        }
        return ""
    }
    
    private func achievementSubtitle() -> String {
        if title.contains(L("history.longestJourney")) {
            return "Longest Focus Session"
        } else if title.contains(L("history.farthestDistance")) {
            return "Farthest Journey"
        } else if title.contains(L("history.mostPOIs")) {
            return "Most POIs Discovered"
        } else if title.contains(L("history.stats.fastestJourney")) {
            return "Fastest Average Speed"
        }
        return ""
    }
}

struct AchievementStatItem: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}
