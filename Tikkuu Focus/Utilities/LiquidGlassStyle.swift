//
//  LiquidGlassStyle.swift
//  Tikkuu Focus
//
//  Created by Tikkuu on 2026/2/8.
//

import SwiftUI

/// Liquid glass visual style modifiers and components
struct LiquidGlassStyle {
    
    // MARK: - Colors
    
    // 更简洁优雅的渐变 - Focus Flight 风格
    static let primaryGradient = LinearGradient(
        colors: [
            Color(red: 0.4, green: 0.6, blue: 1.0),
            Color(red: 0.5, green: 0.5, blue: 0.95)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let accentGradient = LinearGradient(
        colors: [
            Color(red: 1.0, green: 0.65, blue: 0.4),
            Color(red: 0.95, green: 0.5, blue: 0.55)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static func glassBackground(for colorScheme: ColorScheme) -> Color {
        if colorScheme == .dark {
            // 深色模式：极致通透的玻璃效果 - 大幅增加透明度
            return Color.white.opacity(0.01)
        } else {
            // 浅色模式：明亮轻盈的白色玻璃 - 大幅增加透明度
            return Color.white.opacity(0.25)
        }
    }
    
    static func glassBorder(for colorScheme: ColorScheme) -> Color {
        if colorScheme == .dark {
            // 深色模式：精致的边框 - 大幅增加透明度
            return Color.white.opacity(0.12)
        } else {
            // 浅色模式：清晰的边框 - 大幅增加透明度
            return Color.white.opacity(0.3)
        }
    }
    
    static func shadowColor(for colorScheme: ColorScheme) -> Color {
        if colorScheme == .dark {
            // 深色模式：轻柔的阴影
            return Color.black.opacity(0.35)
        } else {
            // 浅色模式：细腻的阴影
            return Color.black.opacity(0.12)
        }
    }
    
    static func innerGlow(for colorScheme: ColorScheme) -> Color {
        if colorScheme == .dark {
            return Color.white.opacity(0.03)
        } else {
            return Color.white.opacity(0.4)
        }
    }
}

// MARK: - Environment Keys for Adaptive Text Colors

struct AdaptiveTextColorKey: EnvironmentKey {
    static let defaultValue: Color = .primary
}

struct AdaptiveSecondaryTextColorKey: EnvironmentKey {
    static let defaultValue: Color = .secondary
}

extension EnvironmentValues {
    var adaptiveTextColor: Color {
        get { self[AdaptiveTextColorKey.self] }
        set { self[AdaptiveTextColorKey.self] = newValue }
    }
    
    var adaptiveSecondaryTextColor: Color {
        get { self[AdaptiveSecondaryTextColorKey.self] }
        set { self[AdaptiveSecondaryTextColorKey.self] = newValue }
    }
}

// MARK: - View Modifiers

struct GlassCardModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    var cornerRadius: CGFloat = 20
    
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // 主玻璃层 - Focus Flight 风格的极致通透
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)
                    
                    // 内发光层 - 轻盈感
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [
                                    LiquidGlassStyle.innerGlow(for: colorScheme),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .blendMode(colorScheme == .dark ? .plusLighter : .overlay)
                    
                    // 边框 - 简洁清晰
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(
                            LiquidGlassStyle.glassBorder(for: colorScheme),
                            lineWidth: 1
                        )
                }
            )
            .shadow(color: LiquidGlassStyle.shadowColor(for: colorScheme), radius: 12, x: 0, y: 6)
            .shadow(color: LiquidGlassStyle.shadowColor(for: colorScheme).opacity(0.3), radius: 3, x: 0, y: 1)
    }
}

struct GlassButtonModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    var isPressed: Bool = false
    
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                    
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    LiquidGlassStyle.innerGlow(for: colorScheme),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .blendMode(colorScheme == .dark ? .plusLighter : .overlay)
                    
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(LiquidGlassStyle.glassBorder(for: colorScheme), lineWidth: 1)
                }
            )
            .shadow(color: LiquidGlassStyle.shadowColor(for: colorScheme), radius: 8, x: 0, y: 4)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
    }
}

// MARK: - View Extensions

extension View {
    func glassCard(cornerRadius: CGFloat = 20) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius))
    }
    
    func glassButton(isPressed: Bool = false) -> some View {
        modifier(GlassButtonModifier(isPressed: isPressed))
    }
    
    func floating(delay: Double = 0) -> some View {
        modifier(FloatingModifier(delay: delay))
    }
}

// MARK: - Custom Components

struct GlassProgressBar: View {
    @Environment(\.colorScheme) var colorScheme
    var progress: Double
    var height: CGFloat = 8
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(LiquidGlassStyle.glassBackground(for: colorScheme))
                    .frame(height: height)
                
                // Progress fill
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(LiquidGlassStyle.primaryGradient)
                    .frame(width: geometry.size.width * progress, height: height)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progress)
            }
        }
        .frame(height: height)
    }
}

struct GlassBadge: View {
    @Environment(\.colorScheme) var colorScheme
    var text: String
    var icon: String?
    
    var body: some View {
        HStack(spacing: 6) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
            }
            Text(text)
                .font(.system(size: 13, weight: .semibold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(LiquidGlassStyle.accentGradient)
                .shadow(color: LiquidGlassStyle.shadowColor(for: colorScheme), radius: 4, x: 0, y: 2)
        )
    }
}

struct AnimatedGradientBackground: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var animateGradient = false
    
    var body: some View {
        LinearGradient(
            colors: colorScheme == .dark ? darkColors : lightColors,
            startPoint: animateGradient ? .topLeading : .bottomLeading,
            endPoint: animateGradient ? .bottomTrailing : .topTrailing
        )
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 8.0).repeatForever(autoreverses: true)) {
                animateGradient = true
            }
        }
    }
    
    private var lightColors: [Color] {
        [
            Color(red: 0.85, green: 0.92, blue: 0.98),
            Color(red: 0.95, green: 0.88, blue: 0.92),
            Color(red: 0.88, green: 0.95, blue: 0.92)
        ]
    }
    
    private var darkColors: [Color] {
        [
            Color(red: 0.08, green: 0.12, blue: 0.20),  // 更深的深蓝色
            Color(red: 0.12, green: 0.08, blue: 0.18),  // 更深的深紫色
            Color(red: 0.08, green: 0.15, blue: 0.18)   // 更深的深青色
        ]
    }
}
