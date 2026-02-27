//
//  AppSettings.swift
//  Tikkuu Focus
//
//  Created by Tikkuu on 2026/2/8.
//

import SwiftUI
import Combine
import MapKit

enum AppVisualStyle: String, CaseIterable {
    case liquidGlass = "liquidGlass"
    case neumorphism = "neumorphism"
}

enum NeumorphismTone: String, CaseIterable {
    case dark = "dark"
    case light = "light"
}

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
            return .standard(elevation: .realistic)
        case .transit:
            return .hybrid(elevation: .realistic)
        case .satellite:
            return .imagery(elevation: .realistic)
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

    @Published var selectedVisualStyle: AppVisualStyle {
        didSet {
            guard selectedVisualStyle != oldValue else { return }
            UserDefaults.standard.set(selectedVisualStyle.rawValue, forKey: "selectedVisualStyle")
        }
    }

    @Published var selectedMapMode: AppMapMode {
        didSet {
            guard selectedMapMode != oldValue else { return }
            UserDefaults.standard.set(selectedMapMode.rawValue, forKey: "selectedMapMode")
        }
    }

    @Published var selectedNeumorphismTone: NeumorphismTone {
        didSet {
            guard selectedNeumorphismTone != oldValue else { return }
            UserDefaults.standard.set(selectedNeumorphismTone.rawValue, forKey: "selectedNeumorphismTone")
        }
    }
    
    private init() {
        self.selectedLanguage = UserDefaults.standard.string(forKey: "selectedLanguage") ?? "system"
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        self.hasCompletedFirstJourney = UserDefaults.standard.bool(forKey: "hasCompletedFirstJourney")
        self.hasSeenFirstJourneyGuide = UserDefaults.standard.bool(forKey: "hasSeenFirstJourneyGuide")
        let storedStyle = UserDefaults.standard.string(forKey: "selectedVisualStyle") ?? AppVisualStyle.liquidGlass.rawValue
        self.selectedVisualStyle = AppVisualStyle(rawValue: storedStyle) ?? .liquidGlass
        let storedMapMode = UserDefaults.standard.string(forKey: "selectedMapMode") ?? AppMapMode.explore.rawValue
        self.selectedMapMode = AppMapMode(rawValue: storedMapMode) ?? .explore
        let storedTone = UserDefaults.standard.string(forKey: "selectedNeumorphismTone") ?? NeumorphismTone.dark.rawValue
        self.selectedNeumorphismTone = NeumorphismTone(rawValue: storedTone) ?? .dark
    }
    
    var currentLanguage: String {
        if selectedLanguage == "system" {
            return Locale.current.language.languageCode?.identifier ?? "en"
        }
        return selectedLanguage
    }
    
    // Always return dark mode
    var currentColorScheme: ColorScheme? {
        if selectedVisualStyle == .neumorphism, selectedNeumorphismTone == .light {
            return .light
        }
        return .dark
    }

    var isNeumorphismLight: Bool {
        selectedVisualStyle == .neumorphism && selectedNeumorphismTone == .light
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
}

/// Helper to get localized string from AppSettings
func L(_ key: String, comment: String = "") -> String {
    AppSettings.shared.localizedString(key, comment: comment)
}
