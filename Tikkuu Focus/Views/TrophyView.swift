//
//  TrophyView.swift
//  Tikkuu Focus
//
//  Created by Tikkuu on 2026/2/8.
//

import SwiftUI
import SwiftData

struct TrophyView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \JourneyRecord.startTime, order: .reverse) private var records: [JourneyRecord]
    @StateObject private var trophyManager = TrophyManager()
    @ObservedObject private var settings = AppSettings.shared
    
    @State private var selectedCategory: TrophyCategory? = nil
    @State private var selectedTrophy: Trophy? = nil
    @State private var showTrophyDetail = false
    @State private var isLoading = true
    @State private var previousCategory: TrophyCategory? = nil
    @State private var scrollToTopTrigger = UUID()
    
    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedGradientBackground()
                
                if isLoading {
                    // Loading view
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.primary)
                        
                        Text(L("trophy.loading"))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                } else {
                    VStack(spacing: 0) {
                        // Progress overview
                        progressOverview
                            .padding(.horizontal, 24)
                            .padding(.top, 16)
                            .padding(.bottom, 16)
                        
                        // Category filter
                        categoryFilter
                            .padding(.horizontal, 24)
                            .padding(.bottom, 16)
                        
                        // Trophy grid
                        ScrollViewReader { proxy in
                            ScrollView(showsIndicators: false) {
                                LazyVGrid(columns: [
                                    GridItem(.flexible(), spacing: 12),
                                    GridItem(.flexible(), spacing: 12)
                                ], spacing: 12) {
                                    ForEach(filteredTrophies) { trophy in
                                        TrophyCard(trophy: trophy)
                                            .id(trophy.id)
                                            .onTapGesture {
                                                HapticManager.light()
                                                // Ensure trophy data is valid before showing detail
                                                if !trophy.localizedTitle.isEmpty && !trophy.localizedDescription.isEmpty {
                                                    selectedTrophy = trophy
                                                    showTrophyDetail = true
                                                }
                                            }
                                    }
                                }
                                .padding(.horizontal, 24)
                                .padding(.bottom, 40)
                                .id("trophyGridTop")
                            }
                            .onChange(of: scrollToTopTrigger) { _, _ in
                                withAnimation(.easeOut(duration: 0.3)) {
                                    proxy.scrollTo("trophyGridTop", anchor: .top)
                                }
                            }
                        }
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
            .navigationTitle(L("trophy.title"))
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
        .preferredColorScheme(settings.currentColorScheme)
        .onAppear {
            loadTrophies()
        }
        .onChange(of: records.count) { _, _ in
            Task {
                await updateTrophiesAsync()
            }
        }
        .sheet(isPresented: $showTrophyDetail) {
            if let trophy = selectedTrophy {
                NavigationStack {
                    TrophyDetailView(trophy: trophy)
                        .navigationTitle(L("trophy.detail"))
                        .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button(L("common.done")) {
                                    showTrophyDetail = false
                                }
                                .fontWeight(.semibold)
                            }
                        }
                }
                .presentationDragIndicator(.hidden)
                .interactiveDismissDisabled(false)
            } else {
                // Fallback view if trophy is nil
                NavigationStack {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        
                        Text(L("trophy.notFound"))
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AnimatedGradientBackground())
                    .navigationTitle(L("trophy.detail"))
                    .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button(L("common.done")) {
                                showTrophyDetail = false
                                selectedTrophy = nil
                            }
                            .fontWeight(.semibold)
                        }
                    }
                }
            }
        }
        .onChange(of: showTrophyDetail) { _, newValue in
            // Clear selected trophy when sheet is dismissed
            if !newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    selectedTrophy = nil
                }
            }
        }
    }
    
    // MARK: - Loading
    
    private func loadTrophies() {
        Task {
            // Ensure we're on main thread
            await MainActor.run {
                // Update trophies synchronously first
                trophyManager.updateProgress(with: records)
            }
            
            // Small delay to ensure UI is ready
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.3)) {
                    isLoading = false
                }
            }
        }
    }
    
    private func updateTrophiesAsync() async {
        trophyManager.updateProgress(with: records)
    }
    
    // MARK: - Progress Overview
    
    private var progressOverview: some View {
        VStack(spacing: 12) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [Color.yellow, Color.orange],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * trophyManager.unlockedPercentage)
                }
            }
            .frame(height: 12)
            
            // Stats
            HStack(spacing: 16) {
                StatBadge(
                    icon: "trophy.fill",
                    value: "\(trophyManager.unlockedCount)",
                    label: L("trophy.unlocked.short"),
                    color: .yellow
                )
                
                StatBadge(
                    icon: "lock.fill",
                    value: "\(trophyManager.totalCount - trophyManager.unlockedCount)",
                    label: L("trophy.locked"),
                    color: .gray
                )
                
                StatBadge(
                    icon: "percent",
                    value: "\(Int(trophyManager.unlockedPercentage * 100))%",
                    label: L("trophy.completion"),
                    color: .blue
                )
            }
        }
        .padding(16)
        .glassCard(cornerRadius: 16)
    }
    
    // MARK: - Category Filter
    
    private var slideDirection: Edge {
        // Determine slide direction based on category order
        let allCategories: [TrophyCategory?] = [nil] + TrophyCategory.allCases.map { $0 as TrophyCategory? }
        
        guard let currentIndex = allCategories.firstIndex(where: { $0 == selectedCategory }),
              let previousIndex = allCategories.firstIndex(where: { $0 == previousCategory }) else {
            return .trailing
        }
        
        return currentIndex > previousIndex ? .trailing : .leading
    }
    
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // All categories button
                CategoryButton(
                    icon: "square.grid.2x2.fill",
                    label: L("trophy.category.all"),
                    isSelected: selectedCategory == nil
                ) {
                    HapticManager.selection()
                    previousCategory = selectedCategory
                    selectedCategory = nil
                    scrollToTopTrigger = UUID()
                }
                
                ForEach(TrophyCategory.allCases, id: \.self) { category in
                    CategoryButton(
                        icon: category.icon,
                        label: category.localizedName,
                        isSelected: selectedCategory == category
                    ) {
                        HapticManager.selection()
                        previousCategory = selectedCategory
                        selectedCategory = category
                        scrollToTopTrigger = UUID()
                    }
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 4)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 6)
        .background {
            if settings.selectedVisualStyle == .neumorphism {
                NeumorphSurface(cornerRadius: 18, depth: .inset)
            } else {
                Color.clear
            }
        }
    }
    
    // MARK: - Filtered Trophies
    
    private var filteredTrophies: [Trophy] {
        if let category = selectedCategory {
            return trophyManager.trophies.filter { $0.category == category }
        }
        return trophyManager.trophies
    }
}

