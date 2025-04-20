//
//  FavoriteService.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 20/04/2025.
//


import Foundation
import SwiftData
import Combine

/// Service pour gérer les favoris et leurs données associées
class FavoriteService {
    // MARK: - Propriétés
    
    // État des données
    private(set) var favorites: [TransportFavorite] = []
    private(set) var activeFavorites: [TransportFavorite] = []
    private(set) var departures: [String: [Departure]] = [:]
    
    // États de chargement
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    
    // Pour le suivi des mises à jour
    private(set) var lastDataRefresh: Date = Date()
    
    // Timers pour les rafraîchissements
    private var dataRefreshTimer: Timer?
    private var visualRefreshTimer: Timer?
    
    // Référence au ModelContext
    private var modelContext: ModelContext?
    
    // MARK: - Initialisation
    
    init() {}
    
    // MARK: - Configuration
    
    /// Définir le contexte de modèle
    func setModelContext(_ context: ModelContext?) {
        self.modelContext = context
    }
    
    // MARK: - Gestion des favoris
    
    /// Charger tous les favoris
    func loadFavorites() {
        if let modelContext = modelContext {
            // Essayer de charger depuis SwiftData
            do {
                let descriptor = FetchDescriptor<TransportFavoriteModel>(
                    sortBy: [SortDescriptor(\.priority, order: .reverse)]
                )
                let favoriteModels = try modelContext.fetch(descriptor)
                
                // Convertir les modèles en structs
                favorites = favoriteModels.map { $0.toStruct() }
                
                // Filtrer les favoris actifs en fonction des conditions
                updateActiveFavorites()
                
                // Charger les départs pour les favoris actifs
                refreshDepartures()
            } catch {
                print("Erreur lors du chargement des favoris depuis SwiftData: \(error)")
                
                // Fallback vers UserDefaults
                favorites = StorageService.shared.getUserSettings().favorites
                updateActiveFavorites()
                refreshDepartures()
            }
        } else {
            // Fallback vers UserDefaults
            favorites = StorageService.shared.getUserSettings().favorites
            updateActiveFavorites()
            refreshDepartures()
        }
        
        // Vérifier si les timers doivent être démarrés
        let settings = StorageService.shared.getUserSettings()
        if !settings.isRefreshPaused {
            setupRefreshTimers()
        } else {
            stopRefreshTimers()
            print("Chargement des favoris terminé, mais les rafraîchissements sont en pause")
        }
    }
    
    /// Mettre à jour la liste des favoris actifs en fonction des conditions
    func updateActiveFavorites() {
        let conditionService = ConditionEvaluationService.shared
        
        // Déterminer quels favoris sont actifs selon les conditions
        let activeIDs = Set(conditionService.getCurrentlyActiveTransportFavorites().map { $0.id })
        
        // Mettre à jour la liste des favoris actifs
        activeFavorites = favorites.filter { activeIDs.contains($0.id) }
        
        // Trier les favoris (actifs en premier, puis par priorité)
        favorites.sort { (fav1, fav2) -> Bool in
            let isActive1 = activeIDs.contains(fav1.id)
            let isActive2 = activeIDs.contains(fav2.id)
            
            if isActive1 && !isActive2 {
                return true  // Actif avant inactif
            } else if !isActive1 && isActive2 {
                return false // Inactif après actif
            } else {
                // Si le même statut d'activité, trier par priorité
                return fav1.priority > fav2.priority
            }
        }
    }
    
    /// Sauvegarder un favori
    func saveFavorite(_ favorite: TransportFavorite) {
        guard let modelContext = modelContext else {
            // Fallback vers StorageService
            StorageService.shared.saveFavorite(favorite)
            return
        }
        
        do {
            // Vérifier si le favori existe déjà
            let descriptor = FetchDescriptor<TransportFavoriteModel>(
                predicate: #Predicate { $0.id == favorite.id }
            )
            let existingFavorites = try modelContext.fetch(descriptor)
            
            if let existingFavorite = existingFavorites.first {
                // Mettre à jour le favori existant
                existingFavorite.stopId = favorite.stopId
                existingFavorite.lineId = favorite.lineId
                existingFavorite.displayName = favorite.displayName
                existingFavorite.priority = favorite.priority
                
                // Mettre à jour les informations supplémentaires
                existingFavorite.lineName = favorite.lineName
                existingFavorite.lineShortName = favorite.lineShortName
                existingFavorite.lineColor = favorite.lineColor
                existingFavorite.lineTextColor = favorite.lineTextColor
                existingFavorite.lineTransportMode = favorite.lineTransportMode
                existingFavorite.stopName = favorite.stopName
                existingFavorite.stopLatitude = favorite.stopLatitude
                existingFavorite.stopLongitude = favorite.stopLongitude
                existingFavorite.stopType = favorite.stopType
                
                // Supprimer les anciennes conditions et ajouter les nouvelles
                existingFavorite.conditions.removeAll()
                existingFavorite.conditions = favorite.displayConditions.map {
                    DisplayConditionModel.fromStruct($0)
                }
            } else {
                // Créer un nouveau favori
                let newFavorite = TransportFavoriteModel.fromStruct(favorite)
                modelContext.insert(newFavorite)
            }
            
            try modelContext.save()
            
            // Mettre également à jour dans StorageService pour la compatibilité
            StorageService.shared.saveFavorite(favorite)
            
            // Recharger les favoris après la sauvegarde
            loadFavorites()
            
            // Rafraîchir les widgets
            Task {
                await WidgetService.shared.refreshWidgetData()
            }
        } catch {
            print("Erreur lors de la sauvegarde du favori: \(error)")
            
            // Fallback vers StorageService
            StorageService.shared.saveFavorite(favorite)
            
            // Recharger les favoris après la sauvegarde
            loadFavorites()
        }
    }
    
