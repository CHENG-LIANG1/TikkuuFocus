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

    var body: some View {
        GeometryReader { geometry in
            let isCompact = geometry.size.height < 780
            let topInset = max(geometry.safeAreaInsets.top + 4, 10)
            let bottomInset = max(geometry.safeAreaInsets.bottom + 4, 8)
            let actionAreaHeight: CGFloat = 74 + 8 + bottomInset
            let maxCardHeight = max(440, geometry.size.height - topInset - actionAreaHeight + 12)

            ZStack {
                backgroundMapLayer

                LinearGradient(
                    colors: [
                        Color.black.opacity(0.18),
                        Color.black.opacity(0.48)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    summaryCard(isCompact: isCompact, cardHeight: maxCardHeight)
                        .padding(.horizontal, 16)
                        .padding(.top, topInset)

                    actionCards
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, bottomInset)
                }

                if showConfetti {
                    ConfettiView()
                        .allowsHitTesting(false)
                }

                if showSaveToast {
                    VStack {
                        Spacer()
                        saveToastView
                            .padding(.bottom, max(geometry.safeAreaInsets.bottom + 92, 120))
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    .allowsHitTesting(false)
                }
            }
        }
        .preferredColorScheme(settings.currentColorScheme)
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
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

    private func summaryCard(isCompact: Bool, cardHeight: CGFloat) -> some View {
        let verticalInset = isCompact ? CGFloat(12) : CGFloat(14)
        return VStack(spacing: isCompact ? 8 : 12) {
            Text("Roam Focus App")
                .font(.system(size: isCompact ? 11 : 12, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.9))

            statusHeader(isCompact: isCompact)

            metricsGrid(isCompact: isCompact)

            if !topPOIs.isEmpty {
                poiHighlightsCard(isCompact: isCompact)
                    .padding(.horizontal, 14)
            }

            routeCard
                .frame(maxHeight: .infinity)
                .frame(minHeight: isCompact ? 138 : 160)
                .padding(.horizontal, 14)
        }
        .padding(.vertical, verticalInset)
        .frame(height: cardHeight)
        .background {
            if isNeumorphism {
                SummaryNeumorphCard(cornerRadius: 28, depth: .inset)
            } else {
                surfaceBackground
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            if !isNeumorphism {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
            }
        }
        .shadow(color: Color.black.opacity(0.35), radius: 18, x: 0, y: 10)
        .scaleEffect(animateIn ? 1 : 0.98)
        .opacity(animateIn ? 1 : 0)
    }

    private func statusHeader(isCompact: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "pause.circle.fill")
                .font(.system(size: isCompact ? 13 : 14, weight: .semibold))

            Text(String(format: L("journey.summary.completed"), progress * 100))
                .font(.system(size: isCompact ? 12 : 13, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(
                    LinearGradient(
                        colors: isCompleted
                            ? [Color.green.opacity(0.45), Color.mint.opacity(0.35)]
                            : [Color.orange.opacity(0.45), Color.red.opacity(0.35)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    Capsule()
                        .stroke(
                            isCompleted ? Color.green.opacity(0.55) : Color.orange.opacity(0.55),
                            lineWidth: 1
                        )
                )
        )
    }

    private func metricsGrid(isCompact: Bool) -> some View {
        let equalHeight = isCompact ? CGFloat(96) : CGFloat(112)
        return VStack(spacing: 10) {
            HStack(spacing: 10) {
                metricCard(
                    icon: "clock.fill",
                    title: L("journey.summary.focusTime"),
                    value: FormatUtilities.formatTime(actualDuration),
                    accent: LinearGradient(colors: [Color.blue, Color.cyan], startPoint: .topLeading, endPoint: .bottomTrailing),
                    minHeight: equalHeight
                )

                metricCard(
                    icon: weatherIcon,
                    title: isDaytime ? L("journey.summary.day") : L("journey.summary.night"),
                    value: weatherCondition,
                    accent: LinearGradient(colors: [Color.cyan, Color.indigo], startPoint: .topLeading, endPoint: .bottomTrailing),
                    minHeight: equalHeight
                )
            }

            HStack(spacing: 10) {
                metricCard(
                    icon: "location.fill",
                    title: L("journey.summary.distance"),
                    value: FormatUtilities.formatDistance(session.totalDistance),
                    accent: LinearGradient(colors: [Color.orange, Color.red], startPoint: .topLeading, endPoint: .bottomTrailing),
                    minHeight: equalHeight
                )

                metricCard(
                    icon: session.transportMode.iconName,
                    title: L("history.detail.transport"),
                    value: transportDisplayText,
                    accent: LinearGradient(colors: [Color.green, Color.teal], startPoint: .topLeading, endPoint: .bottomTrailing),
                    minHeight: equalHeight
                )
            }

            metricCard(
                icon: "star.fill",
                title: L("journey.summary.pois"),
                value: "\(discoveredPOIs.count)",
                accent: LinearGradient(colors: [Color.yellow, Color.orange], startPoint: .topLeading, endPoint: .bottomTrailing),
                minHeight: equalHeight
            )
        }
        .padding(.horizontal, 14)
    }

    private var topPOIs: [DiscoveredPOI] {
        Array(discoveredPOIs.prefix(3))
    }

    private func poiHighlightsCard(isCompact: Bool) -> some View {
        let equalHeight = isCompact ? CGFloat(96) : CGFloat(112)
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 11, weight: .semibold))
                Text(L("journey.summary.pois"))
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundColor(.white.opacity(0.88))

            ForEach(topPOIs) { poi in
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.yellow)
                        .frame(width: 6, height: 6)
                    Text(poi.name)
                        .font(.system(size: isCompact ? 11 : 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.92))
                        .lineLimit(1)
                    Spacer(minLength: 0)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, minHeight: equalHeight, maxHeight: equalHeight, alignment: .topLeading)
        .background {
            if isNeumorphism {
                SummaryNeumorphCard(cornerRadius: 14, depth: .inset)
            } else {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.16), lineWidth: 1)
                    )
            }
        }
    }

    private func metricCard(icon: String, title: String, value: String, accent: LinearGradient, minHeight: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(accent)

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
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .leading)
        .background {
            if isNeumorphism {
                SummaryNeumorphCard(cornerRadius: 16, depth: .inset)
            } else {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
                    )
            }
        }
    }

    private var routeCard: some View {
        ZStack(alignment: .bottomLeading) {
            Map(initialPosition: .region(mapRegion)) {
                MapPolyline(coordinates: session.route)
                    .stroke(
                        LinearGradient(
                            colors: [Color.green, Color.blue, Color.purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 3.5, lineCap: .round)
                    )

                Annotation("", coordinate: session.startLocation) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 10, height: 10)
                        .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                }

                Annotation("", coordinate: session.destinationLocation) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 10, height: 10)
                        .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                }
            }
            .mapStyle(settings.selectedMapMode.style)
            .disabled(true)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            HStack(spacing: 6) {
                Image(systemName: "map.fill")
                    .font(.system(size: 11, weight: .semibold))
                Text(L("journey.summary.route"))
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.35))
                    .overlay(Capsule().stroke(Color.white.opacity(0.25), lineWidth: 1))
            )
            .padding(10)
        }
        .background {
            if isNeumorphism {
                SummaryNeumorphCard(cornerRadius: 16, depth: .inset)
            } else {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
                    )
            }
        }
    }

    private var actionCards: some View {
        HStack(spacing: 12) {
            actionCard(
                title: L("journey.summary.save"),
                icon: "square.and.arrow.down",
                fill: AnyShapeStyle(.ultraThinMaterial)
            ) {
                saveAsImage()
            }

            actionCard(
                title: L("journey.summary.share"),
                icon: "square.and.arrow.up",
                fill: AnyShapeStyle(
                    LinearGradient(
                        colors: [Color(red: 0.38, green: 0.56, blue: 0.98), Color(red: 0.52, green: 0.46, blue: 0.94)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            ) {
                shareImage()
            }

            actionCard(
                title: L("journey.summary.done"),
                icon: "checkmark",
                fill: AnyShapeStyle(
                    LinearGradient(
                        colors: [Color.green, Color.teal],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            ) {
                onDismiss()
                dismiss()
            }
        }
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 10)
        .animation(.spring(response: 0.4, dampingFraction: 0.82).delay(0.08), value: animateIn)
    }

    private func actionCard(title: String, icon: String, fill: AnyShapeStyle, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 74)
            .background {
                if isNeumorphism {
                    SummaryNeumorphActionCard(cornerRadius: 18, fill: fill)
                } else {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(fill)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
                        )
                }
            }
        }
        .buttonStyle(.plain)
    }

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
        .mapStyle(settings.selectedMapMode.style)
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }

    private var surfaceBackground: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.12, green: 0.14, blue: 0.35),
                        Color(red: 0.11, green: 0.11, blue: 0.30),
                        Color(red: 0.15, green: 0.18, blue: 0.39)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
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

    private var weatherIcon: String {
        let value = weatherCondition.lowercased()
        if value.contains("clear") { return isDaytime ? "sun.max.fill" : "moon.stars.fill" }
        if value.contains("cloud") { return "cloud.fill" }
        if value.contains("rain") { return "cloud.rain.fill" }
        if value.contains("snow") { return "cloud.snow.fill" }
        return isDaytime ? "sun.max.fill" : "moon.fill"
    }

    private var transportDisplayText: String {
        if session.transportMode == .subway, let stations = session.subwayStations, !stations.isEmpty {
            return extractSubwayLine(from: stations)
        }
        return session.transportMode.localizedName
    }

    // MARK: - Subway Helpers

    private func extractSubwayLine(from stations: [SubwayStationInfo]) -> String {
        guard let firstStation = stations.first else { return L("journey.summary.subway") }

        let name = firstStation.name

        if let lineMatch = name.range(of: "Line\\s+\\d+|\\d+\\s+Line", options: .regularExpression) {
            let line = String(name[lineMatch])
            return line.replacingOccurrences(of: "Line", with: "").trimmingCharacters(in: .whitespaces) + " Line"
        }

        if let lineMatch = name.range(of: "\\d+号线", options: .regularExpression) {
            return String(name[lineMatch])
        }

        return L("journey.summary.subway")
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
        let optimizedImage = PerformanceOptimizer.shared.compressImage(image, maxSizeKB: 450) ?? image

        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: optimizedImage)
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
            renderedImage = PerformanceOptimizer.shared.compressImage(image, maxSizeKB: 600) ?? image
            showShareSheet = true
        }
    }

    @MainActor
    private func renderAsImage() async -> UIImage? {
        let snapshotSize = CGSize(width: 332, height: 180)
        let mapSnapshot = await generateRouteSnapshot(size: snapshotSize)
        let renderer = ImageRenderer(content: exportCard(snapshotImage: mapSnapshot))
        renderer.scale = PerformanceOptimizer.shared.isEnergySavingMode ? 1.2 : 1.35
        return renderer.uiImage
    }

    private func exportCard(snapshotImage: UIImage?) -> some View {
        VStack(spacing: 12) {
            statusHeader(isCompact: false)
                .padding(.top, 24)

            metricsGrid(isCompact: false)

            exportRouteCard(snapshotImage: snapshotImage)
                .frame(height: 180)
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
        }
        .frame(width: 360, height: 700)
        .background(surfaceBackground)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private func exportRouteCard(snapshotImage: UIImage?) -> some View {
        ZStack(alignment: .bottomLeading) {
            Group {
                if let snapshotImage {
                    Image(uiImage: snapshotImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    StaticRoutePreview(
                        route: session.route,
                        start: session.startLocation,
                        end: session.destinationLocation
                    )
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            HStack(spacing: 6) {
                Image(systemName: "map.fill")
                    .font(.system(size: 11, weight: .semibold))
                Text(L("journey.summary.route"))
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.35))
                    .overlay(Capsule().stroke(Color.white.opacity(0.25), lineWidth: 1))
            )
            .padding(10)
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
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

    private var saveToastView: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14, weight: .semibold))
            Text(L("journey.summary.saved"))
                .font(.system(size: 14, weight: .semibold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.72))
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
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

// MARK: - Journey Summary Neumorph Cards (Local Only)

private struct SummaryNeumorphCard: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var settings = AppSettings.shared
    let cornerRadius: CGFloat
    let depth: NeumorphDepth

    private var isLightTone: Bool {
        settings.selectedNeumorphismTone == .light
    }

    private var surface: Color {
        if isLightTone {
            return depth == .inset
            ? Color(red: 0.941, green: 0.957, blue: 0.973)
            : Color(red: 0.890, green: 0.941, blue: 1.0)
        }
        return depth == .inset
        ? Color(red: 0.145, green: 0.145, blue: 0.220)
        : Color(red: 0.196, green: 0.196, blue: 0.302)
    }

    private var edgeLight: Color {
        if isLightTone {
            return Color(red: 0.760, green: 0.830, blue: 0.920).opacity(0.62)
        }
        return Color(red: 0.335, green: 0.395, blue: 0.575).opacity(0.68)
    }

    private var edgeDark: Color {
        if isLightTone {
            return Color(red: 0.490, green: 0.560, blue: 0.650).opacity(0.72)
        }
        return Color(red: 0.090, green: 0.105, blue: 0.170).opacity(0.88)
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        ZStack {
            shape.fill(surface)

            if depth == .inset {
                shape
                    .strokeBorder(
                        LinearGradient(
                            colors: [edgeLight, Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2.1
                    )

                shape
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.clear, edgeDark],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2.1
                    )

                shape
                    .fill(
                        LinearGradient(
                            colors: [Color.clear, edgeDark.opacity(0.14)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(shape)
            } else {
                shape
                    .fill(
                        LinearGradient(
                            colors: [edgeLight.opacity(0.18), Color.clear, edgeDark.opacity(0.10)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        }
        .shadow(
            color: depth == .raised ? edgeDark.opacity(colorScheme == .dark ? 0.78 : 0.42) : .clear,
            radius: depth == .raised ? 10 : 0,
            x: depth == .raised ? 6 : 0,
            y: depth == .raised ? 6 : 0
        )
        .shadow(
            color: depth == .raised ? edgeLight.opacity(colorScheme == .dark ? 0.28 : 0.24) : .clear,
            radius: depth == .raised ? 3 : 0,
            x: depth == .raised ? -1 : 0,
            y: depth == .raised ? -1 : 0
        )
    }
}

private struct SummaryNeumorphActionCard: View {
    let cornerRadius: CGFloat
    let fill: AnyShapeStyle

    var body: some View {
        ZStack {
            SummaryNeumorphCard(cornerRadius: cornerRadius, depth: .raised)
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(fill)
                .opacity(0.78)
        }
    }
}

// MARK: - Static Route Preview (for image rendering)

private struct StaticRoutePreview: View {
    let route: [CLLocationCoordinate2D]
    let start: CLLocationCoordinate2D
    let end: CLLocationCoordinate2D

    var body: some View {
        GeometryReader { proxy in
            let points = normalizedPoints(in: proxy.size)

            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.18, green: 0.24, blue: 0.34),
                        Color(red: 0.15, green: 0.20, blue: 0.30)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

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

                if let first = points.first {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 10, height: 10)
                        .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                        .position(first)
                }

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
            // invert y so north is up
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

        for i in 0..<45 {
            let piece = ConfettiPiece(
                id: UUID(),
                shape: shapes.randomElement()!,
                color: colors.randomElement()!,
                size: CGFloat.random(in: 8...14),
                position: CGPoint(x: CGFloat.random(in: 0...size.width), y: -40),
                rotation: Double.random(in: 0...360),
                opacity: 1.0
            )

            confettiPieces.append(piece)

            withAnimation(.easeOut(duration: Double.random(in: 2...4)).delay(Double(i) * 0.02)) {
                if let index = confettiPieces.firstIndex(where: { $0.id == piece.id }) {
                    confettiPieces[index].position.y = size.height + 40
                    confettiPieces[index].rotation += Double.random(in: 300...700)
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
