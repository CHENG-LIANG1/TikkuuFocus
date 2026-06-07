//
//  AppSettings.swift
//  Tikkuu Focus
//
//  Created by Tikkuu on 2026/2/8.
//

import SwiftUI
import Combine
import MapKit

enum AppMapMode: String, CaseIterable {
    case explore = "explore"
    case transit = "transit"
    case satellite = "satellite"
    case simple = "simple"
}

extension AppMapMode {
    static var focusSelectableModes: [AppMapMode] {
        [.explore, .transit, .satellite]
    }

    var iconName: String {
        switch self {
        case .explore:
            return "map"
        case .transit:
            return "tram.fill"
        case .satellite:
            return "globe.americas.fill"
        case .simple:
            return "square.grid.2x2"
        }
    }

    var title: String {
        switch self {
        case .explore:
            return L("map.mode.explore")
        case .transit:
            return L("map.mode.transit")
        case .satellite:
            return L("map.mode.satellite")
        case .simple:
            return L("map.mode.simple")
        }
    }

    var style: MapStyle {
        switch self {
        case .explore:
            return .standard(elevation: PerformanceConfig.shouldReduceVisualEffects ? .flat : .realistic)
        case .transit:
            return .hybrid(elevation: PerformanceConfig.shouldReduceVisualEffects ? .flat : .realistic)
        case .satellite:
            return .imagery(elevation: PerformanceConfig.shouldReduceVisualEffects ? .flat : .realistic)
        case .simple:
            return .standard(elevation: .flat)
        }
    }

    var snapshotMapType: MKMapType {
        switch self {
        case .explore:
            return .standard
        case .transit:
            return .hybrid
        case .satellite:
            return .satellite
        case .simple:
            return .mutedStandard
        }
    }
}

/// App-wide settings manager
class AppSettings: ObservableObject {
    static let shared = AppSettings()
    private var localizationBundles: [String: Bundle] = [:]
    private let localizationBundleLock = NSLock()
    
    @Published var selectedLanguage: String {
        didSet {
            guard selectedLanguage != oldValue else { return }
            UserDefaults.standard.set(selectedLanguage, forKey: "selectedLanguage")
        }
    }
    
    @Published var hasCompletedOnboarding: Bool {
        didSet {
            guard hasCompletedOnboarding != oldValue else { return }
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding")
            syncWidgetPreferences()
        }
    }
    
    @Published var hasCompletedFirstJourney: Bool {
        didSet {
            guard hasCompletedFirstJourney != oldValue else { return }
            UserDefaults.standard.set(hasCompletedFirstJourney, forKey: "hasCompletedFirstJourney")
        }
    }
    
    @Published var hasSeenFirstJourneyGuide: Bool {
        didSet {
            guard hasSeenFirstJourneyGuide != oldValue else { return }
            UserDefaults.standard.set(hasSeenFirstJourneyGuide, forKey: "hasSeenFirstJourneyGuide")
        }
    }

    @Published var selectedMapMode: AppMapMode {
        didSet {
            guard selectedMapMode != oldValue else { return }
            UserDefaults.standard.set(selectedMapMode.rawValue, forKey: "selectedMapMode")
        }
    }
    
    @Published var preferredTransportMode: TransportMode {
        didSet {
            guard preferredTransportMode != oldValue else { return }
            UserDefaults.standard.set(preferredTransportMode.rawValue, forKey: "preferredTransportMode")
            syncWidgetPreferences()
        }
    }
    
    @Published var preferredDuration: Int {
        didSet {
            guard preferredDuration != oldValue else { return }
            UserDefaults.standard.set(preferredDuration, forKey: "preferredDuration")
            syncWidgetPreferences()
        }
    }

    @Published var isLooseModeEnabled: Bool {
        didSet {
            guard isLooseModeEnabled != oldValue else { return }
            UserDefaults.standard.set(isLooseModeEnabled, forKey: "isLooseModeEnabled")
        }
    }
    
    private init() {
        self.selectedLanguage = UserDefaults.standard.string(forKey: "selectedLanguage") ?? "system"
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        self.hasCompletedFirstJourney = UserDefaults.standard.bool(forKey: "hasCompletedFirstJourney")
        self.hasSeenFirstJourneyGuide = UserDefaults.standard.bool(forKey: "hasSeenFirstJourneyGuide")
        let storedMapMode = UserDefaults.standard.string(forKey: "selectedMapMode") ?? AppMapMode.explore.rawValue
        self.selectedMapMode = AppMapMode(rawValue: storedMapMode) ?? .explore
        let storedTransport = UserDefaults.standard.string(forKey: "preferredTransportMode") ?? TransportMode.cycling.rawValue
        self.preferredTransportMode = TransportMode(rawValue: storedTransport) ?? .cycling
        let storedDuration = UserDefaults.standard.integer(forKey: "preferredDuration")
        self.preferredDuration = storedDuration == 0 ? 25 : min(max(storedDuration, 5), 240)
        self.isLooseModeEnabled = UserDefaults.standard.bool(forKey: "isLooseModeEnabled")

        syncWidgetPreferences()
    }
    
    var currentLanguage: String {
        if selectedLanguage == "system" {
            return Locale.current.language.languageCode?.identifier ?? "en"
        }
        return selectedLanguage
    }

    var appLocale: Locale {
        if selectedLanguage == "system" {
            return .autoupdatingCurrent
        }
        return Locale(identifier: selectedLanguage)
    }
    
    // Always return dark mode
    var currentColorScheme: ColorScheme? {
        return .dark
    }

    var isDarkMode: Bool {
        currentColorScheme == .dark
    }
    
    /// Get localized string with current language
    func localizedString(_ key: String, comment: String = "") -> String {
        if selectedLanguage == "system" {
            return NSLocalizedString(key, comment: comment)
        }
        
        guard let bundle = localizationBundle(for: selectedLanguage) else {
            return NSLocalizedString(key, comment: comment)
        }
        
        return bundle.localizedString(forKey: key, value: nil, table: nil)
    }

    private func localizationBundle(for language: String) -> Bundle? {
        localizationBundleLock.lock()
        if let cached = localizationBundles[language] {
            localizationBundleLock.unlock()
            return cached
        }
        localizationBundleLock.unlock()

        guard let path = Bundle.main.path(forResource: language, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return nil
        }

        localizationBundleLock.lock()
        localizationBundles[language] = bundle
        localizationBundleLock.unlock()
        return bundle
    }

    private func syncWidgetPreferences() {
        WidgetSnapshotStore.shared.syncPreferenceMirror(
            hasCompletedOnboarding: hasCompletedOnboarding,
            preferredTransportModeRawValue: preferredTransportMode.rawValue,
            preferredDuration: preferredDuration
        )
    }
}

/// Helper to get localized string from AppSettings
func L(_ key: String, comment: String = "") -> String {
    AppSettings.shared.localizedString(key, comment: comment)
}
