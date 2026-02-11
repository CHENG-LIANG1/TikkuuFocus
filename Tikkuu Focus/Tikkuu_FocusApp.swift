//
//  Tikkuu_FocusApp.swift
//  Tikkuu Focus
//
//  Created by 梁非凡 on 2026/2/8.
//

import SwiftUI
import SwiftData

@main
struct Tikkuu_FocusApp: App {
    @StateObject private var settings = AppSettings.shared
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            JourneyRecord.self,
        ])
        
        // Get the app support directory and ensure it exists
        let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        try? FileManager.default.createDirectory(at: appSupportURL, withIntermediateDirectories: true)
        
        let storeURL = appSupportURL.appendingPathComponent("TikkuuFocus.sqlite")
        let modelConfiguration = ModelConfiguration(url: storeURL)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            if settings.hasCompletedOnboarding {
                SetupView()
                    .preferredColorScheme(settings.currentColorScheme)
            } else {
                OnboardingView()
                    .preferredColorScheme(settings.currentColorScheme)
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
