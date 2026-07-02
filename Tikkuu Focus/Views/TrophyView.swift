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
    @StateObject private var trophyInbox = TrophyInboxStore.shared
    @ObservedObject private var settings = AppSettings.shared
    
    @State private var selectedCategory: TrophyCategory? = nil
    @State private var selectedTrophy: Trophy? = nil
    @State private var showTrophyDetail = false
    @State private var isLoading = true
    @State private var scrollToTopTrigger = UUID()
    @State private var isProgressCollapsed = false
    @State private var lastScrollOffset: CGFloat = 0
    @State private var hasCapturedInitialOffset = false
    @State private var cachedFilteredTrophies: [Trophy] = []
    @State private var gridRenderID = UUID()
    @State private var trophyLoadTask: Task<Void, Never>?
    @State private var showInbox = false
    
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
                    ScrollViewReader { proxy in
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 16) {
                                progressOverview
                                categoryFilter
                                selectedCategorySummary
                                trophyList
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                            .padding(.bottom, 36)
                            .id(gridRenderID)
                        }
                        .onChange(of: scrollToTopTrigger) { _, _ in
                            withAnimation(.easeOut(duration: 0.28)) {
                                proxy.scrollTo(gridRenderID, anchor: .top)
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
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        HapticManager.light()
                        showInbox = true
                    } label: {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "bell.fill")
                            if trophyInbox.unreadCount > 0 {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 8, height: 8)
                                    .offset(x: 5, y: -4)
                            }
                        }
                    }
                    .accessibilityLabel(L("trophy.inbox.title"))
                }
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
            scheduleTrophyLoad()
        }
        .onChange(of: records.count) { _, _ in
            scheduleTrophyLoad()
        }
        .onChange(of: selectedCategory) { _, _ in
            refreshFilteredTrophies()
            let update = {
                gridRenderID = UUID()
            }
            if PerformanceConfig.shouldReduceVisualEffects {
                update()
            } else {
                withAnimation(AnimationConfig.tabSwitch) {
                    update()
                }
            }
        }
        .onChange(of: trophyManager.trophies.count) { _, _ in
            refreshFilteredTrophies()
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
        .sheet(isPresented: $showInbox) {
            TrophyInboxView(messages: trophyInbox.messages)
                .onAppear {
                    trophyInbox.markAllRead()
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
        .onDisappear {
            trophyLoadTask?.cancel()
            trophyLoadTask = nil
        }
    }
    
    // MARK: - Loading
    
    private func scheduleTrophyLoad() {
        trophyLoadTask?.cancel()
        trophyLoadTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 120_000_000)
            guard !Task.isCancelled else { return }
            loadTrophies()
        }
    }

    private func loadTrophies() {
        trophyManager.updateProgress(with: records)
        refreshFilteredTrophies()
        let update = {
            isLoading = false
        }
        if PerformanceConfig.shouldReduceVisualEffects {
            update()
        } else {
            withAnimation(AnimationConfig.standardEase) {
                update()
            }
        }
    }
    
    // MARK: - Progress Overview
    
    private var progressOverview: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.13), lineWidth: 10)
                Circle()
                    .trim(from: 0, to: trophyManager.unlockedPercentage)
                    .stroke(
                        LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 2) {
                    Text("\(Int(trophyManager.unlockedPercentage * 100))%")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Text(L("trophy.completion"))
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 92, height: 92)

            VStack(alignment: .leading, spacing: 12) {
                Text(L("trophy.title"))
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                Text(String(format: L("trophy.unlocked"), trophyManager.unlockedCount, trophyManager.totalCount))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)

                HStack(spacing: 8) {
                    CompactTrophyStat(icon: "trophy.fill", value: "\(trophyManager.unlockedCount)", tint: .yellow)
                    CompactTrophyStat(icon: "lock.fill", value: "\(trophyManager.totalCount - trophyManager.unlockedCount)", tint: .secondary)
                    if let nextLockedTrophy {
                        Text(nextLockedTrophy.localizedTitle)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(Color.white.opacity(0.08)))
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .glassCard(cornerRadius: 24)
    }

    // MARK: - Category Filter
    
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
                        selectedCategory = category
                        scrollToTopTrigger = UUID()
                    }
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 4)
        }
        .padding(8)
        .glassCard(cornerRadius: 24, tintColor: Color.indigo.opacity(0.45))
    }

    private var selectedCategorySummary: some View {
        let trophies = cachedFilteredTrophies
        let unlocked = trophies.filter(\.isUnlocked).count
        let total = max(trophies.count, 1)
        return HStack(spacing: 12) {
            Image(systemName: selectedCategory?.icon ?? "square.grid.2x2.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(LiquidGlassStyle.primaryGradient)
                .frame(width: 42, height: 42)
                .background(Circle().fill(Color.white.opacity(0.09)))

            VStack(alignment: .leading, spacing: 4) {
                Text(selectedCategory?.localizedName ?? L("trophy.category.all"))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                Text("\(unlocked) / \(trophies.count) · \(Int(Double(unlocked) / Double(total) * 100))%")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.secondary)
            }

            Spacer()

            if let closest = trophies.filter({ !$0.isUnlocked }).max(by: { $0.progressPercentage < $1.progressPercentage }) {
                VStack(alignment: .trailing, spacing: 4) {
                    Text(L("trophy.next"))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                    Text(closest.localizedTitle)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }
            }
        }
        .padding(14)
        .glassCard(cornerRadius: 22)
    }

    private var trophyList: some View {
        LazyVStack(spacing: 10) {
            if cachedFilteredTrophies.isEmpty {
                VStack(spacing: 14) {
                    Image(systemName: "trophy")
                        .font(.system(size: 38, weight: .semibold))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text(L("trophy.empty.category"))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 50)
                .glassCard(cornerRadius: 24)
            } else {
                ForEach(Array(cachedFilteredTrophies.enumerated()), id: \.element.id) { index, trophy in
                    Button {
                        HapticManager.light()
                        selectedTrophy = trophy
                        showTrophyDetail = true
                    } label: {
                        TrophyRowCard(trophy: trophy)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .modifier(ConditionalStaggerModifier(index: min(index, 10)))
                }
            }
        }
    }
    
    // MARK: - Filtered Trophies
    
    private func refreshFilteredTrophies() {
        if let category = selectedCategory {
            cachedFilteredTrophies = sortedTrophies(trophyManager.trophies.filter { $0.category == category })
        } else {
            cachedFilteredTrophies = sortedTrophies(trophyManager.trophies)
        }
    }

    private func sortedTrophies(_ trophies: [Trophy]) -> [Trophy] {
        trophies.sorted {
            if $0.isUnlocked != $1.isUnlocked {
                return $0.isUnlocked && !$1.isUnlocked
            }
            if $0.category != $1.category {
                return $0.category.rawValue < $1.category.rawValue
            }
            if $0.tier != $1.tier {
                return $0.tier.sortOrder < $1.tier.sortOrder
            }
            return $0.requirement < $1.requirement
        }
    }

    private var nextLockedTrophy: Trophy? {
        trophyManager.trophies
            .filter { !$0.isUnlocked }
            .max { $0.progressPercentage < $1.progressPercentage }
    }
}

