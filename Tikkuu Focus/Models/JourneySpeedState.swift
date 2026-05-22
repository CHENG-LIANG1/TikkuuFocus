//
//  JourneySpeedState.swift
//  Tikkuu Focus
//
//  Created by SOLO on 2026/5/21.
//

import Foundation

/// Keeps the displayed journey speed stable while paused and only advances it during active updates.
struct JourneySpeedState {
    let transportMode: TransportMode
    private(set) var currentSpeed: Double

    init(transportMode: TransportMode, initialSpeed: Double = 0) {
        self.transportMode = transportMode
        self.currentSpeed = Self.sanitize(initialSpeed) ?? 0
    }

    mutating func ensureInitialized(using initialSpeedProvider: (TransportMode) -> Double) -> Double {
        if let stableSpeed = Self.sanitize(currentSpeed) {
            currentSpeed = stableSpeed
            return stableSpeed
        }

        let initialSpeed = Self.sanitize(initialSpeedProvider(transportMode)) ?? transportMode.speedKmh
        currentSpeed = initialSpeed
        return initialSpeed
    }

    mutating func tickIfNeeded(
        isPaused: Bool,
        nextSpeedProvider: (TransportMode, Double) -> Double
    ) -> Double {
        let stableSpeed = ensureInitialized(using: { $0.speedKmh })
        guard !isPaused else { return stableSpeed }

        let candidateSpeed = nextSpeedProvider(transportMode, stableSpeed)
        let nextSpeed = Self.sanitize(candidateSpeed) ?? stableSpeed
        currentSpeed = nextSpeed
        return nextSpeed
    }

    private static func sanitize(_ speed: Double) -> Double? {
        guard speed.isFinite, speed > 0 else { return nil }
        return speed
    }
}
