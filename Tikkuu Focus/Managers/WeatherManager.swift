//
//  WeatherManager.swift
//  Tikkuu Focus
//
//  Created by Tikkuu on 2026/2/8.
//

import Foundation
import CoreLocation
import WeatherKit
import SwiftUI
import Combine

/// Weather manager using Apple's WeatherKit
@MainActor
class WeatherManager: ObservableObject {
    @Published var currentWeather: CurrentWeather?
    @Published var isLoading = false
    @Published var error: Error?
    
    private let weatherService = WeatherService.shared
    
    // MARK: - Performance Optimization
    
    private var lastFetchTime: Date?
    private var lastFetchLocation: CLLocationCoordinate2D?
    private let minimumFetchInterval: TimeInterval = 300 // 5 minutes
    private let locationChangeThreshold: CLLocationDistance = 1000 // 1 km
    
    /// Check if we should fetch new weather data
    private func shouldFetchWeather(for coordinate: CLLocationCoordinate2D) -> Bool {
        // Check time interval
        if let lastTime = lastFetchTime {
            let timeSinceLastFetch = Date().timeIntervalSince(lastTime)
            if timeSinceLastFetch < minimumFetchInterval {
                // Check location change
                if let lastLocation = lastFetchLocation {
                    let lastCLLocation = CLLocation(latitude: lastLocation.latitude, longitude: lastLocation.longitude)
                    let newCLLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                    let distance = lastCLLocation.distance(from: newCLLocation)
                    
                    // Only fetch if moved significantly
                    if distance < locationChangeThreshold {
                        return false
                    }
                }
            }
        }
        
        return true
    }
    
    /// Fetch weather for a given location with caching
    func fetchWeather(for coordinate: CLLocationCoordinate2D) async {
        // Skip if recently fetched for similar location
        guard shouldFetchWeather(for: coordinate) else {
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            let weather = try await weatherService.weather(for: location)
            currentWeather = weather.currentWeather
            
            // Update cache
            lastFetchTime = Date()
            lastFetchLocation = coordinate
        } catch {
            // Silently handle WeatherKit errors in development/simulator
            // WeatherKit requires proper entitlements and only works on real devices with valid App ID
            self.error = error
            
            // Only log in debug mode
            #if DEBUG
            if let nsError = error as NSError? {
                // Check if it's the JWT authentication error (Code 2)
                if nsError.domain.contains("WeatherDaemon") && nsError.code == 2 {
                    // This is expected in simulator/development - don't spam console
                    print("⚠️ WeatherKit unavailable (requires device + entitlements)")
                } else {
                    print("Failed to fetch weather: \(error.localizedDescription)")
                }
            }
            #endif
        }
        
        isLoading = false
    }
    
    /// Get weather icon name
    var weatherIcon: String {
        guard let condition = currentWeather?.condition else { return "cloud.fill" }
        
        switch condition {
        case .clear:
            return isDaytime ? "sun.max.fill" : "moon.stars.fill"
        case .cloudy:
            return "cloud.fill"
        case .mostlyClear:
            return isDaytime ? "cloud.sun.fill" : "cloud.moon.fill"
        case .mostlyCloudy:
            return "cloud.fill"
        case .partlyCloudy:
            return isDaytime ? "cloud.sun.fill" : "cloud.moon.fill"
        case .rain:
            return "cloud.rain.fill"
        case .drizzle:
            return "cloud.drizzle.fill"
        case .heavyRain:
            return "cloud.heavyrain.fill"
        case .snow:
            return "cloud.snow.fill"
        case .sleet:
            return "cloud.sleet.fill"
        case .hail:
            return "cloud.hail.fill"
        case .thunderstorms:
            return "cloud.bolt.rain.fill"
        case .tropicalStorm, .hurricane:
            return "hurricane"
        case .blizzard:
            return "wind.snow"
        case .blowingSnow:
            return "wind.snow"
        case .freezingDrizzle, .freezingRain:
            return "cloud.sleet.fill"
        case .flurries:
            return "cloud.snow.fill"
        case .foggy:
            return "cloud.fog.fill"
        case .haze:
            return "sun.haze.fill"
        case .smoky:
            return "smoke.fill"
        case .breezy, .windy:
            return "wind"
        case .blowingDust:
            return "sun.dust.fill"
        default:
            return "cloud.fill"
        }
    }
    
