//
//  JourneySummaryCards.swift
//  Tikkuu Focus
//
//  Created by Tikkuu on 2026/2/10.
//

import SwiftUI
import MapKit

// MARK: - Time Card

struct JourneyTimeCard: View {
    let duration: TimeInterval
    let cardsAppeared: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "clock.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.blue, Color.purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(FormatUtilities.formatTime(duration))
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                    .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 2)
                
                Text(L("journey.summary.focusTime"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(14)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(.ultraThinMaterial)
                
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.blue.opacity(0.18),
                                Color.purple.opacity(0.12)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .blendMode(.plusLighter)
                
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(Color.white.opacity(0.5), lineWidth: 1)
            }
        )
        .shadow(color: Color.blue.opacity(0.25), radius: 10, x: 0, y: 5)
        .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 6)
        .scaleEffect(cardsAppeared ? 1 : 0.85)
        .opacity(cardsAppeared ? 1 : 0)
        .offset(y: cardsAppeared ? 0 : 20)
        .rotation3DEffect(
            .degrees(cardsAppeared ? 0 : -15),
            axis: (x: 1, y: 0, z: 0),
            perspective: 1.0
        )
        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.05), value: cardsAppeared)
    }
}

// MARK: - Weather Card

struct JourneyWeatherCard: View {
    let weatherIcon: String
    let weatherCondition: String
    let isDaytime: Bool
    let cardsAppeared: Bool
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: weatherIcon)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.white)
                .symbolRenderingMode(.hierarchical)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 1) {
                Text(weatherCondition)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                
                Text(isDaytime ? L("journey.summary.day") : L("journey.summary.night"))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(12)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(.ultraThinMaterial)
                
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.cyan.opacity(0.18),
                                Color.blue.opacity(0.12)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .blendMode(.plusLighter)
                
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(Color.white.opacity(0.5), lineWidth: 1)
            }
        )
        .shadow(color: Color.cyan.opacity(0.25), radius: 10, x: 0, y: 5)
        .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 6)
        .scaleEffect(cardsAppeared ? 1 : 0.85)
        .opacity(cardsAppeared ? 1 : 0)
        .offset(y: cardsAppeared ? 0 : 20)
        .rotation3DEffect(
            .degrees(cardsAppeared ? 0 : -15),
            axis: (x: 1, y: 0, z: 0),
            perspective: 1.0
        )
        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.08), value: cardsAppeared)
    }
}

// MARK: - Distance Card

struct JourneyDistanceCard: View {
    let distance: Double
    let cardsAppeared: Bool
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "location.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.orange, Color.red],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(FormatUtilities.formatDistance(distance))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                    .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 2)
                
                Text(L("journey.summary.distance"))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(12)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.orange.opacity(0.18),
                                Color.red.opacity(0.12)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .blendMode(.plusLighter)
                
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.white.opacity(0.5), lineWidth: 1)
            }
        )
        .shadow(color: Color.orange.opacity(0.25), radius: 10, x: 0, y: 5)
        .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 6)
        .scaleEffect(cardsAppeared ? 1 : 0.85)
        .opacity(cardsAppeared ? 1 : 0)
        .offset(y: cardsAppeared ? 0 : 20)
        .rotation3DEffect(
            .degrees(cardsAppeared ? 0 : -15),
            axis: (x: 1, y: 0, z: 0),
            perspective: 1.0
        )
        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.11), value: cardsAppeared)
    }
}

// MARK: - Transport Card

struct JourneyTransportCard: View {
    let transportMode: TransportMode
    let subwayLine: String?
    let subwayColor: Color?
    let cardsAppeared: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: transportMode.iconName)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
            
            Spacer()
            
            if let line = subwayLine, let color = subwayColor {
                VStack(spacing: 2) {
                    Text(line)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [color.opacity(0.3), color.opacity(0.15)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                    
                    Text(L("transport.\(transportMode.rawValue.lowercased())"))
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
            } else {
                Text(L("transport.\(transportMode.rawValue.lowercased())"))
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.green.opacity(0.18),
                                Color.teal.opacity(0.12)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .blendMode(.plusLighter)
                
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.white.opacity(0.5), lineWidth: 1)
            }
        )
        .shadow(color: Color.green.opacity(0.25), radius: 10, x: 0, y: 5)
        .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 6)
        .scaleEffect(cardsAppeared ? 1 : 0.85)
        .opacity(cardsAppeared ? 1 : 0)
        .offset(y: cardsAppeared ? 0 : 20)
        .rotation3DEffect(
            .degrees(cardsAppeared ? 0 : -15),
            axis: (x: 1, y: 0, z: 0),
            perspective: 1.0
        )
        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.14), value: cardsAppeared)
    }
}

// MARK: - POI Card

struct JourneyPOICard: View {
    let poiCount: Int
    let cardsAppeared: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "star.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.yellow)
                .shadow(color: Color.yellow.opacity(0.5), radius: 8, x: 0, y: 4)
            
            Spacer()
            
            VStack(spacing: 1) {
                Text("\(poiCount)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 2)
                
                Text(L("journey.summary.pois"))
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(10)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.yellow.opacity(0.22),
                                Color.orange.opacity(0.14)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .blendMode(.plusLighter)
                
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.white.opacity(0.5), lineWidth: 1)
            }
        )
        .shadow(color: Color.yellow.opacity(0.25), radius: 10, x: 0, y: 5)
        .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 6)
        .scaleEffect(cardsAppeared ? 1 : 0.85)
        .opacity(cardsAppeared ? 1 : 0)
        .offset(y: cardsAppeared ? 0 : 20)
        .rotation3DEffect(
            .degrees(cardsAppeared ? 0 : -15),
            axis: (x: 1, y: 0, z: 0),
            perspective: 1.0
        )
        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.17), value: cardsAppeared)
    }
}
