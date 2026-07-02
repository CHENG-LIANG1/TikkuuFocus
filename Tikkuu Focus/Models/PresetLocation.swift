//
//  PresetLocation.swift
//  Tikkuu Focus
//
//  Created by Tikkuu on 2026/2/8.
//

import Foundation
import CoreLocation

/// Preset famous locations around the world
struct PresetLocation: Identifiable, Equatable {
    let id: UUID
    let name: String
    let nameZh: String
    let coordinate: CLLocationCoordinate2D
    let country: String
    let emoji: String
    
    init(id: UUID = UUID(), name: String, nameZh: String, coordinate: CLLocationCoordinate2D, country: String, emoji: String) {
        self.id = id
        self.name = name
        self.nameZh = nameZh
        self.coordinate = coordinate
        self.country = country
        self.emoji = emoji
    }
    
    var localizedName: String {
        if AppSettings.shared.currentLanguage.hasPrefix("zh") {
            return nameZh
        }
        return name
    }
    
    static func == (lhs: PresetLocation, rhs: PresetLocation) -> Bool {
        lhs.id == rhs.id
    }
}


// MARK: - Preset Country Grouping

/// A country grouping for preset start locations, holding its top cities.
struct PresetCountry: Identifiable {
    let id: String        // English country key (matches PresetLocation.country)
    let name: String      // English display name
    let nameZh: String
    let flag: String
    let cities: [PresetLocation]

    var localizedName: String {
        AppSettings.shared.currentLanguage.hasPrefix("zh") ? nameZh : name
    }
}

// MARK: - Preset Locations

extension PresetLocation {
    /// Convenience builder so city definitions stay compact.
    fileprivate static func city(
        _ name: String,
        _ nameZh: String,
        _ lat: Double,
        _ lon: Double,
        _ country: String,
        _ emoji: String
    ) -> PresetLocation {
        PresetLocation(
            name: name,
            nameZh: nameZh,
            coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
            country: country,
            emoji: emoji
        )
    }

