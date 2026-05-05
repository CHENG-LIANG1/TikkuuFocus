//
//  FocusLiveActivityManager.swift
//  Tikkuu Focus
//

import ActivityKit
import Foundation

@MainActor
final class FocusLiveActivityManager {
    static let shared = FocusLiveActivityManager()

    private init() {}

    private var currentActivity: Activity<FocusTimerActivityAttributes>?

    func start(session: JourneySession) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        Task {
            await endCurrent(dismissalPolicy: .immediate)

            let remaining = max(Int(ceil(session.endTime.timeIntervalSinceNow)), 0)
            let state = FocusTimerActivityAttributes.ContentState(
                remainingSeconds: remaining,
                isPaused: false,
                endTime: session.endTime,
                totalSeconds: max(Int(ceil(session.duration)), 1),
                transportSymbolName: session.transportMode.iconName
            )
            let attributes = FocusTimerActivityAttributes(sessionID: session.id.uuidString)
            let content = ActivityContent(state: state, staleDate: session.endTime.addingTimeInterval(60))

            do {
                currentActivity = try Activity.request(attributes: attributes, content: content, pushType: nil)
            } catch {
                currentActivity = nil
            }
        }
    }

    func pause(session: JourneySession, remainingTime: TimeInterval) {
        guard let activity = resolveActivity(for: session) else { return }

        Task {
            let remaining = max(Int(ceil(remainingTime)), 0)
            let state = FocusTimerActivityAttributes.ContentState(
                remainingSeconds: remaining,
                isPaused: true,
                endTime: Date().addingTimeInterval(remainingTime),
                totalSeconds: max(Int(ceil(session.duration)), 1),
                transportSymbolName: session.transportMode.iconName
            )
            await activity.update(ActivityContent(state: state, staleDate: nil))
        }
    }

    func resume(session: JourneySession) {
        guard let activity = resolveActivity(for: session) else {
            start(session: session)
            return
        }

        Task {
            let remaining = max(Int(ceil(session.endTime.timeIntervalSinceNow)), 0)
            let state = FocusTimerActivityAttributes.ContentState(
                remainingSeconds: remaining,
                isPaused: false,
                endTime: session.endTime,
                totalSeconds: max(Int(ceil(session.duration)), 1),
                transportSymbolName: session.transportMode.iconName
            )
            await activity.update(ActivityContent(state: state, staleDate: session.endTime.addingTimeInterval(60)))
        }
    }

    func endCurrent(dismissalPolicy: ActivityUIDismissalPolicy = .immediate) async {
        let activities = Activity<FocusTimerActivityAttributes>.activities
        if activities.isEmpty {
            currentActivity = nil
            return
        }

        for activity in activities {
            let state = activity.content.state
            await activity.end(
                ActivityContent(state: state, staleDate: nil),
                dismissalPolicy: dismissalPolicy
            )
        }
        currentActivity = nil
    }

    private func resolveActivity(for session: JourneySession) -> Activity<FocusTimerActivityAttributes>? {
        if let currentActivity, currentActivity.attributes.sessionID == session.id.uuidString {
            return currentActivity
        }

        let activity = Activity<FocusTimerActivityAttributes>.activities.first {
            $0.attributes.sessionID == session.id.uuidString
        }
        currentActivity = activity
        return activity
    }
}
