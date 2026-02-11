//
//  Trophy.swift
//  Tikkuu Focus
//
//  Created by Tikkuu on 2026/2/8.
//

import SwiftUI
import Combine

/// Trophy/Achievement model
struct Trophy: Identifiable, Equatable {
    let id: String
    let category: TrophyCategory
    let tier: TrophyTier
    let requirement: Int
    var isUnlocked: Bool = false
    var progress: Int = 0
    var unlockedDate: Date?
    
    var localizedTitle: String {
        L("trophy.\(id).title")
    }
    
    var localizedDescription: String {
        L("trophy.\(id).description")
    }
    
    var icon: String {
        // Use category-specific icon when unlocked, lock when locked
        if isUnlocked {
            return category.unlockedIcon
        } else {
            return "lock.fill"
        }
    }
    
    var color: Color {
        tier.color
    }
    
    var progressPercentage: Double {
        min(Double(progress) / Double(requirement), 1.0)
    }
}

/// Trophy categories
enum TrophyCategory: String, CaseIterable {
    case distance       // 里程相关
    case journey        // 旅程次数
    case location       // 地点探索
    case time           // 时间相关
    case poi            // 景点发现
    case streak         // 连续天数
    case speed          // 速度相关
    case weather        // 天气相关
    case festival       // 节日相关
    case special        // 特殊成就
    
    var icon: String {
        switch self {
        case .distance: return "location.fill"
        case .journey: return "flag.checkered"
        case .location: return "globe.asia.australia.fill"
        case .time: return "clock.fill"
        case .poi: return "star.fill"
        case .streak: return "flame.fill"
        case .speed: return "speedometer"
        case .weather: return "cloud.sun.fill"
        case .festival: return "gift.fill"
        case .special: return "sparkles"
        }
    }
    
    var unlockedIcon: String {
        switch self {
        case .distance: return "figure.walk.motion"
        case .journey: return "flag.checkered.2.crossed"
        case .location: return "map.fill"
        case .time: return "hourglass"
        case .poi: return "star.circle.fill"
        case .streak: return "flame.fill"
        case .speed: return "bolt.fill"
        case .weather: return "cloud.sun.rain.fill"
        case .festival: return "party.popper.fill"
        case .special: return "crown.fill"
        }
    }
    
    var localizedName: String {
        L("trophy.category.\(rawValue)")
    }
}

/// Trophy tiers
enum TrophyTier: String, CaseIterable {
    case bronze
    case silver
    case gold
    case platinum
    case diamond
    
    var color: Color {
        switch self {
        case .bronze: return Color(red: 0.8, green: 0.5, blue: 0.2)
        case .silver: return Color(red: 0.75, green: 0.75, blue: 0.75)
        case .gold: return Color(red: 1.0, green: 0.84, blue: 0.0)
        case .platinum: return Color(red: 0.9, green: 0.95, blue: 1.0)
        case .diamond: return Color(red: 0.7, green: 0.9, blue: 1.0)
        }
    }
    
    var icon: String {
        switch self {
        case .bronze: return "medal.fill"
        case .silver: return "medal.fill"
        case .gold: return "medal.fill"
        case .platinum: return "star.circle.fill"
        case .diamond: return "crown.fill"
        }
    }
    
    var localizedName: String {
        L("trophy.tier.\(rawValue)")
    }
}

/// Trophy manager to track and unlock achievements
class TrophyManager: ObservableObject {
    @Published var trophies: [Trophy] = []
    
    init() {
        setupTrophies()
    }
    
