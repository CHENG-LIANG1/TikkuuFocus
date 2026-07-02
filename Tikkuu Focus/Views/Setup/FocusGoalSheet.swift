//
//  FocusGoalSheet.swift
//  Tikkuu Focus
//
//  Created by Codex on 2026/6/24.
//

import SwiftUI

/// Sheet for choosing or managing the focus goal of the next journey.
struct FocusGoalSheet: View {
    @ObservedObject var store: FocusGoalStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var isAddingGoal = false
    @State private var newGoalText = ""
    @FocusState private var addFieldFocused: Bool

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(store.allGoals) { goal in
                            FocusGoalCell(
                                goal: goal,
                                isSelected: store.selectedID == goal.id,
                                onSelect: {
                                    HapticManager.selection()
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.78)) {
                                        store.select(goal)
                                    }
                                },
                                onDelete: goal.isCustom ? {
                                    HapticManager.light()
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        store.deleteCustomGoal(goal)
                                    }
                                } : nil
                            )
                        }

                        if store.canAddMore {
                            addGoalCell
                        }
                    }

                    Text(
                        String(
                            format: L("focus.goal.count"),
                            store.customGoals.count,
                            FocusGoalStore.maxCustomGoals
                        )
                    )
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(20)
            }
            .background(AnimatedGradientBackground().ignoresSafeArea())
            .navigationTitle(L("focus.goal.sheet.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L("common.done")) {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .alert(L("focus.goal.add.title"), isPresented: $isAddingGoal) {
                TextField(L("focus.goal.custom.placeholder"), text: Binding(
                    get: { newGoalText },
                    set: { newGoalText = FocusGoalFormatter.limitedCustomText($0) }
                ))
                Button(L("common.cancel"), role: .cancel) {
                    newGoalText = ""
                }
                Button(L("focus.goal.add.confirm")) {
                    store.addCustomGoal(newGoalText)
                    newGoalText = ""
                }
            } message: {
                Text(L("focus.goal.add.message"))
            }
        }
        .preferredColorScheme(.dark)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var addGoalCell: some View {
        Button {
            HapticManager.light()
            newGoalText = ""
            isAddingGoal = true
        } label: {
            VStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 22, weight: .semibold))
                Text(L("focus.goal.add.title"))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundColor(.primary.opacity(0.85))
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(
                        style: StrokeStyle(lineWidth: 1.4, dash: [6, 5])
                    )
                    .foregroundColor(.white.opacity(colorScheme == .dark ? 0.28 : 0.4))
            )
        }
        .buttonStyle(PremiumButtonStyle())
    }
}

// MARK: - Focus Goal Cell

private struct FocusGoalCell: View {
    let goal: FocusGoal
    let isSelected: Bool
    let onSelect: () -> Void
    let onDelete: (() -> Void)?

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 10) {
                Image(systemName: goal.iconName)
                    .font(.system(size: 16, weight: .semibold))

                Text(goal.displayName)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Spacer(minLength: 0)

                if let onDelete {
                    Button(action: onDelete) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(isSelected ? .white.opacity(0.85) : .secondary.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                }
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.95, green: 0.66, blue: 0.20),
                                        Color(red: 0.87, green: 0.42, blue: 0.16)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(Color.white.opacity(0.25), lineWidth: 0.8)
                            )
                            .shadow(color: Color.orange.opacity(0.3), radius: 10, x: 0, y: 5)
                    } else {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.clear)
                            .insetSurface(cornerRadius: 18, isActive: false)
                    }
                }
            )
            .animation(AnimationConfig.snappy, value: isSelected)
        }
        .buttonStyle(PremiumButtonStyle())
    }
}
