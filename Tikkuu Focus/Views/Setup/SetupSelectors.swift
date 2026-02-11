//
//  SetupSelectors.swift
//  Tikkuu Focus
//
//  Created by Tikkuu on 2026/2/10.
//

import SwiftUI

// MARK: - Transport Mode Selector

struct TransportModeSelector: View {
    @Binding var selectedMode: TransportMode
    let cardsAppeared: Bool
    
    private let modes: [TransportMode] = [.walking, .cycling, .driving, .subway]
    
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
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? 
                        AnyShapeStyle(GradientStyles.primaryGradient) : 
                        AnyShapeStyle(.ultraThinMaterial)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                isSelected ? Color.clear : Color.primary.opacity(0.1),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(
                color: isSelected ? Color.blue.opacity(0.3) : Color.clear,
                radius: 10,
                x: 0,
                y: 5
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
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? 
                        AnyShapeStyle(GradientStyles.accentGradient) : 
                        AnyShapeStyle(.ultraThinMaterial)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                isSelected ? Color.clear : Color.primary.opacity(0.1),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(
                color: isSelected ? Color.orange.opacity(0.3) : Color.clear,
                radius: 10,
                x: 0,
                y: 5
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
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.blue.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }
}

// MARK: - Custom Duration Picker

struct CustomDurationPicker: View {
    @Binding var duration: Int
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
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
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L("journey.summary.done")) {
                        isPresented = false
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
