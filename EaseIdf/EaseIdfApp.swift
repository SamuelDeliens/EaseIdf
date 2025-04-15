//
//  EaseIdfApp.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 14/04/2025.
//

import SwiftUI
import SwiftData

@main
struct EaseIdfApp: App {
    // Conteneur de modèle pour les données utilisateur (favoris, paramètres)
    var sharedModelContainer: ModelContainer = PersistenceService.shared.getModelContainer()
    
    // Conteneur de modèle pour les données de transport (lignes, arrêts)
    var transportDataContainer: ModelContainer = DataPersistenceService.shared.getTransportDataContainer()
    
    init() {
        // Initialiser les services dès le démarrage
        initializeServices()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // Demander les autorisations de localisation
                    LocationService.shared.requestAuthorization()
                    LocationService.shared.startLocationUpdates()
                    
                    // Charger des données si nécessaire
                    Task {
                        await loadTransportDataIfNeeded()
                        await WidgetService.shared.refreshWidgetData()
                    }
                }
                .modelContainer(sharedModelContainer)
        }
    }
    
    // Initialisation des services
    private func initializeServices() {
        // Initialiser les services SwiftData
        LineDataService.shared.initializeModelContainer()
        StopDataService.shared.initializeModelContainer()
        
        // Planifier les mises à jour du widget
        let settings = StorageService.shared.getUserSettings()
        WidgetService.shared.scheduleBackgroundUpdates(interval: settings.refreshInterval)
    }
    
    // Chargement des données de transport si nécessaire
    private func loadTransportDataIfNeeded() async {
        // Vérifier si les données sont déjà chargées
        if LineDataService.shared.getAllLines().isEmpty {
            print("Chargement initial des données de lignes")
            LineDataService.shared.loadLinesFromFile(named: "transport_lines")
        }
        
        if StopDataService.shared.getAllStops().isEmpty {
            print("Chargement initial des données d'arrêts")
            StopDataService.shared.loadStopsFromFile(named: "transport_stops")
        }
    }
}
