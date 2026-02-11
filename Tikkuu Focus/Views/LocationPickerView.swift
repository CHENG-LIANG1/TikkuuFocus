//
//  LocationPickerView.swift
//  Tikkuu Focus
//
//  Created by Tikkuu on 2026/2/8.
//

import SwiftUI
import MapKit

struct LocationPickerView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedLocation: LocationSource
    @ObservedObject var locationManager: LocationManager
    @ObservedObject private var settings = AppSettings.shared
    
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
                    Text(L("location.useCurrentLocation"))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    if locationManager.currentLocation != nil {
                        Text(L("location.status.gpsReady"))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.green)
                    } else {
                        Text(L("location.status.waiting"))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.orange)
                    }
                }
                
                Spacer()
                
                if case .currentLocation = selectedLocation {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.green)
                }
            }
            .padding(16)
            .glassCard(cornerRadius: 16)
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
                        isSelected: isSelected(location),
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
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.green)
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
    
    // MARK: - Helper
    
    private var isCustomLocationSelected: Bool {
        if case .custom = selectedLocation {
            return true
        }
        return false
    }
    
    private func isSelected(_ location: PresetLocation) -> Bool {
        if case .preset(let selected) = selectedLocation {
            return selected.id == location.id
        }
        return false
    }
}

// MARK: - Preset Location Card

struct PresetLocationCard: View {
    let location: PresetLocation
    let isSelected: Bool
    let action: () -> Void
    
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
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.green)
                } else {
                    Circle()
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 2)
                        .frame(width: 18, height: 18)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .glassCard(cornerRadius: 16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.blue.opacity(0.5) : Color.clear, lineWidth: isSelected ? 2 : 0)
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
    @Binding var selectedLocation: LocationSource
    @ObservedObject private var settings = AppSettings.shared
    
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
    @State private var previewCoordinate: CLLocationCoordinate2D?
    @State private var previewName: String = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Map with zoom and pan enabled
                MapReader { proxy in
                    Map(position: $cameraPosition, interactionModes: [.pan, .zoom, .rotate]) {
                        if let coordinate = selectedCoordinate {
                            Annotation("", coordinate: coordinate) {
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
                    }
                    .mapStyle(settings.selectedMapMode.style)
                    .onTapGesture { screenCoordinate in
                        if let coordinate = proxy.convert(screenCoordinate, from: .local) {
                            selectLocation(coordinate: coordinate)
                        }
                    }
                }
                .ignoresSafeArea(edges: .bottom)
                
                // Search bar
                VStack(spacing: 0) {
                    searchBar
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 12)
                        .background(Rectangle().fill(.ultraThinMaterial))
                    
                    // Search results
                    if showSearchResults && !searchResults.isEmpty {
                        searchResultsList
                            .frame(maxHeight: 300)
                            .background(Rectangle().fill(.ultraThinMaterial))
                    }
                    
                    Spacer()
                    
                    // Confirm button
                    if selectedCoordinate != nil {
                        confirmButton
                            .padding(.horizontal, 20)
                            .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle(L("location.chooseFromMap"))
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
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField(L("location.search"), text: $searchText)
                .textFieldStyle(.plain)
                .submitLabel(.search)
                .onSubmit {
                    performSearch()
                }
                .onChange(of: searchText) { _, newValue in
                    if newValue.isEmpty {
                        searchResults = []
                        showSearchResults = false
                    }
                }
            
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    searchResults = []
                    showSearchResults = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
            
            if isSearching {
                ProgressView()
                    .scaleEffect(0.8)
            } else if !searchText.isEmpty {
                Button {
                    performSearch()
                } label: {
                    Text(L("location.search"))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(LiquidGlassStyle.primaryGradient)
                        )
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                )
        )
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
    }
    
    // MARK: - Actions
    
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
        
        // Update preview immediately
        previewCoordinate = coordinate
        previewName = String(format: "%.4f, %.4f", coordinate.latitude, coordinate.longitude)
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
        
        // Update preview immediately
        previewCoordinate = coordinate
        previewName = item.name ?? L("location.custom")
    }
    
    private func performSearch() {
        guard !searchText.isEmpty else { return }
        
        HapticManager.light()
        isSearching = true
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        
        // Set search region based on current camera position
        // Note: Only set region if camera is in region mode
        
        let search = MKLocalSearch(request: request)
        search.start { [self] response, error in
            isSearching = false
            
            if let response = response {
                searchResults = response.mapItems
                showSearchResults = true
            } else if let error = error {
                print("Search error: \(error.localizedDescription)")
            }
        }
    }
    
    private func reverseGeocode(coordinate: CLLocationCoordinate2D) {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        geocoder.reverseGeocodeLocation(location) { placemarks, _ in
            // Silently handle geocoding errors - use coordinates as fallback
            if placemarks == nil {
                let coordString = String(format: "%.4f, %.4f", coordinate.latitude, coordinate.longitude)
                locationName = coordString
                previewName = coordString
                return
            }
            
            guard let placemark = placemarks?.first else {
                let coordString = String(format: "%.4f, %.4f", coordinate.latitude, coordinate.longitude)
                locationName = coordString
                previewName = coordString
                return
            }
            
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
            previewName = finalName
        }
    }
    
    private func confirmSelection() {
        guard let coordinate = selectedCoordinate else { return }
        
        HapticManager.success()
        let name = locationName.isEmpty ? L("location.custom") : locationName
        selectedLocation = .custom(coordinate, name)
        
        // Close the map picker sheet
        dismiss()
    }
}

#Preview {
    LocationPickerView(
        selectedLocation: .constant(.currentLocation),
        locationManager: LocationManager()
    )
}
