//
//  AppInfo.swift
//  Tikkuu Focus
//
//  Created by Tikkuu on 2026/2/8.
//

import Foundation

/// App information utilities
struct AppInfo {
    /// Get app version from Info.plist
    static var version: String {
        // Try to get from main bundle
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return version
        }
        
        // Fallback: try to get from object
        if let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
            return version
        }
        
        // Default fallback
        return "1.0.0"
    }
    
    /// Get build number from Info.plist
    static var build: String {
        if let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            return build
        }
        
        if let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String {
            return build
        }
        
        return "1"
    }
    
    /// Get full version string (version + build)
    static var fullVersion: String {
        return "\(version) (\(build))"
    }
    
    /// Debug: Print all version-related info
    static func debugVersionInfo() {
        print("📱 App Version Debug Info:")
        print("  - CFBundleShortVersionString: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] ?? "nil")")
        print("  - CFBundleVersion: \(Bundle.main.infoDictionary?["CFBundleVersion"] ?? "nil")")
        print("  - Computed version: \(version)")
        print("  - Computed build: \(build)")
    }
}