// MARK: - Conditional Stagger Modifier

private struct ConditionalStaggerModifier: ViewModifier {
    let index: Int
    
    func body(content: Content) -> some View {
        if PerformanceConfig.enableComplexAnimations {
            content.staggeredAppearance(index: index)
        } else {
            content
        }
    }
}

private struct TrophyScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private struct CompactTrophyStat: View {
    let icon: String
    let value: String
    let tint: Color

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
            Text(value)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .monospacedDigit()
        }
        .foregroundColor(tint)
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(Capsule().fill(Color.white.opacity(0.08)))
    }
}

private struct TrophyRowCard: View {
    let trophy: Trophy

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        trophy.isUnlocked
                        ? LinearGradient(colors: [trophy.color, trophy.color.opacity(0.62)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        : LinearGradient(colors: [Color.white.opacity(0.12), Color.white.opacity(0.04)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 54, height: 54)

                Image(systemName: trophy.icon)
                    .font(.system(size: 23, weight: .semibold))
                    .foregroundColor(trophy.isUnlocked ? .white : .secondary)
            }

            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 7) {
                    Text(trophy.localizedTitle)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Text(trophy.tier.localizedName)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(trophy.isUnlocked ? trophy.color : .secondary)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Capsule().fill((trophy.isUnlocked ? trophy.color : Color.white).opacity(0.12)))
                }

