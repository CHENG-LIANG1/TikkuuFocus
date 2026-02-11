//
//  AnimationConfig.swift
//  Tikkuu Focus
//
//  Created by Tikkuu on 2026/2/8.
//

import SwiftUI

/// Premium animation configuration inspired by world-class design systems
/// References: Apple HIG, Stripe, Linear, Vercel, Framer Motion
struct AnimationConfig {
    
    // MARK: - Premium Spring Animations (Apple-inspired)
    
    /// Ultra-snappy spring for instant feedback (buttons, toggles)
    /// Response: 0.25s, Damping: 0.68 (slightly underdamped for liveliness)
    static let snappy = Animation.spring(response: 0.25, dampingFraction: 0.68)
    
    /// Quick spring for small interactions (checkboxes, icons)
    /// Response: 0.3s, Damping: 0.7 (balanced)
    static let quickSpring = Animation.spring(response: 0.3, dampingFraction: 0.7)
    
    /// Smooth spring for card transitions and medium elements
    /// Response: 0.45s, Damping: 0.75 (smooth, professional)
    static let smoothSpring = Animation.spring(response: 0.45, dampingFraction: 0.75)
    
    /// Bouncy spring for playful, delightful interactions
    /// Response: 0.5s, Damping: 0.6 (more bounce)
    static let bouncySpring = Animation.spring(response: 0.5, dampingFraction: 0.6)
    
    /// Gentle spring for large elements, sheets, modals
    /// Response: 0.6s, Damping: 0.82 (very smooth, no overshoot)
    static let gentleSpring = Animation.spring(response: 0.6, dampingFraction: 0.82)
    
    /// Fluid spring for expansive animations (expand/collapse)
    /// Response: 0.7s, Damping: 0.78 (fluid, natural)
    static let fluidSpring = Animation.spring(response: 0.7, dampingFraction: 0.78)
    
    // MARK: - Easing Curves (Bezier-based, industry standard)
    
    /// Lightning-fast for instant feedback (0.15s)
    static let lightning = Animation.timingCurve(0.4, 0.0, 0.2, 1.0, duration: 0.15)
    
    /// Fast ease for quick transitions (0.2s) - iOS standard
    static let fastEase = Animation.timingCurve(0.4, 0.0, 0.2, 1.0, duration: 0.2)
    
    /// Standard ease for most transitions (0.3s) - Material Design
    static let standardEase = Animation.timingCurve(0.4, 0.0, 0.2, 1.0, duration: 0.3)
    
    /// Smooth ease for larger transitions (0.4s)
    static let smoothEase = Animation.timingCurve(0.4, 0.0, 0.2, 1.0, duration: 0.4)
    
    /// Emphasized ease for important transitions (0.5s) - Material Design
    static let emphasizedEase = Animation.timingCurve(0.2, 0.0, 0.0, 1.0, duration: 0.5)
    
    /// Dramatic ease for hero transitions (0.7s)
    static let dramaticEase = Animation.timingCurve(0.25, 0.1, 0.25, 1.0, duration: 0.7)
    
    // MARK: - Specialized Easings
    
    /// Ease-out for entering elements (decelerating)
    static let easeOut = Animation.timingCurve(0.0, 0.0, 0.2, 1.0, duration: 0.3)
    
    /// Ease-in for exiting elements (accelerating)
    static let easeIn = Animation.timingCurve(0.4, 0.0, 1.0, 1.0, duration: 0.3)
    
    /// Anticipation curve (slight back movement before forward)
    static let anticipation = Animation.timingCurve(0.36, 0.0, 0.66, -0.56, duration: 0.4)
    
    // MARK: - Linear Animations
    
    /// Linear for continuous movements
    static let linearSmooth = Animation.linear(duration: 0.3)
    
    /// Linear for map movements
    static let linearMap = Animation.linear(duration: 1.0)
    
    /// Linear for progress indicators
    static let linearProgress = Animation.linear(duration: 0.5)
    
    // MARK: - Physics-based Springs (High-fidelity)
    
    /// Tight spring for precise interactions
    static let tightSpring = Animation.interpolatingSpring(
        mass: 0.8,
        stiffness: 180,
        damping: 18,
        initialVelocity: 0
    )
    