    /// Supprimer un favori par identifiant
    func removeFavorite(with id: UUID) {
        guard let modelContext = modelContext else {
            StorageService.shared.removeFavorite(id: id)
            favorites.removeAll(where: { $0.id == id })
            updateActiveFavorites()
            return
        }
        
        do {
            let descriptor = FetchDescriptor<TransportFavoriteModel>(
                predicate: #Predicate { $0.id == id }
            )
            let models = try modelContext.fetch(descriptor)
            
            if let model = models.first {
                modelContext.delete(model)
                try modelContext.save()
            }
            
            // Supprimer également de StorageService pour la compatibilité
            StorageService.shared.removeFavorite(id: id)
            
            // Mettre à jour les tableaux locaux
            favorites.removeAll(where: { $0.id == id })
            updateActiveFavorites()
            
            // Rafraîchir les données du widget après suppression
            Task {
                await WidgetService.shared.refreshWidgetData()
            }
        } catch {
            print("Erreur lors de la suppression du favori: \(error)")
            
            // Fallback vers StorageService
            StorageService.shared.removeFavorite(id: id)
            favorites.removeAll(where: { $0.id == id })
            updateActiveFavorites()
        }
    }
    
    /// Déplacer un favori (réordonnancement)
    func moveFavorite(from source: IndexSet, to destination: Int) {
        guard let modelContext = modelContext else {
            return
        }
        
        // Mettre à jour le tableau local
        favorites.move(fromOffsets: source, toOffset: destination)
        
        // Mettre à jour les priorités en fonction du nouvel ordre (plus grand index = priorité plus faible)
        for (index, favorite) in favorites.enumerated() {
            let newPriority = favorites.count - index
            
            // Essayer de mettre à jour dans SwiftData
            do {
                let descriptor = FetchDescriptor<TransportFavoriteModel>(
                    predicate: #Predicate { $0.id == favorite.id }
                )
                let models = try modelContext.fetch(descriptor)
                
                if let model = models.first {
                    model.priority = newPriority
                }
                
                // Mettre également à jour dans StorageService
                StorageService.shared.updateFavoritePriority(id: favorite.id, newPriority: newPriority)
            } catch {
                print("Erreur lors de la mise à jour de la priorité: \(error)")
                // Fallback vers StorageService
                StorageService.shared.updateFavoritePriority(id: favorite.id, newPriority: newPriority)
            }
        }
        
        // Enregistrer les modifications
        do {
            try modelContext.save()
        } catch {
            print("Erreur lors de l'enregistrement des changements d'ordre: \(error)")
        }
        
        // Mettre à jour les favoris actifs
        updateActiveFavorites()
    }
    
    // MARK: - Gestion des départs
    
    /// Rafraîchir les départs pour tous les favoris actifs
    func refreshDepartures() {
        guard !favorites.isEmpty else { return }
        
        isLoading = true
        error = nil
        lastDataRefresh = Date()
        
        // Créer une tâche pour récupérer les départs en parallèle
        Task {
            var newDepartures: [String: [Departure]] = [:]
            
            do {
                // D'abord récupérer les départs pour les favoris actifs
                for favorite in activeFavorites {
                    try await fetchDeparturesForFavorite(favorite, into: &newDepartures)
                }
                
                // Ensuite les favoris inactifs si le temps/la charge le permet
                let inactiveFavorites = favorites.filter { favorite in
                    !activeFavorites.contains(where: { activeFavorite in
                        activeFavorite.id == favorite.id
                    })
                }
                
                for favorite in inactiveFavorites {
                    try? await fetchDeparturesForFavorite(favorite, into: &newDepartures)
                }
                
                // Mettre à jour la propriété sur le thread principal
                await MainActor.run {
                    self.departures = newDepartures
                    self.isLoading = false
                }
                
                // Mettre à jour les données du widget
                await WidgetService.shared.refreshWidgetData()
                
            } catch {
                await MainActor.run {
                    self.error = error
                    self.isLoading = false
                }
            }
        }
    }
    
