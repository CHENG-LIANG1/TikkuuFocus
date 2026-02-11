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
    @State private var refreshID = UUID()
    @State private var showClearDataStep1 = false
    @State private var showClearDataStep2 = false
    @State private var clearDataConfirmationText = ""

    private let requiredClearPhrase = "确认清除数据"
    
    var body: some View {
        NavigationView {
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
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L("common.done")) {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .id(refreshID)
        .preferredColorScheme(settings.currentColorScheme)
        .sheet(isPresented: $showAbout) {
            NavigationStack {
                AboutView()
                    .navigationTitle(L("settings.about"))
                    .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
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
        .sheet(isPresented: $showPrivacyPolicy) {
            PrivacyPolicyView()
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
            Text("\(L("settings.data.clear.confirm2.message"))\n\"\(requiredClearPhrase)\"")
        }
        .onChange(of: showClearDataStep2) { _, isPresented in
            if !isPresented {
                clearDataConfirmationText = ""
            }
        }
        .onChange(of: settings.selectedLanguage) { _, _ in
            refreshID = UUID()
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
        .glassCard(cornerRadius: 20)
    }
    
    // MARK: - Language Options
    
    private var languageOptions: some View {
        VStack(spacing: 12) {
            ModernOptionRow(
                title: L("settings.language.system"),
                isSelected: settings.selectedLanguage == "system"
            ) {
                HapticManager.selection()
                withAnimation {
                    settings.selectedLanguage = "system"
                }
            }
            
            ModernOptionRow(
                title: "English",
                isSelected: settings.selectedLanguage == "en"
            ) {
                HapticManager.selection()
                withAnimation {
                    settings.selectedLanguage = "en"
                }
            }
            
            ModernOptionRow(
                title: "简体中文",
                isSelected: settings.selectedLanguage == "zh-Hans"
            ) {
                HapticManager.selection()
                withAnimation {
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
            ModernActionRow(
                title: L("settings.data.icloud"),
                subtitle: L("settings.data.icloud.subtitle"),
                icon: "icloud"
            ) {
                // Reserved for future iCloud sync settings.
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
    let title: String
    var icon: String? = nil
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isSelected ? .white : .secondary)
                        .frame(width: 24)
                }
                
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isSelected ? .white : .primary)
                
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
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? 
                        AnyShapeStyle(LinearGradient(
                            colors: [
                                Color(red: 0.3, green: 0.5, blue: 0.8),
                                Color(red: 0.5, green: 0.3, blue: 0.7)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )) : 
                        AnyShapeStyle(Color(uiColor: .secondarySystemBackground).opacity(0.5))
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.clear : Color(uiColor: .separator).opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Modern Action Row

struct ModernActionRow: View {
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
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.3, green: 0.5, blue: 0.8),
                                Color(red: 0.5, green: 0.3, blue: 0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
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
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(uiColor: .secondarySystemBackground).opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(uiColor: .separator).opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    SettingsView()
}
