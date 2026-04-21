//
//  SetupSelectors.swift
//  Tikkuu Focus
//
//  Created by Tikkuu on 2026/2/10.
//

import SwiftUI

// MARK: - Neumorphic Transport Mode Button

struct LegacyTransportModeButton: View {
    let mode: TransportMode
    let isSelected: Bool
    let action: () -> Void

    @State private var isPressed = false

    private var textColor: Color {
        if isSelected {
            return .white
        }
        return .white.opacity(0.7)
    }

    private var unselectedShadowColor: Color {
        return Color.black.opacity(0.24)
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
                RoundedRectangle(cornerRadius: 24)
                    .fill(isSelected ? AnyShapeStyle(Color(red: 0.42, green: 0.58, blue: 0.95)) : AnyShapeStyle(Color.clear))
            )
            .shadow(
                color: isSelected ? Color.clear : unselectedShadowColor,
                radius: isSelected ? 0 : 5,
                x: 0,
                y: isSelected ? 0 : 3
            )
            .scaleEffect(isSelected ? 1.0 : 0.98)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Neumorphic Duration Button

struct LegacyDurationButton: View {
    let duration: Int
    let isSelected: Bool
    let action: () -> Void

    @State private var isPressed = false

    private var textColor: Color {
        if isSelected {
            return .white
        }
        return .white.opacity(0.7)
    }

    private var unselectedShadowColor: Color {
        return Color.black.opacity(0.24)
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text("\(duration)")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundColor(textColor)

                Text(L("time.unit.min"))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(textColor.opacity(0.82))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(isSelected ? AnyShapeStyle(Color(red: 0.95, green: 0.55, blue: 0.35)) : AnyShapeStyle(Color.clear))
            )
            .shadow(
                color: isSelected ? Color.clear : unselectedShadowColor,
                radius: isSelected ? 0 : 5,
                x: 0,
                y: isSelected ? 0 : 3
            )
            .scaleEffect(isSelected ? 1.0 : 0.98)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(ScaleButtonStyle())
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
                    LegacyTransportModeButton(
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
    let mode: TransportMode
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        LiquidGlassTransportModeButton(
            mode: mode,
            isSelected: isSelected,
            action: action
        )
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
                        RoundedRectangle(cornerRadius: 24)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.24, green: 0.54, blue: 0.98),
                                        Color(red: 0.19, green: 0.44, blue: 0.90)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(Color.white.opacity(0.25), lineWidth: 0.8)
                            )
                            .shadow(color: Color.blue.opacity(0.32), radius: 10, x: 0, y: 5)
                    } else {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.clear)
                            .insetSurface(cornerRadius: 24, isActive: false)
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
                    LegacyDurationButton(
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
    let duration: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        LiquidGlassDurationButton(
            duration: duration,
            isSelected: isSelected,
            action: action
        )
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
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
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
                        RoundedRectangle(cornerRadius: 24)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.56, green: 0.43, blue: 0.98),
                                        Color(red: 0.43, green: 0.35, blue: 0.90)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(Color.white.opacity(0.25), lineWidth: 0.8)
                            )
                            .shadow(color: Color.purple.opacity(0.32), radius: 10, x: 0, y: 5)
                    } else {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.clear)
                            .insetSurface(cornerRadius: 24, isActive: false)
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
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.1))
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
                    .font(.system(size: 48, weight: .semibold, design: .rounded))
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
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(duration == preset ? .white : .primary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    Capsule()
                                        .fill(duration == preset ? 
                                            AnyShapeStyle(Color.accentColor) : 
                                            AnyShapeStyle(Color.secondary.opacity(0.15))
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
