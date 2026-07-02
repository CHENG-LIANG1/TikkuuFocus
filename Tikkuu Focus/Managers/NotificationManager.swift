//
//  NotificationManager.swift
//  Tikkuu Focus
//
//  Created by Tikkuu on 2026/6/21.
//

import Foundation
import UserNotifications

/// Handles local notifications for journey events.
final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    private override init() {
        super.init()
    }

    /// Install ourselves as the notification-center delegate. Apple requires the
    /// delegate to be set before the app finishes launching, so this is called
    /// from the app delegate's `didFinishLaunchingWithOptions`.
    func configure() {
        UNUserNotificationCenter.current().delegate = self
    }

    /// Ask for notification permission. Safe to call repeatedly — iOS only
    /// prompts the user the first time. Call this when a journey starts so the
    /// completion notification can be delivered later without a jarring prompt.
    func requestAuthorization() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    /// Post an immediate notification announcing that a journey has finished,
    /// e.g. "25 分钟 步行 已完成".
    func notifyJourneyCompleted(duration: TimeInterval, transportMode: TransportMode) {
        let content = UNMutableNotificationContent()
        content.title = L("notification.journeyComplete.title")
        content.body = String(
            format: L("notification.journeyComplete.body"),
            FormatUtilities.formatTime(duration),
            transportMode.localizedName
        )
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "journey.completion.\(UUID().uuidString)",
            content: content,
            trigger: nil // deliver right away
        )

        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }
            center.add(request, withCompletionHandler: nil)
        }
    }

    func notifyTrophyUnlocked(trophy: Trophy) {
        let content = UNMutableNotificationContent()
        content.title = L("notification.trophyUnlocked.title")
        content.body = String(format: L("notification.trophyUnlocked.body"), trophy.localizedTitle)
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "trophy.unlocked.\(trophy.id).\(UUID().uuidString)",
            content: content,
            trigger: nil
        )

        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }
            center.add(request, withCompletionHandler: nil)
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// Show the notification even when the app is in the foreground (a journey
    /// can finish while the user is watching the map).
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list, .sound])
    }
}