    private func setupTrophies() {
        trophies = [
            // Distance trophies (里程奖杯) - 9个
            Trophy(id: "distance_1km", category: .distance, tier: .bronze, requirement: 1000),
            Trophy(id: "distance_5km", category: .distance, tier: .bronze, requirement: 5000),
            Trophy(id: "distance_10km", category: .distance, tier: .silver, requirement: 10000),
            Trophy(id: "distance_25km", category: .distance, tier: .silver, requirement: 25000),
            Trophy(id: "distance_50km", category: .distance, tier: .gold, requirement: 50000),
            Trophy(id: "distance_100km", category: .distance, tier: .gold, requirement: 100000),
            Trophy(id: "distance_250km", category: .distance, tier: .platinum, requirement: 250000),
            Trophy(id: "distance_500km", category: .distance, tier: .platinum, requirement: 500000),
            Trophy(id: "distance_1000km", category: .distance, tier: .diamond, requirement: 1000000),
            
            // Journey count trophies (旅程次数) - 9个
            Trophy(id: "journey_1", category: .journey, tier: .bronze, requirement: 1),
            Trophy(id: "journey_5", category: .journey, tier: .bronze, requirement: 5),
            Trophy(id: "journey_10", category: .journey, tier: .silver, requirement: 10),
            Trophy(id: "journey_25", category: .journey, tier: .silver, requirement: 25),
            Trophy(id: "journey_50", category: .journey, tier: .gold, requirement: 50),
            Trophy(id: "journey_100", category: .journey, tier: .gold, requirement: 100),
            Trophy(id: "journey_250", category: .journey, tier: .platinum, requirement: 250),
            Trophy(id: "journey_500", category: .journey, tier: .platinum, requirement: 500),
            Trophy(id: "journey_1000", category: .journey, tier: .diamond, requirement: 1000),
            
            // Location exploration trophies (地点探索) - 7个
            Trophy(id: "location_3", category: .location, tier: .bronze, requirement: 3),
            Trophy(id: "location_5", category: .location, tier: .bronze, requirement: 5),
            Trophy(id: "location_10", category: .location, tier: .silver, requirement: 10),
            Trophy(id: "location_20", category: .location, tier: .gold, requirement: 20),
            Trophy(id: "location_30", category: .location, tier: .gold, requirement: 30),
            Trophy(id: "location_50", category: .location, tier: .platinum, requirement: 50),
            Trophy(id: "location_100", category: .location, tier: .diamond, requirement: 100),
            
            // Time trophies (专注时间) - 9个
            Trophy(id: "time_30min", category: .time, tier: .bronze, requirement: 1800),
            Trophy(id: "time_1h", category: .time, tier: .bronze, requirement: 3600),
            Trophy(id: "time_5h", category: .time, tier: .silver, requirement: 18000),
            Trophy(id: "time_10h", category: .time, tier: .silver, requirement: 36000),
            Trophy(id: "time_25h", category: .time, tier: .gold, requirement: 90000),
            Trophy(id: "time_50h", category: .time, tier: .gold, requirement: 180000),
            Trophy(id: "time_100h", category: .time, tier: .platinum, requirement: 360000),
            Trophy(id: "time_250h", category: .time, tier: .platinum, requirement: 900000),
            Trophy(id: "time_500h", category: .time, tier: .diamond, requirement: 1800000),
            
            // POI discovery trophies (景点发现) - 8个
            Trophy(id: "poi_5", category: .poi, tier: .bronze, requirement: 5),
            Trophy(id: "poi_10", category: .poi, tier: .bronze, requirement: 10),
            Trophy(id: "poi_25", category: .poi, tier: .silver, requirement: 25),
            Trophy(id: "poi_50", category: .poi, tier: .silver, requirement: 50),
            Trophy(id: "poi_100", category: .poi, tier: .gold, requirement: 100),
            Trophy(id: "poi_250", category: .poi, tier: .gold, requirement: 250),
            Trophy(id: "poi_500", category: .poi, tier: .platinum, requirement: 500),
            Trophy(id: "poi_1000", category: .poi, tier: .diamond, requirement: 1000),
            
            // Streak trophies (连续天数) - 8个
            Trophy(id: "streak_2", category: .streak, tier: .bronze, requirement: 2),
            Trophy(id: "streak_3", category: .streak, tier: .bronze, requirement: 3),
            Trophy(id: "streak_7", category: .streak, tier: .silver, requirement: 7),
            Trophy(id: "streak_14", category: .streak, tier: .silver, requirement: 14),
            Trophy(id: "streak_30", category: .streak, tier: .gold, requirement: 30),
            Trophy(id: "streak_60", category: .streak, tier: .gold, requirement: 60),
            Trophy(id: "streak_100", category: .streak, tier: .platinum, requirement: 100),
            Trophy(id: "streak_365", category: .streak, tier: .diamond, requirement: 365),
            
            // Speed trophies (速度成就) - 5个
            Trophy(id: "speed_walker", category: .speed, tier: .bronze, requirement: 2),
            Trophy(id: "speed_jogger", category: .speed, tier: .silver, requirement: 5),
            Trophy(id: "speed_cyclist", category: .speed, tier: .gold, requirement: 8),
            Trophy(id: "speed_racer", category: .speed, tier: .platinum, requirement: 12),
            Trophy(id: "speed_sonic", category: .speed, tier: .diamond, requirement: 17),
            
            // Weather trophies (天气成就) - 5个
            Trophy(id: "weather_rain", category: .weather, tier: .silver, requirement: 1),
            Trophy(id: "weather_night", category: .weather, tier: .bronze, requirement: 5),
            Trophy(id: "weather_night_owl", category: .weather, tier: .silver, requirement: 20),
            Trophy(id: "weather_allseasons", category: .weather, tier: .gold, requirement: 4),
            Trophy(id: "weather_year_round", category: .weather, tier: .platinum, requirement: 12),
            
            // Chinese Festival trophies (中国节日) - 15个
            Trophy(id: "festival_spring", category: .festival, tier: .gold, requirement: 1), // 春节
            Trophy(id: "festival_lantern", category: .festival, tier: .silver, requirement: 1), // 元宵节
            Trophy(id: "festival_qingming", category: .festival, tier: .silver, requirement: 1), // 清明节
            Trophy(id: "festival_dragon_boat", category: .festival, tier: .gold, requirement: 1), // 端午节
            Trophy(id: "festival_qixi", category: .festival, tier: .silver, requirement: 1), // 七夕节
            Trophy(id: "festival_mid_autumn", category: .festival, tier: .gold, requirement: 1), // 中秋节
            Trophy(id: "festival_double_nine", category: .festival, tier: .silver, requirement: 1), // 重阳节
            Trophy(id: "festival_national_day", category: .festival, tier: .gold, requirement: 1), // 国庆节
            Trophy(id: "festival_new_year", category: .festival, tier: .silver, requirement: 1), // 元旦
            Trophy(id: "festival_labor_day", category: .festival, tier: .silver, requirement: 1), // 劳动节
            Trophy(id: "festival_youth_day", category: .festival, tier: .bronze, requirement: 1), // 青年节
            Trophy(id: "festival_children_day", category: .festival, tier: .bronze, requirement: 1), // 儿童节
            Trophy(id: "festival_christmas", category: .festival, tier: .silver, requirement: 1), // 圣诞节
            Trophy(id: "festival_halloween", category: .festival, tier: .bronze, requirement: 1), // 万圣节
            Trophy(id: "festival_valentines", category: .festival, tier: .bronze, requirement: 1), // 情人节
            
            // Special achievement trophies (特殊成就) - 40+个
            Trophy(id: "special_marathon", category: .special, tier: .platinum, requirement: 42195),
            Trophy(id: "special_century", category: .special, tier: .diamond, requirement: 160934),
            Trophy(id: "special_early_bird", category: .special, tier: .silver, requirement: 10),
            Trophy(id: "special_night_rider", category: .special, tier: .gold, requirement: 50),
            Trophy(id: "special_weekend_warrior", category: .special, tier: .gold, requirement: 20),
            Trophy(id: "special_daily_habit", category: .special, tier: .platinum, requirement: 180),
            Trophy(id: "special_explorer", category: .special, tier: .diamond, requirement: 200),
            Trophy(id: "special_poi_hunter", category: .special, tier: .diamond, requirement: 2000),
            Trophy(id: "special_speed_demon", category: .special, tier: .diamond, requirement: 25),
            Trophy(id: "special_all_transport", category: .special, tier: .gold, requirement: 4),
            Trophy(id: "special_long_journey", category: .special, tier: .platinum, requirement: 7200),
            Trophy(id: "special_dedication", category: .special, tier: .diamond, requirement: 2000),
            
            // Time-based special (时间特殊成就) - 10个
            Trophy(id: "special_sunrise", category: .special, tier: .silver, requirement: 5), // 日出时分(5-6点)
            Trophy(id: "special_golden_hour", category: .special, tier: .bronze, requirement: 10), // 黄金时段(6-8点)
            Trophy(id: "special_lunch_break", category: .special, tier: .bronze, requirement: 10), // 午休时光(12-14点)
            Trophy(id: "special_afternoon_tea", category: .special, tier: .bronze, requirement: 10), // 下午茶(15-17点)
            Trophy(id: "special_sunset", category: .special, tier: .silver, requirement: 5), // 日落时分(18-19点)
            Trophy(id: "special_midnight", category: .special, tier: .gold, requirement: 3), // 午夜时分(0点)
            Trophy(id: "special_all_hours", category: .special, tier: .platinum, requirement: 24), // 24小时全覆盖
            Trophy(id: "special_workday", category: .special, tier: .silver, requirement: 50), // 工作日战士
            Trophy(id: "special_weekend_only", category: .special, tier: .bronze, requirement: 10), // 周末专属
            Trophy(id: "special_every_weekday", category: .special, tier: .gold, requirement: 7), // 一周七天
            
            // Transport-based special (交通特殊成就) - 8个
            Trophy(id: "special_walking_master", category: .special, tier: .gold, requirement: 100), // 步行大师
            Trophy(id: "special_cycling_pro", category: .special, tier: .gold, requirement: 100), // 骑行专家
            Trophy(id: "special_driving_expert", category: .special, tier: .gold, requirement: 100), // 驾驶专家
            Trophy(id: "special_subway_rider", category: .special, tier: .gold, requirement: 100), // 地铁达人
            Trophy(id: "special_walking_only", category: .special, tier: .silver, requirement: 50), // 纯步行
            Trophy(id: "special_no_driving", category: .special, tier: .silver, requirement: 50), // 环保出行
            Trophy(id: "special_transport_variety", category: .special, tier: .bronze, requirement: 10), // 交通多样性
            Trophy(id: "special_single_transport", category: .special, tier: .bronze, requirement: 30), // 专一出行
            
            // Distance-based special (距离特殊成就) - 8个
            Trophy(id: "special_short_trips", category: .special, tier: .bronze, requirement: 50), // 短途专家(50次<5km)
            Trophy(id: "special_medium_trips", category: .special, tier: .silver, requirement: 30), // 中途旅行(30次5-20km)
            Trophy(id: "special_long_trips", category: .special, tier: .gold, requirement: 10), // 长途跋涉(10次>20km)
            Trophy(id: "special_ultra_distance", category: .special, tier: .platinum, requirement: 5), // 超长距离(5次>50km)
            Trophy(id: "special_consistent", category: .special, tier: .silver, requirement: 20), // 稳定输出(20次相似距离)
            Trophy(id: "special_distance_variety", category: .special, tier: .bronze, requirement: 10), // 距离多样
            Trophy(id: "special_incremental", category: .special, tier: .gold, requirement: 10), // 循序渐进
            Trophy(id: "special_distance_king", category: .special, tier: .diamond, requirement: 100), // 里程之王(单次100km)
            
            // Social & Fun (社交趣味) - 10个
            Trophy(id: "special_birthday", category: .special, tier: .gold, requirement: 1), // 生日旅程
            Trophy(id: "special_lucky_seven", category: .special, tier: .bronze, requirement: 7), // 幸运7(7次旅程)
            Trophy(id: "special_perfect_ten", category: .special, tier: .silver, requirement: 10), // 完美10
            Trophy(id: "special_double_eleven", category: .special, tier: .bronze, requirement: 1), // 双十一
            Trophy(id: "special_520", category: .special, tier: .bronze, requirement: 1), // 5月20日
            Trophy(id: "special_618", category: .special, tier: .bronze, requirement: 1), // 6月18日
            Trophy(id: "special_first_snow", category: .special, tier: .silver, requirement: 1), // 初雪
            Trophy(id: "special_full_moon", category: .special, tier: .bronze, requirement: 3), // 满月之夜
            Trophy(id: "special_rainy_day", category: .special, tier: .bronze, requirement: 5), // 雨天旅行
            Trophy(id: "special_perfect_weather", category: .special, tier: .bronze, requirement: 10), // 完美天气
            
            // Achievement milestones (成就里程碑) - 6个
            Trophy(id: "special_first_week", category: .special, tier: .bronze, requirement: 7), // 第一周
            Trophy(id: "special_first_month", category: .special, tier: .silver, requirement: 30), // 第一月
            Trophy(id: "special_first_season", category: .special, tier: .gold, requirement: 90), // 第一季
            Trophy(id: "special_half_year", category: .special, tier: .platinum, requirement: 180), // 半年
            Trophy(id: "special_full_year", category: .special, tier: .diamond, requirement: 365), // 一整年
            Trophy(id: "special_veteran", category: .special, tier: .diamond, requirement: 730), // 老兵(2年)
        ]
    }
    
