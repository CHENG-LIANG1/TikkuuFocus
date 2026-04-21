//
//  LiquidGlassStyle.swift
//  Tikkuu Focus
//
//  Created by Tikkuu on 2026/2/8.
//

import SwiftUI

/// Liquid glass visual style modifiers and components
struct LiquidGlassStyle {

    // MARK: - Accent Colors
    static let accentBlueLight = Color(red: 0.415, green: 0.607, blue: 0.800) // Brand Blue
    static let accentBlueDark = Color(red: 0.415, green: 0.607, blue: 0.800)

    static let primaryGradient = LinearGradient(
        colors: [Color(red: 0.415, green: 0.607, blue: 0.800), Color(red: 0.415, green: 0.607, blue: 0.800).opacity(0.8)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let accentGradient = LinearGradient(
        colors: [Color(red: 0.851, green: 0.467, blue: 0.341), Color(red: 0.851, green: 0.467, blue: 0.341).opacity(0.8)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static func glassBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.006) : Color.white.opacity(0.12)
    }

    static func glassBorder(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.1) : Color.white.opacity(0.2)
    }

    static func shadowColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.black.opacity(0.35) : Color.black.opacity(0.12)
    }

    static func innerGlow(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.015) : Color.white.opacity(0.22)
    }

    static func glassMaterialOpacity(for colorScheme: ColorScheme) -> Double {
        colorScheme == .dark ? 0.62 : 0.68
    }

    static func glassLayerFill(for colorScheme: ColorScheme) -> LinearGradient {
        LinearGradient(
            colors: colorScheme == .dark
                ? [
                    Color.white.opacity(0.035),
                    Color.white.opacity(0.014),
                    Color(red: 0.16, green: 0.22, blue: 0.33).opacity(0.04)
                ]
                : [
                    Color.white.opacity(0.12),
                    Color.white.opacity(0.07),
                    Color(red: 0.84, green: 0.91, blue: 0.99).opacity(0.05)
                ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func glassInsetFill(for colorScheme: ColorScheme) -> LinearGradient {
        LinearGradient(
            colors: colorScheme == .dark
                ? [
                    Color.white.opacity(0.028),
                    Color.white.opacity(0.012),
                    Color.black.opacity(0.05)
                ]
                : [
                    Color.white.opacity(0.11),
                    Color.white.opacity(0.06),
                    Color(red: 0.82, green: 0.89, blue: 0.98).opacity(0.04)
                ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func glassEdgeStroke(for colorScheme: ColorScheme) -> LinearGradient {
        LinearGradient(
            colors: colorScheme == .dark
                ? [Color.white.opacity(0.15), Color.white.opacity(0.035)]
                : [Color.white.opacity(0.24), Color.white.opacity(0.07)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
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
    @Environment(\.colorScheme) private var colorScheme
    var cornerRadius: CGFloat = 28
    var tintColor: Color? = nil

    func body(content: Content) -> some View {
        content
            .background {
                cardBackground
            }
    }

    @ViewBuilder
    private var cardBackground: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        ZStack {
            shape
                .fill(.ultraThinMaterial)
                .opacity(LiquidGlassStyle.glassMaterialOpacity(for: colorScheme))

            shape
                .fill(LiquidGlassStyle.glassLayerFill(for: colorScheme))

            if let tintColor = tintColor {
                shape
                    .fill(
                        LinearGradient(
                            colors: [
                                tintColor.opacity(colorScheme == .dark ? 0.24 : 0.14),
                                tintColor.opacity(0.03)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            shape.strokeBorder(LiquidGlassStyle.glassEdgeStroke(for: colorScheme), lineWidth: 1)

            shape
                .strokeBorder(
                    colorScheme == .dark
                        ? Color.white.opacity(0.08)
                        : Color.white.opacity(0.24),
                    lineWidth: 0.5
                )
        }
        .shadow(
            color: colorScheme == .dark ? Color.black.opacity(0.32) : Color.black.opacity(0.10),
            radius: 24,
            x: 0,
            y: 12
        )
        .shadow(
            color: colorScheme == .dark ? Color.white.opacity(0.04) : Color.white.opacity(0.22),
            radius: 1,
            x: 0,
            y: 1
        )
    }
}

struct GlassButtonModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var settings = AppSettings.shared
    var isPressed: Bool = false

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(buttonBackground)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.28, dampingFraction: 0.72), value: isPressed)
    }

    @ViewBuilder
    private var buttonBackground: some View {
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)

        ZStack {
            shape.fill(.ultraThinMaterial)
                .opacity(LiquidGlassStyle.glassMaterialOpacity(for: colorScheme))

            shape
                .fill(
                    LinearGradient(
                        colors: [LiquidGlassStyle.innerGlow(for: colorScheme).opacity(0.8), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .blendMode(colorScheme == .dark ? .screen : .overlay)

            shape.strokeBorder(LiquidGlassStyle.glassBorder(for: colorScheme), lineWidth: 1)
        }
        .shadow(color: LiquidGlassStyle.shadowColor(for: colorScheme), radius: 8, x: 0, y: 4)
    }
}

struct InsetSurfaceModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    var cornerRadius: CGFloat = 12
    var isActive: Bool = false

    func body(content: Content) -> some View {
        content
            .background(insetBackground)
    }

    @ViewBuilder
    private var insetBackground: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        if isActive {
            ZStack {
                shape
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.accentColor.opacity(colorScheme == .dark ? 0.92 : 0.86),
                                Color.accentColor.opacity(colorScheme == .dark ? 0.72 : 0.62)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                shape
                    .strokeBorder(Color.white.opacity(colorScheme == .dark ? 0.30 : 0.42), lineWidth: 0.8)
            }
            .shadow(color: Color.accentColor.opacity(0.34), radius: 10, x: 0, y: 5)
        } else {
            ZStack {
                shape
                    .fill(.thinMaterial)
                    .opacity(colorScheme == .dark ? 0.55 : 0.7)

                shape
                    .fill(LiquidGlassStyle.glassInsetFill(for: colorScheme))

                shape
                    .strokeBorder(
                        colorScheme == .dark
                            ? Color.white.opacity(0.12)
                            : Color.white.opacity(0.35),
                        lineWidth: 0.8
                    )
            }
        }
    }
}

struct ThemedRoundedBackgroundModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background {
                let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                ZStack {
                    shape
                        .fill(.ultraThinMaterial)
                        .opacity(colorScheme == .dark ? 0.7 : 0.82)
                    shape
                        .fill(LiquidGlassStyle.glassLayerFill(for: colorScheme))
                    shape
                        .strokeBorder(LiquidGlassStyle.glassEdgeStroke(for: colorScheme), lineWidth: 1)
                }
                .shadow(
                    color: colorScheme == .dark ? Color.black.opacity(0.28) : Color.black.opacity(0.10),
                    radius: 16,
                    x: 0,
                    y: 8
                )
            }
    }
}

// MARK: - View Extensions

extension View {
    func glassCard(cornerRadius: CGFloat = 16, tintColor: Color? = nil) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius, tintColor: tintColor))
    }

    func glassButton(isPressed: Bool = false) -> some View {
        modifier(GlassButtonModifier(isPressed: isPressed))
    }

    func insetSurface(cornerRadius: CGFloat = 12, isActive: Bool = false) -> some View {
        modifier(InsetSurfaceModifier(cornerRadius: cornerRadius, isActive: isActive))
    }

    func themedRoundedBackground(cornerRadius: CGFloat = 16) -> some View {
        modifier(ThemedRoundedBackgroundModifier(cornerRadius: cornerRadius))
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
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(LiquidGlassStyle.glassBackground(for: colorScheme))
                    .frame(height: height)

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
    @Environment(\.colorScheme) private var colorScheme
    @State private var isAnimated = false

    var body: some View {
        ZStack {
            baseColor
            
            GeometryReader { proxy in
                let width = proxy.size.width
                let height = proxy.size.height
                
                ZStack {
                    Circle()
                        .fill(orb1Color)
                        .blur(radius: 120)
                        .frame(width: width * 1.5)
                        .offset(
                            x: isAnimated ? -width * 0.2 : width * 0.2,
                            y: isAnimated ? -height * 0.2 : height * 0.1
                        )
                        .hueRotation(.degrees(isAnimated ? 30 : 0))
                    
                    Circle()
                        .fill(orb2Color)
                        .blur(radius: 140)
                        .frame(width: width * 1.8)
                        .offset(
                            x: isAnimated ? width * 0.4 : -width * 0.2,
                            y: isAnimated ? height * 0.4 : height * 0.6
                        )
                        .hueRotation(.degrees(isAnimated ? -30 : 0))
                }
                .opacity(colorScheme == .dark ? 0.6 : 0.8)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            guard !PerformanceOptimizer.shared.isEnergySavingMode else { return }
            withAnimation(.easeInOut(duration: 12.0).repeatForever(autoreverses: true)) {
                isAnimated = true
            }
        }
    }

    private var baseColor: Color {
        colorScheme == .dark ? Color(white: 0.04) : Color(white: 0.98)
    }
    
    private var orb1Color: Color {
        colorScheme == .dark ? Color(red: 0.3, green: 0.4, blue: 0.6) : Color(red: 0.7, green: 0.85, blue: 0.95)
    }
    
    private var orb2Color: Color {
        colorScheme == .dark ? Color(red: 0.4, green: 0.3, blue: 0.5) : Color(red: 0.95, green: 0.8, blue: 0.85)
    }
}
