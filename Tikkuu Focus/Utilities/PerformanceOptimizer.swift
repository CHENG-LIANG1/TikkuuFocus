//
//  PerformanceOptimizer.swift
//  Tikkuu Focus
//
//  Created by Tikkuu on 2026/2/11.
//

import Foundation
import SwiftUI
import UIKit

/// Performance optimization utilities
class PerformanceOptimizer {
    static let shared = PerformanceOptimizer()
    
    private init() {}

    // MARK: - Energy & Motion

    /// True when the device requests reduced visual/CPU load.
    var isEnergySavingMode: Bool {
        ProcessInfo.processInfo.isLowPowerModeEnabled || UIAccessibility.isReduceMotionEnabled
    }

    /// Preferred timer interval for journey position refresh.
    var journeyUpdateInterval: TimeInterval {
        isEnergySavingMode ? 3.0 : 1.5
    }

    /// Preferred timer interval for non-critical UI telemetry updates.
    var secondaryUpdateInterval: TimeInterval {
        isEnergySavingMode ? 8.0 : 5.0
    }
    
    // MARK: - Throttle
    
    /// Throttle function calls to reduce frequency
    func throttle(interval: TimeInterval, action: @escaping () -> Void) -> () -> Void {
        var lastExecutionTime: Date?
        
        return {
            let now = Date()
            if let lastTime = lastExecutionTime {
                let timeSinceLastExecution = now.timeIntervalSince(lastTime)
                if timeSinceLastExecution < interval {
                    return
                }
            }
            
            lastExecutionTime = now
            action()
        }
    }
    
    // MARK: - Debounce
    
    /// Debounce function calls to delay execution
    func debounce(interval: TimeInterval, action: @escaping () -> Void) -> () -> Void {
        var workItem: DispatchWorkItem?
        
        return {
            workItem?.cancel()
            let newWorkItem = DispatchWorkItem(block: action)
            workItem = newWorkItem
            DispatchQueue.main.asyncAfter(deadline: .now() + interval, execute: newWorkItem)
        }
    }
    
    // MARK: - Memory Cache
    
    private var cache: [String: Any] = [:]
    private var cacheTimestamps: [String: Date] = [:]
    private let cacheExpiration: TimeInterval = 300 // 5 minutes
    
    /// Cache a value with expiration
    func cache<T>(_ value: T, forKey key: String) {
        cache[key] = value
        cacheTimestamps[key] = Date()
    }
    
    /// Retrieve cached value if not expired
    func getCached<T>(forKey key: String) -> T? {
        guard let timestamp = cacheTimestamps[key] else { return nil }
        
        let now = Date()
        if now.timeIntervalSince(timestamp) > cacheExpiration {
            // Expired, remove from cache
            cache.removeValue(forKey: key)
            cacheTimestamps.removeValue(forKey: key)
            return nil
        }
        
        return cache[key] as? T
    }
    
    /// Clear all cache
    func clearCache() {
        cache.removeAll()
        cacheTimestamps.removeAll()
    }
    
    // MARK: - Image Cache
    
    private var imageCache: [String: UIImage] = [:]
    
    /// Cache an image
    func cacheImage(_ image: UIImage, forKey key: String) {
        imageCache[key] = image
    }
    
    /// Get cached image
    func getCachedImage(forKey key: String) -> UIImage? {
        return imageCache[key]
    }
    
    /// Clear image cache
    func clearImageCache() {
        imageCache.removeAll()
    }
    
    // MARK: - Performance Monitoring
    
    /// Measure execution time of a block
    @discardableResult
    func measure(label: String = "Operation", block: () -> Void) -> TimeInterval {
        let start = CFAbsoluteTimeGetCurrent()
        block()
        let end = CFAbsoluteTimeGetCurrent()
        let duration = end - start
        
        #if DEBUG
        print("⏱️ [\(label)] took \(String(format: "%.4f", duration))s")
        #endif
        
        return duration
    }
    
    /// Measure async execution time
    func measureAsync(label: String = "Async Operation", block: @escaping () async -> Void) async -> TimeInterval {
        let start = CFAbsoluteTimeGetCurrent()
        await block()
        let end = CFAbsoluteTimeGetCurrent()
        let duration = end - start
        
        #if DEBUG
        print("⏱️ [\(label)] took \(String(format: "%.4f", duration))s")
        #endif
        
        return duration
    }
    
    // MARK: - Memory Management
    
