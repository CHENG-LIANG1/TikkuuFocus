//
//  HistoryStatCards.swift
//  Tikkuu Focus
//
//  Created by Tikkuu on 2026/2/10.
//

import SwiftUI

// MARK: - Overview Stats Grid

struct OverviewStatsGrid: View {
    let totalTime: TimeInterval
    let totalDistance: Double
    let completedCount: Int
    let totalPOIs: Int
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            StatCard(
                icon: "clock.fill",
                title: L("history.totalTime"),
                value: FormatUtilities.formatTime(totalTime),
                color: .blue,
                gradient: GradientStyles.primaryGradient
            )
            
            StatCard(
                icon: "location.fill",
                title: L("history.totalDistance"),
                value: FormatUtilities.formatDistance(totalDistance),
                color: .orange,
                gradient: GradientStyles.accentGradient
            )
            
            StatCard(
                icon: "checkmark.circle.fill",
                title: L("history.completed"),
                value: "\(completedCount)",
                color: .green,
                gradient: GradientStyles.successGradient
            )
            
            StatCard(
                icon: "star.fill",
                title: L("history.poisFound"),
                value: "\(totalPOIs)",
                color: .yellow,
                gradient: GradientStyles.warningGradient
            )
        }
    }
}

// MARK: - Achievement Cards Grid

struct AchievementCardsGrid: View {
    let longestJourney: JourneyRecord?
    let farthestDistance: JourneyRecord?
    let mostPOIs: JourneyRecord?
    let fastestSpeed: JourneyRecord?
    let onTapLongest: () -> Void
    let onTapFarthest: () -> Void
    let onTapMostPOIs: () -> Void
    let onTapFastest: () -> Void
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            AchievementCard(
                icon: "clock.fill",
                title: L("history.longestJourney"),
                value: longestJourney != nil ? FormatUtilities.formatTime(longestJourney!.duration) : "—",
                color: .blue,
                hasData: longestJourney != nil
            )
            .onTapGesture {
                if longestJourney != nil {
                    HapticManager.light()
                    onTapLongest()
                }
            }
            
            AchievementCard(
                icon: "arrow.up.right",
                title: L("history.farthestDistance"),
                value: farthestDistance != nil ? FormatUtilities.formatDistance(farthestDistance!.distanceTraveled) : "—",
                color: .orange,
                hasData: farthestDistance != nil
            )
            .onTapGesture {
                if farthestDistance != nil {
                    HapticManager.light()
                    onTapFarthest()
                }
            }
            
            AchievementCard(
                icon: "star.fill",
                title: L("history.mostPOIs"),
                value: mostPOIs != nil ? "\(mostPOIs!.discoveredPOICount)" : "—",
                color: .yellow,
                hasData: mostPOIs != nil
            )
            .onTapGesture {
                if mostPOIs != nil {
                    HapticManager.light()
                    onTapMostPOIs()
                }
            }
            
            AchievementCard(
                icon: "speedometer",
                title: L("history.stats.fastestJourney"),
                value: fastestSpeed != nil ? FormatUtilities.formatSpeed(fastestSpeed!.distanceTraveled / fastestSpeed!.duration) : "—",
                color: .purple,
                hasData: fastestSpeed != nil
            )
            .onTapGesture {
                if fastestSpeed != nil {
                    HapticManager.light()
                    onTapFastest()
                }
            }
        }
    }
}

// MARK: - Achievement Card

struct AchievementCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    let hasData: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(color)
                
                Spacer()
                
                if hasData {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(hasData ? .primary : .secondary)
                
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .frame(height: 120)
        .padding(16)
        .glassCard(cornerRadius: 16)
        .opacity(hasData ? 1.0 : 0.6)
    }
}

// MARK: - Milestone Card

struct MilestoneCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 56, height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(color.opacity(0.15))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(16)
        .glassCard(cornerRadius: 16)
    }
}
