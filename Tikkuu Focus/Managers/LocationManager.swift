//
//  LocationManager.swift
//  Tikkuu Focus
//
//  Created by Tikkuu on 2026/2/8.
//

import Foundation
import CoreLocation
import Combine

/// Manages location services and permissions
@MainActor
class LocationManager: NSObject, ObservableObject {
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var currentLocation: CLLocation?
    @Published var currentLocationName: String = ""
    @Published var error: LocationError?
    
    private let locationManager = CLLocationManager()
    private var hasRequestedLocation = false
    private var geocoder = CLGeocoder()
    private var lastGeocodedCoordinate: CLLocationCoordinate2D?
    private var lastGeocodeTime: Date = .distantPast
    private var geocodeTask: Task<Void, Never>?
    private let geocodeMinInterval: TimeInterval = 45
    private let geocodeMinDistance: CLLocationDistance = 150
    
    /// Reverse geocode coordinate to get location name
    func reverseGeocode(_ coordinate: CLLocationCoordinate2D?) async -> String {
        guard let coordinate = coordinate else {
            return L("location.current")
        }
        
        // Use cached name if coordinate hasn't changed significantly
        if let lastCoord = lastGeocodedCoordinate,
           abs(lastCoord.latitude - coordinate.latitude) < 0.001,
           abs(lastCoord.longitude - coordinate.longitude) < 0.001,
           !currentLocationName.isEmpty {
            return currentLocationName
        }
        
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        // Use app language for geocoding results
        let appLanguage = AppSettings.shared.currentLanguage
        let locale = Locale(identifier: appLanguage)
        lastGeocodeTime = Date()

        if geocoder.isGeocoding {
            geocoder.cancelGeocode()
        }
        
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location, preferredLocale: locale)
            guard let placemark = placemarks.first else {
                return L("location.current")
            }
            
            // Build location name from available components
            // Priority: Name > SubLocality > Locality > AdministrativeArea
            var nameComponents: [String] = []
            
            // Check for named locations (like "Apple Park", "Huawei Nanjing Research Institute")
            if let name = placemark.name, !name.isEmpty,
               !name.contains("\u{53f7}"), // Not a street number
               !name.matches(pattern: "^\\d+") { // Doesn't start with number
                nameComponents.append(name)
            } else if let subLocality = placemark.subLocality, !subLocality.isEmpty {
                nameComponents.append(subLocality)
            } else if let locality = placemark.locality, !locality.isEmpty {
                nameComponents.append(locality)
            } else if let administrativeArea = placemark.administrativeArea, !administrativeArea.isEmpty {
                nameComponents.append(administrativeArea)
            }
            
            // If we have a locality that's different from the name, add it
            if let locality = placemark.locality, !locality.isEmpty,
               !nameComponents.contains(locality) {
                nameComponents.append(locality)
            }
            
            let locationName = nameComponents.joined(separator: ", ")
            
            await MainActor.run {
                self.currentLocationName = locationName.isEmpty ? L("location.current") : locationName
                self.lastGeocodedCoordinate = coordinate
            }
            
            return locationName.isEmpty ? L("location.current") : locationName
            
        } catch {
            return L("location.current")
        }
    }
    
    override init() {
        super.init()
        locationManager.delegate = self
        // 性能优化：降低定位精度，减少电池消耗和发热
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.distanceFilter = 50 // 性能优化：从 10 米改为 50 米，减少更新频率
        authorizationStatus = locationManager.authorizationStatus
    }

    deinit {
        geocodeTask?.cancel()
        geocoder.cancelGeocode()
    }
    
    /// Request location permissions
    func requestPermission() {
        guard authorizationStatus == .notDetermined else { return }
        locationManager.requestWhenInUseAuthorization()
    }
    
    /// Start updating location
    func startUpdatingLocation() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            error = .permissionDenied
            return
        }
        
        locationManager.startUpdatingLocation()
        hasRequestedLocation = true
    }
    
    /// Stop updating location
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
        hasRequestedLocation = false
    }
    
    /// Request a single location update
    func requestLocation() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            error = .permissionDenied
            return
        }
        
        locationManager.requestLocation()
    }
    
    var isAuthorized: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus
            
            // Automatically start updating if authorized and was previously requested
            if isAuthorized && hasRequestedLocation {
                startUpdatingLocation()
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            guard let location = locations.last else { return }
            currentLocation = location
            error = nil
            
            // Reverse geocode with distance/time throttling.
            requestReverseGeocodeIfNeeded(for: location.coordinate)
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            if let clError = error as? CLError {
                switch clError.code {
                case .denied:
                    self.error = .permissionDenied
                case .locationUnknown:
                    self.error = .locationUnavailable
                default:
                    self.error = .unknown(error.localizedDescription)
                }
            } else {
                self.error = .unknown(error.localizedDescription)
            }
        }
    }
}

private extension LocationManager {
    func requestReverseGeocodeIfNeeded(for coordinate: CLLocationCoordinate2D) {
        guard shouldReverseGeocode(for: coordinate) else { return }

        geocodeTask?.cancel()
        geocodeTask = Task { [weak self] in
            guard let self else { return }
            _ = await self.reverseGeocode(coordinate)
        }
    }

    func shouldReverseGeocode(for coordinate: CLLocationCoordinate2D) -> Bool {
        if currentLocationName.isEmpty && lastGeocodeTime == .distantPast {
            return true
        }

        let elapsed = Date().timeIntervalSince(lastGeocodeTime)
        if let lastCoordinate = lastGeocodedCoordinate {
            let movedDistance = lastCoordinate.distance(to: coordinate)
            return movedDistance >= geocodeMinDistance || elapsed >= geocodeMinInterval
        }

        return elapsed >= geocodeMinInterval
    }
}

// MARK: - LocationError

enum LocationError: LocalizedError, Equatable {
    case permissionDenied
    case locationUnavailable
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return L("error.location.permission")
        case .locationUnavailable:
            return L("error.location.unavailable")
        case .unknown(let message):
            return message
        }
    }
    
    static func == (lhs: LocationError, rhs: LocationError) -> Bool {
        switch (lhs, rhs) {
        case (.permissionDenied, .permissionDenied),
             (.locationUnavailable, .locationUnavailable):
            return true
        case (.unknown(let lhsMsg), .unknown(let rhsMsg)):
            return lhsMsg == rhsMsg
        default:
            return false
        }
    }
}

// MARK: - String Extension for Regex

private extension String {
    func matches(pattern: String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return false
        }
        let range = NSRange(location: 0, length: utf16.count)
        return regex.firstMatch(in: self, options: [], range: range) != nil
    }
}
