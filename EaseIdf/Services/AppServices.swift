//
//  AppServices.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 20/04/2025.
//


import Foundation
import SwiftData

/// Conteneur singleton pour tous les services de l'application
class AppServices {
    // Services d'infrastructure
    public let transportService: TransportService
    public let favoriteService: FavoriteService
    public let conditionService: ConditionService
    public let authService: AuthenticationService
    public let locationService: LocationService
    public let widgetService: WidgetService
    
    // Instance partagée (singleton)
    static let shared = AppServices()
    
    // Contexte SwiftData
    private var modelContainer: ModelContainer?
    private var modelContext: ModelContext?
    
    // Initialisation privée pour le pattern singleton
    private init() {
        // Initialiser les services
        transportService = TransportService()
        favoriteService = FavoriteService()
        conditionService = ConditionService()
        authService = AuthenticationService.shared
        locationService = LocationService.shared
        widgetService = WidgetService.shared
    }
    
    /// Définir le conteneur de modèle et initialiser les services
    func setModelContainer(_ container: ModelContainer) {
        self.modelContainer = container
        self.modelContext = ModelContext(container)
        
        // Passer le contexte aux services qui en ont besoin
        favoriteService.setModelContext(modelContext)
    }
    
    /// Obtenir le contexte de modèle actuel
    func getModelContext() -> ModelContext? {
        return modelContext
    }
    
    /// Initialiser les données de base nécessaires
    func initializeBaseData() async -> Bool {
        var success = true
        
        // Vérifier si les données de transport sont chargées
        if transportService.getAllLines().isEmpty {
            let linesLoaded = await transportService.loadLinesFromFile(named: "transport_lines")
            if !linesLoaded {
                print("❌ Échec du chargement des lignes")
                success = false
            }
        }
        
        if transportService.getAllStops().isEmpty {
            let stopsLoaded = await transportService.loadStopsFromFile(named: "transport_stops")
            if !stopsLoaded {
                print("❌ Échec du chargement des arrêts")
                success = false
            }
        }
        
        return success
    }
}
