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
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \JourneyRecord.startTime, order: .reverse) private var records: [JourneyRecord]
    @ObservedObject private var settings = AppSettings.shared
    @State private var showAbout = false
    @State private var showOnboarding = false
    @State private var showPrivacyPolicy = false
    @State private var showClearDataStep1 = false
    @State private var showClearDataStep2 = false
    @State private var clearDataConfirmationText = ""
    
    private var requiredClearPhrase: String {
        L("settings.data.clear.confirmPhrase")
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Use same animated gradient as main app
                AnimatedGradientBackground()
                
                // Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Language Section
                        modernSection(
                            icon: "globe",
                            title: L("settings.language"),
                            gradient: LinearGradient(
                                colors: [Color.blue, Color.purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        ) {
                            languageOptions
                        }

                        // Data Management Section
                        modernSection(
                            icon: "externaldrive.fill.badge.person.crop",
                            title: L("settings.data"),
                            gradient: LinearGradient(
                                colors: [Color.orange, Color.red],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        ) {
                            dataManagementOptions
                        }
                        
                        // Support Section
                        modernSection(
                            icon: "heart.fill",
                            title: L("settings.support"),
                            gradient: LinearGradient(
                                colors: [Color.red, Color.orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        ) {
                            supportOptions
                        }
                        
                        // About Section
                        modernSection(
                            icon: "info.circle.fill",
                            title: L("settings.about"),
                            gradient: LinearGradient(
                                colors: [Color.green, Color.teal],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        ) {
                            aboutOptions
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
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
            OnboardingView(canDismiss: false)
        }
        .fullScreenCover(isPresented: $showPrivacyPolicy) {
            PrivacyPolicyView {
                showPrivacyPolicy = false
            }
        }
        .alert(L("settings.data.clear.confirm1.title"), isPresented: $showClearDataStep1) {
            Button(L("common.cancel"), role: .cancel) {}
            Button(L("settings.data.clear.confirm1.action"), role: .destructive) {
                clearDataConfirmationText = ""
                showClearDataStep2 = true
            }
        } message: {
            Text(L("settings.data.clear.confirm1.message"))
        }
        .alert(L("settings.data.clear.confirm2.title"), isPresented: $showClearDataStep2) {
            TextField(L("settings.data.clear.inputPlaceholder"), text: $clearDataConfirmationText)
            Button(L("common.cancel"), role: .cancel) {}
            Button(L("settings.data.clear.confirm2.action"), role: .destructive) {
                clearAllData()
            }
            .disabled(clearDataConfirmationText.trimmingCharacters(in: .whitespacesAndNewlines) != requiredClearPhrase)
        } message: {
            Text(
                "\(L("settings.data.clear.confirm2.message"))\n\(String(format: L("settings.data.clear.confirm2.guide"), requiredClearPhrase))"
            )
        }
        .onChange(of: showClearDataStep2) { _, isPresented in
            if !isPresented {
                clearDataConfirmationText = ""
            }
        }
    }
    
    // MARK: - Modern Section
    
    private func modernSection<Content: View>(
        icon: String,
        title: String,
        gradient: LinearGradient,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(gradient.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(gradient)
                }
                
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
            }
            
            VStack(spacing: 0) {
                content()
            }
        }
        .padding(20)
        .background(sectionBackground)
    }

    @ViewBuilder
    private var sectionBackground: some View {
        Color.clear
            .glassCard(cornerRadius: 20)
    }
    
    // MARK: - Language Options

    private var appearanceOptions: some View {
        EmptyView()
    }

    private var themeOptions: some View {
        EmptyView()
    }

    private var languageOptions: some View {
        VStack(spacing: 12) {
            ModernOptionRow(
                title: L("settings.language.system"),
                isSelected: settings.selectedLanguage == "system"
            ) {
                HapticManager.selection()
                if settings.selectedLanguage != "system" {
                    settings.selectedLanguage = "system"
                }
            }
            
            ModernOptionRow(
                title: "English",
                isSelected: settings.selectedLanguage == "en"
            ) {
                HapticManager.selection()
                if settings.selectedLanguage != "en" {
                    settings.selectedLanguage = "en"
                }
            }
            
            ModernOptionRow(
                title: "简体中文",
                isSelected: settings.selectedLanguage == "zh-Hans"
            ) {
                HapticManager.selection()
                if settings.selectedLanguage != "zh-Hans" {
                    settings.selectedLanguage = "zh-Hans"
                }
            }
        }
    }
    
    // MARK: - Support Options
    
    private var supportOptions: some View {
        VStack(spacing: 12) {
            ModernActionRow(
                title: L("settings.tutorial"),
                icon: "book.fill",
                showChevron: true
            ) {
                HapticManager.light()
                showOnboarding = true
            }
            
            ModernActionRow(
                title: L("settings.contact"),
                subtitle: "madfool@icloud.com",
                icon: "envelope.fill",
                showChevron: true
            ) {
                HapticManager.light()
                if let url = URL(string: "mailto:madfool@icloud.com") {
                    UIApplication.shared.open(url)
                }
            }
            
            ModernActionRow(
                title: L("settings.privacy"),
                icon: "hand.raised.fill",
                showChevron: true
            ) {
                HapticManager.light()
                showPrivacyPolicy = true
            }
        }
    }
    
    // MARK: - About Options
    
    private var aboutOptions: some View {
        VStack(spacing: 12) {
            ModernActionRow(
                title: L("settings.about.app"),
                icon: "info.circle.fill",
                showChevron: true
            ) {
                HapticManager.light()
                showAbout = true
            }
            
            ModernActionRow(
                title: L("settings.version"),
                subtitle: AppInfo.version,
                icon: "doc.text.fill"
            ) {
                // No action
            }
        }
    }

    // MARK: - Data Management Options

    private var dataManagementOptions: some View {
        VStack(spacing: 12) {
            if AppConfig.isICloudSyncEntryEnabled {
                ModernActionRow(
                    title: L("settings.data.icloud"),
                    subtitle: L("settings.data.icloud.subtitle"),
                    icon: "icloud"
                ) {
                    // Reserved for future iCloud sync settings.
                }
            }

            ModernActionRow(
                title: L("settings.data.clear"),
                subtitle: L("settings.data.clear.subtitle"),
                icon: "trash.fill",
                showChevron: true
            ) {
                HapticManager.light()
                showClearDataStep1 = true
            }
        }
    }

    private func clearAllData() {
        for record in records {
            modelContext.delete(record)
        }
        try? modelContext.save()

        settings.hasCompletedFirstJourney = false
        settings.hasSeenFirstJourneyGuide = false

        HapticManager.success()
    }
}

// MARK: - Modern Option Row

struct ModernOptionRow: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var settings = AppSettings.shared
    let title: String
    var subtitle: String? = nil
    var icon: String? = nil
    let isSelected: Bool
    let action: () -> Void

    private var selectedTextColor: Color {
        false ? Color(red: 0.20, green: 0.24, blue: 0.34) : .white
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isSelected ? selectedTextColor : .secondary)
                        .frame(width: 24)
                }
                
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isSelected ? selectedTextColor : .primary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(isSelected ? selectedTextColor.opacity(0.82) : .secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.green, Color.teal],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(optionRowBackground)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    @ViewBuilder
    private var optionRowBackground: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(Color.clear)
            .insetSurface(cornerRadius: 20, isActive: isSelected)
    }
}

// MARK: - Modern Action Row

struct ModernActionRow: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var settings = AppSettings.shared
    let title: String
    var subtitle: String? = nil
    var icon: String
    var showChevron: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(GradientStyles.primaryGradient)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(actionRowBackground)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    @ViewBuilder
    private var actionRowBackground: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(Color.clear)
            .insetSurface(cornerRadius: 20, isActive: false)
    }
}

#Preview {
    SettingsView()
}