    /// Balanced spring for general use
    static let balancedSpring = Animation.interpolatingSpring(
        mass: 1.0,
        stiffness: 100,
        damping: 10,
        initialVelocity: 0
    )
    
    /// Loose spring for floating elements
    static let looseSpring = Animation.interpolatingSpring(
        mass: 1.2,
        stiffness: 80,
        damping: 12,
        initialVelocity: 0
    )
    
    // MARK: - Premium Custom Animations
    
    /// Card appearance with stagger support
    static func cardAppear(delay: Double = 0) -> Animation {
        Animation.spring(response: 0.5, dampingFraction: 0.75)
            .delay(delay)
    }
    
    /// Staggered animation for list items (optimized timing)
    static func staggered(index: Int, total: Int = 10) -> Animation {
        let delay = Double(index) * 0.04 // 40ms between items
        return Animation.spring(response: 0.45, dampingFraction: 0.75)
            .delay(delay)
    }
    
    /// Cascade animation (wave effect)
    static func cascade(index: Int, direction: CascadeDirection = .down) -> Animation {
        let baseDelay = Double(index) * 0.06
        let delay = direction == .up ? -baseDelay : baseDelay
        return Animation.spring(response: 0.5, dampingFraction: 0.7)
            .delay(max(0, delay))
    }
    
    /// Fade with custom duration
    static func fade(duration: Double = 0.25) -> Animation {
        Animation.easeInOut(duration: duration)
    }
    
    /// Scale animation for buttons (with haptic timing)
    static let buttonScale = Animation.spring(response: 0.22, dampingFraction: 0.65)
    
    /// Ripple effect timing
    static let ripple = Animation.timingCurve(0.0, 0.0, 0.2, 1.0, duration: 0.6)
    
    /// Morph animation for shape changes
    static let morph = Animation.spring(response: 0.55, dampingFraction: 0.72)
    
    /// Elastic animation for playful interactions
    static let elastic = Animation.spring(response: 0.6, dampingFraction: 0.5)
    
    // MARK: - Micro-interactions (60fps optimized)
    
    /// Hover effect (desktop/iPad)
    static let hover = Animation.spring(response: 0.25, dampingFraction: 0.7)
    
    /// Press down animation
    static let pressDown = Animation.spring(response: 0.18, dampingFraction: 0.68)
    
    /// Release animation
    static let pressUp = Animation.spring(response: 0.25, dampingFraction: 0.65)
    
    /// Toggle switch animation
    static let toggle = Animation.spring(response: 0.3, dampingFraction: 0.75)
    
    /// Checkbox animation
    static let checkbox = Animation.spring(response: 0.28, dampingFraction: 0.7)
    
    /// Slider animation
    static let slider = Animation.spring(response: 0.35, dampingFraction: 0.8)
    
    // MARK: - Page Transitions
    
    /// Sheet presentation
    static let sheetPresent = Animation.spring(response: 0.5, dampingFraction: 0.85)
    
    /// Sheet dismissal
    static let sheetDismiss = Animation.spring(response: 0.45, dampingFraction: 0.82)
    
    /// Modal presentation
    static let modalPresent = Animation.spring(response: 0.55, dampingFraction: 0.88)
    
    /// Tab switch
    static let tabSwitch = Animation.spring(response: 0.4, dampingFraction: 0.78)
    
    /// Navigation push
    static let navigationPush = Animation.timingCurve(0.4, 0.0, 0.2, 1.0, duration: 0.35)
    
    /// Navigation pop
    static let navigationPop = Animation.timingCurve(0.4, 0.0, 0.2, 1.0, duration: 0.3)
}

// MARK: - Cascade Direction

enum CascadeDirection {
    case up, down, left, right
}

// MARK: - Premium View Modifiers

extension View {
    /// Animate appearance with scale and opacity (premium timing)
    func animatedAppearance(delay: Double = 0) -> some View {
        self.modifier(PremiumAppearanceModifier(delay: delay))
    }
    
