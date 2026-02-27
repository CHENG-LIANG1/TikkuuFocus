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
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var settings = AppSettings.shared

    let session: JourneySession
    let discoveredPOIs: [DiscoveredPOI]
    let weatherCondition: String
    let isDaytime: Bool
    let progress: Double
    let isCompleted: Bool
    let actualDuration: TimeInterval
    let onDismiss: () -> Void

    @State private var animateIn = false
    @State private var showShareSheet = false
    @State private var renderedImage: UIImage?
    @State private var showPhotoPermissionAlert = false
    @State private var showConfetti = false
    @State private var showSaveToast = false

    private var isNeumorphism: Bool {
        settings.selectedVisualStyle == .neumorphism
    }

    private var isLightTone: Bool {
        settings.selectedNeumorphismTone == .light
    }

    // MARK: - Layout Constants
    private enum Layout {
        static let horizontalPadding: CGFloat = 20
        static let cardSpacing: CGFloat = 16
        static let innerSpacing: CGFloat = 12
        static let cornerRadius: CGFloat = 24
        static let cardCornerRadius: CGFloat = 16
    }

    var body: some View {
        ZStack {
            // Background
            backgroundLayer

            // Content
            ScrollView(showsIndicators: false) {
                VStack(spacing: Layout.cardSpacing) {
                    // Main Summary Card
                    summaryCard
                        .padding(.top, 20)

                    // Action Buttons
                    actionButtons
                        .padding(.bottom, 24)
                }
                .padding(.horizontal, Layout.horizontalPadding)
            }

            // Effects & Toasts
            if showConfetti {
                ConfettiView()
                    .allowsHitTesting(false)
            }

            if showSaveToast {
                saveToast
            }
        }
        .preferredColorScheme(settings.currentColorScheme)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                animateIn = true
            }
            if isCompleted {
                showConfetti = true
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let image = renderedImage {
                ShareSheet(items: [image])
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

    // MARK: - Background

    @ViewBuilder
    private var backgroundLayer: some View {
        if isNeumorphism {
            // Neumorphism: keep map visible with a softer veil.
            ZStack {
                neumorphismBackground
                backgroundMapLayer
                LinearGradient(
                    colors: [
                        Color.black.opacity(isLightTone ? 0.08 : 0.14),
                        Color.black.opacity(isLightTone ? 0.18 : 0.32)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            }
        } else {
            // Liquid Glass: Map with gradient overlay
            ZStack {
                backgroundMapLayer
                overlayGradient
            }
        }
    }

    private var neumorphismBackground: some View {
        (isLightTone ? NeumorphismColors.lightBackground : NeumorphismColors.darkBackground)
            .ignoresSafeArea()
    }

    private var overlayGradient: some View {
        LinearGradient(
            colors: [
                Color.black.opacity(0.15),
                Color.black.opacity(0.45)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    // MARK: - Summary Card

    @ViewBuilder
    private var summaryCard: some View {
        if isNeumorphism {
            neumorphicSummaryCard
        } else {
            liquidGlassSummaryCard
        }
    }

    // MARK: Neumorphic Summary Card

    private var neumorphicSummaryCard: some View {
        VStack(spacing: Layout.innerSpacing) {
            // Brand Header
            Text("Roam Focus App")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(textColor.opacity(0.8))
                .tracking(0.5)

            // Status Badge
            neumorphicStatusBadge

            // Metrics Grid
            neumorphicMetricsSection

            // POI Highlights
            if !topPOIs.isEmpty {
                neumorphicPOIHighlights
            }

            // Route Preview (Static for Neumorphism)
            neumorphicRoutePreview
        }
        .padding(20)
        .background(
            NeumorphSurface(cornerRadius: Layout.cornerRadius, depth: .raised)
        )
        .scaleEffect(animateIn ? 1 : 0.96)
        .opacity(animateIn ? 1 : 0)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: animateIn)
    }

    private var neumorphicStatusBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "pause.circle.fill")
                .font(.system(size: 13, weight: .semibold))

            Text(String(format: L("journey.summary.completed"), progress * 100))
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .foregroundColor(isCompleted ? successColor : warningColor)
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(
            NeumorphSurface(cornerRadius: 12, depth: .inset)
        )
    }

    private var neumorphicMetricsSection: some View {
        VStack(spacing: 10) {
            // Row 1: Time & Weather
            HStack(spacing: 10) {
                neumorphicMetricCell(
                    icon: "clock.fill",
                    title: L("journey.summary.focusTime"),
                    value: FormatUtilities.formatTime(actualDuration),
                    iconColor: Color.blue
                )

                neumorphicMetricCell(
                    icon: weatherIcon,
                    title: isDaytime ? L("journey.summary.day") : L("journey.summary.night"),
                    value: weatherCondition,
                    iconColor: Color.cyan
                )
            }

            // Row 2: Distance & Transport
            HStack(spacing: 10) {
                neumorphicMetricCell(
                    icon: "location.fill",
                    title: L("journey.summary.distance"),
                    value: FormatUtilities.formatDistance(session.totalDistance),
                    iconColor: Color.orange
                )

                neumorphicMetricCell(
                    icon: session.transportMode.iconName,
                    title: L("history.detail.transport"),
                    value: transportDisplayText,
                    iconColor: Color.green
                )
            }

            // Row 3: POI Count (Full Width)
            neumorphicMetricCell(
                icon: "star.fill",
                title: L("journey.summary.pois"),
                value: "\(discoveredPOIs.count)",
                iconColor: Color.yellow
            )
        }
    }

    private func neumorphicMetricCell(icon: String, title: String, value: String, iconColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(iconColor)

            Spacer(minLength: 0)

            Text(value)
                .font(.system(size: 19, weight: .bold, design: .rounded))
                .foregroundColor(textColor)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(textColor.opacity(0.55))
                .lineLimit(1)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 95, alignment: .leading)
        .background(
            NeumorphSurface(cornerRadius: 16, depth: .inset)
        )
    }

    private var neumorphicPOIHighlights: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 12, weight: .semibold))
                Text(L("journey.summary.pois"))
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(textColor.opacity(0.75))

            // POI List
            VStack(alignment: .leading, spacing: 8) {
                ForEach(topPOIs) { poi in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.yellow)
                            .frame(width: 6, height: 6)
                            .shadow(color: Color.yellow.opacity(0.5), radius: 2, x: 0, y: 1)

                        Text(poi.name)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(textColor.opacity(0.9))
                            .lineLimit(1)

                        Spacer(minLength: 0)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            NeumorphSurface(cornerRadius: Layout.cardCornerRadius, depth: .inset)
        )
    }

    private var neumorphicRoutePreview: some View {
        ZStack(alignment: .bottomLeading) {
            Map(initialPosition: .region(mapRegion)) {
                MapPolyline(coordinates: session.route)
                    .stroke(
                        LinearGradient(
                            colors: [Color.green, Color.blue, Color.purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )

                Annotation("", coordinate: session.startLocation) {
                    routePoint(color: .green)
                }

                Annotation("", coordinate: session.destinationLocation) {
                    routePoint(color: .red)
                }
            }
            .mapStyle(summaryMapStyle)
            .disabled(true)
            .clipShape(RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous))

            HStack(spacing: 6) {
                Image(systemName: "map.fill")
                    .font(.system(size: 11, weight: .semibold))
                Text(L("journey.summary.route"))
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundColor(textColor.opacity(0.88))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(isLightTone ? Color.white.opacity(0.55) : Color.black.opacity(0.35))
            )
            .padding(10)
        }
        .frame(height: 150)
        .background(
            NeumorphSurface(cornerRadius: Layout.cardCornerRadius, depth: .inset)
        )
    }

    // MARK: Liquid Glass Summary Card (Original)

    private var liquidGlassSummaryCard: some View {
        VStack(spacing: Layout.innerSpacing) {
            // Brand Header
            Text("Roam Focus App")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
                .tracking(0.5)

            // Status Badge
            statusBadge

            // Metrics Grid
            metricsSection

            // POI Highlights
            if !topPOIs.isEmpty {
                poiHighlights
            }

            // Route Map
            routeMap
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: Layout.cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.12, green: 0.14, blue: 0.35),
                            Color(red: 0.10, green: 0.12, blue: 0.28),
                            Color(red: 0.14, green: 0.16, blue: 0.36)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Layout.cornerRadius, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.35), radius: 20, x: 0, y: 12)
        )
        .scaleEffect(animateIn ? 1 : 0.96)
        .opacity(animateIn ? 1 : 0)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: animateIn)
    }

    private var statusBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "pause.circle.fill")
                .font(.system(size: 13, weight: .semibold))

            Text(String(format: L("journey.summary.completed"), progress * 100))
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(
                    LinearGradient(
                        colors: isCompleted
                            ? [Color.green.opacity(0.5), Color.mint.opacity(0.4)]
                            : [Color.orange.opacity(0.5), Color.red.opacity(0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    Capsule()
                        .stroke(
                            isCompleted ? Color.green.opacity(0.6) : Color.orange.opacity(0.6),
                            lineWidth: 1
                        )
                )
        )
    }

    private var metricsSection: some View {
        VStack(spacing: 10) {
            // Row 1: Time & Weather
            HStack(spacing: 10) {
                MetricCell(
                    icon: "clock.fill",
                    title: L("journey.summary.focusTime"),
                    value: FormatUtilities.formatTime(actualDuration),
                    gradient: LinearGradient(colors: [Color.blue, Color.cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
                )

                MetricCell(
                    icon: weatherIcon,
                    title: isDaytime ? L("journey.summary.day") : L("journey.summary.night"),
                    value: weatherCondition,
                    gradient: LinearGradient(colors: [Color.cyan, Color.indigo], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
            }

            // Row 2: Distance & Transport
            HStack(spacing: 10) {
                MetricCell(
                    icon: "location.fill",
                    title: L("journey.summary.distance"),
                    value: FormatUtilities.formatDistance(session.totalDistance),
                    gradient: LinearGradient(colors: [Color.orange, Color.red], startPoint: .topLeading, endPoint: .bottomTrailing)
                )

                MetricCell(
                    icon: session.transportMode.iconName,
                    title: L("history.detail.transport"),
                    value: transportDisplayText,
                    gradient: LinearGradient(colors: [Color.green, Color.teal], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
            }

            // Row 3: POI Count (Full Width)
            MetricCell(
                icon: "star.fill",
                title: L("journey.summary.pois"),
                value: "\(discoveredPOIs.count)",
                gradient: LinearGradient(colors: [Color.yellow, Color.orange], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
        }
    }

    private var poiHighlights: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 12, weight: .semibold))
                Text(L("journey.summary.pois"))
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(.white.opacity(0.9))

            // POI List
            VStack(alignment: .leading, spacing: 8) {
                ForEach(topPOIs) { poi in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.yellow)
                            .frame(width: 6, height: 6)

                        Text(poi.name)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.95))
                            .lineLimit(1)

                        Spacer(minLength: 0)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
    }

    private var routeMap: some View {
        Map(initialPosition: .region(mapRegion)) {
            MapPolyline(coordinates: session.route)
                .stroke(
                    LinearGradient(
                        colors: [Color.green, Color.blue, Color.purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )

            Annotation("", coordinate: session.startLocation) {
                routePoint(color: .green)
            }

            Annotation("", coordinate: session.destinationLocation) {
                routePoint(color: .red)
            }
        }
        .mapStyle(summaryMapStyle)
        .disabled(true)
        .clipShape(RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous))
        .frame(height: 160)
        .background(
            RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
    }

    private func routePoint(color: Color) -> some View {
        Circle()
            .fill(color)
            .frame(width: 10, height: 10)
            .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
    }

    // MARK: - Action Buttons

    @ViewBuilder
    private var actionButtons: some View {
        if isNeumorphism {
            neumorphicActionButtons
        } else {
            liquidGlassActionButtons
        }
    }

    private var neumorphicActionButtons: some View {
        HStack(spacing: 12) {
            NeumorphicButton(cornerRadius: 18) {
                saveAsImage()
            } content: {
                VStack(spacing: 6) {
                    Image(systemName: "square.and.arrow.down")
                        .font(.system(size: 18, weight: .semibold))
                    Text(L("journey.summary.save"))
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(textColor)
            }
            .frame(height: 76)

            NeumorphicButton(cornerRadius: 18) {
                shareImage()
            } content: {
                VStack(spacing: 6) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 18, weight: .semibold))
                    Text(L("journey.summary.share"))
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(primaryColor)
            }
            .frame(height: 76)

            NeumorphicButton(cornerRadius: 18) {
                onDismiss()
                dismiss()
            } content: {
                VStack(spacing: 6) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 18, weight: .semibold))
                    Text(L("journey.summary.done"))
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(successColor)
            }
            .frame(height: 76)
        }
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 15)
        .animation(.spring(response: 0.45, dampingFraction: 0.82).delay(0.1), value: animateIn)
    }

    private var liquidGlassActionButtons: some View {
        HStack(spacing: 12) {
            ActionButton(
                title: L("journey.summary.save"),
                icon: "square.and.arrow.down",
                style: .secondary
            ) {
                saveAsImage()
            }

            ActionButton(
                title: L("journey.summary.share"),
                icon: "square.and.arrow.up",
                style: .primary
            ) {
                shareImage()
            }

            ActionButton(
                title: L("journey.summary.done"),
                icon: "checkmark",
                style: .success
            ) {
                onDismiss()
                dismiss()
            }
        }
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 15)
        .animation(.spring(response: 0.45, dampingFraction: 0.82).delay(0.1), value: animateIn)
    }

    // MARK: - Save Toast

    @ViewBuilder
    private var saveToast: some View {
        if isNeumorphism {
            neumorphicSaveToast
        } else {
            liquidGlassSaveToast
        }
    }

    private var neumorphicSaveToast: some View {
        VStack {
            Spacer()
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(successColor)
                Text(L("journey.summary.saved"))
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(textColor)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(
                NeumorphSurface(cornerRadius: 20, depth: .raised)
            )
            .padding(.bottom, 100)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
        .allowsHitTesting(false)
    }

    private var liquidGlassSaveToast: some View {
        VStack {
            Spacer()
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16, weight: .semibold))
                Text(L("journey.summary.saved"))
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.75))
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .padding(.bottom, 100)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
        .allowsHitTesting(false)
    }

    // MARK: - Background Components

    private var backgroundMapLayer: some View {
        Map(initialPosition: .region(mapRegion)) {
            MapPolyline(coordinates: session.route)
                .stroke(
                    Color.green.opacity(0.85),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )

            Annotation("", coordinate: session.startLocation) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 12, height: 12)
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
            }

            Annotation("", coordinate: session.destinationLocation) {
                Circle()
                    .fill(Color.red)
                    .frame(width: 12, height: 12)
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
            }
        }
        .mapStyle(summaryMapStyle)
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }

    // MARK: - Color Helpers

    private var textColor: Color {
        isLightTone ? Color(red: 0.25, green: 0.30, blue: 0.38) : .white
    }

    private var primaryColor: Color {
        isLightTone ? Color(red: 0.38, green: 0.52, blue: 0.75) : NeumorphismColors.darkPrimary
    }

    private var successColor: Color {
        isLightTone ? Color(red: 0.35, green: 0.65, blue: 0.45) : Color(red: 0.4, green: 0.85, blue: 0.5)
    }

    private var warningColor: Color {
        isLightTone ? Color(red: 0.85, green: 0.55, blue: 0.25) : Color.orange
    }

    // MARK: - Helpers

    private var topPOIs: [DiscoveredPOI] {
        Array(discoveredPOIs.prefix(3))
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

    private var summaryMapStyle: MapStyle {
        if isNeumorphism {
            // Ensure readability in neumorphism cards/background.
            return .standard(elevation: .realistic)
        }
        return settings.selectedMapMode.style
    }

    private var weatherIcon: String {
        let value = weatherCondition.lowercased()
        if value.contains("clear") { return isDaytime ? "sun.max.fill" : "moon.stars.fill" }
        if value.contains("cloud") { return "cloud.fill" }
        if value.contains("rain") { return "cloud.rain.fill" }
        if value.contains("snow") { return "cloud.snow.fill" }
        return isDaytime ? "sun.max.fill" : "moon.fill"
    }

    private var transportDisplayText: String {
        return session.transportMode.localizedName
    }

    // MARK: - Actions

    private func saveAsImage() {
        Task { @MainActor in
            guard let image = await renderAsImage() else { return }

            let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
            switch status {
            case .authorized, .limited:
                saveImageToLibrary(image)
            case .notDetermined:
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
                showPhotoPermissionAlert = true
                HapticManager.error()
            @unknown default:
                break
            }
        }
    }

    private func saveImageToLibrary(_ image: UIImage) {
        // Save original high-quality image without compression
        // The image is already rendered at 2x scale, no need for additional compression
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }) { success, _ in
            DispatchQueue.main.async {
                if success {
                    HapticManager.success()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                        showSaveToast = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                        withAnimation(.easeOut(duration: 0.22)) {
                            showSaveToast = false
                        }
                    }
                } else {
                    HapticManager.error()
                }
            }
        }
    }

    private func shareImage() {
        Task { @MainActor in
            guard let image = await renderAsImage() else { return }
            // Use high quality for sharing, only compress if image is extremely large
            let imageSizeKB = (image.pngData()?.count ?? 0) / 1024
            if imageSizeKB > 2048 {  // Only compress if > 2MB
                renderedImage = PerformanceOptimizer.shared.compressImage(image, maxSizeKB: 1500) ?? image
            } else {
                renderedImage = image
            }
            showShareSheet = true
        }
    }

    @MainActor
    private func renderAsImage() async -> UIImage? {
        let snapshotSize = CGSize(width: 700, height: 380)
        let mapSnapshot = await generateRouteSnapshot(size: snapshotSize)
        let renderer = ImageRenderer(content: exportCard(snapshotImage: mapSnapshot))
        renderer.scale = 2.0  // High resolution for crisp images
        return renderer.uiImage
    }

    @ViewBuilder
    private func exportCard(snapshotImage: UIImage?) -> some View {
        if isNeumorphism {
            neumorphicExportCard(snapshotImage: snapshotImage)
        } else {
            liquidGlassExportCard(snapshotImage: snapshotImage)
        }
    }

    private func neumorphicExportCard(snapshotImage: UIImage?) -> some View {
        VStack(spacing: 20) {
            // App Name Header
            Text("Roam Focus")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(textColor)
                .padding(.top, 32)
            
            neumorphicStatusBadge

            neumorphicMetricsSection
                .padding(.horizontal, 20)

            neumorphicExportRouteCard(snapshotImage: snapshotImage)
                .frame(height: 200)
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
        }
        .frame(width: 390, height: 720)
        .background(
            NeumorphSurface(cornerRadius: Layout.cornerRadius, depth: .raised)
        )
    }

    private func neumorphicExportRouteCard(snapshotImage: UIImage?) -> some View {
        Group {
            if let snapshotImage {
                Image(uiImage: snapshotImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            } else {
                StaticRoutePreview(
                    route: session.route,
                    start: session.startLocation,
                    end: session.destinationLocation
                )
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous))
        .background(
            NeumorphSurface(cornerRadius: Layout.cardCornerRadius, depth: .inset)
        )
    }

    private func liquidGlassExportCard(snapshotImage: UIImage?) -> some View {
        VStack(spacing: 20) {
            // App Name Header
            Text("Roam Focus")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.top, 32)
            
            statusBadge

            metricsSection
                .padding(.horizontal, 20)

            exportRouteCard(snapshotImage: snapshotImage)
                .frame(height: 200)
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
        }
        .frame(width: 390, height: 720)
        .background(
            RoundedRectangle(cornerRadius: Layout.cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.12, green: 0.14, blue: 0.35),
                            Color(red: 0.10, green: 0.12, blue: 0.28),
                            Color(red: 0.14, green: 0.16, blue: 0.36)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadius, style: .continuous))
    }

    private func exportRouteCard(snapshotImage: UIImage?) -> some View {
        Group {
            if let snapshotImage {
                Image(uiImage: snapshotImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            } else {
                StaticRoutePreview(
                    route: session.route,
                    start: session.startLocation,
                    end: session.destinationLocation
                )
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous))
        .background(
            RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
                )
        )
    }

    private func generateRouteSnapshot(size: CGSize) async -> UIImage? {
        let options = MKMapSnapshotter.Options()
        options.region = mapRegion
        options.size = size
        options.scale = UIScreen.main.scale
        options.mapType = settings.selectedMapMode.snapshotMapType
        options.showsBuildings = true
        options.pointOfInterestFilter = .excludingAll

        let snapshotter = MKMapSnapshotter(options: options)

        let snapshot: MKMapSnapshotter.Snapshot
        do {
            snapshot = try await withCheckedThrowingContinuation { continuation in
                snapshotter.start { snapshot, error in
                    if let snapshot {
                        continuation.resume(returning: snapshot)
                    } else if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(throwing: NSError(domain: "SnapshotError", code: -1, userInfo: nil))
                    }
                }
            }
        } catch {
            return nil
        }

        let routeCoordinates = session.route.isEmpty ? [session.startLocation, session.destinationLocation] : session.route
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            snapshot.image.draw(at: .zero)

            guard routeCoordinates.count >= 2 else { return }
            let cgContext = context.cgContext

            let points = routeCoordinates.map { snapshot.point(for: $0) }
            cgContext.setLineCap(.round)
            cgContext.setLineJoin(.round)
            cgContext.setLineWidth(4.5)
            cgContext.setStrokeColor(UIColor.systemBlue.withAlphaComponent(0.92).cgColor)

            cgContext.beginPath()
            cgContext.move(to: points[0])
            for point in points.dropFirst() {
                cgContext.addLine(to: point)
            }
            cgContext.strokePath()

            let startPoint = snapshot.point(for: session.startLocation)
            let endPoint = snapshot.point(for: session.destinationLocation)
            let startRect = CGRect(x: startPoint.x - 6, y: startPoint.y - 6, width: 12, height: 12)
            let endRect = CGRect(x: endPoint.x - 6, y: endPoint.y - 6, width: 12, height: 12)

            cgContext.setFillColor(UIColor.systemGreen.cgColor)
            cgContext.fillEllipse(in: startRect)
            cgContext.setStrokeColor(UIColor.white.cgColor)
            cgContext.setLineWidth(2)
            cgContext.strokeEllipse(in: startRect)

            cgContext.setFillColor(UIColor.systemRed.cgColor)
            cgContext.fillEllipse(in: endRect)
            cgContext.setStrokeColor(UIColor.white.cgColor)
            cgContext.setLineWidth(2)
            cgContext.strokeEllipse(in: endRect)
        }

        return image
    }
}

