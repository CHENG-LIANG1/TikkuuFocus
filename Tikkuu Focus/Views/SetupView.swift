//
//  SetupView.swift
//  Tikkuu Focus
//
//  Created by Tikkuu on 2026/2/8.
//

import SwiftUI
import CoreLocation
import SwiftData
import MapKit

struct SetupView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var locationManager = LocationManager()
    @StateObject private var journeyManager = JourneyManager()
    @StateObject private var weatherManager = WeatherManager()
    
    @State private var selectedTransport: TransportMode = .cycling
    @State private var selectedDuration: Int = 25 // minutes
    @State private var isStarting = false
    @State private var showPermissionAlert = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var selectedLocation: LocationSource = .currentLocation
    @State private var showLocationPicker = false
    @State private var showHistory = false
    @State private var showSettings = false
    @State private var showTrophies = false
    @ObservedObject private var settings = AppSettings.shared
    @State private var refreshID = UUID()
    @State private var cardsAppeared = false
    @State private var buttonScale: CGFloat = 1.0
    @State private var buttonGlow: CGFloat = 0
    @State private var preparingRotation: Double = 0
    @State private var preparingPulse: CGFloat = 1.0
    @State private var showFirstJourneyGuide = false
    @State private var showWeatherDetail = false
    @State private var mapPreloadCoordinate: CLLocationCoordinate2D?
    @Query(sort: \JourneyRecord.startTime, order: .reverse) private var allRecords: [JourneyRecord]
    @Environment(\.adaptiveSecondaryTextColor) var adaptiveSecondaryTextColor
    
    // MARK: - Performance Optimization
    
    // Throttle weather updates to reduce CPU usage
    private let weatherUpdateThrottle = PerformanceOptimizer.shared.throttle(interval: 5.0) {
        // Weather update logic
    }
    
    // Cache journey count to avoid repeated queries
    @State private var cachedJourneyCount: Int = 0
    
    private func updateJourneyCount() {
        cachedJourneyCount = allRecords.count
    }
    
    var body: some View {
        let isNeumorphism = settings.selectedVisualStyle == .neumorphism
        let weatherColors = weatherManager.weatherGradientColors
        let weatherCondition = weatherManager.weatherCondition
        let isDaytime = weatherManager.isDaytime
        let animSpeed = weatherManager.gradientAnimationSpeed
        let overlayInt = weatherManager.overlayIntensity
        let baseTextColor: Color = isNeumorphism ? .primary : weatherManager.optimalTextColor
        let baseSecondaryTextColor: Color = isNeumorphism ? .secondary : weatherManager.optimalSecondaryTextColor
        
        return ZStack {
            if isNeumorphism {
                AnimatedGradientBackground()
            } else {
                // Weather-based background with decorations
                WeatherBackgroundView(
                    colors: weatherColors,
                    weatherCondition: weatherCondition,
                    isDaytime: isDaytime,
                    animationSpeed: animSpeed,
                    overlayIntensity: overlayInt
                )
                .animation(.easeInOut(duration: 1.5), value: weatherColors)
                .animation(.easeInOut(duration: 1.5), value: isDaytime)
            }
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Header
                    headerView
                        .padding(.top, 20)
                        .padding(.bottom, 20)
                    
                    // Weather & History Row
                    weatherAndHistoryRow
                        .padding(.horizontal, 24)
                        .padding(.bottom, 20)
                    
                    // Main content
                    VStack(spacing: 20) {
                        locationSelectionCard
                            .scaleEffect(cardsAppeared ? 1 : 0.9)
                            .opacity(cardsAppeared ? 1 : 0)
                            .offset(y: cardsAppeared ? 0 : 20)
                            .blur(radius: cardsAppeared ? 0 : 4)
                            .animation(AnimationConfig.smoothSpring.delay(0.08), value: cardsAppeared)
                            // Note: avoid drawingGroup on material-based cards to prevent black backgrounds

                    transportSelectionCard
                        .scaleEffect(cardsAppeared ? 1 : 0.9)
                        .opacity(cardsAppeared ? 1 : 0)
                        .offset(y: cardsAppeared ? 0 : 20)
                        .blur(radius: cardsAppeared ? 0 : 4)
                        .animation(AnimationConfig.smoothSpring.delay(0.12), value: cardsAppeared)
                            // Note: avoid drawingGroup on material-based cards to prevent black backgrounds
                        
                    durationSelectionCard
                        .scaleEffect(cardsAppeared ? 1 : 0.9)
                        .opacity(cardsAppeared ? 1 : 0)
                        .offset(y: cardsAppeared ? 0 : 20)
                        .blur(radius: cardsAppeared ? 0 : 4)
                        .animation(AnimationConfig.smoothSpring.delay(0.16), value: cardsAppeared)
                        
                    startButton
                        .scaleEffect(cardsAppeared ? 1 : 0.9)
                        .opacity(cardsAppeared ? 1 : 0)
                        .offset(y: cardsAppeared ? 0 : 20)
                        .blur(radius: cardsAppeared ? 0 : 4)
                        .animation(AnimationConfig.smoothSpring.delay(0.20), value: cardsAppeared)
                }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
            .environment(\.adaptiveTextColor, baseTextColor)
            .environment(\.adaptiveSecondaryTextColor, baseSecondaryTextColor)

            if let preloadCoordinate = mapPreloadCoordinate {
                MapPreloadView(center: preloadCoordinate)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
        .id(refreshID)
        .preferredColorScheme(settings.currentColorScheme)
        .onAppear {
            setupLocation()
            fetchWeatherForSelectedLocation()
            prewarmMapIfPossible()
            
            // Debug version info
            AppInfo.debugVersionInfo()
            
            // Trigger card animations
            withAnimation(AnimationConfig.smoothSpring.delay(0.05)) {
                cardsAppeared = true
            }
            
            // Start button breathing animation
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                buttonGlow = 1.0
            }
        }
        .onChange(of: selectedLocation) { _, _ in
            fetchWeatherForSelectedLocation()
            prewarmMapIfPossible()
        }
        .onChange(of: locationManager.currentLocation) { _, newLocation in
            if case .currentLocation = selectedLocation, let location = newLocation {
                // Throttle weather updates to avoid excessive API calls
                Task {
                    await weatherManager.fetchWeather(for: location.coordinate)
                }
                prewarmMapIfPossible()
            }
        }
        .onChange(of: locationManager.authorizationStatus) { _, newStatus in
            if newStatus == .denied || newStatus == .restricted {
                showPermissionAlert = true
            } else if newStatus == .authorizedWhenInUse || newStatus == .authorizedAlways {
                locationManager.startUpdatingLocation()
            }
        }
        .onChange(of: journeyManager.state) { _, newState in
            if case .failed(let error) = newState {
                errorMessage = error
                showErrorAlert = true
                isStarting = false
            } else if case .idle = newState {
                // Reset starting state when journey ends
                isStarting = false
            }
        }
        .onChange(of: settings.selectedLanguage) { _, _ in
            refreshID = UUID()
        }
        .onChange(of: isStarting) { _, newValue in
            if newValue {
                // Start preparing animations
                withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                    preparingRotation = 360
                }
                withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                    preparingPulse = 1.15
                }
            } else {
                // Reset animations
                preparingRotation = 0
                preparingPulse = 1.0
            }
        }
        .alert(L("permission.location.title"), isPresented: $showPermissionAlert) {
            Button(L("permission.location.settings")) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button(L("permission.location.cancel"), role: .cancel) {}
        } message: {
            Text(L("permission.location.message"))
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {
                journeyManager.cancelJourney()
            }
        } message: {
            Text(errorMessage)
        }
        .fullScreenCover(isPresented: Binding(
            get: { journeyManager.state.isActive || journeyManager.state.session != nil },
            set: { if !$0 { journeyManager.cancelJourney() } }
        )) {
            ActiveJourneyView(
                locationManager: locationManager,
                journeyManager: journeyManager
            )
        }
        .sheet(isPresented: $showLocationPicker) {
            LocationPickerView(
                selectedLocation: $selectedLocation,
                locationManager: locationManager
            )
        }
        .sheet(isPresented: $showHistory) {
            HistoryView()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showTrophies) {
            TrophyView()
        }
        .sheet(isPresented: $showWeatherDetail) {
            NavigationStack {
                WeatherDetailView(
                    weatherManager: weatherManager,
                    coordinate: currentCoordinate
                )
                .navigationTitle(L("label.weather"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(.hidden, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(L("common.done")) {
                            showWeatherDetail = false
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
        }
        .sheet(item: $journeyManager.pendingSummaryPayload) { payload in
            NavigationStack {
                JourneySummaryView(
                    session: payload.session,
                    discoveredPOIs: payload.discoveredPOIs,
                    weatherCondition: payload.weatherCondition,
                    isDaytime: payload.isDaytime,
                    progress: payload.progress,
                    isCompleted: payload.isCompleted,
                    actualDuration: payload.actualDuration,
                    onDismiss: {
                        journeyManager.pendingSummaryPayload = nil
                    }
                )
                .navigationTitle(L("journey.viewSummary"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(.hidden, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(L("common.done")) {
                            journeyManager.pendingSummaryPayload = nil
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
        }
        .overlay {
            if showFirstJourneyGuide {
                firstJourneyGuideOverlay
                    .transition(.opacity.combined(with: .scale))
            }
        }
        // 注释掉自动显示首次完成引导
        /*
        .onAppear {
            // Check if we should show first journey guide
            if settings.hasCompletedFirstJourney && !settings.hasSeenFirstJourneyGuide {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                        showFirstJourneyGuide = true
                    }
                }
            }
        }
        */
    }
    
    // MARK: - Setup
    
    private func setupLocation() {
        locationManager.requestPermission()
        if locationManager.isAuthorized {
            locationManager.startUpdatingLocation()
        }
    }
    
    private func fetchWeatherForSelectedLocation() {
        Task {
            let coordinate: CLLocationCoordinate2D
            
            switch selectedLocation {
            case .currentLocation:
                guard let location = locationManager.currentLocation?.coordinate else { return }
                coordinate = location
            case .preset(let location):
                coordinate = location.coordinate
            case .custom(let coord, _):
                coordinate = coord
            }
            
            await weatherManager.fetchWeather(for: coordinate)
        }
    }

    private func prewarmMapIfPossible() {
        let coordinate = currentCoordinate
        mapPreloadCoordinate = coordinate
        journeyManager.prewarmMapServices(near: coordinate)
    }
    
    // MARK: - Header
    
    private var weatherAndHistoryRow: some View {
        HStack(spacing: 12) {
            Button {
                HapticManager.light()
                showWeatherDetail = true
            } label: {
                WeatherWidget(weatherManager: weatherManager)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(CardButtonStyle())
            .scaleEffect(cardsAppeared ? 1 : 0.9)
            .opacity(cardsAppeared ? 1 : 0)
            .offset(x: cardsAppeared ? 0 : -15)
            .blur(radius: cardsAppeared ? 0 : 3)
            .animation(AnimationConfig.smoothSpring.delay(0.04), value: cardsAppeared)
            
            Button {
                HapticManager.light()
                showHistory = true
            } label: {
                HistorySummaryWidget(records: monthRecords)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(CardButtonStyle())
            .scaleEffect(cardsAppeared ? 1 : 0.9)
            .opacity(cardsAppeared ? 1 : 0)
            .offset(x: cardsAppeared ? 0 : 15)
            .blur(radius: cardsAppeared ? 0 : 3)
            .animation(AnimationConfig.smoothSpring.delay(0.04), value: cardsAppeared)
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        ZStack {
            // Left button - Trophy only
            HStack {
                Button {
                    HapticManager.light()
                    withAnimation(AnimationConfig.quickSpring) {
                        showTrophies = true
                    }
                } label: {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.85, blue: 0.2),
                                    Color(red: 1.0, green: 0.7, blue: 0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                        .background(
                            Group {
                                if settings.selectedVisualStyle == .neumorphism {
                                    Circle()
                                        .fill(NeumorphismStyle.surface(for: colorScheme))
                                        .shadow(color: NeumorphismStyle.raisedBottomShadow(for: colorScheme), radius: 11, x: 7, y: 7)
                                        .shadow(color: NeumorphismStyle.raisedTopHighlight(for: colorScheme), radius: 8, x: -6, y: -6)
                                } else {
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                                }
                            }
                        )
                }
                .buttonStyle(PressableButtonStyle())
                .scaleEffect(cardsAppeared ? 1 : 0.8)
                .opacity(cardsAppeared ? 1 : 0)
                .blur(radius: cardsAppeared ? 0 : 5)
                .animation(AnimationConfig.bouncySpring.delay(0.0), value: cardsAppeared)
                
                Spacer()
            }
            
            // Center title (absolutely centered)
            Text("Roam Focus")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(weatherManager.optimalTextColor)
                .shadow(color: weatherManager.isBackgroundDark ? Color.black.opacity(0.3) : Color.white.opacity(0.5), radius: 2, x: 0, y: 1)
                .scaleEffect(cardsAppeared ? 1 : 0.8)
                .opacity(cardsAppeared ? 1 : 0)
                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.0), value: cardsAppeared)
            
            // Right button - Settings
            HStack {
                Spacer()
                
                Button {
                    HapticManager.light()
                    withAnimation(AnimationConfig.quickSpring) {
                        showSettings = true
                    }
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(weatherManager.optimalTextColor)
                        .frame(width: 44, height: 44)
                        .background(
                            Group {
                                if settings.selectedVisualStyle == .neumorphism {
                                    Circle()
                                        .fill(NeumorphismStyle.surface(for: colorScheme))
                                        .shadow(color: NeumorphismStyle.raisedBottomShadow(for: colorScheme), radius: 11, x: 7, y: 7)
                                        .shadow(color: NeumorphismStyle.raisedTopHighlight(for: colorScheme), radius: 8, x: -6, y: -6)
                                } else {
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                                }
                            }
                        )
                }
                .buttonStyle(PressableButtonStyle())
                .scaleEffect(cardsAppeared ? 1 : 0.8)
                .opacity(cardsAppeared ? 1 : 0)
                .blur(radius: cardsAppeared ? 0 : 5)
                .animation(AnimationConfig.bouncySpring.delay(0.0), value: cardsAppeared)
            }
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Month Records
    
    private var monthRecords: [JourneyRecord] {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        
        return allRecords.filter { record in
            record.startTime >= startOfMonth && record.startTime <= now
        }
    }
    
    // MARK: - Current Coordinate
    
    private var currentCoordinate: CLLocationCoordinate2D {
        switch selectedLocation {
        case .currentLocation:
            return locationManager.currentLocation?.coordinate ?? CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        case .preset(let location):
            return location.coordinate
        case .custom(let coordinate, _):
            return coordinate
        }
    }
    
    // MARK: - Location Selection
    
    private var locationSelectionCard: some View {
        Button {
            HapticManager.light()
            showLocationPicker = true
        } label: {
            VStack(alignment: .leading, spacing: 14) {
                Text(L("location.selectStart"))
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(weatherManager.optimalTextColor)
                
                HStack(spacing: 12) {
                    // Location icon or emoji
                    if case .preset(let location) = selectedLocation {
                        // Show emoji for preset locations
                        ZStack {
                            Circle()
                                .fill(LiquidGlassStyle.primaryGradient)
                                .frame(width: 44, height: 44)
                            
                            Text(location.emoji)
                                .font(.system(size: 24))
                        }
                    } else {
                        // Show SF Symbol for current location and custom
                        ZStack {
                            Circle()
                                .fill(LiquidGlassStyle.primaryGradient)
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: locationIcon)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(selectedLocation.displayName)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(weatherManager.optimalTextColor)
                        
                        Text(locationSubtitle)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(weatherManager.optimalSecondaryTextColor)
                    }
                    .id(selectedLocation.displayName) // Force refresh when location changes
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(weatherManager.optimalSecondaryTextColor)
                }
            }
            .padding(20)
            .glassCard(cornerRadius: 20)
        }
    }
    
    private var locationIcon: String {
        switch selectedLocation {
        case .currentLocation:
            return "location.fill"
        case .preset:
            return "globe.asia.australia.fill" // This won't be used anymore for preset
        case .custom:
            return "globe.asia.australia.fill"
        }
    }
    
    private var locationSubtitle: String {
        switch selectedLocation {
        case .currentLocation:
            return locationManager.currentLocation != nil ? L("location.status.gpsReady") : L("location.status.waiting")
        case .preset(let location):
            return location.country
        case .custom:
            return L("location.custom")
        }
    }
    
    // MARK: - Transport Selection
    
    private var transportSelectionCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L("label.selectTransport"))
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(weatherManager.optimalTextColor)
            
            HStack(spacing: 10) {
                ForEach(TransportMode.allCases) { mode in
                    TransportModeButton(
                        mode: mode,
                        isSelected: selectedTransport == mode
                    ) {
                        HapticManager.selection()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTransport = mode
                            // 不再自动更新时长，保持用户选择
                        }
                    }
                }
            }
        }
        .padding(20)
        .glassCard(cornerRadius: 20)
    }
    
    // MARK: - Duration Selection
    
    private var durationSelectionCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L("label.selectDuration"))
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(weatherManager.optimalTextColor)
            
            VStack(spacing: 14) {
                // Duration picker
                HStack(spacing: 10) {
                    ForEach(selectedTransport.suggestedDurations, id: \.self) { duration in
                        DurationButton(
                            duration: duration,
                            isSelected: selectedDuration == duration
                        ) {
                            HapticManager.selection()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedDuration = duration
                            }
                        }
                    }
                }
                
                // Custom duration slider
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(L("label.custom"))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(adaptiveSecondaryTextColor)
                        
                        Spacer()
                        
                        Text("\(selectedDuration) \(L("time.unit.min"))")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(LiquidGlassStyle.primaryGradient)
                    }
                    
                    Slider(value: Binding(
                        get: { Double(selectedDuration) },
                        set: {
                            let newValue = Int($0)
                            guard newValue != selectedDuration else { return }
                            selectedDuration = newValue
                            triggerDurationSliderHaptic(for: newValue)
                        }
                    ), in: 5...120, step: 5)
                    .tint(Color(red: 0.4, green: 0.7, blue: 0.9))
                }
                .padding(.top, 4)
            }
        }
        .padding(20)
        .glassCard(cornerRadius: 20)
    }
    
    // MARK: - Start Button (优化尺寸)
    
    private var startButton: some View {
        let ctaTextColor: Color = settings.isNeumorphismLight
            ? Color(red: 0.18, green: 0.22, blue: 0.32)
            : .white

        return Button {
            HapticManager.medium()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                buttonScale = 0.95
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    buttonScale = 1.0
                }
            }
            startJourney()
        } label: {
            HStack(spacing: 10) {
                if isStarting {
                    // Preparing state with custom spinner
                    ZStack {
                        Circle()
                            .stroke(ctaTextColor.opacity(0.3), lineWidth: 2.5)
                            .frame(width: 20, height: 20)
                        
                        Circle()
                            .trim(from: 0, to: 0.7)
                            .stroke(
                                ctaTextColor,
                                style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                            )
                            .frame(width: 20, height: 20)
                            .rotationEffect(.degrees(preparingRotation))
                    }
                    .scaleEffect(preparingPulse)
                    .transition(.scale.combined(with: .opacity))
                    
                    Text(L("label.preparing"))
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .transition(.opacity)
                } else {
                    // Normal state
                    Image(systemName: "location.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .transition(.scale.combined(with: .opacity))
                    
                    Text(L("label.startJourney"))
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .transition(.opacity)
                }
            }
            .foregroundColor(ctaTextColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                Group {
                    if settings.selectedVisualStyle == .neumorphism {
                        ZStack {
                            NeumorphSurface(
                                cornerRadius: 16,
                                depth: canStartJourney ? .raised : .inset,
                                fill: AnyShapeStyle(
                                    canStartJourney
                                    ? LinearGradient(
                                        colors: [
                                            Color(red: 0.45, green: 0.57, blue: 0.90),
                                            Color(red: 0.36, green: 0.48, blue: 0.80)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                    : LinearGradient(
                                        colors: [
                                            NeumorphismStyle.pressedSurface(for: colorScheme).opacity(0.95),
                                            NeumorphismStyle.surface(for: colorScheme).opacity(0.92)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            )
                        }
                    } else {
                        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)
                        ZStack {
                            shape
                                .fill(.ultraThinMaterial)

                            shape
                                .fill(
                                    canStartJourney ?
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.34, green: 0.62, blue: 1.0).opacity(0.36),
                                            Color(red: 0.46, green: 0.42, blue: 0.96).opacity(0.32)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ) :
                                    LinearGradient(
                                        colors: [Color.gray.opacity(0.20)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )

                            shape
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.26),
                                            Color.white.opacity(0.0)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .blendMode(.overlay)

                            shape
                                .strokeBorder(Color.white.opacity(0.28), lineWidth: 1.1)

                            // Shimmer effect (only when not preparing)
                            if canStartJourney && !isStarting {
                                shape
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0),
                                                Color.white.opacity(0.25),
                                                Color.white.opacity(0)
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .offset(x: -200 + buttonGlow * 400)
                                    .mask(shape)
                            }
                        }
                    }
                }
            )
            .shadow(
                color: settings.selectedVisualStyle == .neumorphism
                    ? Color.clear
                    : (canStartJourney
                        ? Color(red: 0.3, green: 0.5, blue: 0.9).opacity(0.3 + buttonGlow * 0.15)
                        : Color.clear),
                radius: settings.selectedVisualStyle == .neumorphism ? 0 : (12 + buttonGlow * 6),
                x: 0,
                y: settings.selectedVisualStyle == .neumorphism ? 0 : (6 + buttonGlow * 2)
            )
            .shadow(
                color: settings.selectedVisualStyle == .neumorphism
                    ? Color.clear
                    : Color.black.opacity(canStartJourney ? 0.2 : 0.08),
                radius: settings.selectedVisualStyle == .neumorphism ? 0 : 10,
                x: 0,
                y: settings.selectedVisualStyle == .neumorphism ? 0 : 5
            )
        }
        .disabled(!canStartJourney)
        .scaleEffect(buttonScale)
        .opacity(canStartJourney ? 1.0 : 0.5)
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: canStartJourney)
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isStarting)
        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: buttonGlow)
    }
    
    private var canStartJourney: Bool {
        if isStarting {
            return false
        }
        
        // Check based on location source
        switch selectedLocation {
        case .currentLocation:
            return locationManager.isAuthorized && locationManager.currentLocation != nil
        case .preset, .custom:
            return true // Preset and custom locations are always ready
        }
    }
    
    // MARK: - First Journey Guide Overlay (简洁版)
    
    @ViewBuilder
    private var firstJourneyGuideOverlay: some View {
        ZStack {
            Color.black.opacity(0.75)
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                // 庆祝图标
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.green.opacity(0.3), Color.teal.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 50, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.green, Color.teal],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .shadow(color: Color.green.opacity(0.4), radius: 20, x: 0, y: 10)
                
                // 标题
                Text("🎉 " + L("guide.firstJourney.title"))
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                // 简洁的3步骤
                VStack(spacing: 20) {
                    OnboardingStepView(
                        number: "1",
                        icon: "clock.arrow.circlepath",
                        color: .blue
                    )
                    
                    OnboardingStepView(
                        number: "2",
                        icon: "chart.bar.fill",
                        color: .orange
                    )
                    
                    OnboardingStepView(
                        number: "3",
                        icon: "star.fill",
                        color: .yellow
                    )
                }
                .padding(.horizontal, 40)
                
                // 指向历史按钮的箭头
                HStack {
                    Spacer()
                    VStack(spacing: 6) {
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.yellow)
                        Text(L("guide.firstJourney.tapHistory"))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.yellow)
                    }
                    .padding(.trailing, 30)
                }
                
                // 开始按钮
                Button {
                    HapticManager.success()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                        showFirstJourneyGuide = false
                    }
                    settings.hasSeenFirstJourneyGuide = true
                } label: {
                    Text(L("guide.firstJourney.gotIt"))
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.green, Color.teal],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                }
                .padding(.horizontal, 40)
                .shadow(color: Color.green.opacity(0.4), radius: 15, x: 0, y: 8)
            }
            .padding(.vertical, 40)
            .padding(.horizontal, 24)
            .themedRoundedBackground(cornerRadius: 28, depth: .inset)
            .padding(.horizontal, 32)
        }
    }
    
    // MARK: - Actions
    
    private func startJourney() {
        let startCoordinate: CLLocationCoordinate2D
        let isPresetCity: Bool
        var presetLocation: PresetLocation? = nil
        
        // Determine start coordinate based on selected location
        switch selectedLocation {
        case .currentLocation:
            guard let location = locationManager.currentLocation?.coordinate else {
                errorMessage = "Location not available. Please wait..."
                showErrorAlert = true
                return
            }
            startCoordinate = location
            isPresetCity = false
            
        case .preset(let location):
            startCoordinate = location.coordinate
            isPresetCity = true
            presetLocation = location
            
        case .custom(let coordinate, _):
            startCoordinate = coordinate
            isPresetCity = false
        }
        
        isStarting = true
        
        Task {
            await journeyManager.startJourney(
                from: startCoordinate,
                transportMode: selectedTransport,
                duration: TimeInterval(selectedDuration * 60),
                isPresetCity: isPresetCity,
                presetLocation: presetLocation
            )
            
            // Check if journey started successfully
            if case .failed = journeyManager.state {
                isStarting = false
            }
        }
    }

    private func triggerDurationSliderHaptic(for value: Int) {
        // Give crisp step feedback while dragging, with stronger pulses on milestones.
        if value == 5 || value == 120 || value % 30 == 0 {
            HapticManager.heavy()
        } else if value % 15 == 0 {
            HapticManager.medium()
        } else {
            HapticManager.selection()
        }
    }
}

