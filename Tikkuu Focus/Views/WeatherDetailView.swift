//
//  WeatherDetailView.swift
//  Tikkuu Focus
//
//  Created by Tikkuu on 2026/2/10.
//

import SwiftUI
import WeatherKit
import CoreLocation

/// 天气详情和预报视图
struct WeatherDetailView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var weatherManager: WeatherManager
    let coordinate: CLLocationCoordinate2D
    
    @State private var hourlyForecast: [HourWeather] = []
    @State private var dailyForecast: [DayWeather] = []
    @State private var isLoadingForecast = false
    @State private var selectedTab = 0
    
    // Helper to check if hour is current
    private func isCurrentHour(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let now = Date()
        return calendar.isDate(date, equalTo: now, toGranularity: .hour)
    }
    
    // Helper to check if day is today
    private func isToday(_ date: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.isDateInToday(date)
    }
    
    var body: some View {
        ZStack {
            // Weather-based background
            WeatherBackgroundView(
                colors: weatherManager.weatherGradientColors,
                weatherCondition: weatherManager.weatherCondition,
                isDaytime: weatherManager.isDaytime,
                animationSpeed: weatherManager.gradientAnimationSpeed,
                overlayIntensity: weatherManager.overlayIntensity
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                    .padding(.top, 20)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Current weather card
                        currentWeatherCard
                        
                        // Tab selector
                        tabSelector
                        
                        // Forecast content
                        if selectedTab == 0 {
                            hourlyForecastView
                        } else {
                            dailyForecastView
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
        }
        .preferredColorScheme(AppSettings.shared.currentColorScheme)
        .onAppear {
            loadForecast()
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            Spacer()
            
            Text(L("label.weather"))
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(weatherManager.optimalTextColor)
            
            Spacer()
        }
        .overlay(alignment: .trailing) {
            Button {
                HapticManager.light()
                dismiss()
            } label: {
                Text(L("common.done"))
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(weatherManager.optimalTextColor)
            }
        }
    }
    
    // MARK: - Current Weather Card
    
    private var currentWeatherCard: some View {
        VStack(spacing: 24) {
            // Large weather icon with glow
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                weatherManager.optimalTextColor.opacity(0.15),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                
                Image(systemName: weatherManager.weatherIcon)
                    .font(.system(size: 90, weight: .light))
                    .foregroundColor(weatherManager.optimalTextColor)
                    .symbolRenderingMode(.hierarchical)
            }
            
            // Temperature
            Text(weatherManager.temperatureString)
                .font(.system(size: 72, weight: .ultraLight, design: .rounded))
                .foregroundColor(weatherManager.optimalTextColor)
            
            // Description
            if !weatherManager.weatherDescription.isEmpty {
                Text(weatherManager.weatherDescription)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(weatherManager.optimalSecondaryTextColor)
            }
            
            // Additional details in grid
            if let weather = weatherManager.currentWeather {
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        WeatherDetailItemCard(
                            icon: "humidity.fill",
                            label: L("weather.humidity"),
                            value: String(format: "%.0f%%", weather.humidity * 100),
                            textColor: weatherManager.optimalTextColor,
                            secondaryColor: weatherManager.optimalSecondaryTextColor
                        )
                        
                        WeatherDetailItemCard(
                            icon: "wind",
                            label: L("weather.wind"),
                            value: String(format: "%.0f km/h", weather.wind.speed.value),
                            textColor: weatherManager.optimalTextColor,
                            secondaryColor: weatherManager.optimalSecondaryTextColor
                        )
                    }
                    
                    HStack(spacing: 12) {
                        WeatherDetailItemCard(
                            icon: "eye.fill",
                            label: L("weather.visibility"),
                            value: String(format: "%.0f km", weather.visibility.value / 1000),
                            textColor: weatherManager.optimalTextColor,
                            secondaryColor: weatherManager.optimalSecondaryTextColor
                        )
                        
                        WeatherDetailItemCard(
                            icon: "gauge.with.dots.needle.bottom.50percent",
                            label: L("weather.pressure"),
                            value: String(format: "%.0f hPa", weather.pressure.value),
                            textColor: weatherManager.optimalTextColor,
                            secondaryColor: weatherManager.optimalSecondaryTextColor
                        )
                    }
                }
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
        .padding(.horizontal, 24)
        .glassCard(cornerRadius: 28)
    }
    
    // MARK: - Tab Selector
    
    private var tabSelector: some View {
        HStack(spacing: 12) {
            WeatherTabButton(
                title: L("weather.hourly"),
                isSelected: selectedTab == 0
            ) {
                HapticManager.selection()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedTab = 0
                }
            }
            
            WeatherTabButton(
                title: L("weather.daily"),
                isSelected: selectedTab == 1
            ) {
                HapticManager.selection()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedTab = 1
                }
            }
        }
    }
    
    // MARK: - Hourly Forecast
    
    private var hourlyForecastView: some View {
        VStack(alignment: .leading, spacing: 16) {
            if isLoadingForecast {
                HStack {
                    Spacer()
                    ProgressView()
                        .tint(weatherManager.optimalTextColor)
                    Spacer()
                }
                .padding(.vertical, 40)
            } else if hourlyForecast.isEmpty {
                Text(L("weather.noData"))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(weatherManager.optimalSecondaryTextColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(hourlyForecast.prefix(24), id: \.date) { hour in
                            HourlyForecastCard(
                                hour: hour,
                                isNow: isCurrentHour(hour.date),
                                textColor: weatherManager.optimalTextColor,
                                secondaryColor: weatherManager.optimalSecondaryTextColor
                            )
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 8)
                }
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 20)
        .glassCard(cornerRadius: 20)
    }
    
    // MARK: - Daily Forecast
    
    private var dailyForecastView: some View {
        VStack(spacing: 12) {
            if isLoadingForecast {
                HStack {
                    Spacer()
                    ProgressView()
                        .tint(weatherManager.optimalTextColor)
                    Spacer()
                }
                .padding(.vertical, 40)
            } else if dailyForecast.isEmpty {
                Text(L("weather.noData"))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(weatherManager.optimalSecondaryTextColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            } else {
                ForEach(dailyForecast.prefix(7), id: \.date) { day in
                    DailyForecastRow(
                        day: day,
                        isToday: isToday(day.date),
                        textColor: weatherManager.optimalTextColor,
                        secondaryColor: weatherManager.optimalSecondaryTextColor
                    )
                    
                    if day.date != dailyForecast.prefix(7).last?.date {
                        Divider()
                            .background(weatherManager.optimalSecondaryTextColor.opacity(0.15))
                            .padding(.horizontal, 8)
                    }
                }
            }
        }
        .padding(20)
        .glassCard(cornerRadius: 20)
    }
    
    // MARK: - Load Forecast
    
    private func loadForecast() {
        isLoadingForecast = true
        
        Task {
            do {
                let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                let weather = try await WeatherService.shared.weather(for: location)
                
                await MainActor.run {
                    hourlyForecast = Array(weather.hourlyForecast)
                    dailyForecast = Array(weather.dailyForecast)
                    isLoadingForecast = false
                }
            } catch {
                #if DEBUG
                print("Failed to load forecast: \(error.localizedDescription)")
                #endif
                await MainActor.run {
                    isLoadingForecast = false
                }
            }
        }
    }
}

// MARK: - Weather Detail Item Card

struct WeatherDetailItemCard: View {
    @Environment(\.colorScheme) var colorScheme
    let icon: String
    let label: String
    let value: String
    let textColor: Color
    let secondaryColor: Color
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(textColor.opacity(0.9))
                .symbolRenderingMode(.hierarchical)
            
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(textColor)
            
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(secondaryColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.15))
        )
    }
}

