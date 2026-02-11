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
    @Published var error: LocationError?
    
    private let locationManager = CLLocationManager()
    private var hasRequestedLocation = false
    
    override init() {
        super.init()
        locationManager.delegate = self
        // 性能优化：降低定位精度，减少电池消耗和发热
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.distanceFilter = 50 // 性能优化：从 10 米改为 50 米，减少更新频率
        authorizationStatus = locationManager.authorizationStatus
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
