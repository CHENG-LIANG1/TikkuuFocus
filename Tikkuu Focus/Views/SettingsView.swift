//
//  SettingsView.swift
//  Tikkuu Focus
//
//  Created by Tikkuu on 2026/2/8.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \JourneyRecord.startTime, order: .reverse) private var records: [JourneyRecord]
    @ObservedObject private var settings = AppSettings.shared
    @State private var showAbout = false
    @State private var showOnboarding = false
    @State private var showPrivacyPolicy = false
    @State private var showClearDataStep1 = false
    @State private var showClearDataStep2 = false
    @State private var showClearDataSuccess = false
    @State private var showAvatarSettings = false
    @State private var showAcknowledgements = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Use same animated gradient as main app
                AnimatedGradientBackground()
                
                // Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 34) {
                        // Preferences Section
                        modernSection(
                            title: L("settings.preferences"),
                            tint: Color(red: 0.38, green: 0.57, blue: 0.96)
                        ) {
                            preferencesOptions
                        }

                        // Support & About Section
                        modernSection(
                            title: L("settings.supportAbout"),
                            tint: Color(red: 0.62, green: 0.46, blue: 0.94)
                        ) {
                            supportAndAboutOptions
                        }

                        // Data Management Section
                        modernSection(
                            title: L("settings.data"),
                            tint: Color(red: 0.93, green: 0.39, blue: 0.42)
                        ) {
                            dataManagementOptions
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 28)
                    .padding(.bottom, 56)
                }
            }
            .navigationTitle(L("settings.title"))
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
        }
        .preferredColorScheme(settings.currentColorScheme)
        .sheet(isPresented: $showAbout) {
            NavigationStack {
                AboutView()
                    .navigationTitle(L("settings.about"))
                    .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button(L("common.done")) {
                                showAbout = false
                            }
                            .fontWeight(.semibold)
                        }
                    }
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView(canDismiss: true)
        }
        .fullScreenCover(isPresented: $showPrivacyPolicy) {
            PrivacyPolicyView {
                showPrivacyPolicy = false
            }
        }
        .sheet(isPresented: $showAvatarSettings) {
            TransportAvatarSettingsView()
        }
        .sheet(isPresented: $showAcknowledgements) {
            AcknowledgementsView()
        }
        .alert(L("settings.data.clear.confirm1.title"), isPresented: $showClearDataStep1) {
            Button(L("common.cancel"), role: .cancel) {}
            Button(L("settings.data.clear.confirm1.action"), role: .destructive) {
                showClearDataStep2 = true
            }
        } message: {
            Text(L("settings.data.clear.confirm1.message"))
        }
        .alert(L("settings.data.clear.confirm2.title"), isPresented: $showClearDataStep2) {
            Button(L("common.cancel"), role: .cancel) {}
            Button(L("settings.data.clear.confirm2.action"), role: .destructive) {
                Task {
                    await clearAllData()
                }
            }
        } message: {
            Text(L("settings.data.clear.confirm2.message"))
        }
        .alert(L("settings.data.clear.success.title"), isPresented: $showClearDataSuccess) {
            Button(L("common.ok")) {}
        } message: {
            Text(L("settings.data.clear.success.message.local"))
        }
    }
    
    // MARK: - Modern Section
    
    private func modernSection<Content: View>(
        title: String,
        tint: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .tracking(0.6)
                .foregroundStyle(tint.opacity(0.92))
                .padding(.leading, 18)

            VStack(spacing: 0) {
                content()
            }
            .padding(8)
            .background(sectionBackground(tint: tint))
        }
    }

    private func sectionBackground(tint: Color) -> some View {
        Color.clear
            .glassCard(cornerRadius: 30, tintColor: tint)
            .overlay {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.18), Color.white.opacity(0.03)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.7
                    )
            }
    }
    
    // MARK: - Preferences Options

    private var preferencesOptions: some View {
        VStack(spacing: 0) {
            LanguagePickerRow()
            SettingsRowDivider()

            ModernActionRow(
                title: L("settings.avatar.configure"),
                subtitle: L("settings.avatar.configure.subtitle"),
                icon: "person.crop.circle.fill",
                tint: .purple,
                showChevron: true
            ) {
                HapticManager.light()
                showAvatarSettings = true
            }
            SettingsRowDivider()

            ModernToggleRow(
                title: L("settings.strictMode"),
                subtitle: L("settings.strictMode.subtitle"),
                icon: "lock.circle.fill",
                tint: .orange,
                isOn: $settings.isStrictModeEnabled
            )
            SettingsRowDivider()

            ModernToggleRow(
                title: L("settings.hapticFeedback"),
                subtitle: L("settings.hapticFeedback.subtitle"),
                icon: "waveform",
                tint: .pink,
                isOn: $settings.isHapticFeedbackEnabled
            )
        }
    }

    // MARK: - Support & About Options

    private var supportAndAboutOptions: some View {
        VStack(spacing: 0) {
            ModernActionRow(
                title: L("settings.tutorial"),
                icon: "book.fill",
                tint: .blue,
                showChevron: true
            ) {
                HapticManager.light()
                showOnboarding = true
            }
            SettingsRowDivider()

            ModernActionRow(
                title: L("settings.contact"),
                subtitle: "madfool@icloud.com",
                icon: "envelope.fill",
                tint: .green,
                showChevron: true
            ) {
                HapticManager.light()
                if let url = URL(string: "mailto:madfool@icloud.com") {
                    UIApplication.shared.open(url)
                }
            }
            SettingsRowDivider()

            ModernActionRow(
                title: L("settings.privacy"),
                icon: "hand.raised.fill",
                tint: .indigo,
                showChevron: true
            ) {
                HapticManager.light()
                showPrivacyPolicy = true
            }
            SettingsRowDivider()

            ModernActionRow(
                title: L("settings.about.app"),
                icon: "info.circle.fill",
                tint: .teal,
                showChevron: true
            ) {
                HapticManager.light()
                showAbout = true
            }
            SettingsRowDivider()

            ModernActionRow(
                title: L("settings.acknowledgements"),
                icon: "heart.text.square.fill",
                tint: .pink,
                showChevron: true
            ) {
                HapticManager.light()
                showAcknowledgements = true
            }
            SettingsRowDivider()

            ModernActionRow(
                title: L("settings.version"),
                subtitle: AppInfo.version,
                icon: "doc.text.fill",
                tint: .gray
            ) {}
        }
    }

    // MARK: - Data Management Options

    private var dataManagementOptions: some View {
        VStack(spacing: 0) {
            ModernActionRow(
                title: L("settings.data.clear"),
                subtitle: L("settings.data.clear.subtitle"),
                icon: "trash.fill",
                tint: .red,
                showChevron: true
            ) {
                HapticManager.light()
                showClearDataStep1 = true
            }
        }
    }

    private func clearAllData() async {
        // 1. Delete local JourneyRecords
        for record in records {
            modelContext.delete(record)
        }
        
        // 2. Delete local SavedLocations
        let savedLocationsDescriptor = FetchDescriptor<SavedLocation>()
        if let savedLocations = try? modelContext.fetch(savedLocationsDescriptor) {
            for location in savedLocations {
                modelContext.delete(location)
            }
        }

        let avatarSettingsDescriptor = FetchDescriptor<TransportAvatarSettings>()
        if let avatarSettings = try? modelContext.fetch(avatarSettingsDescriptor) {
            for setting in avatarSettings {
                modelContext.delete(setting)
            }
        }
        
        try? modelContext.save()
        WidgetSnapshotStore.shared.refreshSnapshot(using: modelContext, settings: settings)

        settings.hasCompletedFirstJourney = false
        settings.hasSeenFirstJourneyGuide = false

        HapticManager.success()
        showClearDataSuccess = true
    }
}

