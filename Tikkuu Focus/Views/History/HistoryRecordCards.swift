//
//  HistoryRecordCards.swift
//  Tikkuu Focus
//
//  Created by Tikkuu on 2026/2/10.
//

import SwiftUI
import SwiftData

// MARK: - Location Record Row

struct LocationRecordRow: View {
    let location: String
    let count: Int
    let totalTime: TimeInterval
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(LiquidGlassStyle.accentGradient)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(location)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                
                HStack(spacing: 8) {
                    Text("\(count) \(count == 1 ? L("common.journey") : L("common.journeys"))")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Text(L("common.bullet"))
                        .foregroundColor(.secondary)
                    
                    Text(FormatUtilities.formatTime(totalTime))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .padding(16)
        .glassCard(cornerRadius: 16)
    }
}

// MARK: - Transport Mode Row

struct TransportModeRow: View {
    let mode: String
    let count: Int
    let distance: Double
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconForMode(mode))
                .font(.system(size: 20))
                .foregroundStyle(LiquidGlassStyle.primaryGradient)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(L("transport.\(mode.lowercased())"))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                
                HStack(spacing: 8) {
                    Text("\(count) \(count == 1 ? L("common.journey") : L("common.journeys"))")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Text(L("common.bullet"))
                        .foregroundColor(.secondary)
                    
                    Text(FormatUtilities.formatDistance(distance))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
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

// MARK: - Time Record Row

struct TimeRecordRow: View {
    let record: JourneyRecord
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "clock.fill")
                .font(.system(size: 20))
                .foregroundStyle(LiquidGlassStyle.primaryGradient)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(FormatUtilities.formatDate(record.startTime))
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
                
                Text(L("transport.\(record.transportMode.lowercased())"))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .glassCard(cornerRadius: 16)
    }
}

// MARK: - Distance Record Row

struct DistanceRecordRow: View {
    let record: JourneyRecord
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "location.fill")
                .font(.system(size: 20))
                .foregroundStyle(LiquidGlassStyle.accentGradient)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(FormatUtilities.formatDistance(record.distanceTraveled))
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
                Image(systemName: iconForMode(record.transportMode))
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                
                Text(L("transport.\(record.transportMode.lowercased())"))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
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

// MARK: - Completed Record Row

struct CompletedRecordRow: View {
    let record: JourneyRecord
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(.green)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(record.startLocationName.isEmpty ? L("location.current") : record.startLocationName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text(FormatUtilities.formatTime(record.duration))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Text(L("common.bullet"))
                        .foregroundColor(.secondary)
                    
                    Text(FormatUtilities.formatDistance(record.distanceTraveled))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if record.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.green)
            }
        }
        .padding(16)
        .glassCard(cornerRadius: 16)
    }
}

// MARK: - POI Record Row

struct POIRecordRow: View {
    let record: JourneyRecord
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.yellow.opacity(0.3), Color.orange.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                
                Image(systemName: "star.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.yellow)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(record.startLocationName.isEmpty ? L("location.current") : record.startLocationName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text(FormatUtilities.formatDate(record.startTime))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Text(L("common.bullet"))
                        .foregroundColor(.secondary)
                    
                    Text(FormatUtilities.formatDistance(record.distanceTraveled))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(record.discoveredPOICount)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.yellow, Color.orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text(L("journey.summary.pois"))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .glassCard(cornerRadius: 16)
    }
}

// MARK: - Achievement Record Card

struct AchievementRecordCard: View {
    let record: JourneyRecord
    let highlightColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(record.startLocationName.isEmpty ? L("location.current") : record.startLocationName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(FormatUtilities.formatDate(record.startTime))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if record.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            
            Divider()
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L("history.detail.duration"))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                    Text(FormatUtilities.formatTime(record.duration))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.primary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(L("history.detail.distanceTraveled"))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                    Text(FormatUtilities.formatDistance(record.distanceTraveled))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.primary)
                }
                
                Spacer()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(highlightColor.opacity(0.3), lineWidth: 2)
                )
        )
    }
}
