//
//  NeomorphicStyle.swift
//  Tikkuu Focus
//
//  Created by Tikkuu on 2026/2/11.
//

import SwiftUI

struct NeomorphicStyle {
    
    // MARK: - Colors (Based on Figma)
    
    static let mainBackground = Color(red: 0.10, green: 0.10, blue: 0.18) // #1A1A2E
    static let cardBackground = Color(red: 0.12, green: 0.16, blue: 0.23).opacity(0.3) // rgba(30, 41, 59, 0.30)
    static let innerShadowDark = Color.black.opacity(0.4)
    static let innerShadowLight = Color.white.opacity(0.05)
    static let outerShadowDark = Color.black.opacity(0.3)
    static let outerShadowLight = Color.white.opacity(0.03)
    
    // MARK: - Gradients
    
    static let primaryGradient = LinearGradient(
        colors: [
            Color(red: 0.49, green: 0.61, blue: 1.0), // #7C9CFF
            Color(red: 0.35, green: 0.50, blue: 0.95)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let cyclingGradient = LinearGradient(
        colors: [
            Color(red: 0.66, green: 0.33, blue: 0.97), // #A855F7
            Color(red: 0.75, green: 0.15, blue: 0.83)  // #C026D3
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let durationGradient = LinearGradient(
        colors: [
            Color(red: 1.0, green: 0.42, blue: 0.24), // #FF6B3D
            Color(red: 0.94, green: 0.27, blue: 0.27)  // #EF4444
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - View Modifiers

struct NeomorphicCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 24
    var isPressed: Bool = false
    
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    if isPressed {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(NeomorphicStyle.cardBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: cornerRadius)
                                    .stroke(NeomorphicStyle.innerShadowDark, lineWidth: 4)
                                    .blur(radius: 4)
                                    .offset(x: 2, y: 2)
                                    .mask(RoundedRectangle(cornerRadius: cornerRadius).fill(LinearGradient(colors: [Color.black, Color.clear], startPoint: .topLeading, endPoint: .bottomTrailing)))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: cornerRadius)
                                    .stroke(NeomorphicStyle.innerShadowLight, lineWidth: 4)
                                    .blur(radius: 4)
                                    .offset(x: -2, y: -2)
                                    .mask(RoundedRectangle(cornerRadius: cornerRadius).fill(LinearGradient(colors: [Color.clear, Color.black], startPoint: .topLeading, endPoint: .bottomTrailing)))
                            )
                    } else {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(NeomorphicStyle.cardBackground)
                            .shadow(color: NeomorphicStyle.outerShadowDark, radius: 16, x: 8, y: 8)
                            .shadow(color: NeomorphicStyle.outerShadowLight, radius: 12, x: -4, y: -4)
                    }
                }
            )
    }
}

// MARK: - Inset Shadow Modifier (Helper for Neomorphism)
extension View {
    func neomorphicInsetShadow<S: Shape>(shape: S, color: Color, lineWidth: CGFloat, blur: CGFloat, offset: CGPoint) -> some View {
        self.overlay(
            shape
                .stroke(color, lineWidth: lineWidth)
                .blur(radius: blur)
                .offset(x: offset.x, y: offset.y)
                .mask(shape)
        )
    }
}

struct NeomorphicInsetCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 16
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.black.opacity(0.2)) // Deep background for inset
                    .neomorphicInsetShadow(
                        shape: RoundedRectangle(cornerRadius: cornerRadius),
                        color: NeomorphicStyle.innerShadowDark,
                        lineWidth: 4,
                        blur: 8,
                        offset: CGPoint(x: 4, y: 4)
                    )
                    .neomorphicInsetShadow(
                        shape: RoundedRectangle(cornerRadius: cornerRadius),
                        color: NeomorphicStyle.innerShadowLight,
                        lineWidth: 4,
                        blur: 8,
                        offset: CGPoint(x: -4, y: -4)
                    )
            )
    }
}

extension View {
    func neomorphicCard(cornerRadius: CGFloat = 24, isPressed: Bool = false) -> some View {
        modifier(NeomorphicCardModifier(cornerRadius: cornerRadius, isPressed: isPressed))
    }
    
    func neomorphicInsetCard(cornerRadius: CGFloat = 16) -> some View {
        modifier(NeomorphicInsetCardModifier(cornerRadius: cornerRadius))
    }
}

// MARK: - Custom Neomorphic Button Component
struct NeomorphicButton<Content: View>: View {
    var action: () -> Void
    var content: Content
    var cornerRadius: CGFloat = 24
    var gradient: LinearGradient? = nil
    @State private var isPressed = false
    
    init(action: @escaping () -> Void, cornerRadius: CGFloat = 24, gradient: LinearGradient? = nil, @ViewBuilder content: () -> Content) {
        self.action = action
        self.cornerRadius = cornerRadius
        self.gradient = gradient
        self.content = content()
    }
    
    var body: some View {
        Button(action: {
            action()
        }) {
            content
                .padding()
                .background(
                    ZStack {
                        if let gradient = gradient {
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .fill(gradient)
                                .shadow(color: NeomorphicStyle.outerShadowDark, radius: 10, x: 0, y: 5)
                                .overlay(
                                    RoundedRectangle(cornerRadius: cornerRadius)
                                        .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        } else {
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .fill(NeomorphicStyle.cardBackground)
                                .shadow(color: NeomorphicStyle.outerShadowDark, radius: 16, x: 8, y: 8)
                                .shadow(color: NeomorphicStyle.outerShadowLight, radius: 12, x: -4, y: -4)
                        }
                    }
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
