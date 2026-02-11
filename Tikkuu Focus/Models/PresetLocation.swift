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
    let subwayStations: [PresetSubwayStation]
    
    init(id: UUID = UUID(), name: String, nameZh: String, coordinate: CLLocationCoordinate2D, country: String, emoji: String, subwayStations: [PresetSubwayStation]) {
        self.id = id
        self.name = name
        self.nameZh = nameZh
        self.coordinate = coordinate
        self.country = country
        self.emoji = emoji
        self.subwayStations = subwayStations
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

/// Preset subway station for a city
struct PresetSubwayStation {
    let name: String
    let nameZh: String
    let coordinate: CLLocationCoordinate2D
    
    var localizedName: String {
        if AppSettings.shared.currentLanguage.hasPrefix("zh") {
            return nameZh
        }
        return name
    }
}

// MARK: - Preset Locations

extension PresetLocation {
    static let presets: [PresetLocation] = [
        // Asia
        PresetLocation(
            name: "Tokyo, Japan",
            nameZh: "日本东京",
            coordinate: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503),
            country: "Japan",
            emoji: "🗼",
            subwayStations: [
                PresetSubwayStation(name: "Shinjuku Station", nameZh: "新宿站", coordinate: CLLocationCoordinate2D(latitude: 35.6896, longitude: 139.7006)),
                PresetSubwayStation(name: "Shibuya Station", nameZh: "涩谷站", coordinate: CLLocationCoordinate2D(latitude: 35.6580, longitude: 139.7016)),
                PresetSubwayStation(name: "Tokyo Station", nameZh: "东京站", coordinate: CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)),
                PresetSubwayStation(name: "Ikebukuro Station", nameZh: "池袋站", coordinate: CLLocationCoordinate2D(latitude: 35.7295, longitude: 139.7109)),
                PresetSubwayStation(name: "Ueno Station", nameZh: "上野站", coordinate: CLLocationCoordinate2D(latitude: 35.7138, longitude: 139.7774)),
                PresetSubwayStation(name: "Ginza Station", nameZh: "银座站", coordinate: CLLocationCoordinate2D(latitude: 35.6719, longitude: 139.7648))
            ]
        ),
        PresetLocation(
            name: "Seoul, South Korea",
            nameZh: "韩国首尔",
            coordinate: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780),
            country: "South Korea",
            emoji: "🏯",
            subwayStations: [
                PresetSubwayStation(name: "Gangnam Station", nameZh: "江南站", coordinate: CLLocationCoordinate2D(latitude: 37.4979, longitude: 127.0276)),
                PresetSubwayStation(name: "Seoul Station", nameZh: "首尔站", coordinate: CLLocationCoordinate2D(latitude: 37.5547, longitude: 126.9707)),
                PresetSubwayStation(name: "Hongdae Station", nameZh: "弘大站", coordinate: CLLocationCoordinate2D(latitude: 37.5571, longitude: 126.9245)),
                PresetSubwayStation(name: "Myeongdong Station", nameZh: "明洞站", coordinate: CLLocationCoordinate2D(latitude: 37.5636, longitude: 126.9866)),
                PresetSubwayStation(name: "Jamsil Station", nameZh: "蚕室站", coordinate: CLLocationCoordinate2D(latitude: 37.5133, longitude: 127.1000)),
                PresetSubwayStation(name: "City Hall Station", nameZh: "市厅站", coordinate: CLLocationCoordinate2D(latitude: 37.5658, longitude: 126.9779))
            ]
        ),
        PresetLocation(
            name: "Beijing, China",
            nameZh: "中国北京",
            coordinate: CLLocationCoordinate2D(latitude: 39.9042, longitude: 116.4074),
            country: "China",
            emoji: "🏛️",
            subwayStations: [
                PresetSubwayStation(name: "Tiananmen Square", nameZh: "天安门广场", coordinate: CLLocationCoordinate2D(latitude: 39.9055, longitude: 116.3976)),
                PresetSubwayStation(name: "Wangfujing", nameZh: "王府井", coordinate: CLLocationCoordinate2D(latitude: 39.9097, longitude: 116.4109)),
                PresetSubwayStation(name: "Sanlitun", nameZh: "三里屯", coordinate: CLLocationCoordinate2D(latitude: 39.9368, longitude: 116.4472)),
                PresetSubwayStation(name: "Beijing Railway Station", nameZh: "北京站", coordinate: CLLocationCoordinate2D(latitude: 39.9024, longitude: 116.4273)),
                PresetSubwayStation(name: "Guomao", nameZh: "国贸", coordinate: CLLocationCoordinate2D(latitude: 39.9088, longitude: 116.4577)),
                PresetSubwayStation(name: "Xidan", nameZh: "西单", coordinate: CLLocationCoordinate2D(latitude: 39.9061, longitude: 116.3752))
            ]
        ),
        PresetLocation(
            name: "Shanghai, China",
            nameZh: "中国上海",
            coordinate: CLLocationCoordinate2D(latitude: 31.2304, longitude: 121.4737),
            country: "China",
            emoji: "🌃",
            subwayStations: [
                PresetSubwayStation(name: "People's Square", nameZh: "人民广场", coordinate: CLLocationCoordinate2D(latitude: 31.2286, longitude: 121.4753)),
                PresetSubwayStation(name: "Lujiazui", nameZh: "陆家嘴", coordinate: CLLocationCoordinate2D(latitude: 31.2397, longitude: 121.4994)),
                PresetSubwayStation(name: "Jing'an Temple", nameZh: "静安寺", coordinate: CLLocationCoordinate2D(latitude: 31.2246, longitude: 121.4453)),
                PresetSubwayStation(name: "Xujiahui", nameZh: "徐家汇", coordinate: CLLocationCoordinate2D(latitude: 31.1880, longitude: 121.4363)),
                PresetSubwayStation(name: "Century Avenue", nameZh: "世纪大道", coordinate: CLLocationCoordinate2D(latitude: 31.2364, longitude: 121.5354)),
                PresetSubwayStation(name: "Nanjing Road", nameZh: "南京路", coordinate: CLLocationCoordinate2D(latitude: 31.2342, longitude: 121.4759))
            ]
        ),
        PresetLocation(
            name: "Nanjing, China",
            nameZh: "中国南京",
            coordinate: CLLocationCoordinate2D(latitude: 32.0603, longitude: 118.7969),
            country: "China",
            emoji: "🏯",
            subwayStations: [
                PresetSubwayStation(name: "Xinjiekou", nameZh: "新街口", coordinate: CLLocationCoordinate2D(latitude: 32.0458, longitude: 118.7789)),
                PresetSubwayStation(name: "Nanjing Railway Station", nameZh: "南京站", coordinate: CLLocationCoordinate2D(latitude: 32.0863, longitude: 118.7972)),
                PresetSubwayStation(name: "Gulou", nameZh: "鼓楼", coordinate: CLLocationCoordinate2D(latitude: 32.0606, longitude: 118.7717)),
                PresetSubwayStation(name: "Confucius Temple", nameZh: "夫子庙", coordinate: CLLocationCoordinate2D(latitude: 32.0237, longitude: 118.7889)),
                PresetSubwayStation(name: "Olympic Sports Center", nameZh: "奥体中心", coordinate: CLLocationCoordinate2D(latitude: 32.0111, longitude: 118.7361)),
                PresetSubwayStation(name: "Jimingsi", nameZh: "鸡鸣寺", coordinate: CLLocationCoordinate2D(latitude: 32.0706, longitude: 118.7889))
            ]
        ),
        
        // Americas
        PresetLocation(
            name: "New York, USA",
            nameZh: "美国纽约",
            coordinate: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
            country: "USA",
            emoji: "🗽",
            subwayStations: [
                PresetSubwayStation(name: "Times Square", nameZh: "时代广场", coordinate: CLLocationCoordinate2D(latitude: 40.7580, longitude: -73.9855)),
                PresetSubwayStation(name: "Grand Central", nameZh: "中央车站", coordinate: CLLocationCoordinate2D(latitude: 40.7527, longitude: -73.9772)),
                PresetSubwayStation(name: "Union Square", nameZh: "联合广场", coordinate: CLLocationCoordinate2D(latitude: 40.7359, longitude: -73.9911)),
                PresetSubwayStation(name: "Brooklyn Bridge", nameZh: "布鲁克林大桥", coordinate: CLLocationCoordinate2D(latitude: 40.7127, longitude: -73.9989)),
                PresetSubwayStation(name: "Penn Station", nameZh: "宾州车站", coordinate: CLLocationCoordinate2D(latitude: 40.7505, longitude: -73.9934)),
                PresetSubwayStation(name: "Columbus Circle", nameZh: "哥伦布圆环", coordinate: CLLocationCoordinate2D(latitude: 40.7681, longitude: -73.9819))
            ]
        ),
        PresetLocation(
            name: "San Francisco, USA",
            nameZh: "美国旧金山",
            coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            country: "USA",
            emoji: "🌉",
            subwayStations: [
                PresetSubwayStation(name: "Powell Street", nameZh: "鲍威尔街", coordinate: CLLocationCoordinate2D(latitude: 37.7844, longitude: -122.4079)),
                PresetSubwayStation(name: "Embarcadero", nameZh: "内河码头", coordinate: CLLocationCoordinate2D(latitude: 37.7929, longitude: -122.3967)),
                PresetSubwayStation(name: "Montgomery Street", nameZh: "蒙哥马利街", coordinate: CLLocationCoordinate2D(latitude: 37.7894, longitude: -122.4013)),
                PresetSubwayStation(name: "Civic Center", nameZh: "市政中心", coordinate: CLLocationCoordinate2D(latitude: 37.7798, longitude: -122.4134)),
                PresetSubwayStation(name: "16th Street Mission", nameZh: "16街米申", coordinate: CLLocationCoordinate2D(latitude: 37.7650, longitude: -122.4197)),
                PresetSubwayStation(name: "24th Street Mission", nameZh: "24街米申", coordinate: CLLocationCoordinate2D(latitude: 37.7524, longitude: -122.4183))
            ]
        ),
        PresetLocation(
            name: "Los Angeles, USA",
            nameZh: "美国洛杉矶",
            coordinate: CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437),
            country: "USA",
            emoji: "🎬",
            subwayStations: [
                PresetSubwayStation(name: "Union Station", nameZh: "联合车站", coordinate: CLLocationCoordinate2D(latitude: 34.0560, longitude: -118.2348)),
                PresetSubwayStation(name: "Hollywood/Highland", nameZh: "好莱坞高地", coordinate: CLLocationCoordinate2D(latitude: 34.1024, longitude: -118.3387)),
                PresetSubwayStation(name: "Universal City", nameZh: "环球影城", coordinate: CLLocationCoordinate2D(latitude: 34.1381, longitude: -118.3534)),
                PresetSubwayStation(name: "7th Street/Metro Center", nameZh: "第七街地铁中心", coordinate: CLLocationCoordinate2D(latitude: 34.0484, longitude: -118.2582)),
                PresetSubwayStation(name: "Pershing Square", nameZh: "潘兴广场", coordinate: CLLocationCoordinate2D(latitude: 34.0486, longitude: -118.2512)),
                PresetSubwayStation(name: "Westlake/MacArthur Park", nameZh: "西湖麦克阿瑟公园", coordinate: CLLocationCoordinate2D(latitude: 34.0579, longitude: -118.2765))
            ]
        ),
        
        // Europe
        PresetLocation(
            name: "London, UK",
            nameZh: "英国伦敦",
            coordinate: CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278),
            country: "UK",
            emoji: "🎡",
            subwayStations: [
                PresetSubwayStation(name: "King's Cross", nameZh: "国王十字", coordinate: CLLocationCoordinate2D(latitude: 51.5308, longitude: -0.1238)),
                PresetSubwayStation(name: "Oxford Circus", nameZh: "牛津圆环", coordinate: CLLocationCoordinate2D(latitude: 51.5152, longitude: -0.1415)),
                PresetSubwayStation(name: "Piccadilly Circus", nameZh: "皮卡迪利圆环", coordinate: CLLocationCoordinate2D(latitude: 51.5098, longitude: -0.1342)),
                PresetSubwayStation(name: "Leicester Square", nameZh: "莱斯特广场", coordinate: CLLocationCoordinate2D(latitude: 51.5113, longitude: -0.1281)),
                PresetSubwayStation(name: "Westminster", nameZh: "威斯敏斯特", coordinate: CLLocationCoordinate2D(latitude: 51.5010, longitude: -0.1246)),
                PresetSubwayStation(name: "London Bridge", nameZh: "伦敦桥", coordinate: CLLocationCoordinate2D(latitude: 51.5048, longitude: -0.0863))
            ]
        ),
        PresetLocation(
            name: "Paris, France",
            nameZh: "法国巴黎",
            coordinate: CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522),
            country: "France",
            emoji: "🗼",
            subwayStations: [
                PresetSubwayStation(name: "Châtelet", nameZh: "夏特雷", coordinate: CLLocationCoordinate2D(latitude: 48.8583, longitude: 2.3470)),
                PresetSubwayStation(name: "Gare du Nord", nameZh: "北站", coordinate: CLLocationCoordinate2D(latitude: 48.8809, longitude: 2.3553)),
                PresetSubwayStation(name: "République", nameZh: "共和国", coordinate: CLLocationCoordinate2D(latitude: 48.8676, longitude: 2.3633)),
                PresetSubwayStation(name: "Opéra", nameZh: "歌剧院", coordinate: CLLocationCoordinate2D(latitude: 48.8708, longitude: 2.3314)),
                PresetSubwayStation(name: "Champs-Élysées", nameZh: "香榭丽舍", coordinate: CLLocationCoordinate2D(latitude: 48.8698, longitude: 2.3075)),
                PresetSubwayStation(name: "Montparnasse", nameZh: "蒙帕纳斯", coordinate: CLLocationCoordinate2D(latitude: 48.8420, longitude: 2.3219))
            ]
        ),
        PresetLocation(
            name: "Rome, Italy",
            nameZh: "意大利罗马",
            coordinate: CLLocationCoordinate2D(latitude: 41.9028, longitude: 12.4964),
            country: "Italy",
            emoji: "🏛️",
            subwayStations: [
                PresetSubwayStation(name: "Termini", nameZh: "特米尼", coordinate: CLLocationCoordinate2D(latitude: 41.9010, longitude: 12.5024)),
                PresetSubwayStation(name: "Colosseo", nameZh: "斗兽场", coordinate: CLLocationCoordinate2D(latitude: 41.8902, longitude: 12.4923)),
                PresetSubwayStation(name: "Spagna", nameZh: "西班牙广场", coordinate: CLLocationCoordinate2D(latitude: 41.9062, longitude: 12.4822)),
                PresetSubwayStation(name: "Flaminio", nameZh: "弗拉米尼奥", coordinate: CLLocationCoordinate2D(latitude: 41.9107, longitude: 12.4762)),
                PresetSubwayStation(name: "Repubblica", nameZh: "共和国", coordinate: CLLocationCoordinate2D(latitude: 41.9038, longitude: 12.4970)),
                PresetSubwayStation(name: "Barberini", nameZh: "巴贝里尼", coordinate: CLLocationCoordinate2D(latitude: 41.9039, longitude: 12.4897))
            ]
        ),
        
        // Oceania
        PresetLocation(
            name: "Sydney, Australia",
            nameZh: "澳大利亚悉尼",
            coordinate: CLLocationCoordinate2D(latitude: -33.8688, longitude: 151.2093),
            country: "Australia",
            emoji: "🦘",
            subwayStations: [
                PresetSubwayStation(name: "Central Station", nameZh: "中央车站", coordinate: CLLocationCoordinate2D(latitude: -33.8830, longitude: 151.2061)),
                PresetSubwayStation(name: "Town Hall", nameZh: "市政厅", coordinate: CLLocationCoordinate2D(latitude: -33.8732, longitude: 151.2063)),
                PresetSubwayStation(name: "Circular Quay", nameZh: "环形码头", coordinate: CLLocationCoordinate2D(latitude: -33.8617, longitude: 151.2109)),
                PresetSubwayStation(name: "Martin Place", nameZh: "马丁广场", coordinate: CLLocationCoordinate2D(latitude: -33.8671, longitude: 151.2099)),
                PresetSubwayStation(name: "Wynyard", nameZh: "温亚德", coordinate: CLLocationCoordinate2D(latitude: -33.8659, longitude: 151.2062)),
                PresetSubwayStation(name: "Kings Cross", nameZh: "国王十字", coordinate: CLLocationCoordinate2D(latitude: -33.8737, longitude: 151.2224))
            ]
        )
    ]
}

/// Location source type
enum LocationSource: Equatable {
    case currentLocation
    case preset(PresetLocation)
    case custom(CLLocationCoordinate2D, String)
    
    var coordinate: CLLocationCoordinate2D? {
        switch self {
        case .currentLocation:
            return nil // Will be determined at runtime
        case .preset(let location):
            return location.coordinate
        case .custom(let coordinate, _):
            return coordinate
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
        }
    }
}
