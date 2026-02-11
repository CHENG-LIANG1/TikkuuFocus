//
//  LiquidGlassStyle.swift
//  Tikkuu Focus
//
//  Created by Tikkuu on 2026/2/8.
//

import SwiftUI

/// Liquid glass visual style modifiers and components
struct LiquidGlassStyle {

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
        colorScheme == .dark ? Color.white.opacity(0.01) : Color.white.opacity(0.25)
    }

    static func glassBorder(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.12) : Color.white.opacity(0.3)
    }

    static func shadowColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.black.opacity(0.35) : Color.black.opacity(0.12)
    }

    static func innerGlow(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.03) : Color.white.opacity(0.4)
    }
}

enum NeumorphDepth {
    case raised
    case inset
}

struct NeumorphismStyle {
    private static var tone: NeumorphismTone {
        AppSettings.shared.selectedNeumorphismTone
    }

    private static var isLightTone: Bool {
        tone == .light
    }

    // Reference palette (dark neumorphism):
    // bg-dark: #2A2A40, surface-dark: #32324D, surface-pressed: #252538, primary: #8BA7FF
    private static let darkBackground = Color(red: 0.165, green: 0.165, blue: 0.251)      // #2A2A40
    private static let darkSurface = Color(red: 0.196, green: 0.196, blue: 0.302)         // #32324D
    private static let darkPressed = Color(red: 0.145, green: 0.145, blue: 0.220)         // #252538
    private static let darkPrimary = Color(red: 0.545, green: 0.655, blue: 1.0)           // #8BA7FF

    // Reference palette (light neumorphism):
    // bg-frost: #F0F4F8, card-mint: #E2F3F0, card-lavender: #EBE9F5, card-blue: #E3F0FF
    // primary: #A5C9FF, accent-glow: #C2DFFF
    private static let lightBackground = Color(red: 0.941, green: 0.957, blue: 0.973)     // #F0F4F8
    private static let lightSurfaceBlue = Color(red: 0.890, green: 0.941, blue: 1.0)      // #E3F0FF
    private static let lightSurfaceMint = Color(red: 0.886, green: 0.953, blue: 0.941)     // #E2F3F0
    private static let lightSurfaceLavender = Color(red: 0.922, green: 0.914, blue: 0.961) // #EBE9F5
    private static let lightGlow = Color(red: 0.761, green: 0.875, blue: 1.0)              // #C2DFFF

    // Palette tuned to match the reference: deep navy base + cool blue light.
    static func surface(for colorScheme: ColorScheme) -> Color {
        if isLightTone {
            return lightSurfaceBlue
        }

        if colorScheme == .dark {
            return darkSurface
        }
        return Color(red: 0.90, green: 0.92, blue: 0.96)
    }

    static func pressedSurface(for colorScheme: ColorScheme) -> Color {
        if isLightTone {
            return lightBackground
        }

        if colorScheme == .dark {
            return darkPressed
        }
        return Color(red: 0.84, green: 0.87, blue: 0.93)
    }

    static func border(for colorScheme: ColorScheme) -> Color {
        if isLightTone {
            return Color(red: 0.760, green: 0.820, blue: 0.910).opacity(0.52)
        }

        if colorScheme == .dark {
            return Color(red: 0.365, green: 0.425, blue: 0.600).opacity(0.52)
        }
        return Color.white.opacity(0.74)
    }

    static func raisedTopHighlight(for colorScheme: ColorScheme) -> Color {
        if isLightTone {
            return Color(red: 0.745, green: 0.815, blue: 0.910).opacity(0.34)
        }

        if colorScheme == .dark {
            return Color(red: 0.345, green: 0.405, blue: 0.580).opacity(0.34)
        }
        return Color.white.opacity(1.0)
    }

    static func raisedBottomShadow(for colorScheme: ColorScheme) -> Color {
        if isLightTone {
            return Color(red: 0.545, green: 0.612, blue: 0.698).opacity(0.52)
        }

        if colorScheme == .dark {
            return Color(red: 0.110, green: 0.120, blue: 0.190).opacity(0.95)
        }
        return Color.black.opacity(0.24)
    }

