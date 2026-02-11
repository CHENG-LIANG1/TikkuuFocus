//
//  CommonStyles.swift
//  Tikkuu Focus
//
//  Created by Tikkuu on 2026/2/10.
//

import SwiftUI

// MARK: - Gradient Styles

struct GradientStyles {
    static let primaryGradient = LinearGradient(
        colors: [Color.blue, Color.purple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let accentGradient = LinearGradient(
        colors: [Color.orange, Color.red],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let successGradient = LinearGradient(
        colors: [Color.green, Color.teal],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    static let warningGradient = LinearGradient(
        colors: [Color.yellow, Color.orange],
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

// MARK: - Text Styles

struct TextStyles {
    static func title(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 24, weight: .bold, design: .rounded))
            .foregroundColor(.primary)
    }
    
    static func subtitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 18, weight: .semibold))
            .foregroundColor(.primary)
    }
    
    static func body(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 15, weight: .regular))
            .foregroundColor(.secondary)
    }
    
    static func caption(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .medium))
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
