//
//  Vehicle.swift
//  Tikkuu Focus
//
//  Created by Codex on 2026/6/24.
//

import SwiftUI
import Combine

// MARK: - Energy Type

enum VehicleEnergyType: String, Codable, CaseIterable, Identifiable {
    case gasoline
    case electric

    var id: String { rawValue }

    var localizedName: String { L("vehicle.energy.\(rawValue)") }

    var iconName: String {
        switch self {
        case .gasoline: return "fuelpump.fill"
        case .electric: return "bolt.fill"
        }
    }

    var plateMaxLength: Int {
        switch self {
        case .gasoline: return 7
        case .electric: return 8
        }
    }
}

// MARK: - Vehicle

struct Vehicle: Codable, Identifiable, Equatable {
    var id: String
    var brand: String
    var model: String
    var energyType: VehicleEnergyType
    var plate: String

    init(
        id: String = UUID().uuidString,
        brand: String,
        model: String,
        energyType: VehicleEnergyType,
        plate: String
    ) {
        self.id = id
        self.brand = brand
        self.model = model
        self.energyType = energyType
        self.plate = plate
    }

    /// "Toyota Corolla" — falls back to whichever part exists.
    var displayName: String {
        [brand, model]
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    var plateOrName: String {
        let trimmed = plate.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? displayName : trimmed
    }

    var modelDisplayName: String {
        let trimmed = model.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? displayName : trimmed
    }
}

// MARK: - Vehicle Store

/// Persists up to 5 user vehicles and the current selection.
final class VehicleStore: ObservableObject {
    static let shared = VehicleStore()
    static let maxVehicles = 5

    private enum Keys {
        static let vehicles = "vehicles.list"
        static let selected = "vehicles.selectedID"
    }

    @Published private(set) var vehicles: [Vehicle]
    @Published var selectedID: String? {
        didSet {
            guard selectedID != oldValue else { return }
            UserDefaults.standard.set(selectedID, forKey: Keys.selected)
        }
    }

    private init() {
        if let data = UserDefaults.standard.data(forKey: Keys.vehicles),
           let decoded = try? JSONDecoder().decode([Vehicle].self, from: data) {
            self.vehicles = decoded
        } else {
            self.vehicles = []
        }
        self.selectedID = UserDefaults.standard.string(forKey: Keys.selected)
    }

    var selectedVehicle: Vehicle? {
        vehicles.first { $0.id == selectedID } ?? vehicles.first
    }

    var canAddMore: Bool { vehicles.count < Self.maxVehicles }

    @discardableResult
    func add(_ vehicle: Vehicle) -> Bool {
        guard canAddMore else { return false }
        vehicles.append(vehicle)
        selectedID = vehicle.id
        persist()
        return true
    }

    func update(_ vehicle: Vehicle) {
        guard let index = vehicles.firstIndex(where: { $0.id == vehicle.id }) else { return }
        vehicles[index] = vehicle
        persist()
    }

    func delete(_ vehicle: Vehicle) {
        vehicles.removeAll { $0.id == vehicle.id }
        if selectedID == vehicle.id {
            selectedID = vehicles.first?.id
        }
        persist()
    }

    func select(_ vehicle: Vehicle) {
        selectedID = vehicle.id
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(vehicles) {
            UserDefaults.standard.set(data, forKey: Keys.vehicles)
        }
    }
}

// MARK: - Vehicle Catalog

struct VehicleBrand: Identifiable {
    let name: String
    let models: [String]
    var id: String { name }
}

/// Separate catalogs keep fuel and EV selection from suggesting mismatched models.
enum VehicleCatalog {
    static func brands(for energyType: VehicleEnergyType) -> [VehicleBrand] {
        switch energyType {
        case .gasoline: return gasolineBrands
        case .electric: return electricBrands
        }
    }