    /// Update trophy progress based on journey records
    func updateProgress(with records: [JourneyRecord]) {
        let calendar = Calendar.current
        
        // Calculate basic stats
        let totalDistance = records.reduce(0.0) { $0 + $1.distanceTraveled }
        let totalJourneys = records.count
        let totalTime = records.reduce(0.0) { $0 + $1.duration }
        let totalPOIs = records.reduce(0) { $0 + $1.discoveredPOICount }
        let uniqueLocations = Set(records.map { $0.startLocationName }).count
        let currentStreak = calculateStreak(from: records)
        let maxSpeed = records.map { record in
            guard record.duration > 0 else { return 0.0 }
            return record.distanceTraveled / record.duration
        }.max() ?? 0
        
        // Time-based stats
        let nightJourneys = records.filter {
            let hour = calendar.component(.hour, from: $0.startTime)
            return hour >= 22 || hour < 6
        }.count
        
        let earlyBirdJourneys = records.filter {
            let hour = calendar.component(.hour, from: $0.startTime)
            return hour >= 5 && hour < 7
        }.count
        
        let lateNightJourneys = records.filter {
            let hour = calendar.component(.hour, from: $0.startTime)
            return hour >= 0 && hour < 4
        }.count
        
        let sunriseJourneys = records.filter {
            let hour = calendar.component(.hour, from: $0.startTime)
            return hour >= 5 && hour < 6
        }.count
        
        let goldenHourJourneys = records.filter {
            let hour = calendar.component(.hour, from: $0.startTime)
            return hour >= 6 && hour < 8
        }.count
        
        let lunchBreakJourneys = records.filter {
            let hour = calendar.component(.hour, from: $0.startTime)
            return hour >= 12 && hour < 14
        }.count
        
        let afternoonTeaJourneys = records.filter {
            let hour = calendar.component(.hour, from: $0.startTime)
            return hour >= 15 && hour < 17
        }.count
        
        let sunsetJourneys = records.filter {
            let hour = calendar.component(.hour, from: $0.startTime)
            return hour >= 18 && hour < 19
        }.count
        
        let midnightJourneys = records.filter {
            let hour = calendar.component(.hour, from: $0.startTime)
            return hour == 0
        }.count
        
        let uniqueHours = Set(records.map { calendar.component(.hour, from: $0.startTime) }).count
        
        // Day-based stats
        let weekendJourneys = records.filter {
            let weekday = calendar.component(.weekday, from: $0.startTime)
            return weekday == 1 || weekday == 7
        }.count
        
        let workdayJourneys = records.filter {
            let weekday = calendar.component(.weekday, from: $0.startTime)
            return weekday >= 2 && weekday <= 6
        }.count
        
        let uniqueWeekdays = Set(records.map { calendar.component(.weekday, from: $0.startTime) }).count
        
        // Transport stats
        let uniqueTransportModes = Set(records.map { $0.transportMode }).count
        let walkingJourneys = records.filter { $0.transportMode == TransportMode.walking.rawValue }.count
        let cyclingJourneys = records.filter { $0.transportMode == TransportMode.cycling.rawValue }.count
        let drivingJourneys = records.filter { $0.transportMode == TransportMode.driving.rawValue }.count
        let subwayJourneys = records.filter { $0.transportMode == TransportMode.subway.rawValue }.count
        
        let nonDrivingJourneys = records.filter { $0.transportMode != TransportMode.driving.rawValue }.count
        let transportVariety = records.count > 0 ? uniqueTransportModes : 0
        
        // Check if using single transport mode
        let singleTransportCount = max(walkingJourneys, cyclingJourneys, drivingJourneys, subwayJourneys)
        
        // Distance-based stats
        let shortTrips = records.filter { $0.distanceTraveled < 5000 }.count
        let mediumTrips = records.filter { $0.distanceTraveled >= 5000 && $0.distanceTraveled < 20000 }.count
        let longTrips = records.filter { $0.distanceTraveled >= 20000 }.count
        let ultraTrips = records.filter { $0.distanceTraveled >= 50000 }.count
        let maxSingleDistance = records.map { $0.distanceTraveled }.max() ?? 0
        
        // Check distance consistency (within 20% variance)
        let avgDistance = totalDistance / Double(max(records.count, 1))
        let consistentTrips = records.filter {
            abs($0.distanceTraveled - avgDistance) / avgDistance < 0.2
        }.count
        
        // Check incremental progress (each journey longer than previous)
        var incrementalCount = 0
        let sortedByDate = records.sorted { $0.startTime < $1.startTime }
        for i in 1..<sortedByDate.count {
            if sortedByDate[i].distanceTraveled > sortedByDate[i-1].distanceTraveled {
                incrementalCount += 1
            }
        }
        
        // Other stats
        let longestJourneyTime = records.map { $0.duration }.max() ?? 0
        let uniqueMonths = Set(records.map { calendar.component(.month, from: $0.startTime) }).count
        
        // Festival checks
        let festivalJourneys = checkFestivalJourneys(records: records)
        
        // Milestone stats
        let uniqueDays = Set(records.map { calendar.startOfDay(for: $0.startTime) }).count
        
        // Update each trophy
        for index in trophies.indices {
            let trophy = trophies[index]
            
            switch trophy.id {
            // Distance trophies
            case let id where id.hasPrefix("distance_"):
                trophies[index].progress = Int(totalDistance)
                
            // Journey count trophies
            case let id where id.hasPrefix("journey_"):
                trophies[index].progress = totalJourneys
                
            // Location trophies
            case let id where id.hasPrefix("location_"):
                trophies[index].progress = uniqueLocations
                
            // Time trophies
            case let id where id.hasPrefix("time_"):
                trophies[index].progress = Int(totalTime)
                
            // POI trophies
            case let id where id.hasPrefix("poi_"):
                trophies[index].progress = totalPOIs
                
            // Streak trophies
            case let id where id.hasPrefix("streak_"):
                trophies[index].progress = currentStreak
                
            // Speed trophies
            case let id where id.hasPrefix("speed_"):
                trophies[index].progress = Int(maxSpeed)
                
            // Weather trophies
            case "weather_night":
                trophies[index].progress = nightJourneys
            case "weather_night_owl":
                trophies[index].progress = nightJourneys
            case "weather_allseasons":
                trophies[index].progress = uniqueMonths
            case "weather_year_round":
                trophies[index].progress = uniqueMonths
            case "weather_rain":
                trophies[index].progress = 0 // Placeholder
                
            // Festival trophies
            case let id where id.hasPrefix("festival_"):
                trophies[index].progress = festivalJourneys[id] ?? 0
                
            // Special achievements - Basic
            case "special_marathon":
                trophies[index].progress = Int(totalDistance)
            case "special_century":
                trophies[index].progress = Int(totalDistance)
            case "special_early_bird":
                trophies[index].progress = earlyBirdJourneys
            case "special_night_rider":
                trophies[index].progress = lateNightJourneys
            case "special_weekend_warrior":
                trophies[index].progress = weekendJourneys
            case "special_daily_habit":
                trophies[index].progress = currentStreak
            case "special_explorer":
                trophies[index].progress = uniqueLocations
            case "special_poi_hunter":
                trophies[index].progress = totalPOIs
            case "special_speed_demon":
                trophies[index].progress = Int(maxSpeed)
            case "special_all_transport":
                trophies[index].progress = uniqueTransportModes
            case "special_long_journey":
                trophies[index].progress = Int(longestJourneyTime)
            case "special_dedication":
                trophies[index].progress = totalJourneys
                
            // Time-based special
            case "special_sunrise":
                trophies[index].progress = sunriseJourneys
            case "special_golden_hour":
                trophies[index].progress = goldenHourJourneys
            case "special_lunch_break":
                trophies[index].progress = lunchBreakJourneys
            case "special_afternoon_tea":
                trophies[index].progress = afternoonTeaJourneys
            case "special_sunset":
                trophies[index].progress = sunsetJourneys
            case "special_midnight":
                trophies[index].progress = midnightJourneys
            case "special_all_hours":
                trophies[index].progress = uniqueHours
            case "special_workday":
                trophies[index].progress = workdayJourneys
            case "special_weekend_only":
                trophies[index].progress = weekendJourneys
            case "special_every_weekday":
                trophies[index].progress = uniqueWeekdays
                
            // Transport-based special
            case "special_walking_master":
                trophies[index].progress = walkingJourneys
            case "special_cycling_pro":
                trophies[index].progress = cyclingJourneys
            case "special_driving_expert":
                trophies[index].progress = drivingJourneys
            case "special_subway_rider":
                trophies[index].progress = subwayJourneys
            case "special_walking_only":
                trophies[index].progress = walkingJourneys == totalJourneys ? walkingJourneys : 0
            case "special_no_driving":
                trophies[index].progress = nonDrivingJourneys
            case "special_transport_variety":
                trophies[index].progress = transportVariety >= 3 ? totalJourneys : 0
            case "special_single_transport":
                trophies[index].progress = singleTransportCount
                
            // Distance-based special
            case "special_short_trips":
                trophies[index].progress = shortTrips
            case "special_medium_trips":
                trophies[index].progress = mediumTrips
            case "special_long_trips":
                trophies[index].progress = longTrips
            case "special_ultra_distance":
                trophies[index].progress = ultraTrips
            case "special_consistent":
                trophies[index].progress = consistentTrips
            case "special_distance_variety":
                trophies[index].progress = (shortTrips > 0 && mediumTrips > 0 && longTrips > 0) ? totalJourneys : 0
            case "special_incremental":
                trophies[index].progress = incrementalCount
            case "special_distance_king":
                trophies[index].progress = Int(maxSingleDistance / 1000)
                
            // Social & Fun
            case "special_birthday":
                trophies[index].progress = 0 // User needs to set birthday
            case "special_lucky_seven":
                trophies[index].progress = totalJourneys >= 7 ? 7 : totalJourneys
            case "special_perfect_ten":
                trophies[index].progress = totalJourneys >= 10 ? 10 : totalJourneys
            case "special_double_eleven":
                trophies[index].progress = festivalJourneys["festival_double_eleven"] ?? 0
            case "special_520":
                trophies[index].progress = festivalJourneys["festival_520"] ?? 0
            case "special_618":
                trophies[index].progress = festivalJourneys["festival_618"] ?? 0
            case "special_first_snow":
                trophies[index].progress = 0 // Weather-based
            case "special_full_moon":
                trophies[index].progress = 0 // Moon phase-based
            case "special_rainy_day":
                trophies[index].progress = 0 // Weather-based
            case "special_perfect_weather":
                trophies[index].progress = 0 // Weather-based
                
            // Achievement milestones
            case "special_first_week":
                trophies[index].progress = uniqueDays >= 7 ? 7 : uniqueDays
            case "special_first_month":
                trophies[index].progress = uniqueDays >= 30 ? 30 : uniqueDays
            case "special_first_season":
                trophies[index].progress = uniqueDays >= 90 ? 90 : uniqueDays
            case "special_half_year":
                trophies[index].progress = uniqueDays >= 180 ? 180 : uniqueDays
            case "special_full_year":
                trophies[index].progress = uniqueDays >= 365 ? 365 : uniqueDays
            case "special_veteran":
                trophies[index].progress = uniqueDays >= 730 ? 730 : uniqueDays
                
            default:
                break
            }
            
            // Check if unlocked
            if trophies[index].progress >= trophy.requirement && !trophies[index].isUnlocked {
                trophies[index].isUnlocked = true
                trophies[index].unlockedDate = Date()
            }
        }
    }
    