    /// Staggered appearance for list items
    func staggeredAppearance(index: Int) -> some View {
        self.modifier(StaggeredAppearanceModifier(index: index))
    }
    
    /// Shimmer effect for loading states (optimized)
    func shimmer(isActive: Bool = true, speed: Double = 1.5) -> some View {
        self.modifier(PremiumShimmerModifier(isActive: isActive, speed: speed))
    }
    
    /// Pulse animation (breathing effect)
    func pulse(isActive: Bool = true, scale: CGFloat = 1.05, duration: Double = 1.0) -> some View {
        self.modifier(PremiumPulseModifier(isActive: isActive, scale: scale, duration: duration))
    }
    
    /// Bounce animation on appear
    func bounceOnAppear(delay: Double = 0) -> some View {
        self.modifier(BounceOnAppearModifier(delay: delay))
    }
    
    /// Slide in from direction with premium timing
    func slideIn(from edge: Edge, delay: Double = 0, distance: CGFloat = 100) -> some View {
        self.modifier(PremiumSlideInModifier(edge: edge, delay: delay, distance: distance))
    }
    
    /// Scale on press (button feedback)
    func scaleOnPress(scale: CGFloat = 0.96) -> some View {
        self.modifier(ScaleOnPressModifier(scale: scale))
    }
    
    /// Glow effect (for highlights)
    func glow(color: Color = .blue, radius: CGFloat = 10, isActive: Bool = true) -> some View {
        self.modifier(GlowModifier(color: color, radius: radius, isActive: isActive))
    }
    
    /// Floating animation (subtle up/down movement)
    func floating(isActive: Bool = true, distance: CGFloat = 8, duration: Double = 2.0) -> some View {
        self.modifier(FloatingModifier(isActive: isActive, distance: distance, duration: duration))
    }
    
    /// Rotate continuously
    func rotating(isActive: Bool = true, duration: Double = 2.0) -> some View {
        self.modifier(RotatingModifier(isActive: isActive, duration: duration))
    }
    
    /// Wiggle animation (attention grabber)
    func wiggle(isActive: Bool = true) -> some View {
        self.modifier(WiggleModifier(isActive: isActive))
    }
    
    /// Parallax effect (depth on scroll)
    func parallax(magnitude: CGFloat = 20) -> some View {
        self.modifier(ParallaxModifier(magnitude: magnitude))
    }
}

// MARK: - Premium Appearance Modifier

struct PremiumAppearanceModifier: ViewModifier {
    let delay: Double
    @State private var isVisible = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isVisible ? 1 : 0.92)
            .opacity(isVisible ? 1 : 0)
            .blur(radius: isVisible ? 0 : 8)
            .onAppear {
                withAnimation(AnimationConfig.smoothSpring.delay(delay)) {
                    isVisible = true
                }
            }
    }
}

// MARK: - Staggered Appearance Modifier

struct StaggeredAppearanceModifier: ViewModifier {
    let index: Int
    @State private var isVisible = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isVisible ? 1 : 0.9)
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 20)
            .onAppear {
                withAnimation(AnimationConfig.staggered(index: index)) {
                    isVisible = true
                }
            }
    }
}

// MARK: - Premium Shimmer Modifier

struct PremiumShimmerModifier: ViewModifier {
    let isActive: Bool
    let speed: Double
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    if isActive {
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0),
                                Color.white.opacity(0.4),
                                Color.white.opacity(0.6),
                                Color.white.opacity(0.4),
                                Color.white.opacity(0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: geometry.size.width * 2.5)
                        .offset(x: -geometry.size.width * 1.25 + phase * geometry.size.width * 2.5)
                        .blendMode(.overlay)
                        .onAppear {
                            withAnimation(
                                Animation.linear(duration: speed)
                                    .repeatForever(autoreverses: false)
                            ) {
                                phase = 1
                            }
                        }
                    }
                }
            )
            .clipped()
    }
}

// MARK: - Premium Pulse Modifier

struct PremiumPulseModifier: ViewModifier {
    let isActive: Bool
    let scale: CGFloat
    let duration: Double
    @State private var currentScale: CGFloat = 1.0
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(currentScale)
            .onAppear {
                if isActive {
                    withAnimation(
                        Animation.easeInOut(duration: duration)
                            .repeatForever(autoreverses: true)
                    ) {
                        currentScale = scale
                    }
                }
            }
    }
}

