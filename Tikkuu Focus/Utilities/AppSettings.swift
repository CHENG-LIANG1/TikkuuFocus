//
//  AppSettings.swift
//  Tikkuu Focus
//
//  Created by Tikkuu on 2026/2/8.
//

import SwiftUI
import Combine

/// App-wide settings manager
class AppSettings: ObservableObject {
    static let shared = AppSettings()
    
    @Published var selectedLanguage: String {
        didSet {
            UserDefaults.standard.set(selectedLanguage, forKey: "selectedLanguage")
            // Trigger immediate UI refresh
            objectWillChange.send()
        }
    }
    
    @Published var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding")
        }
    }
    
    @Published var hasCompletedFirstJourney: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedFirstJourney, forKey: "hasCompletedFirstJourney")
        }
    }
    
    @Published var hasSeenFirstJourneyGuide: Bool {
        didSet {
            UserDefaults.standard.set(hasSeenFirstJourneyGuide, forKey: "hasSeenFirstJourneyGuide")
        }
    }
    
    private init() {
        self.selectedLanguage = UserDefaults.standard.string(forKey: "selectedLanguage") ?? "system"
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        self.hasCompletedFirstJourney = UserDefaults.standard.bool(forKey: "hasCompletedFirstJourney")
        self.hasSeenFirstJourneyGuide = UserDefaults.standard.bool(forKey: "hasSeenFirstJourneyGuide")
    }
    
    var currentLanguage: String {
        if selectedLanguage == "system" {
            return Locale.current.language.languageCode?.identifier ?? "en"
        }
        return selectedLanguage
    }
    
    // Always return dark mode
    var currentColorScheme: ColorScheme? {
        return .dark
    }
    
    /// Get localized string with current language
    func localizedString(_ key: String, comment: String = "") -> String {
        if selectedLanguage == "system" {
            return NSLocalizedString(key, comment: comment)
        }
        
        // Load specific language bundle
        guard let path = Bundle.main.path(forResource: selectedLanguage, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return NSLocalizedString(key, comment: comment)
        }
        
        return bundle.localizedString(forKey: key, value: nil, table: nil)
    }
}

/// Helper to get localized string from AppSettings
func L(_ key: String, comment: String = "") -> String {
    AppSettings.shared.localizedString(key, comment: comment)
}
