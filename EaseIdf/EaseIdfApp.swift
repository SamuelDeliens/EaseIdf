//
//  EaseIdfApp.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 14/04/2025.
//


import SwiftUI
import SwiftData
import Combine

@main
struct EaseIdfApp: App {
    // Conteneurs de modèles
    var sharedModelContainer: ModelContainer
    
    // État de l'application
    @State private var needsDataLoading: Bool = false
    @State private var cancellables = Set<AnyCancellable>()
    
    // Initialisation
    init() {
        // Initialiser le conteneur de modèle pour les données utilisateur
        let userContainer = PersistenceService.shared.getModelContainer()
        self.sharedModelContainer = userContainer
        
        // Configurer les services avec le conteneur
        AppServices.shared.setModelContainer(userContainer)
        
        // Vérifier si le chargement des données est nécessaire
        self.needsDataLoading = checkIfDataLoadingNeeded()
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if needsDataLoading {
                    SplashScreenContainer(
                        content: ContentView(),
                        onAppear: loadTransportDataIfNeeded
                    )
                    .modelContainer(sharedModelContainer)
                } else {
                    ContentView()
                        .modelContainer(sharedModelContainer)
                        .onAppear {
                            Task {
                                // Demander les autorisations de localisation au démarrage
                                AppServices.shared.locationService.requestAuthorization()
                                AppServices.shared.locationService.startLocationUpdates()
                                
                                // Rafraîchir les données du widget
                                await AppServices.shared.widgetService.refreshWidgetData()
                            }
                        }
                }
            }
            .onAppear {
                needsDataLoading = shouldLoadData
            }
        }
    }
    
    // Propriété calculée pour déterminer si les données doivent être chargées
    private var shouldLoadData: Bool {
        return checkIfDataLoadingNeeded()
    }
    
    // Vérifier si le chargement des données est nécessaire
    private func checkIfDataLoadingNeeded() -> Bool {
        let transportService = AppServices.shared.transportService
        
        let linesEmpty = transportService.getAllLines().isEmpty
        let stopsEmpty = transportService.getAllStops().isEmpty
        
        print("Vérification des données: lignes vides = \(linesEmpty), arrêts vides = \(stopsEmpty)")
        
        return linesEmpty || stopsEmpty
    }
    
    // Charger les données de transport si nécessaire
    private func loadTransportDataIfNeeded(_ progressCallback: @escaping (Double) -> Void) async {
        // Démarrer les tâches en parallèle
        let totalSteps = 5
        var currentStep = 0
        
        // Fonction locale pour mettre à jour la progression
        func updateProgress() {
            currentStep += 1
            let progress = Double(currentStep) / Double(totalSteps)
            if progress == 1 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    needsDataLoading = false
                }
            }
            progressCallback(progress)
        }
        
        // Étape 1: Initialisation des services
        print("🔄 Initialisation des services...")
        updateProgress()
        
        // Étape 2-3: Charger les données de transport
        Task {
            let success = await AppServices.shared.initializeBaseData()
            if success {
                print("✅ Données de transport chargées avec succès")
            } else {
                print("⚠️ Problèmes lors du chargement des données de transport")
            }
            
            // On compte deux étapes pour le chargement (lignes et arrêts)
            updateProgress() // Étape 2
            updateProgress() // Étape 3
            
            // Étape 4: Configuration des services de localisation
            AppServices.shared.locationService.requestAuthorization()
            AppServices.shared.locationService.startLocationUpdates()
            updateProgress()
            
            // Étape 5: Configuration des widgets
            let settings = StorageService.shared.getUserSettings()
            
            if settings.isRefreshPaused {
                AppServices.shared.widgetService.stopBackgroundUpdate()
            } else {
                AppServices.shared.widgetService.scheduleBackgroundUpdates(interval: settings.refreshInterval)
            }
            await AppServices.shared.widgetService.refreshWidgetData()
            updateProgress()
        }
    }
}

// Environnement d'application pour les configurations globales
struct AppEnvironment {
    // Constantes et configurations globales
    static var useSimulatedData: Bool = false
    static var isDevelopmentMode: Bool = false
    
    // Paramètres de débogage
    static var enableDetailedLogging: Bool = true
}
