//
//  Tikkuu_FocusApp.swift
//  Tikkuu Focus
//
//  Created by 梁非凡 on 2026/2/8.
//

import SwiftUI
import SwiftData
import CoreData

@main
struct Tikkuu_FocusApp: App {
    @StateObject private var settings = AppSettings.shared
    
    init() {
        NotificationCenter.default.addObserver(
            forName: .NSPersistentStoreRemoteChange,
            object: nil,
            queue: .main
        ) { _ in
            AppSettings.shared.lastCloudKitSyncTime = Date()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if settings.hasCompletedOnboarding {
                    SetupView()
                } else {
                    OnboardingView()
                }
            }
            .preferredColorScheme(settings.currentColorScheme)
            .environment(\.locale, settings.appLocale)
            .modelContainer(createModelContainer())
        }
    }

    private func createModelContainer() -> ModelContainer {
        let schema = Schema([
            JourneyRecord.self,
            SavedLocation.self,
        ])

        let modelConfiguration: ModelConfiguration
        if AppSettings.shared.isICloudSyncEnabled {
            modelConfiguration = ModelConfiguration(
                schema: schema,
                cloudKitDatabase: .automatic
            )
        } else {
            let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            try? FileManager.default.createDirectory(at: appSupportURL, withIntermediateDirectories: true)
            let storeURL = appSupportURL.appendingPathComponent("TikkuuFocus.sqlite")
            modelConfiguration = ModelConfiguration(url: storeURL)
        }

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            if !AppSettings.shared.isICloudSyncEnabled {
                let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
                let storeURL = appSupportURL.appendingPathComponent("TikkuuFocus.sqlite")
                removePersistentStoreFiles(at: storeURL)
            }

            do {
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("Could not create ModelContainer after recovery: \(error)")
            }
        }
    }
}

private func removePersistentStoreFiles(at storeURL: URL) {
    let fileManager = FileManager.default
    let relatedFiles = [
        storeURL,
        storeURL.appendingPathExtension("shm"),
        storeURL.appendingPathExtension("wal")
    ]

    for fileURL in relatedFiles {
        if fileManager.fileExists(atPath: fileURL.path) {
            try? fileManager.removeItem(at: fileURL)
        }
    }
}