    /// Get weather description (localized)
    var weatherDescription: String {
        guard let condition = currentWeather?.condition else { return "" }
        
        // Map weather conditions to localization keys
        let key: String
        switch condition {
        case .clear:
            key = isDaytime ? "weather.condition.clear" : "weather.condition.clearNight"
        case .cloudy:
            key = "weather.condition.cloudy"
        case .mostlyClear:
            key = "weather.condition.mostlyClear"
        case .mostlyCloudy:
            key = "weather.condition.mostlyCloudy"
        case .partlyCloudy:
            key = "weather.condition.partlyCloudy"
        case .rain:
            key = "weather.condition.rain"
        case .drizzle:
            key = "weather.condition.drizzle"
        case .heavyRain:
            key = "weather.condition.heavyRain"
        case .snow:
            key = "weather.condition.snow"
        case .sleet:
            key = "weather.condition.sleet"
        case .hail:
            key = "weather.condition.hail"
        case .thunderstorms:
            key = "weather.condition.thunderstorms"
        case .tropicalStorm:
            key = "weather.condition.tropicalStorm"
        case .hurricane:
            key = "weather.condition.hurricane"
        case .blizzard:
            key = "weather.condition.blizzard"
        case .blowingSnow:
            key = "weather.condition.blowingSnow"
        case .freezingDrizzle:
            key = "weather.condition.freezingDrizzle"
        case .freezingRain:
            key = "weather.condition.freezingRain"
        case .flurries:
            key = "weather.condition.flurries"
        case .foggy:
            key = "weather.condition.foggy"
        case .haze:
            key = "weather.condition.haze"
        case .smoky:
            key = "weather.condition.smoky"
        case .breezy:
            key = "weather.condition.breezy"
        case .windy:
            key = "weather.condition.windy"
        case .blowingDust:
            key = "weather.condition.blowingDust"
        default:
            return condition.description
        }
        
        return NSLocalizedString(key, comment: "")
    }
    
    /// Get temperature string
    var temperatureString: String {
        guard let temp = currentWeather?.temperature else { return "--°" }
        return String(format: "%.0f°", temp.value)
    }
    
    /// Check if it's daytime (public for background view)
    var isDaytime: Bool {
        guard let isDaylight = currentWeather?.isDaylight else {
            let hour = Calendar.current.component(.hour, from: Date())
            return hour >= 6 && hour < 18
        }
        return isDaylight
    }
    
    /// Get current weather condition (public for background view)
    var weatherCondition: WeatherCondition? {
        return currentWeather?.condition
    }
    
    /// Check if background is dark (for text contrast)
    var isBackgroundDark: Bool {
        guard let condition = currentWeather?.condition else {
            return false
        }
        
        switch condition {
        case .clear:
            return !isDaytime // Night is dark
        case .cloudy, .mostlyCloudy:
            return !isDaytime // Day is medium-light, night is dark
        case .partlyCloudy, .mostlyClear:
            return !isDaytime // Night is dark
        case .rain, .drizzle, .heavyRain:
            return !isDaytime // Day is medium, night is dark
        case .thunderstorms:
            return true // Always dark
        case .snow, .blizzard, .flurries, .blowingSnow:
            return false // White-blue is bright
        case .foggy, .haze, .smoky:
            return !isDaytime // Day is light, night is dark
        case .windy, .breezy:
            return !isDaytime // Day is light, night is dark
        default:
            return false
        }
    }
    
    /// Get optimal text color based on background brightness
    var optimalTextColor: Color {
        isBackgroundDark ? .white : .black
    }
    
    /// Get optimal secondary text color
    var optimalSecondaryTextColor: Color {
        isBackgroundDark ? Color.white.opacity(0.7) : Color.black.opacity(0.6)
    }
    
    /// Get animation speed based on weather condition
    var gradientAnimationSpeed: Double {
        guard let condition = currentWeather?.condition else {
            return 12.0
        }
        
        switch condition {
        case .clear:
            return 15.0 // Slow, peaceful
        case .cloudy, .mostlyCloudy:
            return 10.0 // Medium, gentle movement
        case .partlyCloudy, .mostlyClear:
            return 12.0 // Moderate
        case .rain, .drizzle:
            return 8.0 // Faster, flowing
        case .heavyRain:
            return 6.0 // Fast, intense
        case .thunderstorms:
            return 5.0 // Very fast, dramatic
        case .snow, .flurries:
            return 14.0 // Slow, gentle falling
        case .blizzard, .blowingSnow:
            return 7.0 // Fast, swirling
        case .foggy, .haze, .smoky:
            return 16.0 // Very slow, drifting
        case .windy, .breezy:
            return 8.0 // Fast, sweeping
        default:
            return 12.0
        }
    }
    
    /// Get overlay animation intensity
    var overlayIntensity: Double {
        guard let condition = currentWeather?.condition else {
            return 0.3
        }
        
        switch condition {
        case .clear:
            return 0.25 // Subtle
        case .cloudy, .mostlyCloudy:
            return 0.35 // Medium
        case .partlyCloudy, .mostlyClear:
            return 0.3 // Moderate
        case .rain, .drizzle, .heavyRain:
            return 0.45 // Strong
        case .thunderstorms:
            return 0.5 // Very strong
        case .snow, .flurries, .blizzard:
            return 0.4 // Strong
        case .foggy, .haze, .smoky:
            return 0.5 // Very strong, misty
        case .windy, .breezy:
            return 0.4 // Strong
        default:
            return 0.3
        }
    }
    
