//
//  SetupSelectors.swift
//  Tikkuu Focus
//
//  Created by Tikkuu on 2026/2/10.
//

import SwiftUI

// MARK: - Neumorphic Transport Mode Button

struct NeumorphicTransportModeButton: View {
    let mode: TransportMode
    let isSelected: Bool
    let action: () -> Void

    @State private var isPressed = false

    private var textColor: Color {
        let isLight = AppSettings.shared.selectedNeumorphismTone == .light
        if isSelected {
            return isLight ? Color(red: 0.20, green: 0.24, blue: 0.34) : .white
        }
        return isLight ? Color(red: 0.40, green: 0.44, blue: 0.52) : .white.opacity(0.7)
    }

    private var unselectedShadowColor: Color {
        let isLight = AppSettings.shared.selectedNeumorphismTone == .light
        return isLight ? Color.black.opacity(0.08) : Color.black.opacity(0.24)
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: mode.iconName)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(textColor)
                    .frame(height: 24)

                Text(L("transport.\(mode.rawValue.lowercased())"))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(textColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, minHeight: 80)
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(
                NeumorphSurface(
                    cornerRadius: 16,
                    depth: isSelected ? .raised : .inset,
                    fill: isSelected ? AnyShapeStyle(Color(red: 0.42, green: 0.58, blue: 0.95)) : nil
                )
            )
            .shadow(
                color: isSelected ? Color.clear : unselectedShadowColor,
                radius: isSelected ? 0 : 5,
                x: 0,
                y: isSelected ? 0 : 3
            )
            .scaleEffect(isPressed ? 0.96 : (isSelected ? 1.0 : 0.98))
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isPressed)
        }
        .buttonStyle(.plain)
        .pressEvents {
            isPressed = true
        } onRelease: {
            isPressed = false
        }
    }
}

// MARK: - Neumorphic Duration Button

struct NeumorphicDurationButton: View {
    let duration: Int
    let isSelected: Bool
    let action: () -> Void

    @State private var isPressed = false

    private var textColor: Color {
        let isLight = AppSettings.shared.selectedNeumorphismTone == .light
        if isSelected {
            return isLight ? Color(red: 0.20, green: 0.24, blue: 0.34) : .white
        }
        return isLight ? Color(red: 0.40, green: 0.44, blue: 0.52) : .white.opacity(0.7)
    }

    private var unselectedShadowColor: Color {
        let isLight = AppSettings.shared.selectedNeumorphismTone == .light
        return isLight ? Color.black.opacity(0.08) : Color.black.opacity(0.24)
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text("\(duration)")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(textColor)

                Text(L("time.unit.min"))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(textColor.opacity(0.82))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                NeumorphSurface(
                    cornerRadius: 16,
                    depth: isSelected ? .raised : .inset,
                    fill: isSelected ? AnyShapeStyle(Color(red: 0.95, green: 0.55, blue: 0.35)) : nil
                )
            )
            .shadow(
                color: isSelected ? Color.clear : unselectedShadowColor,
                radius: isSelected ? 0 : 5,
                x: 0,
                y: isSelected ? 0 : 3
            )
            .scaleEffect(isPressed ? 0.96 : (isSelected ? 1.0 : 0.98))
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isPressed)
        }
        .buttonStyle(.plain)
        .pressEvents {
            isPressed = true
        } onRelease: {
            isPressed = false
        }
    }
}

// MARK: - Transport Mode Selector

struct TransportModeSelector: View {
    @Binding var selectedMode: TransportMode
    let cardsAppeared: Bool
    
    private let modes: [TransportMode] = [.walking, .cycling, .driving, .skateboard]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L("label.selectTransport"))
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
            
            HStack(spacing: 12) {
                ForEach(modes, id: \.self) { mode in
                    TransportModeButton(
                        mode: mode,
                        isSelected: selectedMode == mode
                    ) {
                        HapticManager.selection()
                        withAnimation(AnimationConfig.snappy) {
                            selectedMode = mode
                        }
                    }
                }
            }
        }
        .scaleEffect(cardsAppeared ? 1 : 0.9)
        .opacity(cardsAppeared ? 1 : 0)
        .offset(y: cardsAppeared ? 0 : 20)
        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1), value: cardsAppeared)
    }
}

// MARK: - Transport Mode Button

struct TransportModeButton: View {
    @ObservedObject private var settings = AppSettings.shared
    let mode: TransportMode
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        if settings.selectedVisualStyle == .neumorphism {
            NeumorphicTransportModeButton(
                mode: mode,
                isSelected: isSelected,
                action: action
            )
        } else {
            LiquidGlassTransportModeButton(
                mode: mode,
                isSelected: isSelected,
                action: action
            )
        }
    }
}

