//
//  FormatUtilities.swift
//  Tikkuu Focus
//
//  Created by Tikkuu on 2026/2/8.
//

import Foundation

/// Utility functions for formatting values
enum FormatUtilities {
    
    /// Format time interval to human-readable string
    static func formatTime(_ seconds: TimeInterval) -> String {
        let totalSeconds = Int(seconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60
        
        if hours > 0 {
            // Show hours and minutes: "6 hr 30 min"
            if minutes > 0 {
                let hourStr = String(format: L("time.hours"), hours)
                let minStr = String(format: L("time.minutes"), minutes)
                return "\(hourStr) \(minStr)"
            } else {
                return String(format: L("time.hours"), hours)
            }
        } else if minutes > 0 {
            return String(format: L("time.minutes"), minutes)
        } else {
            return String(format: L("time.seconds"), secs)
        }
    }
    
    /// Format time interval to MM:SS or HH:MM:SS format
    static func formatTimeDigital(_ seconds: TimeInterval) -> String {
        let totalSeconds = Int(seconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%02d:%02d", minutes, secs)
        }
    }
    
    /// Format distance to human-readable string
    static func formatDistance(_ meters: Double) -> String {
        if meters >= 1000 {
            let km = meters / 1000.0
            return String(format: L("distance.kilometers"), km)
        } else {
            return String(format: L("distance.meters"), meters)
        }
    }
    
    /// Format speed to human-readable string
    static func formatSpeed(_ metersPerSecond: Double) -> String {
        let kmh = metersPerSecond * 3.6
        return String(format: L("speed.kmh"), kmh)
    }
    
    /// Format progress percentage
    static func formatProgress(_ progress: Double) -> String {
        return String(format: "%.0f%%", progress * 100)
    }
    
    /// Format date to human-readable string (localized)
    static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: AppSettings.shared.currentLanguage)
        return formatter.string(from: date)
    }
    
    /// Format date and time to human-readable string (localized)
    static func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: AppSettings.shared.currentLanguage)
        return formatter.string(from: date)
    }
    
    /// Format date to short string (localized)
    static func formatDateShort(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: AppSettings.shared.currentLanguage)
        return formatter.string(from: date)
    }
    
    /// Format time only (localized)
    static func formatTimeOnly(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: AppSettings.shared.currentLanguage)
        return formatter.string(from: date)
    }
    
    /// Format relative date (e.g., "Today", "Yesterday", "2 days ago")
    static func formatRelativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: AppSettings.shared.currentLanguage)
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    /// Format large numbers with separators
    static func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}
