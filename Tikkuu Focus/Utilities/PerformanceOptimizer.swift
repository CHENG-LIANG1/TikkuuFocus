//
//  PerformanceOptimizer.swift
//  Tikkuu Focus
//
//  Created by Tikkuu on 2026/2/11.
//

import Foundation
import SwiftUI

/// Performance optimization utilities
class PerformanceOptimizer {
    static let shared = PerformanceOptimizer()
    
    private init() {}
    
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
    func lazyLoad<Placeholder: View>(@ViewBuilder placeholder: () -> Placeholder) -> some View {
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