private struct MapPreloadView: View {
    @ObservedObject private var settings = AppSettings.shared
    let center: CLLocationCoordinate2D
    @State private var cameraPosition: MapCameraPosition = .automatic

    var body: some View {
        Map(position: $cameraPosition) {}
            .mapStyle(settings.selectedMapMode.style)
            .frame(width: 1, height: 1)
            .opacity(0.01)
            .onAppear {
                cameraPosition = .region(
                    MKCoordinateRegion(
                        center: center,
                        span: MKCoordinateSpan(latitudeDelta: 0.06, longitudeDelta: 0.06)
                    )
                )
            }
            .onChange(of: center.latitude) { _, _ in
                cameraPosition = .region(
                    MKCoordinateRegion(
                        center: center,
                        span: MKCoordinateSpan(latitudeDelta: 0.06, longitudeDelta: 0.06)
                    )
                )
            }
            .onChange(of: center.longitude) { _, _ in
                cameraPosition = .region(
                    MKCoordinateRegion(
                        center: center,
                        span: MKCoordinateSpan(latitudeDelta: 0.06, longitudeDelta: 0.06)
                    )
                )
            }
    }
}

// MARK: - Scale Button Style

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(AnimationConfig.snappy, value: configuration.isPressed)
    }
}

// MARK: - Pressable Button Style

struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(AnimationConfig.quickSpring, value: configuration.isPressed)
    }
}

// MARK: - Card Button Style

struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.92 : 1.0)
            .animation(AnimationConfig.snappy, value: configuration.isPressed)
    }
}

// MARK: - Onboarding Step View (简洁图标步骤)

struct OnboardingStepView: View {
    let number: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            // 步骤编号
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Text(number)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(color)
            }
            
            // 图标
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: [
                                color.opacity(0.3),
                                color.opacity(0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(color)
            }
            
            Spacer()
        }
    }
}

// MARK: - History Summary Widget

struct HistorySummaryWidget: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.adaptiveTextColor) var adaptiveTextColor
    @Environment(\.adaptiveSecondaryTextColor) var adaptiveSecondaryTextColor
    let records: [JourneyRecord]
    
    private var totalTime: TimeInterval {
        records.reduce(0) { $0 + $1.duration }
    }
    
    private var journeyCount: Int {
        records.count
    }
    
    private var currentMonthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        formatter.locale = Locale(identifier: AppSettings.shared.selectedLanguage == "zh-Hans" ? "zh-Hans" : "en")
        return formatter.string(from: Date())
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Icon and title with chevron
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.6, green: 0.4, blue: 0.9).opacity(colorScheme == .dark ? 0.2 : 0.3),
                                    Color(red: 0.4, green: 0.6, blue: 1.0).opacity(colorScheme == .dark ? 0.08 : 0.15)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.6, green: 0.4, blue: 0.9),
                                    Color(red: 0.4, green: 0.6, blue: 1.0)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                Text(currentMonthName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(adaptiveTextColor.opacity(0.9))
                
                Spacer()
                
                // Chevron indicator
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(adaptiveSecondaryTextColor.opacity(0.6))
            }
            
            // Stats
            VStack(alignment: .leading, spacing: 6) {
                Text(FormatUtilities.formatTime(totalTime))
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(adaptiveTextColor)
                
                HStack(spacing: 4) {
                    Text("\(journeyCount)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(adaptiveTextColor.opacity(0.8))
                    
                    Text(journeyCount == 1 ? L("common.journey") : L("common.journeys"))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(adaptiveSecondaryTextColor)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .glassCard(cornerRadius: 16)
    }
}

// MARK: - Weather Widget

struct WeatherWidget: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.adaptiveTextColor) var adaptiveTextColor
    @Environment(\.adaptiveSecondaryTextColor) var adaptiveSecondaryTextColor
    @ObservedObject var weatherManager: WeatherManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Icon and title with chevron
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(colorScheme == .dark ? 0.15 : 0.35),
                                    Color.white.opacity(colorScheme == .dark ? 0.05 : 0.15)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)
                    
                    if weatherManager.isLoading {
                        ProgressView()
                            .tint(adaptiveTextColor)
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: weatherManager.weatherIcon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(adaptiveTextColor)
                            .symbolRenderingMode(.hierarchical)
                    }
                }
                
                Text(L("label.weather"))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(adaptiveTextColor.opacity(0.9))
                
                Spacer()
                
                // Chevron indicator
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(adaptiveSecondaryTextColor.opacity(0.6))
            }
            
            // Weather info
            VStack(alignment: .leading, spacing: 6) {
                Text(weatherManager.temperatureString)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(adaptiveTextColor)
                
                if !weatherManager.weatherDescription.isEmpty {
                    Text(weatherManager.weatherDescription)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(adaptiveSecondaryTextColor)
                        .lineLimit(1)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .glassCard(cornerRadius: 16)
    }
}

#Preview {
    SetupView()
}
