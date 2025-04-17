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
    @Published var refreshInterval: Double = 120.0
    @Published var visualRefreshInterval: Double = 60.0
    @Published var showOnlyUpcomingDepartures: Bool = true
    @Published var numberOfDeparturesToShow: Int = 3
    @Published var showSavedAlert: Bool = false
    @Published var isConnectionValid: Bool = false
    @Published var isTestingConnection: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    private var modelContext: ModelContext?
    
    init() {
        // Initial loading will happen when the modelContext is set
    }
    
    func setModelContext(_ context: ModelContext?) {
        self.modelContext = context
    }
    
    func loadSettings() {
        if let modelContext = modelContext {
            // Try to load from SwiftData first
            do {
                let descriptor = FetchDescriptor<UserSettingsModel>()
                let userSettings = try modelContext.fetch(descriptor)
                
                if let settings = userSettings.first {
                    apiKey = settings.apiKey ?? ""
                    refreshInterval = settings.refreshInterval
                    showOnlyUpcomingDepartures = settings.showOnlyUpcomingDepartures
                    numberOfDeparturesToShow = settings.numberOfDeparturesToShow
                    return
                }
            } catch {
                print("Error fetching settings from SwiftData: \(error)")
            }
        }
        
        // Fall back to UserDefaults via StorageService
        let defaultSettings = StorageService.shared.getUserSettings()
        apiKey = defaultSettings.apiKey ?? ""
        refreshInterval = defaultSettings.refreshInterval
        showOnlyUpcomingDepartures = defaultSettings.showOnlyUpcomingDepartures
        numberOfDeparturesToShow = defaultSettings.numberOfDeparturesToShow
    }
    
    func saveSettings() {
        // Save to SwiftData if available
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
                
                settings.apiKey = apiKey
                settings.refreshInterval = refreshInterval
                settings.showOnlyUpcomingDepartures = showOnlyUpcomingDepartures
                settings.numberOfDeparturesToShow = numberOfDeparturesToShow
                
                try modelContext.save()
            } catch {
                print("Error saving settings to SwiftData: \(error)")
            }
        }
        
        // Also save to UserDefaults via StorageService for backward compatibility
        let userDefaults = UserSettings(
            favorites: StorageService.shared.getUserSettings().favorites,
            apiKey: apiKey,
            refreshInterval: refreshInterval,
            showOnlyUpcomingDepartures: showOnlyUpcomingDepartures,
            numberOfDeparturesToShow: numberOfDeparturesToShow
        )
        StorageService.shared.saveUserSettings(userDefaults)
        
        // Save API key to authentication service
        UserDefaults.standard.set(apiKey, forKey: "IDFMobilite_ApiKey")
        
        // Update widget refresh interval
        WidgetService.shared.scheduleBackgroundUpdates(interval: refreshInterval)
        
        // Notify any active view models about the setting changes
        NotificationCenter.default.post(name: Notification.Name("SettingsChanged"), object: nil)
        
        // Show confirmation
        showSavedAlert = true
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