    /// Get weather-based gradient colors
    var weatherGradientColors: [Color] {
        guard let condition = currentWeather?.condition else {
            return defaultGradientColors
        }
        
        switch condition {
        case .clear:
            if isDaytime {
                // Sunny day - bright blue to cyan
                return [
                    Color(red: 0.4, green: 0.7, blue: 1.0),
                    Color(red: 0.5, green: 0.8, blue: 1.0),
                    Color(red: 0.6, green: 0.9, blue: 1.0)
                ]
            } else {
                // Clear night - deep blue to purple
                return [
                    Color(red: 0.1, green: 0.1, blue: 0.3),
                    Color(red: 0.2, green: 0.1, blue: 0.4),
                    Color(red: 0.3, green: 0.2, blue: 0.5)
                ]
            }
            
        case .cloudy, .mostlyCloudy:
            // Cloudy - soft blue-gray with depth
            if isDaytime {
                return [
                    Color(red: 0.55, green: 0.62, blue: 0.72),
                    Color(red: 0.62, green: 0.68, blue: 0.78),
                    Color(red: 0.68, green: 0.74, blue: 0.84)
                ]
            } else {
                return [
                    Color(red: 0.25, green: 0.28, blue: 0.38),
                    Color(red: 0.32, green: 0.35, blue: 0.45),
                    Color(red: 0.38, green: 0.42, blue: 0.52)
                ]
            }
            
        case .partlyCloudy, .mostlyClear:
            if isDaytime {
                // Partly cloudy day - bright soft blue with warmth
                return [
                    Color(red: 0.52, green: 0.72, blue: 0.92),
                    Color(red: 0.62, green: 0.78, blue: 0.96),
                    Color(red: 0.72, green: 0.84, blue: 1.0)
                ]
            } else {
                // Partly cloudy night - deep blue with purple hints
                return [
                    Color(red: 0.18, green: 0.22, blue: 0.42),
                    Color(red: 0.24, green: 0.28, blue: 0.52),
                    Color(red: 0.30, green: 0.34, blue: 0.62)
                ]
            }
            
        case .rain, .drizzle, .heavyRain:
            // Rainy - moody blue-gray with depth
            if isDaytime {
                return [
                    Color(red: 0.38, green: 0.45, blue: 0.58),
                    Color(red: 0.45, green: 0.52, blue: 0.65),
                    Color(red: 0.52, green: 0.58, blue: 0.72)
                ]
            } else {
                return [
                    Color(red: 0.18, green: 0.22, blue: 0.32),
                    Color(red: 0.24, green: 0.28, blue: 0.38),
                    Color(red: 0.30, green: 0.34, blue: 0.44)
                ]
            }
            
        case .thunderstorms:
            // Stormy - dramatic dark purple-gray
            return [
                Color(red: 0.22, green: 0.24, blue: 0.35),
                Color(red: 0.28, green: 0.26, blue: 0.42),
                Color(red: 0.35, green: 0.32, blue: 0.50)
            ]
            
        case .snow, .blizzard, .flurries, .blowingSnow:
            // Snowy - cool white-blue
            return [
                Color(red: 0.8, green: 0.85, blue: 0.95),
                Color(red: 0.85, green: 0.9, blue: 0.98),
                Color(red: 0.9, green: 0.95, blue: 1.0)
            ]
            
        case .foggy, .haze, .smoky:
            // Foggy - soft misty gray with subtle warmth
            if isDaytime {
                return [
                    Color(red: 0.72, green: 0.74, blue: 0.78),
                    Color(red: 0.78, green: 0.79, blue: 0.82),
                    Color(red: 0.82, green: 0.83, blue: 0.86)
                ]
            } else {
                return [
                    Color(red: 0.28, green: 0.30, blue: 0.35),
                    Color(red: 0.35, green: 0.37, blue: 0.42),
                    Color(red: 0.42, green: 0.44, blue: 0.48)
                ]
            }
            
        case .windy, .breezy:
            // Windy - fresh blue-gray with movement feel
            if isDaytime {
                return [
                    Color(red: 0.52, green: 0.65, blue: 0.80),
                    Color(red: 0.60, green: 0.72, blue: 0.86),
                    Color(red: 0.68, green: 0.78, blue: 0.92)
                ]
            } else {
                return [
                    Color(red: 0.22, green: 0.28, blue: 0.40),
                    Color(red: 0.28, green: 0.35, blue: 0.48),
                    Color(red: 0.35, green: 0.42, blue: 0.56)
                ]
            }
            
        default:
            return defaultGradientColors
        }
    }
    
    private var defaultGradientColors: [Color] {
        [
            Color(red: 0.4, green: 0.6, blue: 0.9),
            Color(red: 0.5, green: 0.7, blue: 0.95),
            Color(red: 0.6, green: 0.8, blue: 1.0)
        ]
    }
}

// MARK: - Color Extension

extension Color {
    init(red: Double, green: Double, blue: Double) {
        self.init(red: red, green: green, blue: blue, opacity: 1.0)
    }
}
