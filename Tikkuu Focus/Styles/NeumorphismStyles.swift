//
//  NeumorphismStyles.swift
//  Tikkuu Focus
//
//  Neumorphism view extensions
//

import SwiftUI

// MARK: - Neumorphism Colors

enum NeumorphismColors {
    static let darkBackground = Color(red: 0.165, green: 0.165, blue: 0.251)
    static let darkSurface = Color(red: 0.196, green: 0.196, blue: 0.302)
    static let darkPressed = Color(red: 0.125, green: 0.125, blue: 0.195)
    static let darkPrimary = Color(red: 0.545, green: 0.655, blue: 1.0)

    static let lightBackground = Color(red: 0.941, green: 0.957, blue: 0.973)
    static let lightSurface = Color(red: 0.890, green: 0.941, blue: 1.0)
    static let lightPressed = Color(red: 0.800, green: 0.850, blue: 0.900)
}

// MARK: - Press Events Modifier

struct PressEventsModifier: ViewModifier {
    var onPress: () -> Void
    var onRelease: () -> Void

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in onPress() }
                    .onEnded { _ in onRelease() }
            )
    }
}

extension View {
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        modifier(PressEventsModifier(onPress: onPress, onRelease: onRelease))
    }

    func neumorphicBackground(cornerRadius: CGFloat = 20, depth: NeumorphDepth = .inset) -> some View {
        background(
            NeumorphSurface(cornerRadius: cornerRadius, depth: depth)
        )
    }
}

// MARK: - Neumorphic Button

struct NeumorphicButton<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let cornerRadius: CGFloat
    let action: () -> Void
    let content: Content
    
    @State private var isPressed = false
    
    init(
        cornerRadius: CGFloat = 16,
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.action = action
        self.content = content()
    }
    
    var body: some View {
        Button(action: action) {
            content
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(
                    NeumorphSurface(
                        cornerRadius: cornerRadius,
                        depth: isPressed ? .inset : .raised
                    )
                )
                .scaleEffect(isPressed ? 0.98 : 1.0)
                .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isPressed)
        }
        .buttonStyle(.plain)
        .pressEvents {
            isPressed = true
        } onRelease: {
            isPressed = false
        }
    }
}
