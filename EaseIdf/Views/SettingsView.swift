//
//  SettingsView.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 14/04/2025.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var apiKey: String = ""
    @State private var refreshInterval: Double = 60
    @State private var showOnlyUpcomingDepartures: Bool = true
    @State private var numberOfDeparturesToShow: Int = 3
    
    @State private var isValidatingKey: Bool = false
    @State private var validationMessage: String? = nil
    @State private var showingSuccessAlert = false
    
    private let refreshIntervalOptions: [Double] = [30, 60, 120, 300, 600]
    private let numberOfDeparturesToShowOptions = [1, 2, 3, 5, 10]
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Authentification")) {
                    SecureField("Clé API IDF Mobilités", text: $apiKey)
                    
                    Button(action: {
                        validateApiKey()
                    }) {
                        HStack {
                            Text("Valider la clé API")
                            
                            if isValidatingKey {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            }
                        }
                    }
                    .disabled(apiKey.isEmpty || isValidatingKey)
                    
                    if let message = validationMessage {
                        Text(message)
                            .font(.caption)
                            .foregroundColor(message.contains("invalide") ? .red : .green)
                    }
                }
                
                Section(header: Text("Actualisation des données")) {
                    Picker("Intervalle de rafraîchissement", selection: $refreshInterval) {
                        ForEach(refreshIntervalOptions, id: \.self) { interval in
                            Text(formatInterval(interval)).tag(interval)
                        }
                    }
                }
                
                Section(header: Text("Affichage")) {
                    Toggle("Afficher uniquement les passages à venir", isOn: $showOnlyUpcomingDepartures)
                    
                    Picker("Nombre de passages à afficher", selection: $numberOfDeparturesToShow) {
                        ForEach(numberOfDeparturesToShowOptions, id: \.self) { number in
                            Text("\(number)").tag(number)
                        }
                    }
                }
                
                Section {
                    Button("Vider le cache") {
                        clearCache()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Paramètres")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Enregistrer") {
                        saveSettings()
                    }
                }
            }
            .alert("Paramètres sauvegardés", isPresented: $showingSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Les modifications ont été enregistrées avec succès.")
            }
            .onAppear {
                loadCurrentSettings()
            }
        }
    }
    
    // MARK: - Methods
    
    private func loadCurrentSettings() {
        // Try to load from SwiftData
        let descriptor = FetchDescriptor<UserSettingsModel>()
        
        do {
            let settings = try modelContext.fetch(descriptor).first ?? UserSettingsModel()
            
            apiKey = settings.apiKey ?? ""
            refreshInterval = settings.refreshInterval
            showOnlyUpcomingDepartures = settings.showOnlyUpcomingDepartures
            numberOfDeparturesToShow = settings.numberOfDeparturesToShow
            
        } catch {
            print("Error loading settings: \(error)")
            
            // Fallback to UserDefaults via StorageService
            let defaultSettings = StorageService.shared.getUserSettings()
            
            apiKey = defaultSettings.apiKey ?? ""
            refreshInterval = defaultSettings.refreshInterval
            showOnlyUpcomingDepartures = defaultSettings.showOnlyUpcomingDepartures
            numberOfDeparturesToShow = defaultSettings.numberOfDeparturesToShow
        }
    }
    
    private func saveSettings() {
        // Save to SwiftData
        let descriptor = FetchDescriptor<UserSettingsModel>()
        
        do {
            let existingSettings = try modelContext.fetch(descriptor).first
            
            if let settings = existingSettings {
                // Update existing settings
                settings.apiKey = apiKey.isEmpty ? nil : apiKey
                settings.refreshInterval = refreshInterval
                settings.showOnlyUpcomingDepartures = showOnlyUpcomingDepartures
                settings.numberOfDeparturesToShow = numberOfDeparturesToShow
            } else {
                // Create new settings
                let newSettings = UserSettingsModel(
                    apiKey: apiKey.isEmpty ? nil : apiKey,
                    refreshInterval: refreshInterval,
                    showOnlyUpcomingDepartures: showOnlyUpcomingDepartures,
                    numberOfDeparturesToShow: numberOfDeparturesToShow
                )
                
                modelContext.insert(newSettings)
            }
            
            try modelContext.save()
            
            // Also save to UserDefaults via StorageService for widget access
            let settings = UserSettings(
                favorites: StorageService.shared.getUserSettings().favorites,
                apiKey: apiKey.isEmpty ? nil : apiKey,
                refreshInterval: refreshInterval,
                showOnlyUpcomingDepartures: showOnlyUpcomingDepartures,
                numberOfDeparturesToShow: numberOfDeparturesToShow
            )
            
            StorageService.shared.saveUserSettings(settings)
            
            // Set the API key for the authentication service
            if !apiKey.isEmpty {
                UserDefaults.standard.set(apiKey, forKey: "IDFMobilite_ApiKey")
            }
            
            // Update widget refresh interval
            WidgetService.shared.scheduleBackgroundUpdates(interval: refreshInterval)
            
            // Show success alert
            showingSuccessAlert = true
            
        } catch {
            print("Error saving settings: \(error)")
        }
    }
    
    private func validateApiKey() {
        isValidatingKey = true
        validationMessage = nil
        
        Task {
            let isValid = await AuthenticationService.shared.saveAndValidateApiKey(apiKey)
            
            DispatchQueue.main.async {
                isValidatingKey = false
                
                validationMessage = isValid ? 
                    "Clé API valide ✓" : 
                    "Clé API invalide. Veuillez vérifier et réessayer."
            }
        }
    }
    
    private func clearCache() {
        StorageService.shared.clearAllCache()
    }
    
    private func formatInterval(_ seconds: Double) -> String {
        switch seconds {
        case 60:
            return "1 minute"
        case let s where s < 60:
            return "\(Int(s)) secondes"
        case let s where s < 3600:
            return "\(Int(s / 60)) minutes"
        default:
            let hours = Int(seconds / 3600)
            return "\(hours) heure\(hours > 1 ? "s" : "")"
        }
    }
}

#Preview {
    SettingsView()
}