    /// Check for festival-specific journeys
    private func checkFestivalJourneys(records: [JourneyRecord]) -> [String: Int] {
        var festivalCounts: [String: Int] = [:]
        let calendar = Calendar.current
        
        for record in records {
            let month = calendar.component(.month, from: record.startTime)
            let day = calendar.component(.day, from: record.startTime)
            
            // Western calendar festivals
            if month == 1 && day == 1 {
                festivalCounts["festival_new_year", default: 0] += 1
            }
            if month == 2 && day == 14 {
                festivalCounts["festival_valentines", default: 0] += 1
            }
            if month == 5 && day == 1 {
                festivalCounts["festival_labor_day", default: 0] += 1
            }
            if month == 5 && day == 4 {
                festivalCounts["festival_youth_day", default: 0] += 1
            }
            if month == 5 && day == 20 {
                festivalCounts["festival_520", default: 0] += 1
            }
            if month == 6 && day == 1 {
                festivalCounts["festival_children_day", default: 0] += 1
            }
            if month == 6 && day == 18 {
                festivalCounts["festival_618", default: 0] += 1
            }
            if month == 10 && day == 1 {
                festivalCounts["festival_national_day", default: 0] += 1
            }
            if month == 10 && day == 31 {
                festivalCounts["festival_halloween", default: 0] += 1
            }
            if month == 11 && day == 11 {
                festivalCounts["festival_double_eleven", default: 0] += 1
            }
            if month == 12 && day == 25 {
                festivalCounts["festival_christmas", default: 0] += 1
            }
            
            // Chinese lunar calendar festivals (approximate dates for 2026)
            // Note: These should be calculated based on lunar calendar
            // For now using approximate Gregorian dates
            if month == 1 && (day >= 28 && day <= 30) {
                festivalCounts["festival_spring", default: 0] += 1
            }
            if month == 2 && day == 12 {
                festivalCounts["festival_lantern", default: 0] += 1
            }
            if month == 4 && day == 4 {
                festivalCounts["festival_qingming", default: 0] += 1
            }
            if month == 6 && day == 3 {
                festivalCounts["festival_dragon_boat", default: 0] += 1
            }
            if month == 8 && day == 19 {
                festivalCounts["festival_qixi", default: 0] += 1
            }
            if month == 9 && day == 29 {
                festivalCounts["festival_mid_autumn", default: 0] += 1
            }
            if month == 10 && day == 21 {
                festivalCounts["festival_double_nine", default: 0] += 1
            }
        }
        
        return festivalCounts
    }
    
    /// Calculate current streak of consecutive days
    private func calculateStreak(from records: [JourneyRecord]) -> Int {
        guard !records.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        let sortedRecords = records.sorted { $0.startTime > $1.startTime }
        
        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())
        
        for record in sortedRecords {
            let recordDate = calendar.startOfDay(for: record.startTime)
            
            if recordDate == currentDate {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
            } else if recordDate < currentDate {
                // Gap in streak
                break
            }
        }
        
        return streak
    }
    
    var unlockedCount: Int {
        trophies.filter { $0.isUnlocked }.count
    }
    
    var totalCount: Int {
        trophies.count
    }
    
    var unlockedPercentage: Double {
        guard totalCount > 0 else { return 0 }
        return Double(unlockedCount) / Double(totalCount)
    }
}
