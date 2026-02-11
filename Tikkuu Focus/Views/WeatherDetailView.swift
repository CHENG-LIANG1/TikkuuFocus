//
//  WeatherDetailView.swift
//  Tikkuu Focus
//
//  Created by Tikkuu on 2026/2/10.
//

import SwiftUI
import WeatherKit
import CoreLocation

struct WeatherDetailView: View {
    @ObservedObject var weatherManager: WeatherManager
    let coordinate: CLLocationCoordinate2D

    @State private var hourlyForecast: [HourWeather] = []
    @State private var dailyForecast: [DayWeather] = []
    @State private var isLoadingForecast = false
    @State private var selectedTab: ForecastTab = .hourly

    var body: some View {
        ZStack {
            WeatherBackgroundView(
                colors: weatherManager.weatherGradientColors,
                weatherCondition: weatherManager.weatherCondition,
                isDaytime: weatherManager.isDaytime,
                animationSpeed: weatherManager.gradientAnimationSpeed,
                overlayIntensity: weatherManager.overlayIntensity
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        currentSummaryCard
                        metricsGridCard
                        tabSelector

                        if selectedTab == .hourly {
                            hourlySection
                        } else {
                            dailySection
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 36)
                }
            }
        }
        .preferredColorScheme(AppSettings.shared.currentColorScheme)
        .onAppear(perform: loadForecast)
    }

    private var currentSummaryCard: some View {
        VStack(spacing: 14) {
            Image(systemName: weatherManager.weatherIcon)
                .font(.system(size: 64, weight: .light))
                .foregroundColor(weatherManager.optimalTextColor)
                .symbolRenderingMode(.hierarchical)

            Text(weatherManager.temperatureString)
                .font(.system(size: 66, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundColor(weatherManager.optimalTextColor)

            if !weatherManager.weatherDescription.isEmpty {
                Text(weatherManager.weatherDescription)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(weatherManager.optimalSecondaryTextColor)
            }

            if let weather = weatherManager.currentWeather {
                HStack(spacing: 10) {
                    WeatherBadge(
                        icon: "sun.max.fill",
                        title: L("weather.temperature"),
                        value: String(format: "%.0f°", weather.temperature.value),
                        textColor: weatherManager.optimalTextColor,
                        secondaryColor: weatherManager.optimalSecondaryTextColor
                    )

                    WeatherBadge(
                        icon: "humidity.fill",
                        title: L("weather.humidity"),
                        value: String(format: "%.0f%%", weather.humidity * 100),
                        textColor: weatherManager.optimalTextColor,
                        secondaryColor: weatherManager.optimalSecondaryTextColor
                    )

                    WeatherBadge(
                        icon: "wind",
                        title: L("weather.wind"),
                        value: String(format: "%.0f km/h", weather.wind.speed.value),
                        textColor: weatherManager.optimalTextColor,
                        secondaryColor: weatherManager.optimalSecondaryTextColor
                    )
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, 20)
        .glassCard(cornerRadius: 24)
    }

    private var metricsGridCard: some View {
        VStack(spacing: 10) {
            if let weather = weatherManager.currentWeather {
                HStack(spacing: 10) {
                    WeatherMetricTile(
                        icon: "humidity.fill",
                        label: L("weather.humidity"),
                        value: String(format: "%.0f%%", weather.humidity * 100),
                        textColor: weatherManager.optimalTextColor,
                        secondaryColor: weatherManager.optimalSecondaryTextColor
                    )

                    WeatherMetricTile(
                        icon: "wind",
                        label: L("weather.wind"),
                        value: String(format: "%.0f km/h", weather.wind.speed.value),
                        textColor: weatherManager.optimalTextColor,
                        secondaryColor: weatherManager.optimalSecondaryTextColor
                    )
                }

                HStack(spacing: 10) {
                    WeatherMetricTile(
                        icon: "eye.fill",
                        label: L("weather.visibility"),
                        value: String(format: "%.0f km", weather.visibility.value / 1000),
                        textColor: weatherManager.optimalTextColor,
                        secondaryColor: weatherManager.optimalSecondaryTextColor
                    )

                    WeatherMetricTile(
                        icon: "gauge.with.dots.needle.bottom.50percent",
                        label: L("weather.pressure"),
                        value: String(format: "%.0f hPa", weather.pressure.value),
                        textColor: weatherManager.optimalTextColor,
                        secondaryColor: weatherManager.optimalSecondaryTextColor
                    )
                }
            } else {
                Text(L("weather.noData"))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(weatherManager.optimalSecondaryTextColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
        }
        .padding(16)
        .glassCard(cornerRadius: 20)
    }

    private var tabSelector: some View {
        HStack(spacing: 12) {
            ForecastTabButton(
                title: L("weather.hourly"),
                isSelected: selectedTab == .hourly,
                textColor: weatherManager.optimalTextColor
            ) {
                HapticManager.selection()
                withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
                    selectedTab = .hourly
                }
            }

            ForecastTabButton(
                title: L("weather.daily"),
                isSelected: selectedTab == .daily,
                textColor: weatherManager.optimalTextColor
            ) {
                HapticManager.selection()
                withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
                    selectedTab = .daily
                }
            }
        }
    }

    private var hourlySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L("weather.hourly"))
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(weatherManager.optimalTextColor)

            if isLoadingForecast {
                ProgressView()
                    .tint(weatherManager.optimalTextColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
            } else if hourlyForecast.isEmpty {
                Text(L("weather.noData"))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(weatherManager.optimalSecondaryTextColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Array(hourlyForecast.prefix(24)), id: \.date) { hour in
                            HourlyTile(
                                hour: hour,
                                isCurrent: Calendar.current.isDate(hour.date, equalTo: Date(), toGranularity: .hour),
                                textColor: weatherManager.optimalTextColor,
                                secondaryColor: weatherManager.optimalSecondaryTextColor
                            )
                        }
                    }
                    .padding(.horizontal, 2)
                    .padding(.vertical, 6)
                }
            }
        }
        .padding(16)
        .glassCard(cornerRadius: 20)
    }

    private var dailySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L("weather.daily"))
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(weatherManager.optimalTextColor)

            if isLoadingForecast {
                ProgressView()
                    .tint(weatherManager.optimalTextColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
            } else if dailyForecast.isEmpty {
                Text(L("weather.noData"))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(weatherManager.optimalSecondaryTextColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
            } else {
                let days = Array(dailyForecast.prefix(7))
                let minTemp = days.map { $0.lowTemperature.value }.min() ?? 0
                let maxTemp = days.map { $0.highTemperature.value }.max() ?? 1

                VStack(spacing: 10) {
                    ForEach(days, id: \.date) { day in
                        DailyTile(
                            day: day,
                            isToday: Calendar.current.isDateInToday(day.date),
                            minTemp: minTemp,
                            maxTemp: maxTemp,
                            textColor: weatherManager.optimalTextColor,
                            secondaryColor: weatherManager.optimalSecondaryTextColor
                        )
                    }
                }
            }
        }
        .padding(16)
        .glassCard(cornerRadius: 20)
    }

    private func loadForecast() {
        if isLoadingForecast {
            return
        }

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

private enum ForecastTab {
    case hourly
    case daily
}

struct WeatherBadge: View {
    let icon: String
    let title: String
    let value: String
    let textColor: Color
    let secondaryColor: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(textColor.opacity(0.9))

            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(textColor)

            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(secondaryColor)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.14))
        )
    }
}

