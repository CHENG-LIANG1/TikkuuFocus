//
//  FocusGoal.swift
//  Tikkuu Focus
//
//  Created by Codex on 2026/6/24.
//

import SwiftUI
import Combine

/// Built-in focus goal options.
enum FocusGoalOption: String, CaseIterable, Identifiable {
    case `default`
    case work
    case study
    case exercise

    var id: String { rawValue }

    var localizedName: String {
        L("focus.goal.\(rawValue)")
    }

    var iconName: String {
        switch self {
        case .default: return "sparkle"
        case .work: return "briefcase.fill"
        case .study: return "book.fill"
        case .exercise: return "figure.run"
        }
    }
}

/// A selectable focus goal — either a built-in option or a user-added custom goal.
struct FocusGoal: Identifiable, Equatable {
    enum Kind: Equatable {
        case builtin(FocusGoalOption)
        case custom
    }

    let kind: Kind
    /// Custom title. Ignored for built-in goals.
    let title: String

    init(kind: Kind, title: String = "") {
        self.kind = kind
        self.title = title
    }

    var id: String {
        switch kind {
        case .builtin(let option): return "builtin:\(option.rawValue)"
        case .custom: return "custom:\(title)"
        }
    }

    var displayName: String {
        switch kind {
        case .builtin(let option): return option.localizedName
        case .custom: return title
        }
    }

    var iconName: String {
        switch kind {
        case .builtin(let option): return option.iconName
        case .custom: return "target"
        }
    }

    var isCustom: Bool {
        if case .custom = kind { return true }
        return false
    }

    var isDefault: Bool {
        if case .builtin(.default) = kind { return true }
        return false
    }
}

/// Persists the user's focus goals (built-in + custom) and the current selection.
final class FocusGoalStore: ObservableObject {
    static let shared = FocusGoalStore()

    /// Maximum number of user-added custom goals.
    static let maxCustomGoals = 20

    private enum Keys {
        static let custom = "focusGoals.custom"
        static let selected = "focusGoals.selectedID"
    }

    @Published private(set) var customGoals: [String]
    @Published var selectedID: String {
        didSet {
            guard selectedID != oldValue else { return }
            UserDefaults.standard.set(selectedID, forKey: Keys.selected)
        }
    }

    private init() {
        self.customGoals = UserDefaults.standard.stringArray(forKey: Keys.custom) ?? []
        self.selectedID = UserDefaults.standard.string(forKey: Keys.selected)
            ?? FocusGoal(kind: .builtin(.default)).id
    }

    /// Built-in goals followed by custom goals.
    var allGoals: [FocusGoal] {
        FocusGoalOption.allCases.map { FocusGoal(kind: .builtin($0)) }
            + customGoals.map { FocusGoal(kind: .custom, title: $0) }
    }

    var selectedGoal: FocusGoal {
        allGoals.first { $0.id == selectedID } ?? FocusGoal(kind: .builtin(.default))
    }

    /// Name shown in the home card / active journey.
    var selectedDisplayName: String {
        selectedGoal.displayName
    }

    /// Value stored on the session — empty for the default goal so existing
    /// records keep falling back to the localized "Default" label.
    var selectedSessionValue: String {
        selectedGoal.isDefault ? "" : selectedGoal.displayName
    }

    var canAddMore: Bool {
        customGoals.count < Self.maxCustomGoals
    }

    func select(_ goal: FocusGoal) {
        selectedID = goal.id
    }

    /// Adds a custom goal (deduplicated) and selects it. Returns false if it
    /// could not be added (empty, limit reached). Selects an existing match.
    @discardableResult
    func addCustomGoal(_ rawTitle: String) -> Bool {
        let title = FocusGoalFormatter.limitedCustomText(
            rawTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        guard !title.isEmpty else { return false }

        if let existing = allGoals.first(where: { $0.displayName == title }) {
            selectedID = existing.id
            return false
        }

        guard canAddMore else { return false }

        customGoals.append(title)
        persistCustom()
        selectedID = FocusGoal(kind: .custom, title: title).id
        return true
    }

    func deleteCustomGoal(_ goal: FocusGoal) {
        guard goal.isCustom else { return }
        customGoals.removeAll { $0 == goal.title }
        persistCustom()
        if selectedID == goal.id {
            selectedID = FocusGoal(kind: .builtin(.default)).id
        }
    }

    private func persistCustom() {
        UserDefaults.standard.set(customGoals, forKey: Keys.custom)
    }
}

enum FocusGoalFormatter {
    static let maxWeightedLength = 12

    static func limitedCustomText(_ text: String) -> String {
        var result = ""
        var total = 0

        for scalar in text.unicodeScalars {
            let weight = isCJK(scalar) ? 2 : 1
            guard total + weight <= maxWeightedLength else { break }
            result.unicodeScalars.append(scalar)
            total += weight
        }

        return result
    }

    private static func isCJK(_ scalar: UnicodeScalar) -> Bool {
        switch scalar.value {
        case 0x3400...0x4DBF, 0x4E00...0x9FFF, 0xF900...0xFAFF:
            return true
        default:
            return false
        }
    }
}
