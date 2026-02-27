//
//  CommonButtons.swift
//  Tikkuu Focus
//
//  Created by Tikkuu on 2026/2/10.
//

import SwiftUI

// MARK: - Primary Button

struct PrimaryButton: View {
    @ObservedObject private var settings = AppSettings.shared
    let title: String
    let icon: String?
    let action: () -> Void
    let isLoading: Bool

    private var accentTextColor: Color {
        settings.isNeumorphismLight ? Color(red: 0.18, green: 0.22, blue: 0.32) : .white
    }
    
    init(title: String, icon: String? = nil, isLoading: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isLoading = isLoading
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: accentTextColor))
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(accentTextColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background {
                if settings.selectedVisualStyle == .neumorphism {
                    NeumorphSurface(
                        cornerRadius: 16,
                        depth: .raised,
                        fill: AnyShapeStyle(Color(red: 0.42, green: 0.56, blue: 0.92))
                    )
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(GradientStyles.primaryGradient)
                }
            }
            .shadow(color: Color.blue.opacity(settings.selectedVisualStyle == .neumorphism ? 0.2 : 0.3), radius: 10, x: 0, y: 5)
        }
        .disabled(isLoading)
    }
}

// MARK: - Secondary Button

struct SecondaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    
    init(title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                }
                
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .insetSurface(cornerRadius: 12, isActive: false)
        }
    }
}

// MARK: - Icon Button

struct IconButton: View {
    let icon: String
    let size: CGFloat
    let action: () -> Void
    
    init(icon: String, size: CGFloat = 44, action: @escaping () -> Void) {
        self.icon = icon
        self.size = size
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundColor(.primary)
                .frame(width: size, height: size)
                .glassCard(cornerRadius: size / 2)
        }
    }
}

// MARK: - Gradient Button

struct GradientButton: View {
    @ObservedObject private var settings = AppSettings.shared
    let title: String
    let icon: String?
    let gradient: LinearGradient
    let action: () -> Void

    private var accentTextColor: Color {
        settings.isNeumorphismLight ? Color(red: 0.18, green: 0.22, blue: 0.32) : .white
    }
    
    init(title: String, icon: String? = nil, gradient: LinearGradient = GradientStyles.primaryGradient, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.gradient = gradient
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                }
                
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(accentTextColor)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background {
                if settings.selectedVisualStyle == .neumorphism {
                    NeumorphSurface(
                        cornerRadius: 999,
                        depth: .raised,
                        fill: AnyShapeStyle(Color(red: 0.45, green: 0.55, blue: 0.90))
                    )
                } else {
                    Capsule()
                        .fill(gradient)
                }
            }
            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
        }
    }
}
