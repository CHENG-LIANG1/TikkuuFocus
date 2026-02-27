//
//  SavedLocation.swift
//  Tikkuu Focus
//
//  Created by Tikkuu on 2026/2/12.
//

import Foundation
import CoreLocation
import SwiftData
import SwiftUI
import Combine

/// Represents a saved location that can be a favorite or history item
@Model
final class SavedLocation {
    var id: UUID
    var name: String
    var latitude: Double
    var longitude: Double
    var timestamp: Date
    var isFavorite: Bool
    var emoji: String?
    
    init(
        id: UUID = UUID(),
        name: String,
        coordinate: CLLocationCoordinate2D,
        isFavorite: Bool = false,
        emoji: String? = nil
    ) {
        self.id = id
        self.name = name
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        self.timestamp = Date()
        self.isFavorite = isFavorite
        self.emoji = emoji
    }
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

// MARK: - Location Store Manager

@MainActor
final class LocationStore: ObservableObject, @unchecked Sendable {
    static let shared = LocationStore()
    
    private var modelContext: ModelContext?
    
    @Published var favorites: [SavedLocation] = []
    @Published var history: [SavedLocation] = []
    
    private init() {
        // Defer initialization until we have access to the model context
        // The context will be set by the view using .modelContainer
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        fetchLocations()
    }
    
    func fetchLocations() {
        guard let context = modelContext else { return }
        
        let favoritesDescriptor = FetchDescriptor<SavedLocation>(
            predicate: #Predicate { $0.isFavorite == true },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        
        let historyDescriptor = FetchDescriptor<SavedLocation>(
            predicate: #Predicate { $0.isFavorite == false },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        
        do {
            favorites = try context.fetch(favoritesDescriptor)
            history = try context.fetch(historyDescriptor)
        } catch {
            print("Failed to fetch locations: \(error)")
        }
    }
    
    func addToHistory(name: String, coordinate: CLLocationCoordinate2D) {
        guard let context = modelContext else { return }
        
        // Check if this location already exists in history (within 100m)
        let existingHistory = history.first { location in
            let locCoord = location.coordinate
            let distance = CLLocation(latitude: locCoord.latitude, longitude: locCoord.longitude)
                .distance(from: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))
            return distance < 100
        }
        
        // If exists, update timestamp and move to top
        if let existing = existingHistory {
            existing.timestamp = Date()
            try? context.save()
            fetchLocations()
            return
        }
        
        // Create new history entry
        let newLocation = SavedLocation(
            name: name,
            coordinate: coordinate,
            isFavorite: false
        )
        
        context.insert(newLocation)
        
        // Limit history to 20 items
        if history.count >= 20 {
            let toDelete = history.suffix(from: 20)
            for location in toDelete {
                context.delete(location)
            }
        }
        
        try? context.save()
        fetchLocations()
    }
    
    func addToFavorites(name: String, coordinate: CLLocationCoordinate2D, emoji: String? = nil) {
        guard let context = modelContext else { return }
        
        // Check if already in favorites
        let existing = favorites.first { location in
            let locCoord = location.coordinate
            let distance = CLLocation(latitude: locCoord.latitude, longitude: locCoord.longitude)
                .distance(from: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))
            return distance < 100
        }
        
        guard existing == nil else { return }
        
        let newFavorite = SavedLocation(
            name: name,
            coordinate: coordinate,
            isFavorite: true,
            emoji: emoji
        )
        
        context.insert(newFavorite)
        try? context.save()
        fetchLocations()
    }
    
    func toggleFavorite(_ location: SavedLocation) {
        guard let context = modelContext else { return }
        
        if location.isFavorite {
            // Convert to history
            location.isFavorite = false
            location.timestamp = Date()
        } else {
            // Convert to favorite
            location.isFavorite = true
            location.timestamp = Date()
        }
        try? context.save()
        fetchLocations()
    }
    
    func removeFromFavorites(_ location: SavedLocation) {
        guard let context = modelContext else { return }
        
        location.isFavorite = false
        location.timestamp = Date()
        try? context.save()
        fetchLocations()
    }
    
    func delete(_ location: SavedLocation) {
        guard let context = modelContext else { return }
        
        context.delete(location)
        try? context.save()
        fetchLocations()
    }
    
    func clearHistory() {
        guard let context = modelContext else { return }
        
        for location in history {
            context.delete(location)
        }
        try? context.save()
        fetchLocations()
    }
}
