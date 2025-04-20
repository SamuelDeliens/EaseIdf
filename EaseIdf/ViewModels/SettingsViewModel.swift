//
//  SettingsViewModel.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 14/04/2025.
//


import Foundation
import SwiftData
import Combine

/// ViewModel pour la gestion des paramètres
class SettingsViewModel: BaseViewModel {
    // MARK: - Propriétés de configuration
    
    @Published var apiKey: String = ""
    @Published var refreshInterval: Double = 300.0
    @Published var visualRefreshInterval: Double = 60.0
    @Published var showOnlyUpcomingDepartures: Bool = true
    @Published var numberOfDeparturesToShow: Int = 2
    @Published var showSavedAlert: Bool = false
    @Published var isConnectionValid: Bool = false
    @Published var isTestingConnection: Bool = false
    @Published var isRefreshPaused: Bool = false
    
    // MARK: - Services
    
    private let authService: AuthenticationService
    private let favoritesViewModel: FavoritesViewModel?
    
    // MARK: - Initialisation
    
    init(
        modelContext: ModelContext? = nil,
        authService: AuthenticationService = AuthenticationService.shared,
        favoritesViewModel: FavoritesViewModel? = FavoritesViewModel.shared
    ) {
        self.authService = authService
        self.favoritesViewModel = favoritesViewModel
        
        super.init(modelContext: modelContext)
    }
    
    // MARK: - Charger & Sauvegarder les paramètres
    
    /// Charger les paramètres
    func loadSettings() {
        // Charger la clé API depuis le service Keychain
        if let storedApiKey = KeychainService.shared.getAPIKey() {
            apiKey = storedApiKey
        }
        
        if let modelContext = modelContext {
            // Essayer de charger les autres paramètres depuis SwiftData
            do {
                let descriptor = FetchDescriptor<UserSettingsModel>()
                let userSettings = try modelContext.fetch(descriptor)
                
                if let settings = userSettings.first {
                    refreshInterval = settings.refreshInterval
                    showOnlyUpcomingDepartures = settings.showOnlyUpcomingDepartures
                    numberOfDeparturesToShow = settings.numberOfDeparturesToShow
                    isRefreshPaused = settings.isRefreshPaused
                    return
                }
            } catch {
                print("Erreur lors du chargement des paramètres depuis SwiftData: \(error)")
            }
        }
        
        // Fallback vers UserDefaults via StorageService
        let defaultSettings = StorageService.shared.getUserSettings()
        refreshInterval = defaultSettings.refreshInterval
        showOnlyUpcomingDepartures = defaultSettings.showOnlyUpcomingDepartures
        numberOfDeparturesToShow = defaultSettings.numberOfDeparturesToShow
        isRefreshPaused = defaultSettings.isRefreshPaused
    }
    
    /// Sauvegarder les paramètres
    func saveSettings() {
        // Sauvegarder la clé API dans Keychain
        _ = KeychainService.shared.saveAPIKey(apiKey)
        
        // Sauvegarder les autres paramètres dans SwiftData si disponible
        if let modelContext = modelContext {
            do {
                let descriptor = FetchDescriptor<UserSettingsModel>()
                let userSettings = try modelContext.fetch(descriptor)
                
                let settings: UserSettingsModel
                
                if let existingSettings = userSettings.first {
                    settings = existingSettings
                } else {
                    settings = UserSettingsModel()
                    modelContext.insert(settings)
                }
                
                // La clé API n'est plus stockée dans SwiftData
                settings.refreshInterval = refreshInterval
                settings.showOnlyUpcomingDepartures = showOnlyUpcomingDepartures
                settings.numberOfDeparturesToShow = numberOfDeparturesToShow
                settings.isRefreshPaused = isRefreshPaused
                
                try modelContext.save()
            } catch {
                print("Erreur lors de la sauvegarde des paramètres dans SwiftData: \(error)")
            }
        }
        
        // Également sauvegarder dans UserDefaults via StorageService pour la compatibilité
        let userDefaults = UserSettings(
            favorites: StorageService.shared.getUserSettings().favorites,
            apiKey: nil, // Ne plus stocker la clé API dans UserDefaults
            refreshInterval: refreshInterval,
            showOnlyUpcomingDepartures: showOnlyUpcomingDepartures,
            numberOfDeparturesToShow: numberOfDeparturesToShow,
            isRefreshPaused: isRefreshPaused
        )
        StorageService.shared.saveUserSettings(userDefaults)
        
        // Mettre à jour les timers de rafraîchissement en fonction des nouveaux paramètres
        updateRefreshTimers()
        
        // Notifier les autres ViewModels du changement de paramètres
        NotificationCenter.default.post(name: Notification.Name("SettingsChanged"), object: nil)
        
        // Afficher la confirmation
        showSavedAlert = true
    }
    
    // MARK: - Tester la clé API
    
    /// Tester la validité de la clé API
    func testApiKey() async {
        isTestingConnection = true
        isConnectionValid = false
        
        let isValid = await authService.saveAndValidateApiKey(apiKey)
        
        DispatchQueue.main.async {
            self.isTestingConnection = false
            self.isConnectionValid = isValid
            
            if isValid {
                self.showSavedAlert = true
            }
        }
    }
    
    // MARK: - Activer/désactiver les rafraîchissements
        
    /// Basculer l'état de pause des rafraîchissements
    func toggleRefreshPause() {
        isRefreshPaused.toggle()
    }
    
    /// Mettre à jour les timers de rafraîchissement en fonction des paramètres
    private func updateRefreshTimers() {
        if isRefreshPaused {
            favoritesViewModel?.stopRefreshTimers()
            WidgetService.shared.stopBackgroundUpdate()
        } else {
            favoritesViewModel?.setupRefreshTimers()
            WidgetService.shared.scheduleBackgroundUpdates(interval: refreshInterval)
        }
    }
    
    // MARK: - Actions diverses
    
    /// Effacer le cache
    func clearCache() {
        StorageService.shared.clearAllCache()
    }
    
    /// Formater un intervalle de temps pour l'affichage
    func formatTimeInterval(_ interval: TimeInterval) -> String {
        if interval < 60 {
            return "\(Int(interval)) secondes"
        } else {
            let minutes = Int(interval) / 60
            return "\(minutes) minute\(minutes > 1 ? "s" : "")"
        }
    }
}
