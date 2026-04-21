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
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
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
    @State private var showTrophies = false
    @State private var showSettings = false
    @ObservedObject private var settings = AppSettings.shared
    @State private var cardsAppeared = false
    @State private var buttonScale: CGFloat = 1.0
    @State private var buttonGlow: CGFloat = 0
    @State private var preparingRotation: Double = 0
    @State private var preparingPulse: CGFloat = 1.0
    @State private var showFirstJourneyGuide = false
    @State private var showWeatherDetail = false
    @State private var mapPreloadCoordinate: CLLocationCoordinate2D?
    @State private var journeyPreparationTask: Task<Void, Never>?
    @State private var weatherUpdateTask: Task<Void, Never>?
    @State private var lastWeatherFetchAt: Date = .distantPast
    @State private var lastWeatherFetchCoordinate: CLLocationCoordinate2D?
    @Query(sort: \JourneyRecord.startTime, order: .reverse) private var allRecords: [JourneyRecord]
    @Environment(\.adaptiveSecondaryTextColor) var adaptiveSecondaryTextColor
    
    // MARK: - Theme Colors
    
    private var isEnergySavingMode: Bool {
        reduceMotion || ProcessInfo.processInfo.isLowPowerModeEnabled
    }

    private let weatherFetchMinDistance: CLLocationDistance = 500
    
    private var baseTextColor: Color {
        .primary
    }
    
    private var baseSecondaryTextColor: Color {
        .secondary
    }
    
    private var mainScrollViewContent: some View {
        VStack(spacing: 0) {
            // Header
            headerView
                .padding(.top, 20)
                .padding(.bottom, 20)
            
            // Weather & History Row
            weatherAndHistoryRow
                .padding(.horizontal, 24)
                .padding(.bottom, 18)
            
            // Main content
            VStack(spacing: 20) {
                locationSelectionCard
                    .scaleEffect(cardsAppeared ? 1 : 0.9)
                    .opacity(cardsAppeared ? 1 : 0)
                    .offset(y: cardsAppeared ? 0 : 20)
                    .animation(AnimationConfig.smoothSpring.delay(0.08), value: cardsAppeared)
                    // Note: avoid drawingGroup on material-based cards to prevent black backgrounds

                transportSelectionCard
                    .scaleEffect(cardsAppeared ? 1 : 0.9)
                    .opacity(cardsAppeared ? 1 : 0)
                    .offset(y: cardsAppeared ? 0 : 20)
                    .animation(AnimationConfig.smoothSpring.delay(0.12), value: cardsAppeared)
                    // Note: avoid drawingGroup on material-based cards to prevent black backgrounds
                
                durationSelectionCard
                    .scaleEffect(cardsAppeared ? 1 : 0.9)
                    .opacity(cardsAppeared ? 1 : 0)
                    .offset(y: cardsAppeared ? 0 : 20)
                    .animation(AnimationConfig.smoothSpring.delay(0.16), value: cardsAppeared)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }
    
    var body: some View {
        return ZStack {
            AnimatedGradientBackground()
            
            ScrollView(showsIndicators: false) {
                mainScrollViewContent
            }
            .environment(\.adaptiveTextColor, baseTextColor)
            .environment(\.adaptiveSecondaryTextColor, baseSecondaryTextColor)
            .safeAreaInset(edge: .bottom) {
                startButton
                    .scaleEffect(cardsAppeared ? 1 : 0.9)
                    .opacity(cardsAppeared ? 1 : 0)
                    .offset(y: cardsAppeared ? 0 : 20)
                    .opacity(cardsAppeared ? 1 : 0)
                    .animation(AnimationConfig.smoothSpring.delay(0.20), value: cardsAppeared)
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .padding(.bottom, 8)
            }

            if let preloadCoordinate = mapPreloadCoordinate {
                MapPreloadView(
                    center: preloadCoordinate,
                    destination: journeyManager.preparedDestination
                )
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            }
        }
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
            updateButtonGlowAnimation()
        }
        .onChange(of: scenePhase) { _, _ in
            updateButtonGlowAnimation()
        }
        .onChange(of: reduceMotion) { _, _ in
            updateButtonGlowAnimation()
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSProcessInfoPowerStateDidChange)) { _ in
            updateButtonGlowAnimation()
        }
        .onChange(of: selectedLocation) { _, _ in
            fetchWeatherForSelectedLocation(force: true)
            prewarmMapIfPossible()
        }
        .onChange(of: selectedTransport) { _, _ in
            scheduleJourneyPreparation()
        }
        .onChange(of: selectedDuration) { _, _ in
            scheduleJourneyPreparation()
        }
        .onChange(of: locationManager.currentLocation) { _, newLocation in
            if case .currentLocation = selectedLocation, let location = newLocation {
                // Throttle weather updates to avoid excessive API calls
                fetchWeatherIfNeeded(for: location.coordinate)
                prewarmMapIfPossible()
            }
        }
        .onDisappear {
            journeyPreparationTask?.cancel()
            journeyPreparationTask = nil
            weatherUpdateTask?.cancel()
            weatherUpdateTask = nil
        }
        .onChange(of: locationManager.authorizationStatus) { _, newStatus in
            if newStatus == .denied || newStatus == .restricted {
                showPermissionAlert = true
            } else if newStatus == .authorizedWhenInUse || newStatus == .authorizedAlways {
                locationManager.startUpdatingLocation()
            }
        }
        .onChange(of: journeyManager.state) { _, newState in
            switch newState {
            case .active, .paused, .completed:
                locationManager.stopUpdatingLocation()
            case .failed(let error):
                errorMessage = error
                showErrorAlert = true
                isStarting = false
                if locationManager.isAuthorized {
                    locationManager.startUpdatingLocation()
                }
            case .idle:
                // Reset starting state when journey ends
                isStarting = false
                if locationManager.isAuthorized {
                    locationManager.startUpdatingLocation()
                }
            case .preparing:
                break
            }
        }
        .onChange(of: isStarting) { _, newValue in
            if newValue {
                if isEnergySavingMode {
                    preparingRotation = 0
                    withAnimation(.easeOut(duration: 0.2)) {
                        preparingPulse = 1.05
                    }
                } else {
                    // Start preparing animations
                    withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                        preparingRotation = 360
                    }
                    withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                        preparingPulse = 1.15
                    }
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
        .sheet(isPresented: $showTrophies) {
            TrophyView()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
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
                    attribution: payload.attribution,
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
    
    private func fetchWeatherForSelectedLocation(force: Bool = false) {
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

        fetchWeatherIfNeeded(for: coordinate, force: force)
    }

    private func prewarmMapIfPossible() {
        let coordinate = currentCoordinate
        mapPreloadCoordinate = coordinate
        journeyManager.prewarmMapServices(near: coordinate)
        scheduleJourneyPreparation(immediate: true)
    }

    private func scheduleJourneyPreparation(immediate: Bool = false) {
        journeyPreparationTask?.cancel()
        guard !isStarting else { return }

        let startCoordinate: CLLocationCoordinate2D
        let isPresetCity: Bool
        var presetLocation: PresetLocation? = nil

        switch selectedLocation {
        case .currentLocation:
            guard let location = locationManager.currentLocation?.coordinate else { return }
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

        let selectedMode = selectedTransport
        let selectedDurationValue = selectedDuration

        journeyPreparationTask = Task {
            // Only debounce when not immediate (user is changing settings)
            if !immediate {
                try? await Task.sleep(nanoseconds: 200_000_000)
                guard !Task.isCancelled else { return }
            }

            journeyManager.prepareJourney(
                from: startCoordinate,
                transportMode: selectedMode,
                duration: TimeInterval(selectedDurationValue * 60),
                isPresetCity: isPresetCity,
                presetLocation: presetLocation
            )
        }
    }
    
    // MARK: - Header
    
    private var weatherAndHistoryRow: some View {
        HStack(spacing: 12) {
            Button {
                HapticManager.light()
                showWeatherDetail = true
            } label: {
                WeatherWidget(weatherManager: weatherManager)
            }
            .buttonStyle(ScaleButtonStyle())
            .scaleEffect(cardsAppeared ? 1 : 0.9)
            .opacity(cardsAppeared ? 1 : 0)
            .offset(x: cardsAppeared ? 0 : -15)
            .animation(AnimationConfig.smoothSpring.delay(0.04), value: cardsAppeared)
            
            Button {
                HapticManager.light()
                showHistory = true
            } label: {
                HistorySummaryWidget(records: monthRecords)
            }
            .buttonStyle(ScaleButtonStyle())
            .scaleEffect(cardsAppeared ? 1 : 0.9)
            .opacity(cardsAppeared ? 1 : 0)
            .offset(x: cardsAppeared ? 0 : 15)
            .animation(AnimationConfig.smoothSpring.delay(0.04), value: cardsAppeared)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Header
    
    private var headerView: some View {
        ZStack {
            // Left button - History/Records
            HStack {
                Button {
                    HapticManager.light()
                    withAnimation(AnimationConfig.quickSpring) {
                        showTrophies = true
                    }
                } label: {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(baseTextColor)
                        .frame(width: 44, height: 44)
                        .background(
                            Group {
                                // Clean frosted glass
                                Circle()
                                    .fill(colorScheme == .dark ? Color.black.opacity(0.3) : Color.white.opacity(0.5))
                                    .background(Circle().fill(.ultraThinMaterial))
                            }
                        )
                }
                .buttonStyle(ScaleButtonStyle())
                .scaleEffect(cardsAppeared ? 1 : 0.8)
                .opacity(cardsAppeared ? 1 : 0)
                .animation(AnimationConfig.bouncySpring.delay(0.0), value: cardsAppeared)
                
                Spacer()
            }
            
            // Center title (absolutely centered)
            Text("Roam Focus")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundColor(baseTextColor)
                .shadow(color: colorScheme == .dark ? Color.black.opacity(0.06) : Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
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
                        .foregroundColor(baseTextColor)
                        .frame(width: 44, height: 44)
                        .background(
                            Group {
                                // Clean frosted glass
                                Circle()
                                    .fill(colorScheme == .dark ? Color.black.opacity(0.3) : Color.white.opacity(0.5))
                                    .background(Circle().fill(.ultraThinMaterial))
                            }
                        )
                }
                .buttonStyle(ScaleButtonStyle())
                .scaleEffect(cardsAppeared ? 1 : 0.8)
                .opacity(cardsAppeared ? 1 : 0)
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
                    .font(.system(size: 19, weight: .semibold, design: .rounded))
                    .foregroundColor(baseTextColor)
                
                HStack(spacing: 12) {
                    // Location icon or emoji
                    if case .preset(let location) = selectedLocation {
                        // Show emoji for preset locations
                        ZStack {
                            Circle()
                                .fill(Color.accentColor)
                                .frame(width: 44, height: 44)
                            
                            Text(location.emoji)
                                .font(.system(size: 24))
                        }
                    } else {
                        // Show SF Symbol for current location and custom
                        ZStack {
                            Circle()
                                .fill(Color.accentColor)
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: locationIcon)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(locationDisplayName)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(baseTextColor)
                        
                        if let subtitle = locationSubtitle {
                            Text(subtitle)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(baseSecondaryTextColor)
                        }
                    }
                    .id(locationDisplayName) // Force refresh when location changes
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(baseSecondaryTextColor)
                }
            }
            .padding(24)
            .glassCard(
                cornerRadius: 28,
                tintColor: colorScheme == .dark ? Color(red: 0.15, green: 0.2, blue: 0.3).opacity(0.6) : Color.blue.opacity(0.1)
            )
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
    
    /// Main display name for the location card - shows specific name for current location
    private var locationDisplayName: String {
        switch selectedLocation {
        case .currentLocation:
            // Show actual location name if available, otherwise show "Current Location"
            let name = locationManager.currentLocationName
            return !name.isEmpty ? name : L("location.current")
        case .preset(let location):
            return location.localizedName
        case .custom(_, let name):
            return name
        }
    }
    
    /// Subtitle shown below the main name (nil for current location to avoid duplication)
    private var locationSubtitle: String? {
        switch selectedLocation {
        case .currentLocation:
            // No subtitle for current location - the name itself is sufficient
            return nil
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
                .font(.system(size: 19, weight: .semibold, design: .rounded))
                .foregroundColor(baseTextColor)
            
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
        .padding(24)
        .glassCard(
            cornerRadius: 28,
            tintColor: colorScheme == .dark ? Color(red: 0.1, green: 0.25, blue: 0.15).opacity(0.6) : Color.green.opacity(0.1)
        )
    }
    
    // MARK: - Duration Selection
    
    private var durationSelectionCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L("label.selectDuration"))
                .font(.system(size: 19, weight: .semibold, design: .rounded))
                .foregroundColor(baseTextColor)
            
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
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.accentColor)
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
        .padding(24)
        .glassCard(
            cornerRadius: 28,
            tintColor: colorScheme == .dark ? Color(red: 0.25, green: 0.15, blue: 0.3).opacity(0.6) : Color.purple.opacity(0.1)
        )
    }
    
    // MARK: - Start Button (优化尺寸)
    
    private var startButton: some View {
        let ctaTextColor: Color = .white

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
                    .frame(width: 26, height: 26)
                    .scaleEffect(preparingPulse)
                    .transition(.scale.combined(with: .opacity))
                    
                    Text(L("transport.status.warmingUp"))
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .kerning(0.1)
                        .transition(.opacity)
                } else {
                    // Normal state: text only
                    Text(L("label.startJourney"))
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .kerning(0.1)
                        .transition(.opacity)
                }
            }
            .foregroundColor(ctaTextColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 17)
            .background(
                Group {
                    PremiumAnimatedGradientButtonBackground(isEnabled: canStartJourney)

                        if canStartJourney && !isStarting && !isEnergySavingMode {
                            let shape = RoundedRectangle(cornerRadius: 26, style: .continuous)
                            shape
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0),
                                            Color.white.opacity(0.3),
                                            Color.white.opacity(0)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .offset(x: -220 + buttonGlow * 440)
                                .mask(shape)
                        }
                }
            )
            .shadow(
                color: canStartJourney
                    ? Color(red: 0.28, green: 0.49, blue: 0.92).opacity(0.30 + buttonGlow * 0.14)
                    : Color.black.opacity(0.06),
                radius: canStartJourney ? (14 + buttonGlow * 6) : 6,
                x: 0,
                y: canStartJourney ? (8 + buttonGlow * 2) : 3
            )
            .shadow(
                color: Color.black.opacity(canStartJourney ? 0.22 : 0.08),
                radius: 10,
                x: 0,
                y: 5
            )
        }
        .disabled(!canStartJourney)
        .scaleEffect(buttonScale)
        .opacity(canStartJourney ? 1.0 : 0.56)
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: canStartJourney)
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isStarting)
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

    private func updateButtonGlowAnimation() {
        guard scenePhase == .active, !isEnergySavingMode else {
            buttonGlow = 0
            return
        }

        buttonGlow = 0
        withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
            buttonGlow = 1.0
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
                    .font(.system(size: 26, weight: .semibold, design: .rounded))
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
                            RoundedRectangle(cornerRadius: 24)
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
            .themedRoundedBackground(cornerRadius: 28)
            .padding(.horizontal, 32)
        }
    }
    
    // MARK: - Actions
    
    private func startJourney() {
        journeyPreparationTask?.cancel()
        journeyPreparationTask = nil

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

    private func fetchWeatherIfNeeded(for coordinate: CLLocationCoordinate2D, force: Bool = false) {
        guard shouldFetchWeather(for: coordinate, force: force) else { return }

        lastWeatherFetchAt = Date()
        lastWeatherFetchCoordinate = coordinate

        weatherUpdateTask?.cancel()
        weatherUpdateTask = Task {
            await weatherManager.fetchWeather(for: coordinate)
        }
    }

    private func shouldFetchWeather(for coordinate: CLLocationCoordinate2D, force: Bool) -> Bool {
        if force {
            return true
        }

        let elapsed = Date().timeIntervalSince(lastWeatherFetchAt)
        let minInterval = PerformanceConfig.weatherUpdateInterval

        if let lastCoordinate = lastWeatherFetchCoordinate {
            let movedDistance = lastCoordinate.distance(to: coordinate)
            return movedDistance >= weatherFetchMinDistance || elapsed >= minInterval
        }

        return elapsed >= minInterval
    }
}

