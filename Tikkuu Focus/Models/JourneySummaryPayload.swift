//
//  JourneySummaryPayload.swift
//  Tikkuu Focus
//
//  Created by Tikkuu on 2026/2/11.
//

import Foundation

struct JourneySummaryPayload: Identifiable, Equatable {
    let id: UUID
    let session: JourneySession
    let discoveredPOIs: [DiscoveredPOI]
    let weatherCondition: String
    let isDaytime: Bool
    let progress: Double
    let isCompleted: Bool
    let actualDuration: TimeInterval

    init(
        id: UUID = UUID(),
        session: JourneySession,
        discoveredPOIs: [DiscoveredPOI],
        weatherCondition: String,
        isDaytime: Bool,
        progress: Double,
        isCompleted: Bool,
        actualDuration: TimeInterval
    ) {
        self.id = id
        self.session = session
        self.discoveredPOIs = discoveredPOIs
        self.weatherCondition = weatherCondition
        self.isDaytime = isDaytime
        self.progress = progress
        self.isCompleted = isCompleted
        self.actualDuration = actualDuration
    }
}
