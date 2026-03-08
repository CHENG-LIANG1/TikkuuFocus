//
//  WeatherBackgroundView.swift
//  Tikkuu Focus
//
//  Created by Tikkuu on 2026/2/8.
//

import SwiftUI
import WeatherKit

/// 静态天气背景视图（性能优化版本 - 完全移除动画）
struct WeatherBackgroundView: View {
    let colors: [Color]
    let weatherCondition: WeatherCondition?
    let isDaytime: Bool
    let animationSpeed: Double
    let overlayIntensity: Double
    
    @Environment(\.colorScheme) private var colorScheme
    
    init(colors: [Color], weatherCondition: WeatherCondition? = nil, isDaytime: Bool = true, animationSpeed: Double = 12.0, overlayIntensity: Double = 0.3) {
        self.colors = colors
        self.weatherCondition = weatherCondition
        self.isDaytime = isDaytime
        self.animationSpeed = animationSpeed
        self.overlayIntensity = overlayIntensity
    }
    
    var body: some View {
        ZStack {
            // 静态渐变背景 - 性能优化：完全移除所有动画
            LinearGradient(
                colors: colors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // 简单的静态装饰层
            LinearGradient(
                colors: colors.map { $0.opacity(overlayIntensity * 0.2) },
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
            .ignoresSafeArea()
            .blendMode(.overlay)
            
            Color.black
                .opacity(backgroundDarkenOpacity)
                .ignoresSafeArea()
                .blendMode(.multiply)
        }
    }
    
    private var backgroundDarkenOpacity: Double {
        if colorScheme == .dark {
            return isDaytime ? 0.12 : 0.06
        }
        return isDaytime ? 0.22 : 0.14
    }
}

#Preview {
    WeatherBackgroundView(
        colors: [
            Color(red: 0.4, green: 0.7, blue: 1.0),
            Color(red: 0.5, green: 0.8, blue: 1.0),
            Color(red: 0.6, green: 0.9, blue: 1.0)
        ],
        weatherCondition: .clear,
        isDaytime: true
    )
}