// MARK: - Trophy Card

struct TrophyCard: View {
    let trophy: Trophy
    
    var body: some View {
        VStack(spacing: 12) {
            // Trophy icon - fixed size
            ZStack {
                Circle()
                    .fill(
                        trophy.isUnlocked
                        ? LinearGradient(
                            colors: [trophy.color, trophy.color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        : LinearGradient(
                            colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                
                Image(systemName: trophy.icon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(trophy.isUnlocked ? .white : .gray)
            }
            .frame(height: 60) // Fixed height
            .shadow(color: trophy.isUnlocked ? trophy.color.opacity(0.3) : Color.clear, radius: 10, x: 0, y: 5)
            
            // Trophy info - fixed size
            VStack(spacing: 4) {
                Text(trophy.localizedTitle)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .frame(height: 32) // Fixed height for title
                
                Text(trophy.tier.localizedName)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(trophy.isUnlocked ? trophy.color : .secondary)
                    .frame(height: 14) // Fixed height for tier
            }
            .frame(height: 50) // Fixed total height for info section
            
            // Progress section - fixed height and width
            VStack(spacing: 4) {
                // Progress bar or spacer - always same height
                ZStack {
                    if !trophy.isUnlocked {
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.gray.opacity(0.2))
                                
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(trophy.color)
                                    .frame(width: geometry.size.width * trophy.progressPercentage)
                            }
                        }
                    } else {
                        // Empty spacer for unlocked trophies
                        Rectangle()
                            .fill(Color.clear)
                    }
                }
                .frame(height: 6) // Fixed height for progress bar
                
                // Text - always same height
                Text(progressText)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(height: 12) // Fixed height for text
                    .lineLimit(1)
            }
            .frame(height: 22) // Fixed total height for progress section
        }
        .frame(maxWidth: .infinity) // Fill available width
        .frame(height: 180) // Fixed total height
        .padding(16)
        .glassCard(cornerRadius: 16)
        .opacity(trophy.isUnlocked ? 1.0 : 0.7)
    }
    
    private var progressText: String {
        if !trophy.isUnlocked {
            return "\(trophy.progress) / \(trophy.requirement)"
        } else if let date = trophy.unlockedDate {
            return FormatUtilities.formatDate(date)
        } else {
            return " "
        }
    }
}

// MARK: - Stat Badge

struct StatBadge: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Category Button

struct CategoryButton: View {
    @ObservedObject private var settings = AppSettings.shared
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void

    private var isLightTone: Bool {
        settings.selectedNeumorphismTone == .light
    }

    private var selectedTextColor: Color {
        isLightTone ? Color(red: 0.20, green: 0.24, blue: 0.34) : .white
    }

    private var unselectedTextColor: Color {
        isLightTone ? Color(red: 0.42, green: 0.46, blue: 0.54) : .white.opacity(0.72)
    }

    private var selectedFill: AnyShapeStyle {
        let baseColor = isLightTone
            ? Color(red: 0.70, green: 0.80, blue: 0.97)
            : Color(red: 0.40, green: 0.54, blue: 0.90)
        return AnyShapeStyle(baseColor.opacity(isLightTone ? 0.95 : 0.78))
    }

    private var unselectedShadowColor: Color {
        isLightTone ? Color.black.opacity(0.07) : Color.black.opacity(0.22)
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                
                Text(label)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(isSelected ? selectedTextColor : unselectedTextColor)
            .padding(.horizontal, 15)
            .padding(.vertical, 9)
            .background {
                if settings.selectedVisualStyle == .neumorphism {
                    NeumorphSurface(
                        cornerRadius: 999,
                        depth: isSelected ? .raised : .inset,
                        fill: isSelected ? selectedFill : nil
                    )
                } else {
                    // Liquid Glass: highlight color when selected, subtle border when not
                    Capsule()
                        .fill(isSelected ? Color.white.opacity(0.25) : Color.clear)
                        .overlay(
                            Capsule()
                                .stroke(isSelected ? Color.white.opacity(0.4) : Color.primary.opacity(0.25), lineWidth: 1.5)
                        )
                }
            }
            .overlay {
                if settings.selectedVisualStyle == .neumorphism && isSelected {
                    Capsule()
                        .stroke(
                            Color.white.opacity(isLightTone ? 0.44 : 0.20),
                            lineWidth: 0.8
                        )
                }
            }
            .shadow(
                color: settings.selectedVisualStyle == .neumorphism && !isSelected ? unselectedShadowColor : .clear,
                radius: settings.selectedVisualStyle == .neumorphism && !isSelected ? 4 : 0,
                x: 0,
                y: settings.selectedVisualStyle == .neumorphism && !isSelected ? 2 : 0
            )
        }
    }
}

// MARK: - Trophy Detail View

struct TrophyDetailView: View {
    @ObservedObject private var settings = AppSettings.shared
    let trophy: Trophy
    @State private var isLoaded = false
    