    static let gasolineBrands: [VehicleBrand] = [
        VehicleBrand(name: "Toyota", models: ["Corolla", "Camry", "RAV4", "Hilux", "Highlander", "Land Cruiser", "Prado", "Yaris", "Tacoma", "Sienna"]),
        VehicleBrand(name: "Volkswagen", models: ["Golf", "Passat", "Tiguan", "Polo", "Jetta", "Atlas", "Touareg", "Arteon", "T-Roc", "Teramont"]),
        VehicleBrand(name: "Ford", models: ["F-150", "Mustang", "Explorer", "Escape", "Focus", "Fiesta", "Ranger", "Bronco", "Edge", "Expedition"]),
        VehicleBrand(name: "Honda", models: ["Civic", "Accord", "CR-V", "Pilot", "Fit", "HR-V", "Odyssey", "Ridgeline", "Passport", "Integra"]),
        VehicleBrand(name: "Nissan", models: ["Altima", "Sentra", "Rogue", "X-Trail", "Qashqai", "Maxima", "Pathfinder", "Murano", "GT-R", "Patrol"]),
        VehicleBrand(name: "Chevrolet", models: ["Silverado", "Malibu", "Equinox", "Camaro", "Corvette", "Tahoe", "Suburban", "Traverse", "Trax", "Blazer"]),
        VehicleBrand(name: "Hyundai", models: ["Elantra", "Sonata", "Tucson", "Santa Fe", "Kona", "Palisade", "Accent", "Venue", "Veloster", "Santa Cruz"]),
        VehicleBrand(name: "Kia", models: ["Sportage", "Sorento", "Seltos", "Telluride", "Forte", "Soul", "Rio", "Carnival", "Stinger", "K5"]),
        VehicleBrand(name: "Mercedes-Benz", models: ["C-Class", "E-Class", "S-Class", "A-Class", "GLC", "GLE", "GLA", "CLA", "G-Class", "GLS"]),
        VehicleBrand(name: "BMW", models: ["3 Series", "5 Series", "7 Series", "X1", "X3", "X5", "X7", "M3", "M5", "Z4"]),
        VehicleBrand(name: "Audi", models: ["A3", "A4", "A6", "A8", "Q3", "Q5", "Q7", "Q8", "R8", "TT"]),
        VehicleBrand(name: "Volvo", models: ["XC90", "XC60", "XC40", "S60", "S90", "V60", "V90", "C40", "EX30", "EX90"]),
        VehicleBrand(name: "Porsche", models: ["911", "Cayenne", "Macan", "Panamera", "Boxster", "Cayman", "718"]),
        VehicleBrand(name: "Lexus", models: ["ES", "IS", "LS", "RX", "NX", "GX", "LX", "UX", "RC", "LC"]),
        VehicleBrand(name: "Mazda", models: ["Mazda3", "Mazda6", "CX-5", "CX-30", "CX-9", "MX-5 Miata", "CX-50", "CX-90", "CX-3", "RX-8"]),
        VehicleBrand(name: "Subaru", models: ["Outback", "Forester", "Impreza", "Crosstrek", "Legacy", "Ascent", "WRX", "BRZ"]),
        VehicleBrand(name: "Jeep", models: ["Wrangler", "Grand Cherokee", "Cherokee", "Compass", "Renegade", "Gladiator", "Wagoneer", "Grand Wagoneer"]),
        VehicleBrand(name: "Land Rover", models: ["Range Rover", "Range Rover Sport", "Evoque", "Discovery", "Discovery Sport", "Defender", "Velar"]),
        VehicleBrand(name: "Peugeot", models: ["208", "308", "2008", "3008", "5008", "508", "408", "108", "Rifter"]),
        VehicleBrand(name: "Renault", models: ["Clio", "Megane", "Captur", "Kadjar", "Twingo", "Scenic", "Talisman", "Arkana", "Austral"]),
        VehicleBrand(name: "Fiat", models: ["500", "Panda", "Tipo", "500X", "500L", "Punto", "Doblo", "124 Spider", "Mobi"]),
        VehicleBrand(name: "Buick", models: ["Encore", "Enclave", "Envision", "Regal", "LaCrosse", "Verano", "Cascada", "Envista"]),
        VehicleBrand(name: "Cadillac", models: ["Escalade", "XT5", "XT4", "XT6", "CT4", "CT5", "CT6"]),
        VehicleBrand(name: "GMC", models: ["Sierra", "Yukon", "Acadia", "Terrain", "Canyon", "Savana"]),
        VehicleBrand(name: "Dodge", models: ["Charger", "Challenger", "Durango", "Journey", "Dart", "Grand Caravan", "Hornet"]),
        VehicleBrand(name: "Mitsubishi", models: ["Outlander", "Eclipse Cross", "ASX", "Pajero", "Lancer", "Mirage", "Triton", "Xpander"]),
        VehicleBrand(name: "Suzuki", models: ["Swift", "Vitara", "Jimny", "Baleno", "S-Cross", "Celerio", "Ignis", "Ertiga", "Alto", "Ciaz"]),
        VehicleBrand(name: "Ferrari", models: ["Roma", "Portofino", "F8 Tributo", "SF90", "296 GTB", "812", "Purosangue"])
    ]

