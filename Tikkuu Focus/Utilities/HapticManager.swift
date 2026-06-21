//
//  HapticManager.swift
//  Tikkuu Focus
//
//  Created by Tikkuu on 2026/2/8.
//

import UIKit

/// Manager for haptic feedback
enum HapticManager {
    private static let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private static let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private static let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private static let notificationGenerator = UINotificationFeedbackGenerator()
    private static let selectionGenerator = UISelectionFeedbackGenerator()
    private static var isWarmedUp = false

    /// Pre-warm haptic engine to avoid first-touch hitch.
    static func warmUp() {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { warmUp() }
            return
        }
        guard !isWarmedUp else { return }
        lightGenerator.prepare()
        mediumGenerator.prepare()
        heavyGenerator.prepare()
        notificationGenerator.prepare()
        selectionGenerator.prepare()
        isWarmedUp = true
    }

    private static func ensureReady() -> Bool {
        guard AppSettings.shared.isHapticFeedbackEnabled else { return false }
        if !isWarmedUp {
            warmUp()
            return false
        }
        return true
    }
    
    /// Light impact feedback (for button taps)
    static func light() {
        guard ensureReady() else { return }
        lightGenerator.impactOccurred()
        lightGenerator.prepare()
    }
    
    /// Medium impact feedback (for selections)
    static func medium() {
        guard ensureReady() else { return }
        mediumGenerator.impactOccurred()
        mediumGenerator.prepare()
    }
    
    /// Heavy impact feedback (for important actions)
    static func heavy() {
        guard ensureReady() else { return }
        heavyGenerator.impactOccurred()
        heavyGenerator.prepare()
    }
    
    /// Success notification
    static func success() {
        guard ensureReady() else { return }
        notificationGenerator.notificationOccurred(.success)
        notificationGenerator.prepare()
    }
    
    /// Warning notification
    static func warning() {
        guard ensureReady() else { return }
        notificationGenerator.notificationOccurred(.warning)
        notificationGenerator.prepare()
    }
    
    /// Error notification
    static func error() {
        guard ensureReady() else { return }
        notificationGenerator.notificationOccurred(.error)
        notificationGenerator.prepare()
    }
    
    /// Selection changed feedback
    static func selection() {
        guard ensureReady() else { return }
        selectionGenerator.selectionChanged()
        selectionGenerator.prepare()
    }
}