    /// Mise à jour visuelle des départs (sans requête serveur)
    func updateVisualDepartures() {
        // Mettre à jour les temps d'attente pour tous les départs stockés
        var updatedDepartures: [String: [Departure]] = [:]
        
        for (favoriteId, favoriteDepartures) in departures {
            // Filtrer les départs dépassés si nécessaire (selon les paramètres utilisateur)
            let settings = StorageService.shared.getUserSettings()
            
            var updatedFavoriteDepartures = favoriteDepartures
            
            // Si l'utilisateur veut voir uniquement les prochains départs, filtrer les départs déjà passés
            if settings.showOnlyUpcomingDepartures {
                updatedFavoriteDepartures = updatedFavoriteDepartures.filter {
                    $0.expectedDepartureTime > Date()
                }
            }
            
            // Si on n'a plus de départs à afficher et que le temps depuis le dernier rafraîchissement est trop long,
            // on pourrait forcer un rafraîchissement des données
            if updatedFavoriteDepartures.isEmpty {
                let timeIntervalSinceLastRefresh = Date().timeIntervalSince(lastDataRefresh)
                if timeIntervalSinceLastRefresh > 120 { // Si ça fait plus de 2 minutes
                    // On pourrait forcer un rafraîchissement mais on va simplement le signaler ici
                    print("⚠️ Aucun départ à afficher pour le favori \(favoriteId) après \(Int(timeIntervalSinceLastRefresh))s depuis le dernier rafraîchissement des données")
                }
            }
            
            updatedDepartures[favoriteId] = updatedFavoriteDepartures
        }
        
        // Ne mettre à jour les départs que s'il y a des changements
        if !updatedDepartures.isEmpty {
            self.departures = updatedDepartures
        }
        
        // Mettre à jour la liste des favoris actifs (les conditions peuvent avoir changé)
        updateActiveFavorites()
    }
    
    /// Récupérer les départs pour un favori spécifique
    private func fetchDeparturesForFavorite(_ favorite: TransportFavorite, into departuresDict: inout [String: [Departure]]) async throws {
        // Fetch departures for this favorite
        let departures = try await IDFMobiliteService.shared.fetchDepartures(
            for: favorite.stopId,
            lineId: favorite.lineId
        )
        
        // En mode DEBUG, on peut simuler les départs
        #if DEBUG
        if AppEnvironment.useSimulatedData {
            let simulatedDepartures = DepartureSimulationService.shared.generateSimulatedDepartures(for: favorite)
            
            // Sort by departure time
            let sortedDepartures = simulatedDepartures.sorted {
                $0.expectedDepartureTime < $1.expectedDepartureTime
            }
            
            // Limit number of departures based on user settings
            let settings = StorageService.shared.getUserSettings()
            let limitedDepartures = Array(sortedDepartures.prefix(settings.numberOfDeparturesToShow))
            
            // Store in dictionary with favorite id as key
            departuresDict[favorite.id.uuidString] = limitedDepartures
            return
        }
        #endif
        
        // Sort by departure time
        let sortedDepartures = departures.sorted {
            $0.expectedDepartureTime < $1.expectedDepartureTime
        }
        
        // Limit number of departures based on user settings
        let settings = StorageService.shared.getUserSettings()
        let limitedDepartures = Array(sortedDepartures.prefix(settings.numberOfDeparturesToShow))
        
        // Store in dictionary with favorite id as key
        departuresDict[favorite.id.uuidString] = limitedDepartures
    }
    
    // MARK: - Timer Management
    
    /// Configurer les timers de rafraîchissement
    func setupRefreshTimers() {
        // Annuler les timers existants
        stopRefreshTimers()
        
        // Obtenir l'intervalle de rafraîchissement des paramètres
        let settings = StorageService.shared.getUserSettings()
        let dataInterval = settings.refreshInterval
        let visualInterval: TimeInterval = settings.visualRefreshInterval
        
        // Créer un nouveau timer pour le rafraîchissement des données (requêtes serveur)
        dataRefreshTimer = Timer.scheduledTimer(withTimeInterval: dataInterval, repeats: true) { [weak self] _ in
            self?.refreshDepartures()
        }
        
        // Créer un nouveau timer pour le rafraîchissement visuel
        visualRefreshTimer = Timer.scheduledTimer(withTimeInterval: visualInterval, repeats: true) { [weak self] _ in
            self?.updateVisualDepartures()
        }
    }
    
    /// Arrêter les timers de rafraîchissement
    func stopRefreshTimers() {
        dataRefreshTimer?.invalidate()
        dataRefreshTimer = nil
        
        visualRefreshTimer?.invalidate()
        visualRefreshTimer = nil
    }
    
    // MARK: - Méthode pour obtenir le temps écoulé depuis la dernière mise à jour
    
    /// Obtenir une chaîne formatée indiquant le temps écoulé depuis la dernière mise à jour
    func getTimeSinceLastRefresh() -> String {
        let interval = Date().timeIntervalSince(lastDataRefresh)
        
        if interval < 60 {
            return "à l'instant"
        } else if interval < 120 {
            return "il y a 1 minute"
        } else if interval < 3600 {
            return "il y a \(Int(interval / 60)) minutes"
        } else if interval < 7200 {
            return "il y a 1 heure"
        } else {
            return "il y a \(Int(interval / 3600)) heures"
        }
    }
}