    var body: some View {
        ZStack {
            AnimatedGradientBackground()
            
            if isLoaded {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        // Trophy icon with animation
                        trophyIconSection
                        
                        // Trophy info
                        trophyInfoSection
                        
                        // Progress or unlock info
                        if trophy.isUnlocked {
                            unlockedSection
                        } else {
                            progressSection
                        }
                        
                        // Description
                        descriptionSection
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
                .transition(.opacity)
            } else {
                // Loading state
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.primary)
            }
        }
        .preferredColorScheme(settings.currentColorScheme)
        .onAppear {
            // Small delay to ensure smooth presentation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeOut(duration: 0.2)) {
                    isLoaded = true
                }
            }
        }
    }
    
    // MARK: - Trophy Icon Section
    
    private var trophyIconSection: some View {
        ZStack {
            // Glow effect
            Circle()
                .fill(
                    RadialGradient(
                        colors: trophy.isUnlocked
                            ? [trophy.color.opacity(0.3), trophy.color.opacity(0)]
                            : [Color.gray.opacity(0.2), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 100
                    )
                )
                .frame(width: 200, height: 200)
            
            // Trophy circle
            Circle()
                .fill(
                    trophy.isUnlocked
                    ? LinearGradient(
                        colors: [trophy.color, trophy.color.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    : LinearGradient(
                        colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 140, height: 140)
                .shadow(color: trophy.isUnlocked ? trophy.color.opacity(0.5) : Color.clear, radius: 20, x: 0, y: 10)
            
            // Trophy icon
            Image(systemName: trophy.icon)
                .font(.system(size: 70, weight: .semibold))
                .foregroundColor(.white)
        }
        .padding(.top, 20)
    }
    
    // MARK: - Trophy Info Section
    
    private var trophyInfoSection: some View {
        VStack(spacing: 12) {
            // Title
            Text(trophy.localizedTitle)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
            
            // Tier badge
            HStack(spacing: 8) {
                Image(systemName: trophy.tier.icon)
                    .font(.system(size: 14, weight: .semibold))
                
                Text(trophy.tier.localizedName)
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background {
                if settings.selectedVisualStyle == .neumorphism {
                    NeumorphSurface(
                        cornerRadius: 999,
                        depth: .raised,
                        fill: trophy.isUnlocked ? AnyShapeStyle(trophy.color) : AnyShapeStyle(Color.gray.opacity(0.5))
                    )
                } else {
                    Capsule()
                        .fill(trophy.isUnlocked ? trophy.color : Color.gray)
                }
            }
            .shadow(color: trophy.isUnlocked ? trophy.color.opacity(0.3) : Color.clear, radius: 8, x: 0, y: 4)
            
            // Category
            Text(trophy.category.localizedName)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Unlocked Section
    
    private var unlockedSection: some View {
        VStack(spacing: 16) {
            // Unlocked badge
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.green)
                
                Text(L("trophy.status.unlocked"))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background {
                if settings.selectedVisualStyle == .neumorphism {
                    NeumorphSurface(cornerRadius: 12, depth: .inset)
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.green.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.green.opacity(0.3), lineWidth: 2)
                        )
                }
            }
            
            // Unlock date
            if let date = trophy.unlockedDate {
                VStack(spacing: 8) {
                    Text(L("trophy.unlockedOn"))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Text(FormatUtilities.formatDateTime(date))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                }
                .padding(16)
                .frame(maxWidth: .infinity)
                .glassCard(cornerRadius: 16)
            }
        }
    }
    
    // MARK: - Progress Section
    
    private var progressSection: some View {
        VStack(spacing: 16) {
            // Progress title
            Text(L("trophy.progress"))
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
            
            // Progress bar
            VStack(spacing: 12) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.2))
                        
                        RoundedRectangle(cornerRadius: 8)
                            .fill(trophy.color)
                            .frame(width: geometry.size.width * trophy.progressPercentage)
                    }
                }
                .frame(height: 16)
                
                // Progress text
                HStack {
                    Text("\(trophy.progress)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("/")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Text("\(trophy.requirement)")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                
                Text("\(Int(trophy.progressPercentage * 100))% " + L("trophy.complete"))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(20)
            .glassCard(cornerRadius: 16)
        }
    }
    
    // MARK: - Description Section
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L("trophy.requirement"))
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
            
            Text(trophy.localizedDescription)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.secondary)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .glassCard(cornerRadius: 16)
    }
}

#Preview {
    TrophyView()
        .modelContainer(for: JourneyRecord.self, inMemory: true)
}
