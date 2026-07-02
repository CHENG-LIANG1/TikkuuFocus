//
//  VehicleSheet.swift
//  Tikkuu Focus
//
//  Created by Codex on 2026/6/24.
//

import SwiftUI

// MARK: - Vehicle List Sheet

struct VehicleListSheet: View {
    @ObservedObject var store: VehicleStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var editingVehicle: Vehicle?
    @State private var isAddingVehicle = false
    @State private var vehiclePendingDelete: Vehicle?
    @State private var showDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedGradientBackground().ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        if store.vehicles.isEmpty {
                            emptyState
                        } else {
                            ForEach(store.vehicles) { vehicle in
                                vehicleRow(vehicle)
                            }
                        }

                        if store.canAddMore {
                            addButton
                        }

                        Text(String(format: L("vehicle.count"), store.vehicles.count, VehicleStore.maxVehicles))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 2)
                    }
                    .padding(20)
                }
            }
            .navigationTitle(L("vehicle.sheet.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L("common.done")) { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
        .preferredColorScheme(.dark)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .sheet(isPresented: $isAddingVehicle) {
            VehicleEditorView(store: store, existing: nil)
        }
        .sheet(item: $editingVehicle) { vehicle in
            VehicleEditorView(store: store, existing: vehicle)
        }
        .alert(L("vehicle.delete.confirm.title"), isPresented: $showDeleteConfirmation) {
            Button(L("common.cancel"), role: .cancel) {
                vehiclePendingDelete = nil
            }
            Button(L("common.delete"), role: .destructive) {
                confirmDeleteVehicle()
            }
        } message: {
            Text(deleteConfirmationMessage)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "car.2.fill")
                .font(.system(size: 40, weight: .semibold))
                .foregroundColor(.secondary)
            Text(L("vehicle.empty"))
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.primary)
            Text(L("vehicle.empty.message"))
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    private var addButton: some View {
        Button {
            HapticManager.light()
            isAddingVehicle = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                Text(L("vehicle.add"))
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
            }
            .foregroundColor(.primary.opacity(0.85))
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1.4, dash: [6, 5]))
                    .foregroundColor(.white.opacity(colorScheme == .dark ? 0.28 : 0.4))
            )
        }
        .buttonStyle(PremiumButtonStyle())
    }

    private func vehicleRow(_ vehicle: Vehicle) -> some View {
        VehicleCard(
            vehicle: vehicle,
            isSelected: isVehicleSelected(vehicle),
            onSelect: { selectVehicle(vehicle) },
            onEdit: { editingVehicle = vehicle },
            onDelete: { requestDeleteVehicle(vehicle) }
        )
    }

    private func isVehicleSelected(_ vehicle: Vehicle) -> Bool {
        if store.selectedID == vehicle.id {
            return true
        }
        return store.selectedID == nil && store.vehicles.first?.id == vehicle.id
    }

    private func selectVehicle(_ vehicle: Vehicle) {
        HapticManager.selection()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            store.select(vehicle)
        }
    }

    private func requestDeleteVehicle(_ vehicle: Vehicle) {
        HapticManager.light()
        vehiclePendingDelete = vehicle
        showDeleteConfirmation = true
    }

    private var deleteConfirmationMessage: String {
        let name = vehiclePendingDelete?.plateOrName ?? L("vehicle.title")
        return String(format: L("vehicle.delete.confirm.message"), name)
    }

    private func confirmDeleteVehicle() {
        guard let vehicle = vehiclePendingDelete else { return }
        HapticManager.medium()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            store.delete(vehicle)
        }
        vehiclePendingDelete = nil
    }
}

// MARK: - Vehicle Card

