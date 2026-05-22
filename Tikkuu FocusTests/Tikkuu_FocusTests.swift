//
//  Tikkuu_FocusTests.swift
//  Tikkuu FocusTests
//
//  Created by 梁非凡 on 2026/2/8.
//

import Testing
@testable import Tikkuu_Focus

struct Tikkuu_FocusTests {

    @Test func pausedJourneyKeepsSpeedStableAcrossMultipleTicks() {
        var speedState = JourneySpeedState(transportMode: .driving)
        let initialSpeed = speedState.ensureInitialized(using: { _ in 62.4 })

        #expect(initialSpeed == 62.4)

        for _ in 0..<6 {
            let pausedSpeed = speedState.tickIfNeeded(isPaused: true) { _, currentSpeed in
                currentSpeed + 18
            }
            #expect(pausedSpeed == 62.4)
            #expect(speedState.currentSpeed == 62.4)
        }
    }

    @Test func resumedJourneyContinuesFromFrozenSpeedOnNextActiveTick() {
        var speedState = JourneySpeedState(transportMode: .cycling, initialSpeed: 19.5)

        let pausedSpeed = speedState.tickIfNeeded(isPaused: true) { _, currentSpeed in
            currentSpeed + 4
        }
        #expect(pausedSpeed == 19.5)

        let resumedSpeed = speedState.tickIfNeeded(isPaused: false) { _, currentSpeed in
            currentSpeed + 2.5
        }
        #expect(resumedSpeed == 22.0)
        #expect(speedState.currentSpeed == 22.0)
    }

    @Test func invalidSpeedUpdateFallsBackToLastStableValue() {
        var speedState = JourneySpeedState(transportMode: .walking, initialSpeed: 4.8)

        let invalidSpeed = speedState.tickIfNeeded(isPaused: false) { _, _ in
            .nan
        }
        #expect(invalidSpeed == 4.8)
        #expect(speedState.currentSpeed == 4.8)
    }
}