    /// Get current memory usage in MB
    func getMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            let usedMemory = Double(info.resident_size) / 1024.0 / 1024.0
            return usedMemory
        }
        
        return 0
    }
    
    /// Log memory usage
    func logMemoryUsage(label: String = "Memory") {
        let usage = getMemoryUsage()
        #if DEBUG
        print("💾 [\(label)] Memory usage: \(String(format: "%.2f", usage)) MB")
        #endif
    }

    // MARK: - Image Optimization

    /// Compress an image to be under a target size in KB.
    /// - Parameters:
    ///   - image: Source image.
    ///   - maxSizeKB: Maximum size in kilobytes.
    /// - Returns: Compressed UIImage or nil if compression fails.
    func compressImage(_ image: UIImage, maxSizeKB: Int) -> UIImage? {
        let maxBytes = maxSizeKB * 1024
        guard maxBytes > 0 else { return nil }
        var bestData: Data?

        // Quick path: already small enough at high quality
        if let data = image.jpegData(compressionQuality: 0.9), data.count <= maxBytes {
            return UIImage(data: data)
        } else if let data = image.jpegData(compressionQuality: 0.9) {
            bestData = data
        }

        var quality: CGFloat = 0.85
        var currentImage = image

        for _ in 0..<6 {
            if let data = currentImage.jpegData(compressionQuality: quality) {
                if bestData == nil || data.count < bestData!.count {
                    bestData = data
                }
                if data.count <= maxBytes {
                    return UIImage(data: data)
                }
            }

            // Reduce dimensions if still too large
            let scale: CGFloat = 0.85
            let newSize = CGSize(width: currentImage.size.width * scale, height: currentImage.size.height * scale)
            guard newSize.width >= 50, newSize.height >= 50 else { break }

            let renderer = UIGraphicsImageRenderer(size: newSize)
            currentImage = renderer.image { _ in
                currentImage.draw(in: CGRect(origin: .zero, size: newSize))
            }

            quality = max(0.5, quality - 0.1)
        }

        // Final attempt with lower quality
        if let data = currentImage.jpegData(compressionQuality: 0.5) {
            if bestData == nil || data.count < bestData!.count {
                bestData = data
            }
            if data.count <= maxBytes {
                return UIImage(data: data)
            }
        }

        if let bestData, let image = UIImage(data: bestData) {
            return image
        }
        return nil
    }
    
    // MARK: - Batch Processing
    
    /// Process items in batches to avoid blocking UI
    func processBatch<T>(_ items: [T], batchSize: Int = 50, process: @escaping (T) -> Void, completion: @escaping () -> Void) {
        guard !items.isEmpty else {
            completion()
            return
        }
        
        var currentIndex = 0
        
        func processNextBatch() {
            let endIndex = min(currentIndex + batchSize, items.count)
            let batch = Array(items[currentIndex..<endIndex])
            
            for item in batch {
                process(item)
            }
            
            currentIndex = endIndex
            
            if currentIndex < items.count {
                // Process next batch on next run loop
                DispatchQueue.main.async {
                    processNextBatch()
                }
            } else {
                completion()
            }
        }
        
        processNextBatch()
    }
}

// MARK: - View Extensions for Performance

extension View {
    /// Add performance monitoring to a view
    func measurePerformance(label: String) -> some View {
        self.onAppear {
            PerformanceOptimizer.shared.logMemoryUsage(label: "\(label) - Appeared")
        }
        .onDisappear {
            PerformanceOptimizer.shared.logMemoryUsage(label: "\(label) - Disappeared")
        }
    }
    
    /// Optimize rendering for complex views
    func optimizeRendering() -> some View {
        self.drawingGroup()
    }
    
    /// Lazy load view with placeholder
    func lazyLoad<Placeholder: View>(@ViewBuilder placeholder: @escaping () -> Placeholder) -> some View {
        LazyView {
            self
        } placeholder: {
            placeholder()
        }
    }
}

// MARK: - Lazy View

struct LazyView<Content: View, Placeholder: View>: View {
    let content: () -> Content
    let placeholder: () -> Placeholder
    @State private var isLoaded = false
    
    var body: some View {
        Group {
            if isLoaded {
                content()
            } else {
                placeholder()
                    .onAppear {
                        DispatchQueue.main.async {
                            isLoaded = true
                        }
                    }
            }
        }
    }
}

// MARK: - Equatable Wrapper for Performance

/// Wrapper to make non-Equatable types work with animation
struct EquatableWrapper<T>: Equatable {
    let value: T
    let id: UUID
    
    init(_ value: T) {
        self.value = value
        self.id = UUID()
    }
    
    static func == (lhs: EquatableWrapper<T>, rhs: EquatableWrapper<T>) -> Bool {
        lhs.id == rhs.id
    }
}
