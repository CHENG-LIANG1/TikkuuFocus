//
//  JourneySummaryView.swift
//  Tikkuu Focus
//
//  Created by Tikkuu on 2026/2/8.
//

import SwiftUI
import MapKit
import Photos

struct JourneySummaryView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var settings = AppSettings.shared
    
    let session: JourneySession
    let discoveredPOIs: [DiscoveredPOI]
    let weatherCondition: String
    let isDaytime: Bool
    let progress: Double // 0.0 to 1.0
    let isCompleted: Bool // true if journey completed, false if stopped early
    let actualDuration: TimeInterval // Actual duration of the journey
    let onDismiss: () -> Void
    
    @State private var cardsAppeared = false
    @State private var showShareSheet = false
    @State private var renderedImage: UIImage?
    @State private var celebrationScale: CGFloat = 0.5
    @State private var celebrationRotation: Double = -180
    @State private var celebrationOpacity: Double = 0
    @State private var confettiTrigger = false
    @State private var cardHoverStates: [Int: Bool] = [:]
    @State private var floatingOffset: CGFloat = 0
    @State private var showPhotoPermissionAlert = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: backgroundColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Main content - no scroll
                VStack(spacing: 0) {
                    // Header - compact
                    compactHeaderView
                        .padding(.top, 50)
                        .padding(.bottom, 16)
                    
                    // Bento Grid Layout - optimized spacing
                    bentoGridView
                        .padding(.horizontal, 20)
                    
                    Spacer(minLength: 16)
                    
                    // Action buttons - compact
                    actionButtons
                        .padding(.horizontal, 20)
                        .padding(.bottom, max(geometry.safeAreaInsets.bottom + 12, 24))
                }
                
                // Done button in top right
                VStack {
                    HStack {
                        Spacer()
                        
                        Button {
                            HapticManager.light()
                            onDismiss()
                            dismiss()
                        } label: {
                            Text(L("common.done"))
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(.ultraThinMaterial)
                                )
                        }
                        .padding(.trailing, 20)
                        .padding(.top, 50)
                    }
                    
                    Spacer()
                }
            }
        }
        .preferredColorScheme(settings.currentColorScheme)
        .onAppear {
            // Celebration animation for completed journeys
            if isCompleted {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    celebrationScale = 1.0
                    celebrationRotation = 0
                    celebrationOpacity = 1.0
                }
                
                // Trigger confetti
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    confettiTrigger = true
                    HapticManager.success()
                }
            } else {
                // Simple fade in for stopped journeys
                withAnimation(.easeOut(duration: 0.25)) {
                    celebrationScale = 1.0
                    celebrationOpacity = 1.0
                }
            }
            
            // Cards appear after celebration
            DispatchQueue.main.asyncAfter(deadline: .now() + (isCompleted ? 0.3 : 0.15)) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                    cardsAppeared = true
                }
            }
            
            // 移除浮动动画以提升性能
        }
        .sheet(isPresented: $showShareSheet) {
            if let image = renderedImage {
                ShareSheet(items: [image])
            }
        }
        .overlay {
            if isCompleted && confettiTrigger {
                ConfettiView()
                    .allowsHitTesting(false)
            }
        }
        .alert(L("journey.summary.photoPermission.title"), isPresented: $showPhotoPermissionAlert) {
            Button(L("journey.summary.photoPermission.openSettings")) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button(L("journey.summary.photoPermission.cancel"), role: .cancel) {}
        } message: {
            Text(L("journey.summary.photoPermission.message"))
        }
    }
    
    // MARK: - Compact Header
    
    private var compactHeaderView: some View {
        VStack(spacing: 8) {
            // Icon - smaller
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "pause.circle.fill")
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: isCompleted ? 
                            [Color.green, Color.green.opacity(0.7)] :
                            [Color.orange, Color.orange.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: (isCompleted ? Color.green : Color.orange).opacity(0.3), radius: 12, x: 0, y: 6)
                .scaleEffect(celebrationScale)
                .rotationEffect(.degrees(celebrationRotation))
                .opacity(celebrationOpacity)
            
            Text(isCompleted ? L("journey.summary.complete") : L("journey.summary.stopped"))
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .opacity(celebrationOpacity)
                .offset(y: celebrationOpacity == 1 ? 0 : 10)
            
            // Progress badge - smaller
            HStack(spacing: 4) {
                Image(systemName: "flag.checkered")
                    .font(.system(size: 9, weight: .semibold))
                
                Text(String(format: L("journey.summary.completed"), progress * 100))
                    .font(.system(size: 11, weight: .bold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(isCompleted ? Color.green.opacity(0.3) : Color.orange.opacity(0.3))
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
            )
            .opacity(celebrationOpacity)
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        VStack(spacing: 8) {
            // Icon - no badge
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "pause.circle.fill")
                .font(.system(size: 50, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: isCompleted ? 
                            [Color.green, Color.green.opacity(0.7)] :
                            [Color.orange, Color.orange.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: (isCompleted ? Color.green : Color.orange).opacity(0.3), radius: 20, x: 0, y: 10)
                .scaleEffect(celebrationScale)
                .rotationEffect(.degrees(celebrationRotation))
                .opacity(celebrationOpacity)
            
            Text(isCompleted ? L("journey.summary.complete") : L("journey.summary.stopped"))
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .opacity(celebrationOpacity)
                .offset(y: celebrationOpacity == 1 ? 0 : 20)
            
            // Progress badge
            HStack(spacing: 6) {
                Image(systemName: "flag.checkered")
                    .font(.system(size: 12, weight: .semibold))
                
                Text(String(format: L("journey.summary.completed"), progress * 100))
                    .font(.system(size: 14, weight: .bold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(isCompleted ? Color.green.opacity(0.3) : Color.orange.opacity(0.3))
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
            )
            .opacity(celebrationOpacity)
            
            Text(formattedDate)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .opacity(celebrationOpacity)
        }
        .padding(.bottom, 8)
    }
    
    // MARK: - Bento Grid
    
    private var bentoGridView: some View {
        VStack(spacing: 10) {
            // Row 1: Large time card + Weather
            HStack(spacing: 10) {
                timeCard
                    .frame(maxWidth: .infinity)
                
                weatherCard
                    .frame(width: 110)
            }
            .frame(height: 120)
            
            // Row 2: Distance + Transport + POIs
            HStack(spacing: 10) {
                distanceCard
                    .frame(maxWidth: .infinity)
                
                transportCard
                    .frame(width: 90)
                
                poisCard
                    .frame(width: 90)
            }
            .frame(height: 95)
            
            // Row 3: Route map (full width)
            routeMapCard
                .frame(height: 140)
        }
    }
    
    // MARK: - Time Card
    
    private var timeCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: "clock.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.blue, Color.purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.blue.opacity(0.4), radius: 4, x: 0, y: 2)
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 0) {
                Text(FormatUtilities.formatTime(actualDuration))
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                    .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 1)
                
                Text(L("journey.summary.focusTime"))
                    .font(.system(size: 11, weight: .medium))
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
                                Color.blue.opacity(0.18),
                                Color.purple.opacity(0.12)
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
        .shadow(color: Color.blue.opacity(0.2), radius: 8, x: 0, y: 4)
        .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 5)
        .scaleEffect(cardsAppeared ? 1 : 0.85)
        .opacity(cardsAppeared ? 1 : 0)
        .offset(y: cardsAppeared ? 0 : 15)
        .rotation3DEffect(
            .degrees(cardsAppeared ? 0 : -12),
            axis: (x: 1, y: 0, z: 0),
            perspective: 1.0
        )
        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.05), value: cardsAppeared)
    }
    
    // MARK: - Weather Card
    
    private var weatherCard: some View {
        VStack(spacing: 6) {
            Image(systemName: weatherIcon)
                .font(.system(size: 28, weight: .medium))
                .foregroundColor(.white)
                .symbolRenderingMode(.hierarchical)
                .shadow(color: Color.white.opacity(0.25), radius: 5, x: 0, y: 2)
            
            Spacer()
            
            VStack(spacing: 1) {
                Text(weatherCondition)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                
                Text(isDaytime ? L("journey.summary.day") : L("journey.summary.night"))
                    .font(.system(size: 9, weight: .medium))
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
                                Color.cyan.opacity(0.18),
                                Color.blue.opacity(0.12)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .blendMode(.plusLighter)
                
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.white.opacity(0.5), lineWidth: 1)
            }
        )
        .shadow(color: Color.cyan.opacity(0.2), radius: 8, x: 0, y: 4)
        .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 5)
        .scaleEffect(cardsAppeared ? 1 : 0.85)
        .opacity(cardsAppeared ? 1 : 0)
        .offset(y: cardsAppeared ? 0 : 15)
        .rotation3DEffect(
            .degrees(cardsAppeared ? 0 : -12),
            axis: (x: 1, y: 0, z: 0),
            perspective: 1.0
        )
        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.08), value: cardsAppeared)
    }
    
    // MARK: - Distance Card
    
    private var distanceCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: "location.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.orange, Color.red],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.orange.opacity(0.4), radius: 4, x: 0, y: 2)
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 0) {
                Text(FormatUtilities.formatDistance(session.totalDistance))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                    .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 1)
                
                Text(L("journey.summary.distance"))
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(10)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(.ultraThinMaterial)
                
                RoundedRectangle(cornerRadius: 14)
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
                
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(Color.white.opacity(0.5), lineWidth: 1)
            }
        )
        .shadow(color: Color.orange.opacity(0.2), radius: 8, x: 0, y: 4)
        .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 5)
        .scaleEffect(cardsAppeared ? 1 : 0.85)
        .opacity(cardsAppeared ? 1 : 0)
        .offset(y: cardsAppeared ? 0 : 15)
        .rotation3DEffect(
            .degrees(cardsAppeared ? 0 : -12),
            axis: (x: 1, y: 0, z: 0),
            perspective: 1.0
        )
        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.11), value: cardsAppeared)
    }
    
    // MARK: - Transport Card
    
    private var transportCard: some View {
        VStack(spacing: 6) {
            Image(systemName: session.transportMode.iconName)
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.white)
                .shadow(color: Color.white.opacity(0.25), radius: 4, x: 0, y: 2)
            
            Spacer()
            
            // Show subway line info if available
            if session.transportMode == .subway, let stations = session.subwayStations, !stations.isEmpty {
                VStack(spacing: 1) {
                    Text(extractSubwayLine(from: stations))
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(subwayLineColor(from: stations))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    
                    Text(session.transportMode.localizedName)
                        .font(.system(size: 7, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
            } else {
                Text(session.transportMode.localizedName)
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.7)
            }
        }
        .padding(8)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(.ultraThinMaterial)
                
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: session.transportMode == .subway && session.subwayStations != nil ?
                                [subwayLineColor(from: session.subwayStations ?? []).opacity(0.25),
                                 subwayLineColor(from: session.subwayStations ?? []).opacity(0.15)] :
                                [Color.green.opacity(0.18),
                                 Color.teal.opacity(0.12)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .blendMode(.plusLighter)
                
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(Color.white.opacity(0.5), lineWidth: 1)
            }
        )
        .shadow(color: Color.green.opacity(0.2), radius: 8, x: 0, y: 4)
        .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 5)
        .scaleEffect(cardsAppeared ? 1 : 0.85)
        .opacity(cardsAppeared ? 1 : 0)
        .offset(y: cardsAppeared ? 0 : 15)
        .rotation3DEffect(
            .degrees(cardsAppeared ? 0 : -12),
            axis: (x: 1, y: 0, z: 0),
            perspective: 1.0
        )
        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.14), value: cardsAppeared)
    }
    
    // MARK: - POIs Card
    
    private var poisCard: some View {
        VStack(spacing: 6) {
            Image(systemName: "star.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.yellow)
                .shadow(color: Color.yellow.opacity(0.5), radius: 6, x: 0, y: 3)
            
            Spacer()
            
            VStack(spacing: 0) {
                Text("\(discoveredPOIs.count)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 1)
                
                Text(L("journey.summary.pois"))
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(8)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(.ultraThinMaterial)
                
                RoundedRectangle(cornerRadius: 14)
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
                
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(Color.white.opacity(0.5), lineWidth: 1)
            }
        )
        .shadow(color: Color.yellow.opacity(0.2), radius: 8, x: 0, y: 4)
        .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 5)
        .scaleEffect(cardsAppeared ? 1 : 0.85)
        .opacity(cardsAppeared ? 1 : 0)
        .offset(y: cardsAppeared ? 0 : 15)
        .rotation3DEffect(
            .degrees(cardsAppeared ? 0 : -12),
            axis: (x: 1, y: 0, z: 0),
            perspective: 1.0
        )
        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.17), value: cardsAppeared)
    }
    
    // MARK: - Route Map Card
    
    private var routeMapCard: some View {
        ZStack(alignment: .bottomLeading) {
            // Map
            Map(initialPosition: .region(mapRegion)) {
                // Route line
                MapPolyline(coordinates: session.route)
                    .stroke(
                        LinearGradient(
                            colors: [Color.green, Color.blue, Color.purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                
                // Start marker
                Annotation("", coordinate: session.startLocation) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 9, height: 9)
                        .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                        .shadow(color: Color.green.opacity(0.5), radius: 4, x: 0, y: 2)
                }
                
                // End marker
                Annotation("", coordinate: session.destinationLocation) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 9, height: 9)
                        .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                        .shadow(color: Color.red.opacity(0.5), radius: 4, x: 0, y: 2)
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .disabled(true)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            // Route info overlay
            HStack(spacing: 4) {
                Image(systemName: "map.fill")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(L("journey.summary.route"))
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                ZStack {
                    Capsule()
                        .fill(.ultraThinMaterial)
                    
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.15),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .blendMode(.plusLighter)
                    
                    Capsule()
                        .strokeBorder(Color.white.opacity(0.4), lineWidth: 1)
                }
            )
            .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
            .padding(8)
        }
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.purple.opacity(0.15),
                                Color.blue.opacity(0.12)
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
        .shadow(color: Color.purple.opacity(0.2), radius: 8, x: 0, y: 4)
        .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 5)
        .scaleEffect(cardsAppeared ? 1 : 0.85)
        .opacity(cardsAppeared ? 1 : 0)
        .offset(y: cardsAppeared ? 0 : 15)
        .rotation3DEffect(
            .degrees(cardsAppeared ? 0 : -12),
            axis: (x: 1, y: 0, z: 0),
            perspective: 1.0
        )
        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2), value: cardsAppeared)
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        HStack(spacing: 10) {
            // Save as Image
            Button {
                HapticManager.medium()
                saveAsImage()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "square.and.arrow.down")
                        .font(.system(size: 12, weight: .semibold))
                    Text(L("journey.summary.save"))
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(.ultraThinMaterial)
                        
                        RoundedRectangle(cornerRadius: 14)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.12),
                                        Color.clear
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .blendMode(.plusLighter)
                        
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(Color.white.opacity(0.4), lineWidth: 1)
                    }
                )
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            }
            
            // Share
            Button {
                HapticManager.medium()
                shareImage()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 12, weight: .semibold))
                    Text(L("journey.summary.share"))
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.4, green: 0.6, blue: 1.0),
                                        Color(red: 0.5, green: 0.5, blue: 0.95)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        
                        RoundedRectangle(cornerRadius: 14)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.15),
                                        Color.clear
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .blendMode(.plusLighter)
                    }
                )
                .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                .shadow(color: Color.black.opacity(0.12), radius: 5, x: 0, y: 2)
            }
            
            // Done button
            Button {
                HapticManager.success()
                onDismiss()
                dismiss()
            } label: {
                Text(L("journey.summary.done"))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(
                                LinearGradient(
                                    colors: [Color.green, Color.teal],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: Color.green.opacity(0.35), radius: 8, x: 0, y: 4)
                    )
            }
        }
        .opacity(cardsAppeared ? 1 : 0)
        .offset(y: cardsAppeared ? 0 : 10)
        .animation(.spring(response: 0.4, dampingFraction: 0.75).delay(0.25), value: cardsAppeared)
    }
    
    // MARK: - Computed Properties
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: session.startTime)
    }
    
    // MARK: - Subway Line Helpers
    
    /// Extract subway line number/name from station names
    private func extractSubwayLine(from stations: [SubwayStationInfo]) -> String {
        guard let firstStation = stations.first else { return L("journey.summary.subway") }
        
        let name = firstStation.name
        
        // Try to extract line number/name from station name
        // Common patterns: "Line 1", "1号线", "Red Line", etc.
        
        // Pattern 1: "Line X" or "X Line"
        if let lineMatch = name.range(of: "Line\\s+\\d+|\\d+\\s+Line", options: .regularExpression) {
            let line = String(name[lineMatch])
            return line.replacingOccurrences(of: "Line", with: "").trimmingCharacters(in: .whitespaces) + " Line"
        }
        
        // Pattern 2: Chinese "X号线"
        if let lineMatch = name.range(of: "\\d+号线", options: .regularExpression) {
            return String(name[lineMatch])
        }
        
        // Pattern 3: Color-based lines (Red Line, Blue Line, etc.)
        let colorLines = ["Red", "Blue", "Green", "Yellow", "Orange", "Purple", "Pink", "Brown", "Silver", "Gold"]
        for color in colorLines {
            if name.lowercased().contains(color.lowercased()) {
                return "\(color) Line"
            }
        }
        
        // Pattern 4: Named lines (Yamanote, Circle, Central, etc.)
        let namedLines = ["Yamanote", "Circle", "Central", "District", "Northern", "Victoria", "Jubilee", "Metropolitan"]
        for lineName in namedLines {
            if name.lowercased().contains(lineName.lowercased()) {
                return "\(lineName) Line"
            }
        }
        
        // Fallback: Just show "Subway"
        return L("journey.summary.subway")
    }
    
    /// Get color for subway line based on station names
    private func subwayLineColor(from stations: [SubwayStationInfo]) -> Color {
        guard let firstStation = stations.first else { return .blue }
        
        let name = firstStation.name.lowercased()
        
        // Color mapping based on common subway line colors
        if name.contains("red") || name.contains("1号线") || name.contains("line 1") {
            return Color(red: 0.9, green: 0.2, blue: 0.2)
        } else if name.contains("blue") || name.contains("2号线") || name.contains("line 2") {
            return Color(red: 0.2, green: 0.4, blue: 0.9)
        } else if name.contains("green") || name.contains("3号线") || name.contains("line 3") {
            return Color(red: 0.2, green: 0.8, blue: 0.3)
        } else if name.contains("yellow") || name.contains("4号线") || name.contains("line 4") {
            return Color(red: 0.95, green: 0.8, blue: 0.1)
        } else if name.contains("orange") || name.contains("5号线") || name.contains("line 5") {
            return Color(red: 1.0, green: 0.6, blue: 0.2)
        } else if name.contains("purple") || name.contains("6号线") || name.contains("line 6") {
            return Color(red: 0.7, green: 0.3, blue: 0.9)
        } else if name.contains("pink") || name.contains("7号线") || name.contains("line 7") {
            return Color(red: 1.0, green: 0.4, blue: 0.7)
        } else if name.contains("brown") || name.contains("8号线") || name.contains("line 8") {
            return Color(red: 0.6, green: 0.4, blue: 0.2)
        } else if name.contains("silver") || name.contains("9号线") || name.contains("line 9") {
            return Color(red: 0.7, green: 0.7, blue: 0.7)
        } else if name.contains("gold") || name.contains("10号线") || name.contains("line 10") {
            return Color(red: 0.85, green: 0.65, blue: 0.13)
        }
        
        // Default subway blue
        return Color(red: 0.2, green: 0.5, blue: 0.9)
    }
    
    private var weatherIcon: String {
        // Map weather condition to SF Symbol
        switch weatherCondition.lowercased() {
        case let str where str.contains("clear"):
            return isDaytime ? "sun.max.fill" : "moon.stars.fill"
        case let str where str.contains("cloud"):
            return "cloud.fill"
        case let str where str.contains("rain"):
            return "cloud.rain.fill"
        case let str where str.contains("snow"):
            return "cloud.snow.fill"
        default:
            return isDaytime ? "sun.max.fill" : "moon.fill"
        }
    }
    
    private var backgroundColors: [Color] {
        if isDaytime {
            return [
                Color(red: 0.4, green: 0.6, blue: 1.0),
                Color(red: 0.5, green: 0.7, blue: 0.9),
                Color(red: 0.6, green: 0.8, blue: 1.0)
            ]
        } else {
            return [
                Color(red: 0.1, green: 0.15, blue: 0.3),
                Color(red: 0.15, green: 0.1, blue: 0.25),
                Color(red: 0.1, green: 0.2, blue: 0.35)
            ]
        }
    }
    
    private var mapRegion: MKCoordinateRegion {
        let centerLat = (session.startLocation.latitude + session.destinationLocation.latitude) / 2
        let centerLon = (session.startLocation.longitude + session.destinationLocation.longitude) / 2
        
        let latDelta = abs(session.startLocation.latitude - session.destinationLocation.latitude) * 1.5
        let lonDelta = abs(session.startLocation.longitude - session.destinationLocation.longitude) * 1.5
        
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
            span: MKCoordinateSpan(
                latitudeDelta: max(latDelta, 0.05),
                longitudeDelta: max(lonDelta, 0.05)
            )
        )
    }
    
    // MARK: - Actions
    
    @MainActor
    private func saveAsImage() {
        guard let image = renderAsImage() else {
            print("Failed to render image")
            return
        }
        
        // Check current authorization status
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        
        switch status {
        case .authorized, .limited:
            // Already authorized, save directly
            saveImageToLibrary(image)
            
        case .notDetermined:
            // Request authorization
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { newStatus in
                DispatchQueue.main.async {
                    if newStatus == .authorized || newStatus == .limited {
                        self.saveImageToLibrary(image)
                    } else {
                        self.showPhotoPermissionAlert = true
                        HapticManager.error()
                    }
                }
            }
            
        case .denied, .restricted:
            // Show alert to guide user to settings
            showPhotoPermissionAlert = true
            HapticManager.error()
            
        @unknown default:
            print("Unknown photo library authorization status")
        }
    }
    
    private func saveImageToLibrary(_ image: UIImage) {
        // Optimize image before saving
        let optimizedImage = PerformanceOptimizer.shared.compressImage(image, maxSizeKB: 1000) ?? image
        
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: optimizedImage)
        }) { success, error in
            DispatchQueue.main.async {
                if success {
                    HapticManager.success()
                    print("✅ Image saved successfully")
                } else if let error = error {
                    print("❌ Error saving image: \(error.localizedDescription)")
                    HapticManager.error()
                }
            }
        }
    }
    
    private func shareImage() {
        guard let image = renderAsImage() else { return }
        
        // Optimize image before sharing
        let optimizedImage = PerformanceOptimizer.shared.compressImage(image, maxSizeKB: 800) ?? image
        renderedImage = optimizedImage
        showShareSheet = true
    }
    
    @MainActor
    private func renderAsImage() -> UIImage? {
        // Create a renderer for the summary card
        let renderer = ImageRenderer(content: summaryCardForExport)
        renderer.scale = 2.0 // Reduced from 3.0 for better performance
        
        return renderer.uiImage
    }
    
    private var summaryCardForExport: some View {
        VStack(spacing: 20) {
            // App branding at top
            HStack(spacing: 8) {
                Image(systemName: "location.circle.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.white, Color.white.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text(L("about.appName"))
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            .padding(.top, 32)
            
            // Header
            VStack(spacing: 12) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "pause.circle.fill")
                    .font(.system(size: 56, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: isCompleted ? 
                                [Color.green, Color.green.opacity(0.7)] :
                                [Color.orange, Color.orange.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text(isCompleted ? L("journey.summary.complete") : L("journey.summary.stopped"))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                HStack(spacing: 8) {
                    Image(systemName: "flag.checkered")
                        .font(.system(size: 13, weight: .semibold))
                    Text(String(format: L("journey.summary.completed"), progress * 100))
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(isCompleted ? Color.green.opacity(0.3) : Color.orange.opacity(0.3))
                        .overlay(Capsule().stroke(Color.white.opacity(0.3), lineWidth: 1))
                )
                
                Text(formattedDate)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            // Bento Grid - with static map
            exportBentoGridView
                .padding(.horizontal, 18)
            
            Spacer(minLength: 20)
        }
        .frame(width: 420, height: 920)
        .background(
            LinearGradient(
                colors: backgroundColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 32))
    }
    
    // MARK: - Export Bento Grid (with static map snapshot)
    
    private var exportBentoGridView: some View {
        VStack(spacing: 10) {
            // Row 1: Large time card + Weather
            HStack(spacing: 10) {
                exportTimeCard
                    .frame(maxWidth: .infinity)
                
                exportWeatherCard
                    .frame(width: 130)
            }
            .frame(height: 160)
            
            // Row 2: Distance + Transport + POIs
            HStack(spacing: 10) {
                exportDistanceCard
                    .frame(maxWidth: .infinity)
                
                exportTransportCard
                    .frame(width: 95)
                
                exportPOIsCard
                    .frame(width: 95)
            }
            .frame(height: 120)
            
            // Row 3: Route map with static snapshot
            exportRouteMapCard
                .frame(height: 200)
        }
    }
    
    // Export versions of cards (without animations)
    
    private var exportTimeCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "clock.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Spacer()
            }
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 2) {
                Text(FormatUtilities.formatTime(actualDuration))
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
                
                Text(L("journey.summary.focusTime"))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(16)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                
                RoundedRectangle(cornerRadius: 20)
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
                
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(Color.white.opacity(0.5), lineWidth: 1)
            }
        )
    }
    
    private var exportWeatherCard: some View {
        VStack(spacing: 10) {
            Image(systemName: weatherIcon)
                .font(.system(size: 36, weight: .medium))
                .foregroundColor(.white)
                .symbolRenderingMode(.hierarchical)
            
            Spacer()
            
            VStack(spacing: 3) {
                Text(weatherCondition)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Text(isDaytime ? L("journey.summary.day") : L("journey.summary.night"))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(14)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                
                RoundedRectangle(cornerRadius: 20)
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
                
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(Color.white.opacity(0.5), lineWidth: 1)
            }
        )
    }
    
    private var exportDistanceCard: some View {
        VStack(alignment: .leading, spacing: 6) {
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
            
            VStack(alignment: .leading, spacing: 2) {
                Text(FormatUtilities.formatDistance(session.totalDistance))
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
                
                Text(L("journey.summary.distance"))
                    .font(.system(size: 11, weight: .medium))
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
                                Color.orange.opacity(0.18),
                                Color.red.opacity(0.12)
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
    }
    
    private var exportTransportCard: some View {
        VStack(spacing: 10) {
            Image(systemName: session.transportMode.iconName)
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(.white)
            
            Spacer()
            
            // Show subway line info if available
            if session.transportMode == .subway, let stations = session.subwayStations, !stations.isEmpty {
                VStack(spacing: 2) {
                    Text(extractSubwayLine(from: stations))
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(subwayLineColor(from: stations))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    
                    Text(session.transportMode.localizedName)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
            } else {
                Text(session.transportMode.localizedName)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.8)
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
                            colors: session.transportMode == .subway && session.subwayStations != nil ?
                                [subwayLineColor(from: session.subwayStations ?? []).opacity(0.25),
                                 subwayLineColor(from: session.subwayStations ?? []).opacity(0.15)] :
                                [Color.green.opacity(0.18),
                                 Color.teal.opacity(0.12)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .blendMode(.plusLighter)
                
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(Color.white.opacity(0.5), lineWidth: 1)
            }
        )
    }
    
    private var exportPOIsCard: some View {
        VStack(spacing: 10) {
            Image(systemName: "star.fill")
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(.yellow)
            
            Spacer()
            
            VStack(spacing: 2) {
                Text("\(discoveredPOIs.count)")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(L("journey.summary.pois"))
                    .font(.system(size: 10, weight: .semibold))
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
                                Color.yellow.opacity(0.22),
                                Color.orange.opacity(0.14)
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
    }
    
    private var exportRouteMapCard: some View {
        ZStack(alignment: .topLeading) {
            // Static map representation
            Map(initialPosition: .region(mapRegion)) {
                // Route line
                MapPolyline(coordinates: session.route)
                    .stroke(
                        LinearGradient(
                            colors: [Color.green, Color.blue, Color.purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                
                // Start marker
                Annotation("", coordinate: session.startLocation) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 12, height: 12)
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                }
                
                // End marker
                Annotation("", coordinate: session.destinationLocation) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 12, height: 12)
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .allowsHitTesting(false)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            
            // Route info overlay
            HStack(spacing: 6) {
                Image(systemName: "map.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(L("journey.summary.route"))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                ZStack {
                    Capsule()
                        .fill(.ultraThinMaterial)
                    
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.15),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .blendMode(.plusLighter)
                    
                    Capsule()
                        .strokeBorder(Color.white.opacity(0.4), lineWidth: 1)
                }
            )
            .padding(12)
        }
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.purple.opacity(0.15),
                                Color.blue.opacity(0.12)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .blendMode(.plusLighter)
                
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(Color.white.opacity(0.5), lineWidth: 1)
            }
        )
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Confetti View

struct ConfettiView: View {
    @State private var confettiPieces: [ConfettiPiece] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(confettiPieces) { piece in
                    ConfettiShape(shape: piece.shape)
                        .fill(piece.color)
                        .frame(width: piece.size, height: piece.size)
                        .rotationEffect(.degrees(piece.rotation))
                        .position(piece.position)
                        .opacity(piece.opacity)
                }
            }
            .onAppear {
                generateConfetti(in: geometry.size)
            }
        }
        .ignoresSafeArea()
    }
    
    private func generateConfetti(in size: CGSize) {
        let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]
        let shapes: [ConfettiShapeType] = [.circle, .square, .triangle]
        
        for i in 0..<50 {
            let piece = ConfettiPiece(
                id: UUID(),
                shape: shapes.randomElement()!,
                color: colors.randomElement()!,
                size: CGFloat.random(in: 8...16),
                position: CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: -50
                ),
                rotation: Double.random(in: 0...360),
                opacity: 1.0
            )
            
            confettiPieces.append(piece)
            
            // Animate each piece
            withAnimation(
                .easeOut(duration: Double.random(in: 2...4))
                .delay(Double(i) * 0.02)
            ) {
                if let index = confettiPieces.firstIndex(where: { $0.id == piece.id }) {
                    confettiPieces[index].position.y = size.height + 50
                    confettiPieces[index].rotation += Double.random(in: 360...720)
                    confettiPieces[index].opacity = 0
                }
            }
        }
    }
}