                Text(trophy.localizedDescription)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.10))
                            Capsule()
                                .fill(trophy.isUnlocked ? trophy.color : trophy.color.opacity(0.78))
                                .frame(width: max(proxy.size.width * trophy.progressPercentage, trophy.progressPercentage > 0 ? 5 : 0))
                        }
                    }
                    .frame(height: 6)

                    Text(progressText)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(trophy.isUnlocked ? trophy.color : .secondary)
                        .monospacedDigit()
                        .frame(minWidth: 58, alignment: .trailing)
                }
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.secondary.opacity(0.55))
        }
        .padding(14)
        .glassCard(cornerRadius: 22)
        .opacity(trophy.isUnlocked ? 1 : 0.76)
    }

    private var progressText: String {
        if trophy.isUnlocked {
            return L("trophy.done")
        }
        return "\(min(trophy.progress, trophy.requirement))/\(trophy.requirement)"
    }
}

// MARK: - Trophy Card

struct TrophyCard: View {
    let trophy: Trophy
    @State private var animatedProgress: CGFloat = 0
    
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
            .shadow(
                color: !PerformanceConfig.shouldReduceVisualEffects && trophy.isUnlocked ? trophy.color.opacity(0.3) : Color.clear,
                radius: 10,
                x: 0,
                y: 5
            )
            
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
                                    .frame(width: geometry.size.width * animatedProgress)
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
        .glassCard(cornerRadius: 24)
        .opacity(trophy.isUnlocked ? 1.0 : 0.7)
        .onAppear {
            if PerformanceConfig.enableComplexAnimations {
                withAnimation(AnimationConfig.smoothSpring.delay(0.15)) {
                    animatedProgress = trophy.progressPercentage
                }
            } else {
                animatedProgress = trophy.progressPercentage
            }
        }
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
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
            
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Trophy Inbox

struct TrophyInboxView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var settings = AppSettings.shared
    let messages: [TrophyUnlockMessage]

    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedGradientBackground()

                if messages.isEmpty {
                    VStack(spacing: 14) {
                        Image(systemName: "bell")
                            .font(.system(size: 40, weight: .semibold))
                            .foregroundColor(.secondary)
                        Text(L("trophy.inbox.empty"))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 12) {
                            ForEach(messages) { message in
                                TrophyMessageRow(message: message)
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle(L("trophy.inbox.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L("common.done")) { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
        .preferredColorScheme(settings.currentColorScheme)
    }
}

private struct TrophyMessageRow: View {
    let message: TrophyUnlockMessage

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.yellow)
                .frame(width: 44, height: 44)
                .background(Circle().fill(Color.yellow.opacity(0.16)))

            VStack(alignment: .leading, spacing: 5) {
                Text(message.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                Text(message.detail)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                Text(FormatUtilities.formatDate(message.unlockedAt))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary.opacity(0.8))
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .glassCard(cornerRadius: 22)
    }
}

// MARK: - Category Button

struct CategoryButton: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                
                Text(label)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(isSelected ? .white : .white.opacity(0.78))
            .padding(.horizontal, 15)
            .padding(.vertical, 9)
            .insetSurface(cornerRadius: 999, isActive: isSelected)
        }
        .buttonStyle(PremiumButtonStyle())
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
            if trophy.isUnlocked {
                HapticManager.success()
            }
            withAnimation(AnimationConfig.smoothSpring) {
                isLoaded = true
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
                .font(.system(size: 28, weight: .semibold, design: .rounded))
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
                Capsule()
                    .fill(trophy.isUnlocked ? trophy.color : Color.gray)
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
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.green.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.green.opacity(0.3), lineWidth: 2)
                    )
            }
            
            // Unlock date
            if let date = trophy.unlockedDate {
                VStack(spacing: 8) {
                    Text(L("trophy.unlockedOn"))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Text(FormatUtilities.formatDateTime(date))
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                }
                .padding(16)
                .frame(maxWidth: .infinity)
                .glassCard(cornerRadius: 24)
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
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
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
            .glassCard(cornerRadius: 24)
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
        .glassCard(cornerRadius: 24)
    }
}

#Preview {
    TrophyView()
        .modelContainer(for: JourneyRecord.self, inMemory: true)
}
