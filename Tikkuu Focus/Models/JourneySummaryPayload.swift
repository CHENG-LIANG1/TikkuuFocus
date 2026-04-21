//
//  JourneySummaryPayload.swift
//  Tikkuu Focus
//
//  Created by Tikkuu on 2026/2/11.
//

import Foundation
import WeatherKit

struct JourneySummaryPayload: Identifiable {
    let id: UUID
    let session: JourneySession
    let discoveredPOIs: [DiscoveredPOI]
    let weatherCondition: String
    let isDaytime: Bool
    let progress: Double
    let isCompleted: Bool
    let actualDuration: TimeInterval
    let attribution: WeatherAttribution?

    init(
        id: UUID = UUID(),
        session: JourneySession,
        discoveredPOIs: [DiscoveredPOI],
        weatherCondition: String,
        isDaytime: Bool,
        progress: Double,
        isCompleted: Bool,
        actualDuration: TimeInterval,
        attribution: WeatherAttribution? = nil
    ) {
        self.id = id
        self.session = session
        self.discoveredPOIs = discoveredPOIs
        self.weatherCondition = weatherCondition
        self.isDaytime = isDaytime
        self.progress = progress
        self.isCompleted = isCompleted
        self.actualDuration = actualDuration
        self.attribution = attribution
    }
}

extension JourneySummaryPayload: Equatable {
    static func == (lhs: JourneySummaryPayload, rhs: JourneySummaryPayload) -> Bool {
        lhs.id == rhs.id
    }
}
