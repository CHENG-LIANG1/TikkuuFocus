//
//  TransportAvatarSettingsView.swift
//  Tikkuu Focus
//

import SwiftUI
import SwiftData
import PhotosUI
import UIKit

struct TransportAvatarSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsRecords: [TransportAvatarSettings]

    @State private var pickerItem: PhotosPickerItem?
    @State private var isLoading = false
    @State private var cropSourceImage: UIImage?
    @State private var isShowingCropper = false

    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedGradientBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        previewCard
                        toggleCard
                        pickerCard
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle(L("settings.avatar.title"))
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
        .preferredColorScheme(AppSettings.shared.currentColorScheme)
        .onAppear {
            createSettingsRecordIfNeeded()
            ensureEnabledStateConsistency()
        }
        .onChange(of: pickerItem) { _, newValue in
            guard let item = newValue else { return }
            loadImage(from: item)
        }
        .fullScreenCover(isPresented: $isShowingCropper) {
            if let cropSourceImage {
                AvatarCropperView(
                    image: cropSourceImage,
                    targetSide: 320,
                    compressionQuality: 0.84
                ) { croppedData in
                    applyAvatarImageData(croppedData)
                }
            }
        }
    }

    private var currentSettings: TransportAvatarSettings? {
        settingsRecords.first
    }

    private var previewCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.2))
                    .frame(width: 56, height: 56)

                TransportAvatarView(
                    defaultSymbolName: TransportMode.walking.iconName,
                    settings: currentSettings,
                    size: 48,
                    symbolSize: 22,
                    symbolWeight: .bold,
                    symbolColor: .white,
                    borderColor: Color.white.opacity(0.7),
                    borderWidth: 2
                )
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(L("settings.avatar.preview"))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)

                Text(previewSubtitle)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(20)
        .glassCard(cornerRadius: 20)
    }

    private var toggleCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 44, height: 44)

                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.green)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(L("settings.avatar.useCustom"))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)

                Text(toggleStatusText)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(toggleStatusColor)
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { isEnabled },
                set: { setEnabled($0) }
            ))
            .labelsHidden()
            .tint(Color.green)
            .disabled(currentSettings == nil || currentSettings?.imageData == nil)
        }
        .padding(20)
        .glassCard(cornerRadius: 20)
    }

    private var pickerCard: some View {
        PhotosPicker(selection: $pickerItem, matching: .images) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.cyan.opacity(0.2))
                        .frame(width: 44, height: 44)

                    if isLoading {
                        ProgressView()
                            .tint(Color.cyan)
                    } else {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.cyan)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(pickerTitle)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.primary)

                    Text(L("settings.avatar.choose.subtitle"))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(20)
            .glassCard(cornerRadius: 20)
        }
        .disabled(isLoading)
    }

    private var previewSubtitle: String {
        if currentSettings?.imageData == nil {
            return L("settings.avatar.preview.default")
        }
        if isEnabled {
            return L("settings.avatar.preview.enabled")
        }
        return L("settings.avatar.preview.saved")
    }

    private var pickerTitle: String {
        currentSettings?.imageData == nil ? L("settings.avatar.choose") : L("settings.avatar.replace")
    }

    private var toggleStatusText: String {
        guard currentSettings?.imageData != nil else {
            return L("settings.avatar.preview.default")
        }
        return isEnabled ? L("settings.avatar.preview.enabled") : L("settings.avatar.preview.saved")
    }

    private var toggleStatusColor: Color {
        guard currentSettings?.imageData != nil else {
            return .secondary
        }
        return isEnabled ? .green : .secondary
    }

    private var isEnabled: Bool {
        currentSettings?.isEnabled ?? false
    }

    private func ensureEnabledStateConsistency() {
        guard let currentSettings else { return }
        if currentSettings.imageData == nil, currentSettings.isEnabled {
            currentSettings.isEnabled = false
            currentSettings.updatedAt = Date()
            try? modelContext.save()
        }
    }

    private func setEnabled(_ enabled: Bool) {
        guard let currentSettings = currentSettings ?? createSettingsRecordIfNeeded() else { return }
        if enabled, currentSettings.imageData == nil {
            currentSettings.isEnabled = false
            currentSettings.updatedAt = Date()
            try? modelContext.save()
            return
        }
        currentSettings.isEnabled = enabled
        currentSettings.updatedAt = Date()
        try? modelContext.save()
    }

    private func loadImage(from item: PhotosPickerItem) {
        isLoading = true
        Task {
            let data = try? await item.loadTransferable(type: Data.self)
            guard let data else {
                await MainActor.run {
                    isLoading = false
                    pickerItem = nil
                }
                return
            }

            let uiImage = await Task.detached(priority: .userInitiated) {
                ImageProcessing.downsampledUIImage(from: data, maxPixelSize: 1600)
            }.value

            guard let uiImage else {
                await MainActor.run {
                    isLoading = false
                    pickerItem = nil
                }
                return
            }

            await MainActor.run {
                isLoading = false
                cropSourceImage = uiImage
                isShowingCropper = true
            }
        }
    }

    private func applyAvatarImageData(_ data: Data?) {
        pickerItem = nil
        isShowingCropper = false

        guard let data else {
            cropSourceImage = nil
            return
        }
        guard let currentSettings = currentSettings ?? createSettingsRecordIfNeeded() else {
            cropSourceImage = nil
            return
        }

        isLoading = true
        Task.detached(priority: .userInitiated) {
            let processed = ImageProcessing.avatarJPEGData(from: data, targetSide: 320, compressionQuality: 0.84)
            await MainActor.run {
                defer { isLoading = false }
                guard let processed else { return }
                currentSettings.imageData = processed
                currentSettings.isEnabled = true
                currentSettings.updatedAt = Date()
                try? modelContext.save()
                cropSourceImage = nil
            }
        }
    }

    @discardableResult
    private func createSettingsRecordIfNeeded() -> TransportAvatarSettings? {
        if let currentSettings {
            return currentSettings
        }

        let record = TransportAvatarSettings()
        modelContext.insert(record)
        try? modelContext.save()
        return record
    }
}

#Preview {
    TransportAvatarSettingsView()
}