// MARK: - Settings Icon

/// Colored rounded-square icon container (Grow / iOS Settings style).
struct SettingsIcon: View {
    let systemName: String
    let tint: Color

    var body: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [tint.opacity(0.26), tint.opacity(0.12)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 36, height: 36)
            .overlay {
                Image(systemName: systemName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(tint)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(tint.opacity(0.20), lineWidth: 0.8)
            }
    }
}

struct SettingsRowDivider: View {
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.02),
                        Color.white.opacity(0.10),
                        Color.white.opacity(0.02)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 1)
            .padding(.horizontal, 18)
    }
}

// MARK: - Modern Action Row

struct ModernActionRow: View {
    let title: String
    var subtitle: String? = nil
    var icon: String
    var tint: Color = .green
    var showChevron: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                SettingsIcon(systemName: icon, tint: tint)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.secondary)
                            .lineSpacing(2)
                    }
                }

                Spacer()

                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color.secondary.opacity(0.65))
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.05))
                        )
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 17)
            .contentShape(Rectangle())
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Modern Toggle Row

struct ModernToggleRow: View {
    let title: String
    var subtitle: String? = nil
    let icon: String
    var tint: Color = .green
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 16) {
            SettingsIcon(systemName: icon, tint: tint)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.secondary)
                        .lineSpacing(2)
                }
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Color.green)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 17)
    }
}

// MARK: - Language Picker Row

struct LanguagePickerRow: View {
    @ObservedObject private var settings = AppSettings.shared

    private var displayName: String {
        switch settings.selectedLanguage {
        case "en": return "English"
        case "zh-Hans": return "简体中文"
        default: return L("settings.language.system")
        }
    }

    var body: some View {
        Menu {
            Button(L("settings.language.system")) {
                HapticManager.selection()
                settings.selectedLanguage = "system"
            }
            Button("English") {
                HapticManager.selection()
                settings.selectedLanguage = "en"
            }
            Button("简体中文") {
                HapticManager.selection()
                settings.selectedLanguage = "zh-Hans"
            }
        } label: {
            HStack(spacing: 16) {
                SettingsIcon(systemName: "globe", tint: .blue)

                VStack(alignment: .leading, spacing: 4) {
                    Text(L("settings.language"))
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)

                    Text(L("settings.language.system"))
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.secondary.opacity(0.8))
                }

                Spacer()

                Text(displayName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.secondary)

                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color.secondary.opacity(0.6))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 17)
            .contentShape(Rectangle())
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

#Preview {
    SettingsView()
}
