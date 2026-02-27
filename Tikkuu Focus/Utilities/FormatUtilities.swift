//
//  FormatUtilities.swift
//  Tikkuu Focus
//
//  Created by Tikkuu on 2026/2/8.
//

import Foundation

/// Utility functions for formatting values
enum FormatUtilities {
    private static func cachedDateFormatter(
        key: String,
        localeIdentifier: String,
        dateStyle: DateFormatter.Style,
        timeStyle: DateFormatter.Style
    ) -> DateFormatter {
        let cacheKey = "tikkuu.date.\(key).\(localeIdentifier)" as NSString
        let threadCache = Thread.current.threadDictionary

        if let formatter = threadCache[cacheKey] as? DateFormatter {
            return formatter
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: localeIdentifier)
        formatter.dateStyle = dateStyle
        formatter.timeStyle = timeStyle
        threadCache[cacheKey] = formatter
        return formatter
    }

    private static func cachedRelativeFormatter(localeIdentifier: String) -> RelativeDateTimeFormatter {
        let cacheKey = "tikkuu.relative.full.\(localeIdentifier)" as NSString
        let threadCache = Thread.current.threadDictionary

        if let formatter = threadCache[cacheKey] as? RelativeDateTimeFormatter {
            return formatter
        }

        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: localeIdentifier)
        formatter.unitsStyle = .full
        threadCache[cacheKey] = formatter
        return formatter
    }

    private static func cachedNumberFormatter(localeIdentifier: String) -> NumberFormatter {
        let cacheKey = "tikkuu.number.decimal.\(localeIdentifier)" as NSString
        let threadCache = Thread.current.threadDictionary

        if let formatter = threadCache[cacheKey] as? NumberFormatter {
            return formatter
        }

        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: localeIdentifier)
        formatter.numberStyle = .decimal
        threadCache[cacheKey] = formatter
        return formatter
    }

    private static func cachedTemplateDateFormatter(
        template: String,
        localeIdentifier: String
    ) -> DateFormatter {
        let cacheKey = "tikkuu.date.template.\(template).\(localeIdentifier)" as NSString
        let threadCache = Thread.current.threadDictionary

        if let formatter = threadCache[cacheKey] as? DateFormatter {
            return formatter
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: localeIdentifier)
        formatter.setLocalizedDateFormatFromTemplate(template)
        threadCache[cacheKey] = formatter
        return formatter
    }

    private static func cachedCustomDateFormatter(
        key: String,
        localeIdentifier: String,
        format: String
    ) -> DateFormatter {
        let cacheKey = "tikkuu.date.custom.\(key).\(localeIdentifier)" as NSString
        let threadCache = Thread.current.threadDictionary

        if let formatter = threadCache[cacheKey] as? DateFormatter {
            return formatter
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: localeIdentifier)
        formatter.dateFormat = format
        threadCache[cacheKey] = formatter
        return formatter
    }

    
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
        let localeIdentifier = AppSettings.shared.currentLanguage
        let formatter = cachedDateFormatter(
            key: "medium.none",
            localeIdentifier: localeIdentifier,
            dateStyle: .medium,
            timeStyle: .none
        )
        return formatter.string(from: date)
    }
    
    /// Format date and time to human-readable string (localized)
    static func formatDateTime(_ date: Date) -> String {
        let localeIdentifier = AppSettings.shared.currentLanguage
        let formatter = cachedDateFormatter(
            key: "medium.short",
            localeIdentifier: localeIdentifier,
            dateStyle: .medium,
            timeStyle: .short
        )
        return formatter.string(from: date)
    }
    
    /// Format date to short string (localized)
    static func formatDateShort(_ date: Date) -> String {
        let localeIdentifier = AppSettings.shared.currentLanguage
        let formatter = cachedDateFormatter(
            key: "short.none",
            localeIdentifier: localeIdentifier,
            dateStyle: .short,
            timeStyle: .none
        )
        return formatter.string(from: date)
    }
    
    /// Format time only (localized)
    static func formatTimeOnly(_ date: Date) -> String {
        let localeIdentifier = AppSettings.shared.currentLanguage
        let formatter = cachedDateFormatter(
            key: "none.short",
            localeIdentifier: localeIdentifier,
            dateStyle: .none,
            timeStyle: .short
        )
        return formatter.string(from: date)
    }
    
    /// Format relative date (e.g., "Today", "Yesterday", "2 days ago")
    static func formatRelativeDate(_ date: Date) -> String {
        let localeIdentifier = AppSettings.shared.currentLanguage
        let formatter = cachedRelativeFormatter(localeIdentifier: localeIdentifier)
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    /// Format large numbers with separators
    static func formatNumber(_ number: Int) -> String {
        let localeIdentifier = AppSettings.shared.currentLanguage
        let formatter = cachedNumberFormatter(localeIdentifier: localeIdentifier)
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }

    /// Format a date to localized weekday name (e.g. Monday / 星期一)
    static func formatWeekdayLong(_ date: Date, localeIdentifier: String? = nil) -> String {
        let locale = localeIdentifier ?? AppSettings.shared.currentLanguage
        let formatter = cachedTemplateDateFormatter(template: "EEEE", localeIdentifier: locale)
        return formatter.string(from: date)
    }

    /// Format a date to localized short month (e.g. Jan / 1月)
    static func formatMonthShort(_ date: Date, localeIdentifier: String? = nil) -> String {
        let locale = localeIdentifier ?? AppSettings.shared.currentLanguage
        let formatter = cachedTemplateDateFormatter(template: "MMM", localeIdentifier: locale)
        return formatter.string(from: date)
    }

    /// Format a date to localized full month (e.g. January / 一月)
    static func formatMonthLong(_ date: Date, localeIdentifier: String? = nil) -> String {
        let locale = localeIdentifier ?? AppSettings.shared.currentLanguage
        let formatter = cachedTemplateDateFormatter(template: "MMMM", localeIdentifier: locale)
        return formatter.string(from: date)
    }

    /// Format a date to 24-hour hour:minute (e.g. 13:45)
    static func formatHourMinute24(_ date: Date, localeIdentifier: String? = nil) -> String {
        let locale = localeIdentifier ?? AppSettings.shared.currentLanguage
        let formatter = cachedCustomDateFormatter(
            key: "hour24",
            localeIdentifier: locale,
            format: "HH:mm"
        )
        return formatter.string(from: date)
    }
}