    static let electricBrands: [VehicleBrand] = [
        VehicleBrand(name: "特斯拉", models: ["Model 3", "Model Y", "Model S", "Model X", "Cybertruck"]),
        VehicleBrand(name: "比亚迪", models: ["秦PLUS EV", "汉EV", "海豹", "海豚", "元PLUS", "宋PLUS EV", "唐EV", "腾势D9 EV"]),
        VehicleBrand(name: "小米汽车", models: ["SU7", "SU7 Pro", "SU7 Max", "YU7"]),
        VehicleBrand(name: "蔚来", models: ["ET5", "ET5T", "ET7", "ES6", "ES8", "EC6", "EC7", "EL6"]),
        VehicleBrand(name: "小鹏", models: ["P7", "P7i", "P5", "G6", "G9", "X9", "MONA M03"]),
        VehicleBrand(name: "理想", models: ["L6", "L7", "L8", "L9", "MEGA"]),
        VehicleBrand(name: "极氪", models: ["001", "007", "009", "X", "7X"]),
        VehicleBrand(name: "问界", models: ["M5 EV", "M7 EV", "M9 EV"]),
        VehicleBrand(name: "零跑", models: ["T03", "C10", "C11", "C16"]),
        VehicleBrand(name: "哪吒", models: ["AYA", "X", "S", "GT", "L"]),
        VehicleBrand(name: "大众", models: ["ID.3", "ID.4", "ID.6", "ID.7"]),
        VehicleBrand(name: "宝马", models: ["i3", "i4", "i5", "i7", "iX1", "iX3", "iX"]),
        VehicleBrand(name: "奔驰", models: ["EQA", "EQB", "EQE", "EQS", "EQE SUV", "EQS SUV"]),
        VehicleBrand(name: "奥迪", models: ["Q4 e-tron", "Q5 e-tron", "Q8 e-tron", "e-tron GT"]),
        VehicleBrand(name: "保时捷", models: ["Taycan", "Taycan 4S", "Taycan Turbo", "Macan Electric"]),
        VehicleBrand(name: "现代", models: ["Ioniq 5", "Ioniq 6", "Kona Electric"]),
        VehicleBrand(name: "起亚", models: ["EV5", "EV6", "EV9", "Niro EV"]),
        VehicleBrand(name: "日产", models: ["Leaf", "Ariya"]),
        VehicleBrand(name: "雪佛兰", models: ["Bolt EV", "Bolt EUV", "Equinox EV", "Blazer EV"]),
        VehicleBrand(name: "凯迪拉克", models: ["Lyriq", "Optiq", "Escalade IQ"])
    ]
}