// MARK: - Metric Cell (Liquid Glass)

private struct MetricCell: View {
    let icon: String
    let title: String
    let value: String
    let gradient: LinearGradient

    @ObservedObject private var settings = AppSettings.shared

    private var isNeumorphism: Bool {
        settings.selectedVisualStyle == .neumorphism
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(gradient)

            Spacer(minLength: 0)

            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.72))
                .lineLimit(1)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 100, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.10))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
                )
        )
    }
}

// MARK: - Action Button (Liquid Glass)

private struct ActionButton: View {
    let title: String
    let icon: String
    let style: ButtonStyle
    let action: () -> Void

    @ObservedObject private var settings = AppSettings.shared

    enum ButtonStyle {
        case primary, secondary, success

        var gradient: LinearGradient {
            switch self {
            case .primary:
                return LinearGradient(
                    colors: [Color(red: 0.38, green: 0.56, blue: 0.98), Color(red: 0.52, green: 0.46, blue: 0.94)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .secondary:
                return LinearGradient(
                    colors: [Color.white.opacity(0.15), Color.white.opacity(0.08)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .success:
                return LinearGradient(
                    colors: [Color.green, Color.teal],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 72)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(style.gradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Static Route Preview

private struct StaticRoutePreview: View {
    let route: [CLLocationCoordinate2D]
    let start: CLLocationCoordinate2D
    let end: CLLocationCoordinate2D

    @ObservedObject private var settings = AppSettings.shared

    private var isLightTone: Bool {
        settings.selectedNeumorphismTone == .light
    }

    var body: some View {
        GeometryReader { proxy in
            let points = normalizedPoints(in: proxy.size)

            ZStack {
                // Background
                backgroundColor

                // Route Line
                if points.count >= 2 {
                    Path { path in
                        path.move(to: points[0])
                        for point in points.dropFirst() {
                            path.addLine(to: point)
                        }
                    }
                    .stroke(
                        LinearGradient(
                            colors: [Color.green, Color.blue, Color.purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round)
                    )
                }

                // Start Point
                if let first = points.first {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 10, height: 10)
                        .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                        .position(first)
                }

                // End Point
                if let last = points.last {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 10, height: 10)
                        .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                        .position(last)
                }
            }
        }
    }

    private var backgroundColor: some View {
        Group {
            if settings.selectedVisualStyle == .neumorphism {
                if isLightTone {
                    NeumorphismColors.lightPressed
                } else {
                    NeumorphismColors.darkPressed
                }
            } else {
                LinearGradient(
                    colors: [
                        Color(red: 0.18, green: 0.24, blue: 0.34),
                        Color(red: 0.15, green: 0.20, blue: 0.30)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }

    private func normalizedPoints(in size: CGSize) -> [CGPoint] {
        let source = route.isEmpty ? [start, end] : route
        guard !source.isEmpty else { return [] }

        let lats = source.map { $0.latitude }
        let lons = source.map { $0.longitude }
        guard let minLat = lats.min(),
              let maxLat = lats.max(),
              let minLon = lons.min(),
              let maxLon = lons.max() else {
            return []
        }

        let pad: CGFloat = 12
        let width = max(size.width - (pad * 2), 1)
        let height = max(size.height - (pad * 2), 1)
        let latSpan = max(maxLat - minLat, 0.0001)
        let lonSpan = max(maxLon - minLon, 0.0001)

        return source.map { coord in
            let x = ((coord.longitude - minLon) / lonSpan) * width + pad
            let y = (1 - ((coord.latitude - minLat) / latSpan)) * height + pad
            return CGPoint(x: x, y: y)
        }
    }
}

// MARK: - Confetti

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

        confettiPieces = (0..<50).map { _ in
            ConfettiPiece(
                position: CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: CGFloat.random(in: -50...size.height/2)
                ),
                color: colors.randomElement()!,
                size: CGFloat.random(in: 6...12),
                rotation: Double.random(in: 0...360),
                shape: shapes.randomElement()!,
                opacity: Double.random(in: 0.6...1.0)
            )
        }

        withAnimation(.easeOut(duration: 3)) {
            for index in confettiPieces.indices {
                confettiPieces[index].position.y += CGFloat.random(in: 300...600)
                confettiPieces[index].rotation += Double.random(in: 180...540)
                confettiPieces[index].opacity = 0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            confettiPieces.removeAll()
        }
    }
}

private struct ConfettiPiece: Identifiable {
    let id = UUID()
    var position: CGPoint
    let color: Color
    let size: CGFloat
    var rotation: Double
    let shape: ConfettiShapeType
    var opacity: Double
}

private enum ConfettiShapeType {
    case circle, square, triangle
}

private struct ConfettiShape: Shape {
    let shape: ConfettiShapeType

    func path(in rect: CGRect) -> Path {
        switch shape {
        case .circle:
            return Circle().path(in: rect)
        case .square:
            return Rectangle().path(in: rect)
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
