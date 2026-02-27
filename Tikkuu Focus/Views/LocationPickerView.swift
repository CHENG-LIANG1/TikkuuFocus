//
//  LocationPickerView.swift
//  Tikkuu Focus
//
//  Created by Tikkuu on 2026/2/8.
//

import SwiftUI
import MapKit
import SwiftData

struct LocationPickerView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @Binding var selectedLocation: LocationSource
    @ObservedObject var locationManager: LocationManager
    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var locationStore = LocationStore.shared
    
    @State private var showMapPicker = false
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedGradientBackground()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Current Location Option
                        currentLocationCard
                        
                        // Custom Location from Map
                        customLocationCard
                        
                        // Favorite Locations
                        if !locationStore.favorites.isEmpty {
                            favoritesSection
                        }
                        
                        // Location History
                        if !locationStore.history.isEmpty {
                            historySection
                        }
                        
                        // Preset Locations
                        presetLocationsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle(L("location.selectStart"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L("common.done")) {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .preferredColorScheme(settings.currentColorScheme)
        .onAppear {
            locationStore.setModelContext(modelContext)
        }
        .sheet(isPresented: $showMapPicker) {
            MapPickerView(selectedLocation: $selectedLocation)
        }
    }
    
    // MARK: - Current Location Card
    
    private var currentLocationCard: some View {
        Button {
            HapticManager.selection()
            selectedLocation = .currentLocation
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(LiquidGlassStyle.primaryGradient)
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "location.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    let locationName = locationManager.currentLocationName
                    if !locationName.isEmpty {
                        Text(locationName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Text(L("location.useCurrentLocation"))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.green)
                    } else if locationManager.currentLocation != nil {
                        Text(L("location.useCurrentLocation"))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text(L("location.status.gpsReady"))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.green)
                    } else {
                        Text(L("location.useCurrentLocation"))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text(L("location.status.waiting"))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.orange)
                    }
                }
                
                Spacer()
                
                if case .currentLocation = selectedLocation {
                    Image(systemName: "location.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(
                            settings.selectedVisualStyle == .neumorphism
                                ? (settings.isNeumorphismLight ? Color(red: 0.35, green: 0.52, blue: 0.85) : Color(red: 0.55, green: 0.65, blue: 1.0))
                                : Color.blue
                        )
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(
                                    settings.selectedVisualStyle == .neumorphism
                                        ? (settings.isNeumorphismLight ? Color.blue.opacity(0.15) : Color.blue.opacity(0.25))
                                        : Color.blue.opacity(0.2)
                                )
                        )
                }
            }
            .padding(16)
            .glassCard(cornerRadius: 16)
        }
    }
    
    // MARK: - Favorites Section
    
    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(L("location.favorites"))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(locationStore.favorites.count)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color.secondary.opacity(0.15))
                    )
            }
            .padding(.horizontal, 4)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                ForEach(locationStore.favorites.prefix(4)) { location in
                    FavoriteLocationCard(
                        location: location,
                        isSelected: isFavoriteSelected(location),
                        action: {
                            selectedLocation = .custom(location.coordinate, location.name)
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - History Section
    
    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(L("location.history"))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button {
                    HapticManager.light()
                    locationStore.clearHistory()
                } label: {
                    Text(L("location.history.clear"))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.red.opacity(0.8))
                }
            }
            .padding(.horizontal, 4)
            
            LazyVStack(spacing: 8) {
                ForEach(locationStore.history.prefix(5)) { location in
                    HistoryLocationRow(
                        location: location,
                        isSelected: isHistorySelected(location),
                        action: {
                            selectedLocation = .custom(location.coordinate, location.name)
                        },
                        onFavorite: {
                            locationStore.toggleFavorite(location)
                        },
                        onDelete: {
                            locationStore.delete(location)
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Preset Locations Section
    
    private var presetLocationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L("location.preset"))
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
                .padding(.horizontal, 4)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                ForEach(PresetLocation.presets) { location in
                    PresetLocationCard(
                        location: location,
                        isSelected: isPresetSelected(location),
                        action: {
                            selectedLocation = .preset(location)
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Custom Location Card
    
    private var customLocationCard: some View {
        Button {
            showMapPicker = true
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(isCustomLocationSelected ? LiquidGlassStyle.primaryGradient : LiquidGlassStyle.accentGradient)
                        .frame(width: 50, height: 50)
                    
                    if isCustomLocationSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                            .frame(width: 30, height: 30)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(L("location.chooseFromMap"))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    if case .custom(_, let name) = selectedLocation {
                        Text(name)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.green)
                            .lineLimit(1)
                    } else {
                        Text(L("location.selectOnMap"))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if isCustomLocationSelected {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(
                            settings.selectedVisualStyle == .neumorphism
                                ? (settings.isNeumorphismLight ? Color(red: 0.35, green: 0.52, blue: 0.85) : Color(red: 0.55, green: 0.65, blue: 1.0))
                                : Color.blue
                        )
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }
            .padding(16)
            .glassCard(cornerRadius: 16)
        }
    }
    
    // MARK: - Helpers
    
    private var isCustomLocationSelected: Bool {
        if case .custom = selectedLocation {
            return true
        }
        return false
    }
    
    private func isPresetSelected(_ location: PresetLocation) -> Bool {
        if case .preset(let selected) = selectedLocation {
            return selected.id == location.id
        }
        return false
    }
    
    private func isFavoriteSelected(_ location: SavedLocation) -> Bool {
        if case .custom(let coord, _) = selectedLocation {
            let distance = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
                .distance(from: CLLocation(latitude: location.latitude, longitude: location.longitude))
            return distance < 100
        }
        return false
    }
    
    private func isHistorySelected(_ location: SavedLocation) -> Bool {
        if case .custom(let coord, _) = selectedLocation {
            let distance = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
                .distance(from: CLLocation(latitude: location.latitude, longitude: location.longitude))
            return distance < 100
        }
        return false
    }
}

// MARK: - Favorite Location Card

struct FavoriteLocationCard: View {
    let location: SavedLocation
    let isSelected: Bool
    let action: () -> Void
    @ObservedObject private var settings = AppSettings.shared
    
    var body: some View {
        Button(action: {
            HapticManager.selection()
            action()
        }) {
            VStack(spacing: 10) {
                Text(location.emoji ?? "⭐")
                    .font(.system(size: 32))
                
                Text(location.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                
                ZStack {
                    Circle()
                        .fill(isSelected
                            ? (settings.selectedVisualStyle == .neumorphism
                                ? (settings.isNeumorphismLight ? Color(red: 0.35, green: 0.52, blue: 0.85) : Color(red: 0.55, green: 0.65, blue: 1.0))
                                : Color.blue)
                            : Color.secondary.opacity(0.3)
                        )
                        .frame(width: isSelected ? 20 : 18, height: isSelected ? 20 : 18)
                    
                    if isSelected {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .glassCard(cornerRadius: 16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected
                        ? (settings.selectedVisualStyle == .neumorphism
                            ? (settings.isNeumorphismLight ? Color(red: 0.35, green: 0.52, blue: 0.85).opacity(0.6) : Color(red: 0.55, green: 0.65, blue: 1.0).opacity(0.6))
                            : Color.blue.opacity(0.5))
                        : Color.clear,
                        lineWidth: isSelected ? 2.5 : 0
                    )
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - History Location Row

struct HistoryLocationRow: View {
    let location: SavedLocation
    let isSelected: Bool
    let action: () -> Void
    let onFavorite: () -> Void
    let onDelete: () -> Void
    @ObservedObject private var settings = AppSettings.shared
    
    var body: some View {
        Button(action: {
            HapticManager.selection()
            action()
        }) {
            HStack(spacing: 12) {
                // Selection indicator
                ZStack {
                    Circle()
                        .fill(isSelected
                            ? (settings.selectedVisualStyle == .neumorphism
                                ? (settings.isNeumorphismLight ? Color(red: 0.35, green: 0.52, blue: 0.85).opacity(0.15) : Color.blue.opacity(0.25))
                                : Color.blue.opacity(0.2))
                            : Color.clear
                        )
                        .frame(width: 32, height: 32)
                    
                    if isSelected {
                        Image(systemName: "clock.badge.checkmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(
                                settings.selectedVisualStyle == .neumorphism
                                    ? (settings.isNeumorphismLight ? Color(red: 0.35, green: 0.52, blue: 0.85) : Color(red: 0.55, green: 0.65, blue: 1.0))
                                    : Color.blue
                            )
                    } else {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(location.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(formattedDate(location.timestamp))
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Favorite button
                Button {
                    HapticManager.light()
                    onFavorite()
                } label: {
                    Image(systemName: "star.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.yellow.opacity(0.8))
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .glassCard(cornerRadius: 12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected
                        ? (settings.selectedVisualStyle == .neumorphism
                            ? (settings.isNeumorphismLight ? Color(red: 0.35, green: 0.52, blue: 0.85).opacity(0.6) : Color(red: 0.55, green: 0.65, blue: 1.0).opacity(0.6))
                            : Color.blue.opacity(0.5))
                        : Color.clear,
                        lineWidth: isSelected ? 2.5 : 0
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                HapticManager.light()
                onDelete()
            } label: {
                Label(L("common.delete"), systemImage: "trash")
            }
            
            Button {
                HapticManager.light()
                onFavorite()
            } label: {
                Label(L("location.favorite.add"), systemImage: "star.fill")
            }
            .tint(.yellow)
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Preset Location Card

struct PresetLocationCard: View {
    let location: PresetLocation
    let isSelected: Bool
    let action: () -> Void
    @ObservedObject private var settings = AppSettings.shared
    
    var body: some View {
        Button(action: {
            HapticManager.selection()
            action()
        }) {
            VStack(spacing: 10) {
                Text(location.emoji)
                    .font(.system(size: 36))
                
                Text(location.localizedName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                
                ZStack {
                    Circle()
                        .fill(isSelected
                            ? (settings.selectedVisualStyle == .neumorphism
                                ? (settings.isNeumorphismLight ? Color(red: 0.35, green: 0.52, blue: 0.85) : Color(red: 0.55, green: 0.65, blue: 1.0))
                                : Color.blue)
                            : Color.secondary.opacity(0.3)
                        )
                        .frame(width: isSelected ? 20 : 18, height: isSelected ? 20 : 18)
                    
                    if isSelected {
                        Image(systemName: "mappin")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .glassCard(cornerRadius: 16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected
                        ? (settings.selectedVisualStyle == .neumorphism
                            ? (settings.isNeumorphismLight ? Color(red: 0.35, green: 0.52, blue: 0.85).opacity(0.6) : Color(red: 0.55, green: 0.65, blue: 1.0).opacity(0.6))
                            : Color.blue.opacity(0.5))
                        : Color.clear,
                        lineWidth: isSelected ? 2.5 : 0
                    )
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Map Picker View

struct MapPickerView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @Binding var selectedLocation: LocationSource
    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var locationManager = LocationManager()
    @ObservedObject private var locationStore = LocationStore.shared
    
    @State private var cameraPosition: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 32.0603, longitude: 118.7969), // Nanjing
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    ))
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var locationName = ""
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var isSearching = false
    @State private var showSearchResults = false
    @State private var showFavoritesSheet = false
    @State private var searchTask: Task<Void, Never>?
    @State private var hasCenteredOnCurrentLocation = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Map with zoom and pan enabled
                MapReader { proxy in
                    Map(position: $cameraPosition, interactionModes: [.pan, .zoom, .rotate]) {
                        // Show system current-location blue dot when available.
                        UserAnnotation()
                        
                        // Selected location marker
                        if let coordinate = selectedCoordinate {
                            Annotation("", coordinate: coordinate) {
                                SelectedLocationMarker()
                            }
                        }
                    }
                    .mapStyle(settings.selectedMapMode.style)
                    .onTapGesture { screenCoordinate in
                        // Convert tap point to map coordinate
                        if let coordinate = proxy.convert(screenCoordinate, from: .local) {
                            selectLocation(coordinate: coordinate)
                        }
                    }
                }
                .ignoresSafeArea(edges: .bottom)
                
                // Search results overlay
                VStack(spacing: 0) {
                    if showSearchResults && !searchResults.isEmpty {
                        searchResultsList
                            .frame(maxHeight: 300)
                            .background(Rectangle().fill(.ultraThinMaterial))
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                    }
                    
                    Spacer()
                    
                    // Bottom controls
                    bottomControls
                }
            }
            .navigationTitle(L("location.chooseFromMap"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showFavoritesSheet = true
                    } label: {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L("common.done")) {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            // Use system native searchable for official iOS search bar style
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: L("location.search")
            )
            .onSubmit(of: .search) {
                performSearch()
            }
            .onChange(of: searchText) { _, newValue in
                // Cancel previous search task
                searchTask?.cancel()
                
                if newValue.isEmpty {
                    searchResults = []
                    showSearchResults = false
                } else {
                    // Debounce search
                    searchTask = Task {
                        try? await Task.sleep(nanoseconds: 300_000_000) // 300ms
                        if !Task.isCancelled {
                            await performSearchAsync()
                        }
                    }
                }
            }
            .sheet(isPresented: $showFavoritesSheet) {
                FavoritesPickerSheet { location in
                    selectSavedLocation(location)
                }
            }
            .onAppear {
                locationStore.setModelContext(modelContext)
                locationManager.requestPermission()
                if locationManager.isAuthorized {
                    locationManager.startUpdatingLocation()
                }
            }
            .onChange(of: locationManager.authorizationStatus) { _, newStatus in
                if newStatus == .authorizedWhenInUse || newStatus == .authorizedAlways {
                    locationManager.startUpdatingLocation()
                }
            }
            .onChange(of: locationManager.currentLocation) { _, newLocation in
                guard !hasCenteredOnCurrentLocation,
                      let coordinate = newLocation?.coordinate else { return }
                hasCenteredOnCurrentLocation = true
                withAnimation(.easeInOut(duration: 0.45)) {
                    cameraPosition = .region(
                        MKCoordinateRegion(
                            center: coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.06, longitudeDelta: 0.06)
                        )
                    )
                }
            }
            .onDisappear {
                locationManager.stopUpdatingLocation()
            }
        }
        .preferredColorScheme(settings.currentColorScheme)
    }
    
    // MARK: - Selected Location Marker
    
    private struct SelectedLocationMarker: View {
        var body: some View {
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.3))
                    .frame(width: 40, height: 40)
                
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Color.red, Color.white)
                    .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
            }
        }
    }
    
    // MARK: - Bottom Controls
    
    private var bottomControls: some View {
        VStack(spacing: 12) {
            // Confirm button
            if selectedCoordinate != nil {
                confirmButton
            }
            
            // Recenter and action buttons
            HStack(spacing: 12) {
                // Recenter button
                Button {
                    recenterToCurrentLocation()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 14, weight: .semibold))
                        Text(L("map.recenter"))
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .glassCard(cornerRadius: 12)
                }
                
                // Add to favorites button (only when location selected)
                if selectedCoordinate != nil && !locationName.isEmpty {
                    Button {
                        addToFavorites()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 14, weight: .semibold))
                            Text(L("location.favorite.add"))
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.yellow)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .glassCard(cornerRadius: 12)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 40)
    }
    
    // MARK: - Search Results List
    
    private var searchResultsList: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(searchResults, id: \.self) { item in
                    Button {
                        selectSearchResult(item)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.name ?? L("location.custom"))
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            if let address = item.placemark.title {
                                Text(address)
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    
                    if item != searchResults.last {
                        Divider()
                            .padding(.leading, 16)
                    }
                }
            }
        }
    }
    
    // MARK: - Confirm Button
    
    private var confirmButton: some View {
        VStack(spacing: 12) {
            if !locationName.isEmpty {
                VStack(spacing: 4) {
                    Text(L("location.selected"))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Text(locationName)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            
            Button {
                confirmSelection()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                    Text(L("location.confirm"))
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(LiquidGlassStyle.primaryGradient)
                        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                )
            }
        }
        .padding(20)
        .glassCard(cornerRadius: 20)
        .padding(.horizontal, 20)
    }
    
    // MARK: - Actions
    
    private func recenterToCurrentLocation() {
        HapticManager.light()
        
        guard let currentLocation = locationManager.currentLocation else {
            // Show alert or feedback that location is not available
            return
        }
        
        withAnimation(.easeInOut(duration: 0.5)) {
            cameraPosition = .region(MKCoordinateRegion(
                center: currentLocation.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            ))
        }
    }
    
    private func selectLocation(coordinate: CLLocationCoordinate2D) {
        HapticManager.light()
        selectedCoordinate = coordinate
        
        // Move camera to selected location with smooth animation
        withAnimation(.easeInOut(duration: 0.5)) {
            cameraPosition = .region(MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            ))
        }
        
        // Reverse geocode to get location name
        reverseGeocode(coordinate: coordinate)
    }
    
    private func selectSearchResult(_ item: MKMapItem) {
        HapticManager.selection()
        let coordinate = item.placemark.coordinate
        selectedCoordinate = coordinate
        locationName = item.name ?? L("location.custom")
        
        // Move camera to selected location with smooth animation
        withAnimation(.easeInOut(duration: 0.5)) {
            cameraPosition = .region(MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            ))
        }
        
        // Hide search results
        showSearchResults = false
        searchText = ""
    }
    
    private func selectSavedLocation(_ location: SavedLocation) {
        HapticManager.selection()
        let coordinate = location.coordinate
        selectedCoordinate = coordinate
        locationName = location.name
        
        // Move camera to selected location with smooth animation
        withAnimation(.easeInOut(duration: 0.5)) {
            cameraPosition = .region(MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            ))
        }
        
        showFavoritesSheet = false
    }
    
    private func performSearch() {
        Task {
            await performSearchAsync()
        }
    }
    
    private func performSearchAsync() async {
        guard !searchText.isEmpty else { return }
        
        await MainActor.run {
            HapticManager.light()
            isSearching = true
        }
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        request.resultTypes = .pointOfInterest
        
        // Set region based on current camera position
        if let region = cameraPosition.region {
            request.region = region
        }
        
        do {
            let search = MKLocalSearch(request: request)
            let response = try await search.start()
            
            await MainActor.run {
                searchResults = response.mapItems
                showSearchResults = true
                isSearching = false
            }
        } catch {
            print("Search error: \(error.localizedDescription)")
            await MainActor.run {
                isSearching = false
            }
        }
    }
    
    private func reverseGeocode(coordinate: CLLocationCoordinate2D) {
        Task {
            let geocoder = CLGeocoder()
            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            
            // Use app language for geocoding results
            let appLanguage = AppSettings.shared.currentLanguage
            let locale = Locale(identifier: appLanguage)
            
            do {
                let placemarks = try await geocoder.reverseGeocodeLocation(location, preferredLocale: locale)
                
                await MainActor.run {
                    if let placemark = placemarks.first {
                        // Build location name from placemark
                        var components: [String] = []
                        
                        if let name = placemark.name {
                            components.append(name)
                        }
                        if let locality = placemark.locality {
                            components.append(locality)
                        }
                        if let country = placemark.country {
                            components.append(country)
                        }
                        
                        let finalName = components.isEmpty ? L("location.custom") : components.joined(separator: ", ")
                        locationName = finalName
                    } else {
                        let coordString = String(format: "%.4f, %.4f", coordinate.latitude, coordinate.longitude)
                        locationName = coordString
                    }
                }
            } catch {
                await MainActor.run {
                    let coordString = String(format: "%.4f, %.4f", coordinate.latitude, coordinate.longitude)
                    locationName = coordString
                }
            }
        }
    }
    
    private func confirmSelection() {
        guard let coordinate = selectedCoordinate else { return }
        
        HapticManager.success()
        let name = locationName.isEmpty ? L("location.custom") : locationName
        selectedLocation = .custom(coordinate, name)
        
        // Add to history
        locationStore.addToHistory(name: name, coordinate: coordinate)
        
        // Close the map picker sheet
        dismiss()
    }
    
    private func addToFavorites() {
        guard let coordinate = selectedCoordinate, !locationName.isEmpty else { return }
        
        HapticManager.success()
        locationStore.addToFavorites(name: locationName, coordinate: coordinate, emoji: "📍")
    }
}

// MARK: - Favorites Picker Sheet

struct FavoritesPickerSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var locationStore = LocationStore.shared
    @ObservedObject private var settings = AppSettings.shared
    let onSelect: (SavedLocation) -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedGradientBackground()
                
                if locationStore.favorites.isEmpty {
                    emptyState
                } else {
                    favoritesList
                }
            }
            .navigationTitle(L("location.favorites"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L("common.done")) {
                        dismiss()
                    }
                }
            }
        }
        .preferredColorScheme(settings.currentColorScheme)
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "star.slash.fill")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text(L("location.favorites.empty"))
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            Text(L("location.favorites.empty.message"))
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
    
    private var favoritesList: some View {
        List {
            ForEach(locationStore.favorites) { location in
                Button {
                    onSelect(location)
                } label: {
                    HStack(spacing: 12) {
                        Text(location.emoji ?? "⭐")
                            .font(.system(size: 28))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(location.name)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            Text(String(format: "%.4f, %.4f", location.latitude, location.longitude))
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                }
                .listRowBackground(Color.clear)
            }
            .onDelete { indexSet in
                for index in indexSet {
                    let location = locationStore.favorites[index]
                    locationStore.delete(location)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}

#Preview {
    LocationPickerView(
        selectedLocation: .constant(.currentLocation),
        locationManager: LocationManager()
    )
}