// MARK: - Weather Tab Button

struct WeatherTabButton: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.adaptiveTextColor) var adaptiveTextColor
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(isSelected ? .white : adaptiveTextColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? AnyShapeStyle(LiquidGlassStyle.primaryGradient) : AnyShapeStyle(LiquidGlassStyle.glassBackground(for: colorScheme)))
                )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Hourly Forecast Card

struct HourlyForecastCard: View {
    @Environment(\.colorScheme) var colorScheme
    let hour: HourWeather
    let isNow: Bool
    let textColor: Color
    let secondaryColor: Color
    
    private var timeString: String {
        if isNow {
            return L("weather.now")
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: hour.date)
    }
    
    private var weatherIcon: String {
        switch hour.condition {
        case .clear:
            return hour.isDaylight ? "sun.max.fill" : "moon.stars.fill"
        case .cloudy:
            return "cloud.fill"
        case .mostlyClear:
            return hour.isDaylight ? "cloud.sun.fill" : "cloud.moon.fill"
        case .mostlyCloudy:
            return "cloud.fill"
        case .partlyCloudy:
            return hour.isDaylight ? "cloud.sun.fill" : "cloud.moon.fill"
        case .rain:
            return "cloud.rain.fill"
        case .drizzle:
            return "cloud.drizzle.fill"
        case .heavyRain:
            return "cloud.heavyrain.fill"
        case .snow:
            return "cloud.snow.fill"
        case .thunderstorms:
            return "cloud.bolt.rain.fill"
        default:
            return "cloud.fill"
        }
    }
    
