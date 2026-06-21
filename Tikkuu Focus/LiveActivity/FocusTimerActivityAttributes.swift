//
//  FocusTimerActivityAttributes.swift
//  Tikkuu Focus
//

import ActivityKit
import Foundation

struct FocusTimerActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var remainingSeconds: Int
        var isPaused: Bool
        var endTime: Date
        var totalSeconds: Int
        var transportSymbolName: String
        var startLocationName: String
        var destinationName: String
    }

    var sessionID: String
}