struct WeatherMetricTile: View {
    let icon: String
    let label: String
    let value: String
    let textColor: Color
    let secondaryColor: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(textColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(secondaryColor)

                Text(value)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(textColor)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.14))
        )
    }
}

struct ForecastTabButton: View {
    let title: String
    let isSelected: Bool
    let textColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(isSelected ? .white : textColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? AnyShapeStyle(LiquidGlassStyle.primaryGradient) : AnyShapeStyle(Color.white.opacity(0.16)))
                )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct HourlyTile: View {
    let hour: HourWeather
    let isCurrent: Bool
    let textColor: Color
    let secondaryColor: Color

    private var hourText: String {
        if isCurrent {
            return L("weather.now")
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: hour.date)
    }

    var body: some View {
        VStack(spacing: 10) {
            Text(hourText)
                .font(.system(size: 12, weight: isCurrent ? .bold : .medium))
                .foregroundColor(isCurrent ? textColor : secondaryColor)

            Image(systemName: weatherIconSymbol(for: hour.condition, isDaylight: hour.isDaylight))
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(textColor)
                .frame(height: 24)

            Text(String(format: "%.0f°", hour.temperature.value))
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundColor(textColor)
        }
        .frame(width: 76)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isCurrent ? AnyShapeStyle(LiquidGlassStyle.primaryGradient) : AnyShapeStyle(Color.white.opacity(0.14)))
        )
    }
}

struct DailyTile: View {
    let day: DayWeather
    let isToday: Bool
    let minTemp: Double
    let maxTemp: Double
    let textColor: Color
    let secondaryColor: Color

    private var dayText: String {
        if isToday {
            return L("weather.today")
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        formatter.locale = Locale(identifier: AppSettings.shared.selectedLanguage == "zh-Hans" ? "zh-Hans" : "en")
        return formatter.string(from: day.date)
    }

    private var normalizedStart: CGFloat {
        guard maxTemp > minTemp else { return 0 }
        return CGFloat((day.lowTemperature.value - minTemp) / (maxTemp - minTemp))
    }

    private var normalizedWidth: CGFloat {
        guard maxTemp > minTemp else { return 1 }
        return CGFloat((day.highTemperature.value - day.lowTemperature.value) / (maxTemp - minTemp))
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(dayText)
                .font(.system(size: 15, weight: isToday ? .bold : .medium))
                .foregroundColor(textColor)
                .frame(width: 88, alignment: .leading)

            Image(systemName: weatherIconSymbol(for: day.condition, isDaylight: true))
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(textColor)
                .frame(width: 24)

            Text(String(format: "%.0f°", day.lowTemperature.value))
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .monospacedDigit()
                .foregroundColor(secondaryColor)
                .frame(width: 34, alignment: .trailing)

            GeometryReader { proxy in
                let width = max(0, proxy.size.width)
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(secondaryColor.opacity(0.22))
                        .frame(height: 6)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.8), Color.orange.opacity(0.9)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: width * max(0.06, normalizedWidth), height: 6)
                        .offset(x: width * min(0.94, normalizedStart))
                }
            }
            .frame(height: 6)

            Text(String(format: "%.0f°", day.highTemperature.value))
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundColor(textColor)
                .frame(width: 34, alignment: .leading)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isToday ? AnyShapeStyle(Color.white.opacity(0.2)) : AnyShapeStyle(Color.white.opacity(0.08)))
        )
    }
}

private func weatherIconSymbol(for condition: WeatherCondition, isDaylight: Bool) -> String {
    switch condition {
    case .clear:
        return isDaylight ? "sun.max.fill" : "moon.stars.fill"
    case .cloudy:
        return "cloud.fill"
    case .mostlyClear:
        return isDaylight ? "cloud.sun.fill" : "cloud.moon.fill"
    case .mostlyCloudy:
        return "cloud.fill"
    case .partlyCloudy:
        return isDaylight ? "cloud.sun.fill" : "cloud.moon.fill"
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

#Preview {
    WeatherDetailView(
        weatherManager: WeatherManager(),
        coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
    )
}