    static func innerTopHighlight(for colorScheme: ColorScheme) -> Color {
        if isLightTone {
            return Color(red: 0.760, green: 0.830, blue: 0.920).opacity(0.64)
        }

        if colorScheme == .dark {
            return Color(red: 0.335, green: 0.395, blue: 0.575).opacity(0.68)
        }
        return Color.white.opacity(0.92)
    }

    static func innerBottomShadow(for colorScheme: ColorScheme) -> Color {
        if isLightTone {
            return Color(red: 0.490, green: 0.560, blue: 0.650).opacity(0.72)
        }

        if colorScheme == .dark {
            return Color(red: 0.090, green: 0.105, blue: 0.170).opacity(0.88)
        }
        return Color.black.opacity(0.22)
    }

    static func ambientStart(for colorScheme: ColorScheme) -> Color {
        if isLightTone {
            return lightBackground
        }

        if colorScheme == .dark {
            return darkBackground
        }
        return Color(red: 0.93, green: 0.94, blue: 0.97)
    }

    static func ambientMid(for colorScheme: ColorScheme) -> Color {
        if isLightTone {
            return lightSurfaceMint
        }

        if colorScheme == .dark {
            return darkSurface
        }
        return Color(red: 0.90, green: 0.92, blue: 0.95)
    }

    static func ambientEnd(for colorScheme: ColorScheme) -> Color {
        if isLightTone {
            return lightSurfaceLavender
        }

        if colorScheme == .dark {
            return darkPressed
        }
        return Color(red: 0.86, green: 0.89, blue: 0.94)
    }
}