    /// Top-5-by-population cities grouped by country.
    static let countries: [PresetCountry] = [
        PresetCountry(id: "China", name: "China", nameZh: "中国", flag: "🇨🇳", cities: [
            city("Shanghai", "上海", 31.2304, 121.4737, "China", "🌃"),
            city("Beijing", "北京", 39.9042, 116.4074, "China", "🏯"),
            city("Chongqing", "重庆", 29.5630, 106.5516, "China", "🌉"),
            city("Guangzhou", "广州", 23.1291, 113.2644, "China", "🏙️"),
            city("Shenzhen", "深圳", 22.5431, 114.0579, "China", "🌆")
        ]),
        PresetCountry(id: "Japan", name: "Japan", nameZh: "日本", flag: "🇯🇵", cities: [
            city("Tokyo", "东京", 35.6762, 139.6503, "Japan", "🗼"),
            city("Yokohama", "横滨", 35.4437, 139.6380, "Japan", "🎡"),
            city("Osaka", "大阪", 34.6937, 135.5023, "Japan", "🏯"),
            city("Nagoya", "名古屋", 35.1815, 136.9066, "Japan", "🏰"),
            city("Sapporo", "札幌", 43.0618, 141.3545, "Japan", "❄️")
        ]),
        PresetCountry(id: "South Korea", name: "South Korea", nameZh: "韩国", flag: "🇰🇷", cities: [
            city("Seoul", "首尔", 37.5665, 126.9780, "South Korea", "🏙️"),
            city("Busan", "釜山", 35.1796, 129.0756, "South Korea", "🌊"),
            city("Incheon", "仁川", 37.4563, 126.7052, "South Korea", "✈️"),
            city("Daegu", "大邱", 35.8714, 128.6014, "South Korea", "🍎"),
            city("Daejeon", "大田", 36.3504, 127.3845, "South Korea", "🔬")
        ]),
        PresetCountry(id: "USA", name: "United States", nameZh: "美国", flag: "🇺🇸", cities: [
            city("New York", "纽约", 40.7128, -74.0060, "USA", "🗽"),
            city("Los Angeles", "洛杉矶", 34.0522, -118.2437, "USA", "🎬"),
            city("Chicago", "芝加哥", 41.8781, -87.6298, "USA", "🌆"),
            city("Houston", "休斯顿", 29.7604, -95.3698, "USA", "🚀"),
            city("Phoenix", "凤凰城", 33.4484, -112.0740, "USA", "🌵")
        ]),
        PresetCountry(id: "UK", name: "United Kingdom", nameZh: "英国", flag: "🇬🇧", cities: [
            city("London", "伦敦", 51.5074, -0.1278, "UK", "🎡"),
            city("Birmingham", "伯明翰", 52.4862, -1.8904, "UK", "🏭"),
            city("Manchester", "曼彻斯特", 53.4808, -2.2426, "UK", "⚽"),
            city("Glasgow", "格拉斯哥", 55.8642, -4.2518, "UK", "🏴󠁧󠁢󠁳󠁣󠁴󠁿"),
            city("Leeds", "利兹", 53.8008, -1.5491, "UK", "🏙️")
        ]),
        PresetCountry(id: "France", name: "France", nameZh: "法国", flag: "🇫🇷", cities: [
            city("Paris", "巴黎", 48.8566, 2.3522, "France", "🗼"),
            city("Marseille", "马赛", 43.2965, 5.3698, "France", "⛵"),
            city("Lyon", "里昂", 45.7640, 4.8357, "France", "🦁"),
            city("Toulouse", "图卢兹", 43.6047, 1.4442, "France", "🚀"),
            city("Nice", "尼斯", 43.7102, 7.2620, "France", "🏖️")
        ]),
        PresetCountry(id: "Italy", name: "Italy", nameZh: "意大利", flag: "🇮🇹", cities: [
            city("Rome", "罗马", 41.9028, 12.4964, "Italy", "🏛️"),
            city("Milan", "米兰", 45.4642, 9.1900, "Italy", "👗"),
            city("Naples", "那不勒斯", 40.8518, 14.2681, "Italy", "🍕"),
            city("Turin", "都灵", 45.0703, 7.6869, "Italy", "🚗"),
            city("Palermo", "巴勒莫", 38.1157, 13.3615, "Italy", "⛪")
        ]),
        PresetCountry(id: "Australia", name: "Australia", nameZh: "澳大利亚", flag: "🇦🇺", cities: [
            city("Sydney", "悉尼", -33.8688, 151.2093, "Australia", "🎭"),
            city("Melbourne", "墨尔本", -37.8136, 144.9631, "Australia", "☕"),
            city("Brisbane", "布里斯班", -27.4698, 153.0251, "Australia", "☀️"),
            city("Perth", "珀斯", -31.9505, 115.8605, "Australia", "🏖️"),
            city("Adelaide", "阿德莱德", -34.9285, 138.6007, "Australia", "🍷")
        ]),
        PresetCountry(id: "New Zealand", name: "New Zealand", nameZh: "新西兰", flag: "🇳🇿", cities: [
            city("Auckland", "奥克兰", -36.8485, 174.7633, "New Zealand", "⛵"),
            city("Christchurch", "基督城", -43.5321, 172.6362, "New Zealand", "🌳"),
            city("Wellington", "惠灵顿", -41.2865, 174.7762, "New Zealand", "💨"),
            city("Hamilton", "汉密尔顿", -37.7870, 175.2793, "New Zealand", "🐄"),
            city("Tauranga", "陶朗加", -37.6878, 176.1651, "New Zealand", "🏄")
        ]),
        PresetCountry(id: "Canada", name: "Canada", nameZh: "加拿大", flag: "🇨🇦", cities: [
            city("Toronto", "多伦多", 43.6532, -79.3832, "Canada", "🍁"),
            city("Montreal", "蒙特利尔", 45.5017, -73.5673, "Canada", "⛪"),
            city("Calgary", "卡尔加里", 51.0447, -114.0719, "Canada", "🤠"),
            city("Ottawa", "渥太华", 45.4215, -75.6972, "Canada", "🏛️"),
            city("Edmonton", "埃德蒙顿", 53.5461, -113.4938, "Canada", "🛢️")
        ]),
        PresetCountry(id: "Germany", name: "Germany", nameZh: "德国", flag: "🇩🇪", cities: [
            city("Berlin", "柏林", 52.5200, 13.4050, "Germany", "🐻"),
            city("Hamburg", "汉堡", 53.5511, 9.9937, "Germany", "⚓"),
            city("Munich", "慕尼黑", 48.1351, 11.5820, "Germany", "🍺"),
            city("Cologne", "科隆", 50.9375, 6.9603, "Germany", "⛪"),
            city("Frankfurt", "法兰克福", 50.1109, 8.6821, "Germany", "🏦")
        ]),
        PresetCountry(id: "Brazil", name: "Brazil", nameZh: "巴西", flag: "🇧🇷", cities: [
            city("São Paulo", "圣保罗", -23.5505, -46.6333, "Brazil", "🌆"),
            city("Rio de Janeiro", "里约热内卢", -22.9068, -43.1729, "Brazil", "🏖️"),
            city("Brasília", "巴西利亚", -15.7939, -47.8828, "Brazil", "🏛️"),
            city("Salvador", "萨尔瓦多", -12.9777, -38.5016, "Brazil", "🥁"),
            city("Fortaleza", "福塔莱萨", -3.7319, -38.5267, "Brazil", "☀️")
        ])
    ]

    /// Flattened list of all preset cities (backward compatible).
    static var presets: [PresetLocation] {
        countries.flatMap { $0.cities }
    }
}

/// Location source type
enum LocationSource: Equatable {
    case currentLocation
    case preset(PresetLocation)
    case custom(CLLocationCoordinate2D, String)
    case scenicRoute(ScenicRoute)
    
    var coordinate: CLLocationCoordinate2D? {
        switch self {
        case .currentLocation:
            return nil // Will be determined at runtime
        case .preset(let location):
            return location.coordinate
        case .custom(let coordinate, _):
            return coordinate
        case .scenicRoute(let route):
            return route.startCoordinateForNextSession
        }
    }
    
    var displayName: String {
        switch self {
        case .currentLocation:
            return L("location.current")
        case .preset(let location):
            return location.localizedName
        case .custom(_, let name):
            return name
        case .scenicRoute(let route):
            return route.localizedName
        }
    }
}