    var body: some View {
        VStack(spacing: 14) {
            // Time or "Now" label
            Text(timeString)
                .font(.system(size: isNow ? 14 : 13, weight: isNow ? .bold : .medium))
                .foregroundColor(isNow ? textColor : secondaryColor)
            
            // Weather icon
            Image(systemName: weatherIcon)
                .font(.system(size: isNow ? 32 : 28, weight: .medium))
                .foregroundColor(textColor)
                .symbolRenderingMode(.hierarchical)
                .frame(height: 36)
            
            // Temperature
            Text(String(format: "%.0f°", hour.temperature.value))
                .font(.system(size: isNow ? 18 : 16, weight: isNow ? .bold : .semibold, design: .rounded))
                .foregroundColor(textColor)
        }
        .frame(width: isNow ? 80 : 70)
        .padding(.vertical, isNow ? 18 : 16)
        .padding(.horizontal, isNow ? 14 : 12)
        .background(
            ZStack {
                if isNow {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(LiquidGlassStyle.primaryGradient)
                        .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.12))
                }
            }
        )
        .scaleEffect(isNow ? 1.05 : 1.0)
    }
}

// MARK: - Daily Forecast Row

struct DailyForecastRow: View {
    @Environment(\.colorScheme) var colorScheme
    let day: DayWeather
    let isToday: Bool
    let textColor: Color
    let secondaryColor: Color
    
    private var dayString: String {
        if isToday {
            return L("weather.today")
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        formatter.locale = Locale(identifier: AppSettings.shared.selectedLanguage == "zh-Hans" ? "zh-Hans" : "en")
        return formatter.string(from: day.date)
    }
    
    private var weatherIcon: String {
        switch day.condition {
        case .clear:
            return "sun.max.fill"
        case .cloudy:
            return "cloud.fill"
        case .mostlyClear:
            return "cloud.sun.fill"
        case .mostlyCloudy:
            return "cloud.fill"
        case .partlyCloudy:
            return "cloud.sun.fill"
        case .rain:
            return "cloud.rain.fill"
        case .drizzle:
            return "cloud.drizzle.fill"
        case .heavyRain:
            return "cloud.heavyrain.fill"
        case .snow:
            return "cloud.snow.fill"
        case .thunderstorms:
            return "cloud.bolt.rain.fill"
        default:
            return "cloud.fill"
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Day name with badge for today
            HStack(spacing: 8) {
                Text(dayString)
                    .font(.system(size: isToday ? 16 : 15, weight: isToday ? .bold : .medium))
                    .foregroundColor(isToday ? textColor : textColor.opacity(0.9))
                
                if isToday {
                    Circle()
                        .fill(LiquidGlassStyle.primaryGradient)
                        .frame(width: 6, height: 6)
                }
            }
            .frame(width: 110, alignment: .leading)
            
            // Weather icon
            Image(systemName: weatherIcon)
                .font(.system(size: isToday ? 28 : 26, weight: .medium))
                .foregroundColor(textColor)
                .symbolRenderingMode(.hierarchical)
                .frame(width: 44)
            
            Spacer()
            
            // Temperature range with bar
            HStack(spacing: 12) {
                // Low temp
                Text(String(format: "%.0f°", day.lowTemperature.value))
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(secondaryColor)
                    .frame(width: 36, alignment: .trailing)
                
                // Temperature bar
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(secondaryColor.opacity(0.2))
                        .frame(width: 60, height: 6)
                    
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.blue.opacity(0.6),
                                    Color.orange.opacity(0.8)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 60, height: 6)
                }
                
                // High temp
                Text(String(format: "%.0f°", day.highTemperature.value))
                    .font(.system(size: 15, weight: isToday ? .bold : .semibold, design: .rounded))
                    .foregroundColor(textColor)
                    .frame(width: 36, alignment: .leading)
            }
        }
        .padding(.vertical, isToday ? 12 : 10)
        .padding(.horizontal, isToday ? 12 : 8)
        .background(
            Group {
                if isToday {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.12))
                }
            }
        )
    }
}

#Preview {
    WeatherDetailView(
        weatherManager: WeatherManager(),
        coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
    )
}