private struct MapPreloadView: View {
    @ObservedObject private var settings = AppSettings.shared
    let center: CLLocationCoordinate2D
    var destination: CLLocationCoordinate2D?
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var destCameraPosition: MapCameraPosition = .automatic

    var body: some View {
        ZStack {
            // Preload start region
            Map(position: $cameraPosition) {}
                .mapStyle(settings.selectedMapMode.style)
                .frame(width: 1, height: 1)
                .opacity(0.01)
            
            // Preload destination region if available
            if destination != nil {
                Map(position: $destCameraPosition) {}
                    .mapStyle(settings.selectedMapMode.style)
                    .frame(width: 1, height: 1)
                    .opacity(0.01)
            }
        }
        .onAppear {
            updateCameraPositions()
        }
        .onChange(of: center.latitude) { _, _ in
            updateStartCamera()
        }
        .onChange(of: center.longitude) { _, _ in
            updateStartCamera()
        }
        .onChange(of: destination?.latitude) { _, _ in
            updateDestCamera()
        }
        .onChange(of: destination?.longitude) { _, _ in
            updateDestCamera()
        }
    }
    
    private func updateCameraPositions() {
        updateStartCamera()
        updateDestCamera()
    }
    
    private func updateStartCamera() {
        cameraPosition = .region(
            MKCoordinateRegion(
                center: center,
                span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
            )
        )
    }
    