// MARK: - Bounce On Appear Modifier

struct BounceOnAppearModifier: ViewModifier {
    let delay: Double
    @State private var scale: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .onAppear {
                withAnimation(AnimationConfig.elastic.delay(delay)) {
                    scale = 1.0
                }
            }
    }
}

// MARK: - Premium Slide In Modifier

struct PremiumSlideInModifier: ViewModifier {
    let edge: Edge
    let delay: Double
    let distance: CGFloat
    @State private var offset: CGFloat
    @State private var opacity: Double = 0
    
    init(edge: Edge, delay: Double, distance: CGFloat) {
        self.edge = edge
        self.delay = delay
        self.distance = distance
        self._offset = State(initialValue: distance)
    }
    
    func body(content: Content) -> some View {
        content
            .offset(
                x: edge == .leading ? -offset : (edge == .trailing ? offset : 0),
                y: edge == .top ? -offset : (edge == .bottom ? offset : 0)
            )
            .opacity(opacity)
            .onAppear {
                withAnimation(AnimationConfig.smoothSpring.delay(delay)) {
                    offset = 0
                    opacity = 1
                }
            }
    }
}

// MARK: - Scale On Press Modifier

struct ScaleOnPressModifier: ViewModifier {
    let scale: CGFloat
    @State private var isPressed = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? scale : 1.0)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed {
                            withAnimation(AnimationConfig.pressDown) {
                                isPressed = true
                            }
                        }
                    }
                    .onEnded { _ in
                        withAnimation(AnimationConfig.pressUp) {
                            isPressed = false
                        }
                    }
            )
    }
}

// MARK: - Glow Modifier

struct GlowModifier: ViewModifier {
    let color: Color
    let radius: CGFloat
    let isActive: Bool
    @State private var intensity: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .shadow(color: isActive ? color.opacity(0.6) : .clear, radius: radius * intensity, x: 0, y: 0)
            .shadow(color: isActive ? color.opacity(0.4) : .clear, radius: radius * intensity * 0.5, x: 0, y: 0)
            .onAppear {
                if isActive {
                    withAnimation(
                        Animation.easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true)
                    ) {
                        intensity = 1.0
                    }
                }
            }
    }
}

// MARK: - Floating Modifier

struct FloatingModifier: ViewModifier {
    let isActive: Bool
    let distance: CGFloat
    let duration: Double
    let delay: Double
    @State private var offset: CGFloat = 0
    
    init(isActive: Bool = true, distance: CGFloat = 8, duration: Double = 2.0, delay: Double = 0) {
        self.isActive = isActive
        self.distance = distance
        self.duration = duration
        self.delay = delay
    }
    
    func body(content: Content) -> some View {
        content
            .offset(y: offset)
            .onAppear {
                if isActive {
                    withAnimation(
                        Animation.easeInOut(duration: duration)
                            .repeatForever(autoreverses: true)
                            .delay(delay)
                    ) {
                        offset = -distance
                    }
                }
            }
    }
}

// MARK: - Rotating Modifier

struct RotatingModifier: ViewModifier {
    let isActive: Bool
    let duration: Double
    @State private var rotation: Double = 0
    
    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(rotation))
            .onAppear {
                if isActive {
                    withAnimation(
                        Animation.linear(duration: duration)
                            .repeatForever(autoreverses: false)
                    ) {
                        rotation = 360
                    }
                }
            }
    }
}

// MARK: - Wiggle Modifier

struct WiggleModifier: ViewModifier {
    let isActive: Bool
    @State private var rotation: Double = 0
    
    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(rotation))
            .onAppear {
                if isActive {
                    withAnimation(
                        Animation.spring(response: 0.3, dampingFraction: 0.3)
                            .repeatForever(autoreverses: true)
                    ) {
                        rotation = 5
                    }
                }
            }
    }
}

// MARK: - Parallax Modifier

struct ParallaxModifier: ViewModifier {
    let magnitude: CGFloat
    @State private var offset: CGFloat = 0
    
