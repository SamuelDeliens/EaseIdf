//
//  SettingsViewModel.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 14/04/2025.
//

import Foundation
import SwiftData
import Combine

class SettingsViewModel: ObservableObject {
    @Published var apiKey: String = ""
    @Published var refreshInterval: Double = 300.0
    @Published var visualRefreshInterval: Double = 60.0
    @Published var showOnlyUpcomingDepartures: Bool = true
    @Published var numberOfDeparturesToShow: Int = 2
    @Published var showSavedAlert: Bool = false
    @Published var isConnectionValid: Bool = false
    @Published var isTestingConnection: Bool = false
    @Published var isRefreshPaused: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    private var modelContext: ModelContext?
    
    init() {
        // Initial loading will happen when the modelContext is set
    }
    
    func setModelContext(_ context: ModelContext?) {
        self.modelContext = context
        loadSettings()
    }
    
    func loadSettings() {
        // Load API key from Keychain
        if let storedApiKey = KeychainService.shared.getAPIKey() {
            apiKey = storedApiKey
        }
        
        if let modelContext = modelContext {
            // Try to load other settings from SwiftData
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
                print("Error fetching settings from SwiftData: \(error)")
            }
        }
        
        // Fall back to UserDefaults via StorageService for other settings
        let defaultSettings = StorageService.shared.getUserSettings()
        refreshInterval = defaultSettings.refreshInterval
        showOnlyUpcomingDepartures = defaultSettings.showOnlyUpcomingDepartures
        numberOfDeparturesToShow = defaultSettings.numberOfDeparturesToShow
        isRefreshPaused = defaultSettings.isRefreshPaused
    }
    
    func saveSettings() {
        // Save API key to Keychain
        _ = KeychainService.shared.saveAPIKey(apiKey)
        
        // Save other settings to SwiftData if available
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
                
                // No longer storing API key in SwiftData
                settings.refreshInterval = refreshInterval
                settings.showOnlyUpcomingDepartures = showOnlyUpcomingDepartures
                settings.numberOfDeparturesToShow = numberOfDeparturesToShow
                settings.isRefreshPaused = isRefreshPaused
                
                try modelContext.save()
            } catch {
                print("Error saving settings to SwiftData: \(error)")
            }
        }
        
        // Also save to UserDefaults via StorageService for backward compatibility
        let userDefaults = UserSettings(
            favorites: StorageService.shared.getUserSettings().favorites,
            apiKey: nil, // Don't store API key in UserDefaults anymore
            refreshInterval: refreshInterval,
            showOnlyUpcomingDepartures: showOnlyUpcomingDepartures,
            numberOfDeparturesToShow: numberOfDeparturesToShow,
            isRefreshPaused: isRefreshPaused
        )
        StorageService.shared.saveUserSettings(userDefaults)
        
        // Update widget refresh interval
        if (isRefreshPaused) {
            FavoritesViewModel.shared.stopRefreshTimers()
            WidgetService.shared.stopBackgroundUpdate()
        } else {
            FavoritesViewModel.shared.setupRefreshTimers()
            WidgetService.shared.scheduleBackgroundUpdates(interval: refreshInterval)
        }
        
        // Notify any active view models about the setting changes
        NotificationCenter.default.post(name: Notification.Name("SettingsChanged"), object: nil)
        
        // Show confirmation
        showSavedAlert = true
    }
    
    func toggleRefreshPause() {
        isRefreshPaused.toggle()
        print("isRefreshPaused", isRefreshPaused)
    }
    
    func testApiKey() async {
        isTestingConnection = true
        isConnectionValid = false
        
        let isValid = await AuthenticationService.shared.saveAndValidateApiKey(apiKey)
        
        DispatchQueue.main.async {
            self.isTestingConnection = false
            self.isConnectionValid = isValid
            
            if isValid {
                self.showSavedAlert = true
            }
        }
    }
    
    func clearCache() {
        StorageService.shared.clearAllCache()
    }
    
    func formatTimeInterval(_ interval: TimeInterval) -> String {
        if interval < 60 {
            return "\(Int(interval)) secondes"
        } else {
            let minutes = Int(interval) / 60
            return "\(minutes) minute\(minutes > 1 ? "s" : "")"
        }
    }
}