    private func updateDestCamera() {
        guard let dest = destination else { return }
        destCameraPosition = .region(
            MKCoordinateRegion(
                center: dest,
                span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
            )
        )
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
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
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

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Premium Animated Gradient Button Background

struct PremiumAnimatedGradientButtonBackground: View {
    @State private var animateGradient = false
    let isEnabled: Bool
    
    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 26, style: .continuous)
        
        ZStack {
            if isEnabled {
                // Base Animated Gradient
                shape
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.18, green: 0.46, blue: 0.93),
                                Color(red: 0.28, green: 0.63, blue: 0.96),
                                Color(red: 0.42, green: 0.50, blue: 0.94),
                                Color(red: 0.31, green: 0.44, blue: 0.90)
                            ],
                            startPoint: animateGradient ? .topLeading : .bottomTrailing,
                            endPoint: animateGradient ? .bottomTrailing : .topLeading
                        )
                    )
                    .hueRotation(.degrees(animateGradient ? 8 : -4))
                    .animation(.easeInOut(duration: 4.2).repeatForever(autoreverses: true), value: animateGradient)
                    .onAppear {
                        animateGradient = true
                    }

                // Top highlight for glassy premium look
                shape
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.30), Color.white.opacity(0.01)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .blendMode(.overlay)

                // Soft center bloom for richer depth
                shape
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.22),
                                Color.white.opacity(0.0)
                            ],
                            center: animateGradient ? .topLeading : .topTrailing,
                            startRadius: 0,
                            endRadius: 180
                        )
                    )
                    .blendMode(.screen)

                shape
                    .strokeBorder(Color.white.opacity(0.30), lineWidth: 0.9)

                shape
                    .strokeBorder(Color.black.opacity(0.08), lineWidth: 0.6)
                    .blur(radius: 0.3)
            } else {
                shape
                    .fill(Color.secondary.opacity(0.2))
                shape
                    .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.8)
            }
        }
        .shadow(color: isEnabled ? Color(red: 0.31, green: 0.56, blue: 0.94).opacity(0.38) : Color.clear, radius: 12, x: 0, y: 6)
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
        let localeIdentifier = AppSettings.shared.selectedLanguage == "system"
            ? Locale.autoupdatingCurrent.identifier
            : AppSettings.shared.currentLanguage
        return FormatUtilities.formatMonthLong(Date(), localeIdentifier: localeIdentifier)
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
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
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
            // Match WeatherWidget height for consistent card sizing
            .frame(height: 52, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(20)
        .glassCard(cornerRadius: 24, tintColor: Color.indigo)
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
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundColor(adaptiveTextColor)

                // Always show description to maintain consistent card height
                Text(weatherManager.isLoading ? L("common.loading") : weatherManager.weatherDescription)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(adaptiveSecondaryTextColor)
                    .lineLimit(1)
                    .opacity(weatherManager.isLoading || !weatherManager.weatherDescription.isEmpty ? 1 : 0)
            }
            .frame(height: 52, alignment: .leading)
            .padding(.bottom, 2) // Subtle gap before attribution

            // Attribution
            AppleWeatherAttributionView(
                textColor: adaptiveSecondaryTextColor,
                fontSize: 8,
                attribution: weatherManager.attribution
            )
            .opacity(0.8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(20)
        .glassCard(cornerRadius: 24, tintColor: Color.blue)
    }
}

#Preview {
    SetupView()
}