private struct VehicleCard: View {
    let vehicle: Vehicle
    let isSelected: Bool
    let onSelect: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.white.opacity(0.22) : Color.white.opacity(0.1))
                        .frame(width: 46, height: 46)
                    Image(systemName: vehicle.energyType == .electric ? "bolt.car.fill" : "car.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(isSelected ? .white : .primary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(vehicle.displayName.isEmpty ? L("vehicle.title") : vehicle.displayName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(isSelected ? .white : .primary)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        if !vehicle.plate.trimmingCharacters(in: .whitespaces).isEmpty {
                            Text(vehicle.plate)
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2)
                                .background(
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .fill(isSelected ? Color.white.opacity(0.2) : Color.primary.opacity(0.08))
                                )
                        }
                        Label(vehicle.energyType.localizedName, systemImage: vehicle.energyType.iconName)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(isSelected ? .white.opacity(0.85) : .secondary)
                    }
                }

                Spacer(minLength: 4)

                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(.plain)

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.red.opacity(0.85))
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color(red: 0.24, green: 0.54, blue: 0.98), Color(red: 0.19, green: 0.44, blue: 0.90)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: Color.blue.opacity(0.3), radius: 10, x: 0, y: 5)
                    } else {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color.clear)
                            .insetSurface(cornerRadius: 20, isActive: false)
                    }
                }
            )
        }
        .buttonStyle(PremiumButtonStyle())
    }
}

// MARK: - Vehicle Editor

struct VehicleEditorView: View {
    @ObservedObject var store: VehicleStore
    let existing: Vehicle?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var energyType: VehicleEnergyType
    @State private var brand: String
    @State private var model: String
    @State private var plate: String

    init(store: VehicleStore, existing: Vehicle?) {
        self.store = store
        self.existing = existing
        _energyType = State(initialValue: existing?.energyType ?? .gasoline)
        _brand = State(initialValue: existing?.brand ?? "")
        _model = State(initialValue: existing?.model ?? "")
        _plate = State(initialValue: existing?.plate ?? "")
    }

    private var plateMaxLength: Int {
        energyType.plateMaxLength
    }

    private var availableBrands: [VehicleBrand] {
        VehicleCatalog.brands(for: energyType)
    }

    private var availableModels: [String] {
        availableBrands.first { $0.name == brand }?.models ?? []
    }

