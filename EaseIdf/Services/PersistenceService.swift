//
//  PersistenceService.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 14/04/2025.
//

import Foundation
import SwiftData

class PersistenceService {
    static let shared = PersistenceService()
    
    private init() {}
    
    /// Get the model container for the application
    func getModelContainer() -> ModelContainer {
        let schema = Schema([
            TransportFavoriteModel.self,
            DisplayConditionModel.self,
            UserSettingsModel.self
        ])
        
        // Ajoutez ces options pour gérer les migrations et la reconstruction
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        
        do {
            // Utilisez un nom de fichier distinct
            let url = URL.documentsDirectory.appending(path: "user_favorites.store")
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            print("Erreur lors de la création du ModelContainer: \(error)")
            
            // Plan B: conteneur en mémoire si la persistance échoue
            let fallbackConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            do {
                return try ModelContainer(for: schema, configurations: [fallbackConfig])
            } catch {
                fatalError("Impossible de créer un ModelContainer: \(error)")
            }
        }
    }
    
    /// Convert stored favorites to struct format for use with other services
    func getFavoritesAsStructs(context: ModelContext) -> [TransportFavorite] {
        do {
            let descriptor = FetchDescriptor<TransportFavoriteModel>()
            let favoriteModels = try context.fetch(descriptor)
            return favoriteModels.map { $0.toStruct() }
        } catch {
            print("Error fetching favorites: \(error)")
            return []
        }
    }
    
    /// Save a favorite to the database
    func saveFavorite(_ favorite: TransportFavorite, context: ModelContext) {
        // Check if favorite already exists
        do {
            let descriptor = FetchDescriptor<TransportFavoriteModel>(
                predicate: #Predicate { $0.id == favorite.id }
            )
            
            let existingFavorites = try context.fetch(descriptor)
            
            if let existingFavorite = existingFavorites.first {
                // Update existing favorite
                existingFavorite.stopId = favorite.stopId
                existingFavorite.lineId = favorite.lineId
                existingFavorite.displayName = favorite.displayName
                existingFavorite.priority = favorite.priority
                existingFavorite.lastUpdated = Date()
                
                // Remove old conditions and add new ones
                existingFavorite.conditions.removeAll()
                existingFavorite.conditions = favorite.displayConditions.map { 
                    DisplayConditionModel.fromStruct($0) 
                }
            } else {
                // Create new favorite
                let newFavorite = TransportFavoriteModel.fromStruct(favorite)
                context.insert(newFavorite)
            }
            
            try context.save()
        } catch {
            print("Error saving favorite: \(error)")
        }
    }
    
    /// Delete a favorite from the database
    func deleteFavorite(id: UUID, context: ModelContext) {
        do {
            let descriptor = FetchDescriptor<TransportFavoriteModel>(
                predicate: #Predicate { $0.id == id }
            )
            
            let favorites = try context.fetch(descriptor)
            
            if let favorite = favorites.first {
                context.delete(favorite)
                try context.save()
            }
        } catch {
            print("Error deleting favorite: \(error)")
        }
    }
    
    /// Get favorites ordered by priority
    func getFavoritesOrderedByPriority(context: ModelContext) -> [TransportFavoriteModel] {
        do {
            let descriptor = FetchDescriptor<TransportFavoriteModel>(
                sortBy: [SortDescriptor(\.priority, order: .reverse)]
            )
            
            return try context.fetch(descriptor)
        } catch {
            print("Error fetching favorites by priority: \(error)")
            return []
        }
    }
    
    /// Update user settings
    func saveUserSettings(_ settings: UserSettingsModel, context: ModelContext) {
        do {
            // Get existing settings or create new
            let descriptor = FetchDescriptor<UserSettingsModel>()
            let existingSettings = try context.fetch(descriptor)
            
            if let currentSettings = existingSettings.first {
                // Update existing settings
                currentSettings.apiKey = settings.apiKey
                currentSettings.refreshInterval = settings.refreshInterval
                currentSettings.showOnlyUpcomingDepartures = settings.showOnlyUpcomingDepartures
                currentSettings.numberOfDeparturesToShow = settings.numberOfDeparturesToShow
            } else {
                // Create new settings
                context.insert(settings)
            }
            
            try context.save()
        } catch {
            print("Error saving user settings: \(error)")
        }
    }
    
    /// Get current user settings
    func getUserSettings(context: ModelContext) -> UserSettingsModel {
        do {
            let descriptor = FetchDescriptor<UserSettingsModel>()
            let settings = try context.fetch(descriptor)
            
            if let currentSettings = settings.first {
                return currentSettings
            } else {
                // Create default settings if none exist
                let defaultSettings = UserSettingsModel()
                context.insert(defaultSettings)
                try context.save()
                return defaultSettings
            }
        } catch {
            print("Error fetching user settings: \(error)")
            // Return default settings if there's an error
            return UserSettingsModel()
        }
    }
}
