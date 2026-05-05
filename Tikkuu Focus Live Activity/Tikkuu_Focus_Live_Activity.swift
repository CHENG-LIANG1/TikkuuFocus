//
//  Tikkuu_Focus_Live_Activity.swift
//  Tikkuu Focus Live Activity
//

import ActivityKit
import Foundation
import SwiftUI
import WidgetKit

struct TikkuuFocusLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusTimerActivityAttributes.self) { context in
            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    transportIcon(symbolName: context.state.transportSymbolName, size: 30)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(context.state.isPaused ? "已暂停" : "专注进行中")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                        Text(context.state.isPaused ? "点击灵动岛返回并继续" : "保持专注，旅程正在推进")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }

                    Spacer(minLength: 0)

                    timeView(for: context.state)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                }

                ProgressView(value: progress(for: context.state))
                    .progressViewStyle(.linear)
                    .tint(context.state.isPaused ? .orange : .blue)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    expandedIconBadge(
                        symbolName: context.state.transportSymbolName,
                        tint: context.state.isPaused ? .orange : .blue
                    )
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(spacing: 3) {
                        progressRing(
                            progress: progress(for: context.state),
                            size: 28,
                            lineWidth: 3,
                            tint: context.state.isPaused ? .orange : .blue
                        )
                        Text("\(Int(progress(for: context.state) * 100))%")
                            .font(.system(size: 9, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    .frame(width: 36)
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 2) {
                        Text("剩余时间")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.secondary)
                        timeView(for: context.state)
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .lineLimit(1)
                            .minimumScaleFactor(0.55)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 7) {
                        HStack(spacing: 6) {
                            Image(systemName: context.state.isPaused ? "pause.circle.fill" : "bolt.circle.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(context.state.isPaused ? .orange : .blue)
                            Text(context.state.isPaused ? "已暂停" : "专注进行中")
                                .font(.caption.weight(.semibold))
                            Spacer(minLength: 8)
                            Text(expandedMessage(for: context.state))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }

                        progressBar(
                            progress: progress(for: context.state),
                            tint: context.state.isPaused ? .orange : .blue
                        )
                    }
                    .padding(.horizontal, 14)
                }
            } compactLeading: {
                transportIcon(symbolName: context.state.transportSymbolName, size: 16)
            } compactTrailing: {
                progressRing(
                    progress: progress(for: context.state),
                    size: 17,
                    lineWidth: 2,
                    tint: context.state.isPaused ? .orange : .blue
                )
            } minimal: {
                progressRing(
                    progress: progress(for: context.state),
                    size: 20,
                    lineWidth: 2.2,
                    tint: context.state.isPaused ? .orange : .blue
                )
            }
            .keylineTint(context.state.isPaused ? .orange : .blue)
        }
    }

    private func timeView(for state: FocusTimerActivityAttributes.ContentState) -> some View {
        Group {
            if state.isPaused {
                Text(timeString(from: state.remainingSeconds))
            } else {
                Text(timerInterval: Date()...state.endTime, countsDown: true)
            }
        }
    }

    private func transportIcon(symbolName: String, size: CGFloat) -> some View {
        Image(systemName: symbolName)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .fontWeight(.semibold)
    }

    private func expandedIconBadge(symbolName: String, tint: Color) -> some View {
        transportIcon(symbolName: symbolName, size: 18)
            .foregroundStyle(tint)
            .frame(width: 34, height: 34)
            .background(tint.opacity(0.18), in: Circle())
    }

    private func progress(for state: FocusTimerActivityAttributes.ContentState) -> Double {
        let total = max(Double(state.totalSeconds), 1)
        let remaining: Double

        if state.isPaused {
            remaining = Double(max(state.remainingSeconds, 0))
        } else {
            remaining = max(state.endTime.timeIntervalSinceNow, 0)
        }

        return min(max(1 - remaining / total, 0), 1)
    }

    @ViewBuilder
    private func progressRing(progress: Double, size: CGFloat, lineWidth: CGFloat, tint: Color) -> some View {
        ZStack {
            Circle()
                .stroke(tint.opacity(0.22), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: size, height: size)
        .accessibilityLabel("进度")
        .accessibilityValue(Text("\(Int(progress * 100))%"))
    }

    private func progressBar(progress: Double, tint: Color) -> some View {
        GeometryReader { proxy in
            let width = max(proxy.size.width * progress, progress > 0 ? 4 : 0)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(tint.opacity(0.2))
                Capsule()
                    .fill(tint)
                    .frame(width: width)
            }
        }
        .frame(height: 6)
        .accessibilityLabel("进度")
        .accessibilityValue(Text("\(Int(progress * 100))%"))
    }

    private func expandedMessage(for state: FocusTimerActivityAttributes.ContentState) -> String {
        state.isPaused ? "点击返回继续旅程" : "保持节奏，旅程推进中"
    }

    private func timeString(from seconds: Int) -> String {
        let clamped = max(seconds, 0)
        let mins = clamped / 60
        let secs = clamped % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

@main
struct TikkuuFocusLiveActivityBundle: WidgetBundle {
    var body: some Widget {
        TikkuuFocusLiveActivity()
    }
}
