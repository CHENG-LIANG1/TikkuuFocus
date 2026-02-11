//
//  PerformanceConfig.swift
//  Tikkuu Focus
//
//  Created by Tikkuu on 2026/2/11.
//

import Foundation

/// Performance configuration and constants
enum PerformanceConfig {
    
    // MARK: - Animation Performance
    
    /// Enable/disable complex animations on low-end devices
    static var enableComplexAnimations: Bool {
        // Disable on older devices
        return ProcessInfo.processInfo.processorCount >= 4
    }
    
    /// Enable/disable blur effects
    static var enableBlurEffects: Bool {
        return ProcessInfo.processInfo.physicalMemory >= 2_000_000_000 // 2GB+
    }
    
    /// Maximum number of simultaneous animations
    static let maxSimultaneousAnimations = 10
    
    // MARK: - Data Loading
    
    /// Batch size for loading records
    static let recordBatchSize = 50
    
    /// Maximum records to display at once
    static let maxDisplayRecords = 100
    
    /// Enable pagination for large datasets
    static var enablePagination: Bool {
        return true
    }
    
    // MARK: - Cache Configuration
    
    /// Cache expiration time (seconds)
    static let cacheExpiration: TimeInterval = 300 // 5 minutes
    
    /// Maximum cache size (MB)
    static let maxCacheSize = 50
    
    /// Enable memory cache
    static let enableMemoryCache = true
    
    // MARK: - Network Configuration
    
    /// Weather update interval (seconds)
    static let weatherUpdateInterval: TimeInterval = 300 // 5 minutes
    
    /// Location update minimum distance (meters)
    static let locationUpdateDistance: Double = 50
    
    /// Network request timeout (seconds)
    static let networkTimeout: TimeInterval = 30
    
    // MARK: - Map Performance
    
    /// Maximum POI markers to display
    static let maxPOIMarkers = 20
    
    /// Map update throttle interval (seconds)
    static let mapUpdateThrottle: TimeInterval = 0.5
    
    /// Enable map clustering
    static let enableMapClustering = true
    
    // MARK: - UI Performance
    
    /// Enable lazy loading for lists
    static let enableLazyLoading = true
    
    /// Scroll view prefetch distance
    static let scrollPrefetchDistance = 3
    
    /// Enable view recycling
    static let enableViewRecycling = true
    
    // MARK: - Background Tasks
    
    /// Background task execution interval (seconds)
    static let backgroundTaskInterval: TimeInterval = 60
    
    /// Enable background refresh
    static let enableBackgroundRefresh = true
    
    // MARK: - Memory Management
    
    /// Memory warning threshold (MB)
    static let memoryWarningThreshold = 100.0
    
    /// Auto-clear cache on memory warning
    static let autoClearCacheOnMemoryWarning = true
    
    /// Maximum image cache size (count)
    static let maxImageCacheCount = 50
    
    // MARK: - Debug Performance
    
    #if DEBUG
    /// Enable performance logging
    static let enablePerformanceLogging = true
    
    /// Enable memory logging
    static let enableMemoryLogging = true
    
    /// Log slow operations threshold (seconds)
    static let slowOperationThreshold: TimeInterval = 0.1
    #else
    static let enablePerformanceLogging = false
    static let enableMemoryLogging = false
    static let slowOperationThreshold: TimeInterval = 1.0
    #endif
    
    // MARK: - Device Capabilities
    
    /// Check if device is low-end
    static var isLowEndDevice: Bool {
        let processorCount = ProcessInfo.processInfo.processorCount
        let memory = ProcessInfo.processInfo.physicalMemory
        
        // Consider low-end if < 4 cores or < 2GB RAM
        return processorCount < 4 || memory < 2_000_000_000
    }
    
    /// Get recommended quality level
    static var qualityLevel: QualityLevel {
        if isLowEndDevice {
            return .low
        } else if ProcessInfo.processInfo.processorCount >= 6 {
            return .high
        } else {
            return .medium
        }
    }
    
    enum QualityLevel {
        case low, medium, high
        
        var animationDuration: Double {
            switch self {
            case .low: return 0.2
            case .medium: return 0.3
            case .high: return 0.4
            }
        }
        
        var enableShadows: Bool {
            switch self {
            case .low: return false
            case .medium, .high: return true
            }
        }
        
        var enableGradients: Bool {
            return true // Always enable, they're cheap
        }
        
        var maxParticles: Int {
            switch self {
            case .low: return 20
            case .medium: return 50
            case .high: return 100
            }
        }
    }
    
    // MARK: - Optimization Helpers
    
    /// Should use simplified UI
    static func shouldSimplifyUI(for itemCount: Int) -> Bool {
        return isLowEndDevice && itemCount > 50
    }
    
    /// Should throttle updates
    static func shouldThrottleUpdates(for frequency: TimeInterval) -> Bool {
        return isLowEndDevice && frequency < 1.0
    }
    
    /// Get optimal batch size for processing
    static func optimalBatchSize(for totalItems: Int) -> Int {
        if isLowEndDevice {
            return min(25, totalItems)
        } else {
            return min(50, totalItems)
        }
    }
}