struct NeumorphSurface: View {
    @Environment(\.colorScheme) private var colorScheme
    let cornerRadius: CGFloat
    let depth: NeumorphDepth
    var fill: AnyShapeStyle? = nil

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        ZStack {
            shape
                .fill(fill ?? AnyShapeStyle(depth == .inset
                                            ? NeumorphismStyle.pressedSurface(for: colorScheme)
                                            : NeumorphismStyle.surface(for: colorScheme)))

            if depth == .raised {
                // Raised surfaces keep only a subtle tonal rim.
                shape
                    .strokeBorder(NeumorphismStyle.border(for: colorScheme), lineWidth: colorScheme == .dark ? 1.0 : 0.9)

                shape
                    .fill(
                        LinearGradient(
                            colors: [
                                NeumorphismStyle.raisedTopHighlight(for: colorScheme).opacity(0.16),
                                Color.clear,
                                NeumorphismStyle.raisedBottomShadow(for: colorScheme).opacity(0.10)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            } else {
                // Inset surfaces: no outer border, only inner carved edges.
                shape
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                NeumorphismStyle.innerTopHighlight(for: colorScheme),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2.2
                    )

                shape
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                NeumorphismStyle.innerBottomShadow(for: colorScheme)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2.2
                    )

                shape
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                NeumorphismStyle.innerBottomShadow(for: colorScheme).opacity(0.16)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(shape)

                shape
                    .fill(
                        LinearGradient(
                            colors: [
                                NeumorphismStyle.innerTopHighlight(for: colorScheme).opacity(0.10),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(shape)
            }
        }
        .shadow(
            color: depth == .raised
            ? NeumorphismStyle.raisedBottomShadow(for: colorScheme)
            : .clear,
            radius: depth == .raised ? 10 : 0,
            x: depth == .raised ? 6 : 0,
            y: depth == .raised ? 6 : 0
        )
        .shadow(
            color: depth == .raised
            ? NeumorphismStyle.raisedTopHighlight(for: colorScheme)
            : .clear,
            radius: depth == .raised ? 3 : 0,
            x: depth == .raised ? -1 : 0,
            y: depth == .raised ? -1 : 0
        )
        .compositingGroup()
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
    @ObservedObject private var settings = AppSettings.shared
    var cornerRadius: CGFloat = 20

    func body(content: Content) -> some View {
        content
            .background(cardBackground)
    }

    @ViewBuilder
    private var cardBackground: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        if settings.selectedVisualStyle == .neumorphism {
            NeumorphSurface(cornerRadius: cornerRadius, depth: .inset)
        } else {
            ZStack {
                shape.fill(Color.clear)

                shape
                    .strokeBorder(Color.white.opacity(colorScheme == .dark ? 0.14 : 0.22), lineWidth: 1)
            }
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.18 : 0.06), radius: 6, x: 0, y: 3)
        }
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

        if settings.selectedVisualStyle == .neumorphism {
            NeumorphSurface(cornerRadius: 16, depth: isPressed ? .inset : .raised)
        } else {
            ZStack {
                shape.fill(.ultraThinMaterial)

                shape
                    .fill(
                        LinearGradient(
                            colors: [LiquidGlassStyle.innerGlow(for: colorScheme), Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .blendMode(colorScheme == .dark ? .plusLighter : .overlay)

                shape.strokeBorder(LiquidGlassStyle.glassBorder(for: colorScheme), lineWidth: 1)
            }
            .shadow(color: LiquidGlassStyle.shadowColor(for: colorScheme), radius: 8, x: 0, y: 4)
        }
    }
}

struct InsetSurfaceModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var settings = AppSettings.shared
    var cornerRadius: CGFloat = 12
    var isActive: Bool = false

    func body(content: Content) -> some View {
        content
            .background(insetBackground)
    }

    @ViewBuilder
    private var insetBackground: some View {
        if settings.selectedVisualStyle == .neumorphism {
            let fillStyle = isActive ? AnyShapeStyle(LiquidGlassStyle.primaryGradient) : nil
            NeumorphSurface(cornerRadius: cornerRadius, depth: .inset, fill: fillStyle)
        } else {
            let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            if isActive {
                shape
                    .fill(
                        AnyShapeStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.3, green: 0.5, blue: 0.8),
                                    Color(red: 0.5, green: 0.3, blue: 0.7)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    )
                    .overlay(
                        shape.stroke(Color.clear, lineWidth: 1)
                    )
            } else {
                ZStack {
                    shape.fill(Color.clear)

                    shape
                        .stroke(
                            Color.white.opacity(colorScheme == .dark ? 0.12 : 0.20),
                            lineWidth: 1
                        )
                }
            }
        }
    }
}

struct ThemedRoundedBackgroundModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var settings = AppSettings.shared
    let cornerRadius: CGFloat
    let depth: NeumorphDepth

    func body(content: Content) -> some View {
        content
            .background {
                if settings.selectedVisualStyle == .neumorphism {
                    NeumorphSurface(cornerRadius: cornerRadius, depth: depth)
                } else {
                    let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    shape
                        .fill(Color.clear)
                        .overlay(
                            shape.strokeBorder(Color.white.opacity(colorScheme == .dark ? 0.14 : 0.22), lineWidth: 1)
                        )
                }
            }
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

    func insetSurface(cornerRadius: CGFloat = 12, isActive: Bool = false) -> some View {
        modifier(InsetSurfaceModifier(cornerRadius: cornerRadius, isActive: isActive))
    }

    func themedRoundedBackground(cornerRadius: CGFloat = 16, depth: NeumorphDepth = .inset) -> some View {
        modifier(ThemedRoundedBackgroundModifier(cornerRadius: cornerRadius, depth: depth))
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
    @ObservedObject private var settings = AppSettings.shared
    @State private var animateGradient = false

    var body: some View {
        ZStack {
            if settings.selectedVisualStyle == .neumorphism {
                NeumorphismStyle.ambientMid(for: colorScheme)
            } else {
                LinearGradient(
                    colors: colorScheme == .dark ? darkColors : lightColors,
                    startPoint: animateGradient ? .topLeading : .bottomLeading,
                    endPoint: animateGradient ? .bottomTrailing : .topTrailing
                )
            }
        }
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
            Color(red: 0.08, green: 0.12, blue: 0.20),
            Color(red: 0.12, green: 0.08, blue: 0.18),
            Color(red: 0.08, green: 0.15, blue: 0.18)
        ]
    }
}