    private var canSave: Bool {
        availableBrands.contains { $0.name == brand && $0.models.contains(model) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedGradientBackground().ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        // Energy type
                        VStack(alignment: .leading, spacing: 10) {
                            sectionHeader(L("vehicle.energy.title"))
                            HStack(spacing: 10) {
                                ForEach(VehicleEnergyType.allCases) { type in
                                    energySegment(type)
                                }
                            }
                        }

                        // Brand & model
                        VStack(alignment: .leading, spacing: 10) {
                            sectionHeader(L("vehicle.section.model"))
                            VStack(spacing: 0) {
                                NavigationLink {
                                    BrandPickerView(brands: availableBrands, selectedBrand: brand) { picked in
                                        if picked != brand {
                                            brand = picked
                                            model = ""
                                        }
                                    }
                                } label: {
                                    pickerRow(
                                        label: L("vehicle.brand"),
                                        value: brand.isEmpty ? L("vehicle.brand.placeholder") : brand,
                                        isPlaceholder: brand.isEmpty
                                    )
                                }
                                .buttonStyle(ScaleButtonStyle())

                                Rectangle()
                                    .fill(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.18))
                                    .frame(height: 1)
                                    .padding(.leading, 18)

                                NavigationLink {
                                    ModelPickerView(models: availableModels, selectedModel: model) { picked in
                                        model = picked
                                    }
                                } label: {
                                    pickerRow(
                                        label: L("vehicle.model"),
                                        value: model.isEmpty ? L("vehicle.model.placeholder") : model,
                                        isPlaceholder: model.isEmpty
                                    )
                                }
                                .buttonStyle(ScaleButtonStyle())
                                .disabled(brand.isEmpty)
                                .opacity(brand.isEmpty ? 0.45 : 1)
                            }
                            .glassCard(cornerRadius: 22)
                        }

                        // License plate
                        VStack(alignment: .leading, spacing: 10) {
                            sectionHeader(L("vehicle.plate"))
                            HStack(spacing: 10) {
                                Image(systemName: "number")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.secondary)
                                TextField(L("vehicle.plate.placeholder"), text: Binding(
                                    get: { plate },
                                    set: { plate = String($0.prefix(plateMaxLength)) }
                                ))
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .foregroundColor(.primary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 15)
                            .glassCard(cornerRadius: 18)

                            Text(L("vehicle.plate.hint"))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 4)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle(existing == nil ? L("vehicle.add") : L("vehicle.edit"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(L("common.cancel")) { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L("common.save")) { save() }
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
    }

    private func energySegment(_ type: VehicleEnergyType) -> some View {
        let isSelected = energyType == type
        return Button {
            HapticManager.selection()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.78)) {
                switchEnergyType(to: type)
            }
        } label: {
            HStack(spacing: 7) {
                Image(systemName: type.iconName)
                    .font(.system(size: 14, weight: .semibold))
                Text(type.localizedName)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
            }
            .foregroundColor(isSelected ? .white : .primary)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color(red: 0.24, green: 0.54, blue: 0.98), Color(red: 0.19, green: 0.44, blue: 0.90)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                    } else {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.clear)
                            .insetSurface(cornerRadius: 18, isActive: false)
                    }
                }
            )
        }
        .buttonStyle(PremiumButtonStyle())
    }

    private func pickerRow(label: String, value: String, isPlaceholder: Bool) -> some View {
        HStack(spacing: 10) {
            Text(label)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
            Spacer(minLength: 8)
            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(isPlaceholder ? .secondary : Color.accentColor)
                .lineLimit(1)
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .contentShape(Rectangle())
    }

    private func switchEnergyType(to type: VehicleEnergyType) {
        energyType = type
        let brands = VehicleCatalog.brands(for: type)
        if let selectedBrand = brands.first(where: { $0.name == brand }) {
            if !selectedBrand.models.contains(model) {
                model = ""
            }
        } else {
            brand = ""
            model = ""
        }
        plate = String(plate.prefix(type.plateMaxLength))
    }

    private func save() {
        HapticManager.success()
        let trimmedPlate = String(plate.trimmingCharacters(in: .whitespacesAndNewlines).prefix(energyType.plateMaxLength))
        if var vehicle = existing {
            vehicle.brand = brand
            vehicle.model = model
            vehicle.energyType = energyType
            vehicle.plate = trimmedPlate
            store.update(vehicle)
            store.select(vehicle)
        } else {
            let vehicle = Vehicle(brand: brand, model: model, energyType: energyType, plate: trimmedPlate)
            store.add(vehicle)
        }
        dismiss()
    }
}

// MARK: - Picker Option Row

private struct VehiclePickerOptionRow: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isSelected ? .white : .primary)
                Spacer(minLength: 8)
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 54)
            .frame(maxWidth: .infinity)
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color(red: 0.24, green: 0.54, blue: 0.98), Color(red: 0.19, green: 0.44, blue: 0.90)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                    } else {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.clear)
                            .insetSurface(cornerRadius: 16, isActive: false)
                    }
                }
            )
        }
        .buttonStyle(PremiumButtonStyle())
    }
}

// MARK: - Brand Picker

private struct BrandPickerView: View {
    let brands: [VehicleBrand]
    let selectedBrand: String
    let onSelect: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var search = ""

    private var filtered: [VehicleBrand] {
        guard !search.isEmpty else { return brands }
        return brands.filter { $0.name.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 8) {
                ForEach(filtered) { brand in
                    VehiclePickerOptionRow(title: brand.name, isSelected: brand.name == selectedBrand) {
                        HapticManager.selection()
                        onSelect(brand.name)
                        dismiss()
                    }
                }
            }
            .padding(20)
        }
        .background(AnimatedGradientBackground().ignoresSafeArea())
        .navigationTitle(L("vehicle.brand"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .searchable(text: $search, prompt: L("vehicle.brand.search"))
    }
}

// MARK: - Model Picker

private struct ModelPickerView: View {
    let models: [String]
    let selectedModel: String
    let onSelect: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 8) {
                ForEach(models, id: \.self) { model in
                    VehiclePickerOptionRow(title: model, isSelected: model == selectedModel) {
                        HapticManager.selection()
                        onSelect(model)
                        dismiss()
                    }
                }
            }
            .padding(20)
        }
        .background(AnimatedGradientBackground().ignoresSafeArea())
        .navigationTitle(L("vehicle.model"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}
