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
    var sharedModelContainer: ModelContainer = PersistenceService.shared.getModelContainer()
    var transportDataContainer: ModelContainer = DataPersistenceService.shared.getTransportDataContainer()
    
    @State private var needsDataLoading: Bool = false
    private var shouldLoadData: Bool = false
    
    @State private var cancellables = Set<AnyCancellable>()
    
    init() {
        self.shouldLoadData = checkIfDataLoadingNeeded()
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
                                LocationService.shared.requestAuthorization()
                                LocationService.shared.startLocationUpdates()
                                await WidgetService.shared.refreshWidgetData()
                            }
                        }
                }
            }
            .onAppear {
                needsDataLoading = shouldLoadData
            }
        }
    }
    
    private func checkIfDataLoadingNeeded() -> Bool {
        LineDataService.shared.initializeModelContainer()
        StopDataService.shared.initializeModelContainer()
        
        let linesEmpty = LineDataService.shared.getAllLines().isEmpty
        let stopsEmpty = StopDataService.shared.getAllStops().isEmpty
        
        print("Vérification des données: lignes vides = \(linesEmpty), arrêts vides = \(stopsEmpty)")
        
        return linesEmpty || stopsEmpty
    }
    
    
    // Dans EaseIdfApp.swift
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
        
        // Étape 1: Initialisation des conteneurs
        Task {
            print("🔄 Initialisation des conteneurs de modèles...")
            LineDataService.shared.initializeModelContainer()
            StopDataService.shared.initializeModelContainer()
            
            updateProgress()
            
            // Étape 2: Démarrer le chargement des lignes en arrière-plan
            if LineDataService.shared.getAllLines().isEmpty {
                print("📊 Démarrage du chargement des données de lignes...")
                LineDataService.shared.loadLinesFromFile(named: "transport_lines")
                
                // Observer l'état de chargement plutôt que d'attendre
                LineDataService.shared.$isLoading
                    .sink { isLoading in
                        if !isLoading {
                            print("✅ Données de lignes chargées")
                            updateProgress()
                        }
                    }
                    .store(in: &cancellables)
            } else {
                print("✅ Données de lignes déjà chargées")
                updateProgress()
            }
            
            // Étape 3: Démarrer le chargement des arrêts en arrière-plan
            if StopDataService.shared.getAllStops().isEmpty {
                print("📍 Démarrage du chargement des données d'arrêts...")
                StopDataService.shared.loadStopsFromFile(named: "transport_stops")
                
                StopDataService.shared.$isLoading
                    .sink { isLoading in
                        if !isLoading {
                            print("✅ Données d'arrêts chargées")
                            updateProgress()
                        }
                    }
                    .store(in: &cancellables)
            } else {
                print("✅ Données d'arrêts déjà chargées")
                updateProgress()
            }
            
            // Étapes 4 et 5: Configuration des services et widgets
            LocationService.shared.requestAuthorization()
            LocationService.shared.startLocationUpdates()
            updateProgress()
            
            // Widget refresh
            let settings = StorageService.shared.getUserSettings()
            
            if settings.isRefreshPaused {
                WidgetService.shared.stopBackgroundUpdate()
            } else {
                WidgetService.shared.scheduleBackgroundUpdates(interval: settings.refreshInterval)
            }
            await WidgetService.shared.refreshWidgetData()
            updateProgress()
        }
    }
}

// Erreurs spécifiques pour le chargement des données
enum LoadingError: Error {
    case dataNotLoaded(String)
    case timeout
}
