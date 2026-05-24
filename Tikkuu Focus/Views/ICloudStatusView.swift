//
//  ICloudStatusView.swift
//  Tikkuu Focus
//

import SwiftUI
import SwiftData
import CloudKit

struct ICloudStatusView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var settings = AppSettings.shared
    @State private var accountStatus: CKAccountStatus = .couldNotDetermine
    @State private var journeyCount: Int = 0
    @State private var locationCount: Int = 0
    @State private var isChecking = false

    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedGradientBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Sync Toggle
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill((settings.isICloudSyncEnabled ? Color.green : Color.secondary).opacity(0.2))
                                    .frame(width: 44, height: 44)

                                Image(systemName: "icloud")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(settings.isICloudSyncEnabled ? .green : .secondary)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(L("icloud.status.sync"))
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.primary)

                                Text(settings.isICloudSyncEnabled ? L("icloud.status.on") : L("icloud.status.off"))
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(settings.isICloudSyncEnabled ? .green : .secondary)
                            }

                            Spacer()

                            Toggle("", isOn: Binding(
                                get: { settings.isICloudSyncEnabled },
                                set: { newValue in
                                    settings.isICloudSyncEnabled = newValue
                                }
                            ))
                            .labelsHidden()
                            .tint(Color.green)
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(Color.clear)
                                .glassCard(cornerRadius: 20)
                        )

                        // Account Status
                        statusCard(
                            icon: "person.fill",
                            title: L("icloud.status.account"),
                            value: accountStatusText,
                            color: accountStatusColor
                        )

                        // Local Data Count
                        statusCard(
                            icon: "doc.text.fill",
                            title: L("icloud.status.local.data"),
                            value: "\(journeyCount) \(L("icloud.status.journeys")) · \(locationCount) \(L("icloud.status.locations"))",
                            color: .blue
                        )


                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle(L("icloud.status.title"))
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
        .onAppear {
            refreshStatus()
        }
    }

    private var accountStatusText: String {
        switch accountStatus {
        case .available:
            return L("icloud.status.available")
        case .noAccount:
            return L("icloud.status.noaccount")
        case .restricted:
            return L("icloud.status.restricted")
        case .couldNotDetermine:
            return L("icloud.status.unknown")
        default:
            return L("icloud.status.unknown")
        }
    }

    private var accountStatusColor: Color {
        switch accountStatus {
        case .available:
            return .green
        case .noAccount, .restricted:
            return .orange
        case .couldNotDetermine:
            return .secondary
        default:
            return .secondary
        }
    }

    private func statusCard(icon: String, title: String, value: String, color: Color) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)

                Text(value)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(color)
            }

            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.clear)
                .glassCard(cornerRadius: 20)
        )
    }

    private func refreshStatus() {
        isChecking = true

        // Check CloudKit account status
        let container = CKContainer(identifier: "iCloud.roam_focus")
        container.accountStatus { status, _ in
            DispatchQueue.main.async {
                self.accountStatus = status
                self.isChecking = false
            }
        }

        // Count local records
        do {
            let journeyDescriptor = FetchDescriptor<JourneyRecord>()
            self.journeyCount = try modelContext.fetchCount(journeyDescriptor)

            let locationDescriptor = FetchDescriptor<SavedLocation>()
            self.locationCount = try modelContext.fetchCount(locationDescriptor)
        } catch {
            print("Failed to count records: \(error)")
        }
    }
}

#Preview {
    ICloudStatusView()
}
