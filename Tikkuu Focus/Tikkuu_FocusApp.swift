//
//  Tikkuu_FocusApp.swift
//  Tikkuu Focus
//
//  Created by 梁非凡 on 2026/2/8.
//

import SwiftUI
import SwiftData
import Foundation
import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Must register the notification-center delegate before launch completes.
        NotificationManager.shared.configure()
        return true
    }
}

@main
struct Tikkuu_FocusApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var settings = AppSettings.shared
    private let modelContainer: ModelContainer

    init() {
        self.modelContainer = Self.makeModelContainer()
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
            .modelContainer(modelContainer)
        }
    }

    private static func makeModelContainer() -> ModelContainer {
        let schema = Schema([
            JourneyRecord.self,
            SavedLocation.self,
            TransportAvatarSettings.self,
        ])

        let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        try? FileManager.default.createDirectory(at: appSupportURL, withIntermediateDirectories: true)
        let storeURL = appSupportURL.appendingPathComponent("TikkuuFocus.sqlite")

        let localConfiguration = ModelConfiguration(
            schema: schema,
            url: storeURL,
            cloudKitDatabase: .none
        )
        do {
            return try ModelContainer(for: schema, configurations: [localConfiguration])
        } catch {
            removePersistentStoreFiles(at: storeURL)
            return (try? ModelContainer(for: schema, configurations: [localConfiguration])) ?? {
                fatalError("Could not create local ModelContainer after recovery: \(error)")
            }()
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