    func body(content: Content) -> some View {
        GeometryReader { geometry in
            content
                .offset(y: offset)
                .onAppear {
                    // This would need scroll position tracking in real implementation
                    // Simplified version here
                }
        }
    }
}

// MARK: - Premium Transition Extensions

extension AnyTransition {
    /// Premium scale and fade (Apple-style)
    static var premiumScale: AnyTransition {
        .asymmetric(
            insertion: .scale(scale: 0.92).combined(with: .opacity),
            removal: .scale(scale: 0.96).combined(with: .opacity)
        )
    }
    
    /// Slide from bottom with fade (sheet-style)
    static var slideFromBottom: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .bottom).combined(with: .opacity)
        )
    }
    
    /// Slide from top with fade
    static var slideFromTop: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .top).combined(with: .opacity),
            removal: .move(edge: .top).combined(with: .opacity)
        )
    }
    
    /// Slide from leading edge
    static var slideFromLeading: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .leading).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }
    
    /// Slide from trailing edge
    static var slideFromTrailing: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .trailing).combined(with: .opacity)
        )
    }
    
    /// Card flip transition (3D effect)
    static var cardFlip: AnyTransition {
        .asymmetric(
            insertion: .scale(scale: 0.8).combined(with: .opacity),
            removal: .scale(scale: 1.1).combined(with: .opacity)
        )
    }
    
    /// Zoom transition (hero-style)
    static var zoom: AnyTransition {
        .asymmetric(
            insertion: .scale(scale: 0.5).combined(with: .opacity),
            removal: .scale(scale: 1.5).combined(with: .opacity)
        )
    }
    
    /// Blur transition (iOS-style)
    static var blur: AnyTransition {
        .modifier(
            active: BlurTransitionModifier(blurRadius: 20, opacity: 0),
            identity: BlurTransitionModifier(blurRadius: 0, opacity: 1)
        )
    }
    
    /// Push transition (navigation-style)
    static var push: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }
    
    /// Pop transition (back navigation)
    static var pop: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .leading).combined(with: .opacity),
            removal: .move(edge: .trailing).combined(with: .opacity)
        )
    }
    
    /// Expand from center
    static var expandFromCenter: AnyTransition {
        .scale(scale: 0.01, anchor: .center).combined(with: .opacity)
    }
    
    /// Collapse to center
    static var collapseToCenter: AnyTransition {
        .scale(scale: 0.01, anchor: .center).combined(with: .opacity)
    }
}

// MARK: - Blur Transition Modifier

struct BlurTransitionModifier: ViewModifier {
    let blurRadius: CGFloat
    let opacity: Double
    
    func body(content: Content) -> some View {
        content
            .blur(radius: blurRadius)
            .opacity(opacity)
    }
}

// MARK: - Animation Timing Helpers

extension AnimationConfig {
    /// Get animation for specific interaction type
    static func animation(for interaction: InteractionType) -> Animation {
        switch interaction {
        case .tap: return snappy
        case .press: return quickSpring
        case .drag: return smoothSpring
        case .scroll: return linearSmooth
        case .toggle: return toggle
        case .slider: return slider
        case .sheet: return sheetPresent
        case .modal: return modalPresent
        case .navigation: return navigationPush
        }
    }
}

// MARK: - Interaction Type

enum InteractionType {
    case tap, press, drag, scroll, toggle, slider, sheet, modal, navigation
}

// MARK: - Performance Optimization Helpers

extension View {
    /// Optimize animation performance for complex views
    func optimizedAnimation(_ animation: Animation, value: some Equatable) -> some View {
        self.animation(animation, value: value)
            .drawingGroup() // Rasterize for better performance
    }
    
    /// Add subtle shadow with animation
    func animatedShadow(isActive: Bool, color: Color = .black, radius: CGFloat = 10) -> some View {
        self.shadow(
            color: isActive ? color.opacity(0.2) : .clear,
            radius: isActive ? radius : 0,
            x: 0,
            y: isActive ? radius / 2 : 0
        )
        .animation(AnimationConfig.smoothSpring, value: isActive)
    }
}