// MARK: - Liquid Glass Transport Mode Button

struct LiquidGlassTransportModeButton: View {
    let mode: TransportMode
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: mode.iconName)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(isSelected ? .white : .primary)
                    .frame(height: 24)

                Text(L("transport.\(mode.rawValue.lowercased())"))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(isSelected ? .white : .secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, minHeight: 80)
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(GradientStyles.primaryGradient)
                            .shadow(color: Color.blue.opacity(0.3), radius: 10, x: 0, y: 5)
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.clear)
                            .insetSurface(cornerRadius: 16, isActive: false)
                    }
                }
            )
            .scaleEffect(isSelected ? 1.0 : 0.98)
            .animation(AnimationConfig.snappy, value: isSelected)
        }
        .buttonStyle(PremiumButtonStyle())
    }
}

// MARK: - Premium Button Style

struct PremiumButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .brightness(configuration.isPressed ? -0.05 : 0)
            .animation(AnimationConfig.snappy, value: configuration.isPressed)
    }
}

// MARK: - Duration Selector

struct DurationSelector: View {
    @Binding var selectedDuration: Int
    let cardsAppeared: Bool
    
    private let durations = [25, 45, 60, 90]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L("label.selectDuration"))
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
            
            HStack(spacing: 12) {
                ForEach(durations, id: \.self) { duration in
                    DurationButton(
                        duration: duration,
                        isSelected: selectedDuration == duration
                    ) {
                        HapticManager.selection()
                        withAnimation(AnimationConfig.snappy) {
                            selectedDuration = duration
                        }
                    }
                }
            }
        }
        .scaleEffect(cardsAppeared ? 1 : 0.9)
        .opacity(cardsAppeared ? 1 : 0)
        .offset(y: cardsAppeared ? 0 : 20)
        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.15), value: cardsAppeared)
    }
}

// MARK: - Duration Button

struct DurationButton: View {
    @ObservedObject private var settings = AppSettings.shared
    let duration: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        if settings.selectedVisualStyle == .neumorphism {
            NeumorphicDurationButton(
                duration: duration,
                isSelected: isSelected,
                action: action
            )
        } else {
            LiquidGlassDurationButton(
                duration: duration,
                isSelected: isSelected,
                action: action
            )
        }
    }
}

// MARK: - Liquid Glass Duration Button

struct LiquidGlassDurationButton: View {
    let duration: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text("\(duration)")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(isSelected ? .white : .primary)

                Text(L("time.unit.min"))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(isSelected ? .white.opacity(0.82) : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(GradientStyles.accentGradient)
                            .shadow(color: Color.orange.opacity(0.3), radius: 10, x: 0, y: 5)
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.clear)
                            .insetSurface(cornerRadius: 16, isActive: false)
                    }
                }
            )
            .scaleEffect(isSelected ? 1.0 : 0.98)
            .animation(AnimationConfig.snappy, value: isSelected)
        }
        .buttonStyle(PremiumButtonStyle())
    }
}

// MARK: - Location Source Selector

struct LocationSourceSelector: View {
    @Binding var selectedLocation: LocationSource
    let currentLocationName: String?
    let onShowPicker: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.blue)
                
                Text(currentLocationName ?? L("location.current"))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: onShowPicker) {
                    HStack(spacing: 4) {
                        Text(L("location.selectStart"))
                            .font(.system(size: 13, weight: .semibold))
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(.blue)
                }
            }
            .padding(14)
            .background(
                NeumorphSurface(cornerRadius: 12, depth: .inset)
            )
        }
    }
}

// MARK: - Custom Duration Picker

struct CustomDurationPicker: View {
    @Binding var duration: Int
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("\(duration) \(L("time.unit.min"))")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(GradientStyles.primaryGradient)
                
                Slider(value: Binding(
                    get: { Double(duration) },
                    set: { duration = Int($0) }
                ), in: 5...120, step: 5)
                    .tint(.blue)
                    .padding(.horizontal, 24)
                
                HStack(spacing: 12) {
                    ForEach([15, 30, 45, 60, 90], id: \.self) { preset in
                        Button(action: {
                            HapticManager.selection()
                            duration = preset
                        }) {
                            Text("\(preset)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(duration == preset ? .white : .primary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(duration == preset ? 
                                            AnyShapeStyle(GradientStyles.primaryGradient) : 
                                            AnyShapeStyle(.ultraThinMaterial)
                                        )
                                )
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.top, 40)
            .navigationTitle(L("label.selectDuration"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L("journey.summary.done")) {
                        isPresented = false
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
