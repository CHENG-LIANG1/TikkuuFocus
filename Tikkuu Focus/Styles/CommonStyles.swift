//
//  CommonStyles.swift
//  Tikkuu Focus
//
//  Created by Tikkuu on 2026/2/10.
//

import SwiftUI

// MARK: - Brand Colors (Anthropic / Grow)
struct BrandColors {
    static let dark = Color(red: 0.05, green: 0.05, blue: 0.05)         // Clean dark
    static let light = Color(red: 0.98, green: 0.98, blue: 0.98)        // Clean off-white
    static let midGray = Color(red: 0.70, green: 0.70, blue: 0.70)      // Soft gray
    static let lightGray = Color(red: 0.92, green: 0.92, blue: 0.92)    // Lighter gray
    static let orange = Color(red: 0.85, green: 0.60, blue: 0.50)       // Pastel orange
    static let blue = Color(red: 0.50, green: 0.65, blue: 0.75)         // Pastel blue
    static let green = Color(red: 0.50, green: 0.70, blue: 0.60)        // Pastel green
}

// MARK: - Gradient Styles

struct GradientStyles {
    static let primaryGradient = LinearGradient(
        colors: [Color(red: 0.5, green: 0.7, blue: 0.6), Color(red: 0.45, green: 0.65, blue: 0.55)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let accentGradient = LinearGradient(
        colors: [Color(red: 0.85, green: 0.6, blue: 0.5), Color(red: 0.8, green: 0.55, blue: 0.45)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let successGradient = LinearGradient(
        colors: [Color(red: 0.5, green: 0.7, blue: 0.6), Color(red: 0.45, green: 0.65, blue: 0.55)],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    static let warningGradient = LinearGradient(
        colors: [Color(red: 0.9, green: 0.75, blue: 0.45), Color(red: 0.85, green: 0.7, blue: 0.4)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Shadow Styles

struct ShadowStyles {
    static func soft(color: Color = .black, opacity: Double = 0.1, radius: CGFloat = 10, x: CGFloat = 0, y: CGFloat = 5) -> some View {
        EmptyView().shadow(color: color.opacity(opacity), radius: radius, x: x, y: y)
    }
    
    static func medium(color: Color = .black, opacity: Double = 0.15, radius: CGFloat = 15, x: CGFloat = 0, y: CGFloat = 6) -> some View {
        EmptyView().shadow(color: color.opacity(opacity), radius: radius, x: x, y: y)
    }
    
    static func strong(color: Color = .black, opacity: Double = 0.25, radius: CGFloat = 20, x: CGFloat = 0, y: CGFloat = 8) -> some View {
        EmptyView().shadow(color: color.opacity(opacity), radius: radius, x: x, y: y)
    }
}

// MARK: - Typography (Anthropic Brand)

struct BrandTypography {
    static func heading(size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .custom("Poppins", size: size).weight(weight)
    }
    
    static func body(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom("Lora", size: size).weight(weight)
    }
}

// MARK: - Text Styles

struct TextStyles {
    static func title(_ text: String) -> some View {
        Text(text)
            .font(BrandTypography.heading(size: 24, weight: .bold))
            .foregroundColor(.primary)
    }
    
    static func subtitle(_ text: String) -> some View {
        Text(text)
            .font(BrandTypography.heading(size: 18, weight: .semibold))
            .foregroundColor(.primary)
    }
    
    static func body(_ text: String) -> some View {
        Text(text)
            .font(BrandTypography.body(size: 15, weight: .regular))
            .foregroundColor(.secondary)
    }
    
    static func caption(_ text: String) -> some View {
        Text(text)
            .font(BrandTypography.body(size: 13, weight: .medium))
            .foregroundColor(.secondary)
    }
    
    static func metric(_ text: String) -> some View {
        Text(text)
            .font(BrandTypography.heading(size: 20, weight: .bold))
            .foregroundColor(.primary)
    }
    
    static func label(_ text: String) -> some View {
        Text(text)
            .font(BrandTypography.body(size: 11, weight: .medium))
            .foregroundColor(.secondary)
    }
}

// MARK: - Spacing Constants

struct Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
}

// MARK: - Corner Radius Constants

struct CornerRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
}