struct ConfettiPiece: Identifiable {
    let id: UUID
    let shape: ConfettiShapeType
    let color: Color
    let size: CGFloat
    var position: CGPoint
    var rotation: Double
    var opacity: Double
}

enum ConfettiShapeType {
    case circle, square, triangle
}

struct ConfettiShape: Shape {
    let shape: ConfettiShapeType
    
    func path(in rect: CGRect) -> Path {
        switch shape {
        case .circle:
            return Path(ellipseIn: rect)
        case .square:
            return Path(rect)
        case .triangle:
            var path = Path()
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.closeSubpath()
            return path
        }
    }
}

#Preview {
    JourneySummaryView(
        session: JourneySession(
            id: UUID(),
            startLocation: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            destinationLocation: CLLocationCoordinate2D(latitude: 37.8049, longitude: -122.4494),
            route: [
                CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4244),
                CLLocationCoordinate2D(latitude: 37.7949, longitude: -122.4344),
                CLLocationCoordinate2D(latitude: 37.8049, longitude: -122.4494)
            ],
            totalDistance: 5000,
            duration: 1500,
            transportMode: .cycling,
            startTime: Date().addingTimeInterval(-1500),
            subwayStations: nil
        ),
        discoveredPOIs: [
            DiscoveredPOI(
                name: "Golden Gate Park",
                category: "park",
                coordinate: CLLocationCoordinate2D(latitude: 37.7694, longitude: -122.4862)
            ),
            DiscoveredPOI(
                name: "Ferry Building",
                category: "landmark",
                coordinate: CLLocationCoordinate2D(latitude: 37.7956, longitude: -122.3934)
            )
        ],
        weatherCondition: "Clear",
        isDaytime: true,
        progress: 1.0,
        isCompleted: true,
        actualDuration: 1500,
        onDismiss: {}
    )
}
