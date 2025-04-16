//
//  StorageService.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 14/04/2025.
//

import Foundation
import SwiftData

class StorageService {
    static let shared = StorageService()
    
    private init() {}
    
    // MARK: - User Preferences
    
    func saveUserSettings(_ settings: UserSettings) {
        if let encoded = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(encoded, forKey: "userSettings")
        }
    }
    
    func getUserSettings() -> UserSettings {
        if let savedSettings = UserDefaults.standard.data(forKey: "userSettings"),
           let decodedSettings = try? JSONDecoder().decode(UserSettings.self, from: savedSettings) {
            return decodedSettings
        }
        
        // Return default settings if none are saved
        return UserSettings(
            favorites: [],
            refreshInterval: 60,
            showOnlyUpcomingDepartures: true,
            numberOfDeparturesToShow: 3
        )
    }
    
    // MARK: - Favorites Management
    
    func saveFavorite(_ favorite: TransportFavorite) {
        var settings = getUserSettings()
        
        // Check if favorite already exists, then update it
        if let index = settings.favorites.firstIndex(where: { $0.id == favorite.id }) {
            settings.favorites[index] = favorite
        } else {
            // Add new favorite
            settings.favorites.append(favorite)
        }
        
        saveUserSettings(settings)
        
        Task {
            await WidgetService.shared.refreshWidgetData()
        }
    }
    
    func removeFavorite(id: UUID) {
        var settings = getUserSettings()
        settings.favorites.removeAll(where: { $0.id == id })
        saveUserSettings(settings)
    }
    
    func updateFavoritePriority(id: UUID, newPriority: Int) {
        var settings = getUserSettings()
        if let index = settings.favorites.firstIndex(where: { $0.id == id }) {
            settings.favorites[index].priority = newPriority
        }
        saveUserSettings(settings)
    }
    
    // MARK: - Cache Management
    
    func cacheTransportStops(_ stops: [TransportStop]) {
        if let encoded = try? JSONEncoder().encode(stops) {
            UserDefaults.standard.set(encoded, forKey: "cachedStops")
            UserDefaults.standard.set(Date(), forKey: "stopsLastUpdated")
        }
    }
    
    func getCachedStops() -> [TransportStop]? {
        guard let data = UserDefaults.standard.data(forKey: "cachedStops"),
              let stops = try? JSONDecoder().decode([TransportStop].self, from: data) else {
            return nil
        }
        return stops
    }
    
    func cacheTransportLines(_ lines: [TransportLine]) {
        if let encoded = try? JSONEncoder().encode(lines) {
            UserDefaults.standard.set(encoded, forKey: "cachedLines")
            UserDefaults.standard.set(Date(), forKey: "linesLastUpdated")
        }
    }
    
    func getCachedLines() -> [TransportLine]? {
        guard let data = UserDefaults.standard.data(forKey: "cachedLines"),
              let lines = try? JSONDecoder().decode([TransportLine].self, from: data) else {
            return nil
        }
        return lines
    }
    
    func clearAllCache() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "cachedStops")
        defaults.removeObject(forKey: "cachedLines")
        defaults.removeObject(forKey: "stopsLastUpdated")
        defaults.removeObject(forKey: "linesLastUpdated")
    }
    
    // MARK: - Cache Freshness
    
    func isCacheFresh(key: String, maxAge: TimeInterval = 86400) -> Bool {
        guard let lastUpdated = UserDefaults.standard.object(forKey: "\(key)LastUpdated") as? Date else {
            return false
        }
        
        let now = Date()
        let age = now.timeIntervalSince(lastUpdated)
        
        return age < maxAge
    }
}
