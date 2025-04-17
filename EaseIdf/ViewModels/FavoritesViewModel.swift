//
//  FavoritesViewModel.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 14/04/2025.
//

import Foundation
import SwiftData
import Combine

class FavoritesViewModel: ObservableObject {
    @Published var favorites: [TransportFavorite] = []
    @Published var activeFavorites: [TransportFavorite] = []
    @Published var departures: [String: [Departure]] = [:]
    @Published var isLoading = false
    @Published var error: Error?
    
    private var cancellables = Set<AnyCancellable>()
    private var dataRefreshTimer: Timer?     // Timer pour les requêtes serveur
    private var visualRefreshTimer: Timer?   // Timer pour les mises à jour visuelles
    private var modelContext: ModelContext?
    public private(set) var lastDataRefresh: Date = Date()
    
    init() {
    }
    
    func setModelContext(_ context: ModelContext?) {
        self.modelContext = context
        loadFavorites()
    }
    
    // MARK: - Data Loading
    
    func loadFavorites() {
        if let modelContext = modelContext {
            // Try to load from SwiftData
            do {
                let descriptor = FetchDescriptor<TransportFavoriteModel>(
                    sortBy: [SortDescriptor(\.priority, order: .reverse)]
                )
                let favoriteModels = try modelContext.fetch(descriptor)
                
                // Convert models to structs
                favorites = favoriteModels.map { $0.toStruct() }
                
                // Filter active favorites based on conditions
                updateActiveFavorites()
                
                // Load departures for active favorites
                refreshDepartures()
                
                // Start refresh timers
                setupRefreshTimers()
                
            } catch {
                print("Error fetching favorites from SwiftData: \(error)")
                
                // Fallback to UserDefaults via StorageService
                favorites = StorageService.shared.getUserSettings().favorites
                updateActiveFavorites()
                refreshDepartures()
                setupRefreshTimers()
            }
        } else {
            // Fallback to UserDefaults via StorageService
            favorites = StorageService.shared.getUserSettings().favorites
            updateActiveFavorites()
            refreshDepartures()
            setupRefreshTimers()
        }
    }
    
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
    
    // MARK: - Data Refresh Methods
    
    /// Rafraîchissement complet des données (avec requête serveur)
    func refreshDepartures() {
        guard !favorites.isEmpty else { return }
        
        isLoading = true
        error = nil
        lastDataRefresh = Date()
        
        // Create a task group to fetch departures in parallel
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
                
                // Update published property on main thread
                await MainActor.run {
                    self.departures = newDepartures
                    self.isLoading = false
                }
                
                // Update widget data
                await WidgetService.shared.refreshWidgetData()
                
            } catch {
                await MainActor.run {
                    self.error = error
                    self.isLoading = false
                }
            }
        }
    }
    
    /// Rafraîchissement visuel uniquement (sans requête serveur)
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
    
    private func fetchDeparturesForFavorite(_ favorite: TransportFavorite, into departuresDict: inout [String: [Departure]]) async throws {
        // Fetch departures for this favorite
        let favoriteDepartures = try await IDFMobiliteService.shared.fetchDepartures(
            for: favorite.stopId,
            lineId: favorite.lineId
        )

        // Sort by departure time
        let sortedDepartures = favoriteDepartures.sorted {
            $0.expectedDepartureTime < $1.expectedDepartureTime
        }
        
        // Limit number of departures based on user settings
        let settings = StorageService.shared.getUserSettings()
        let limitedDepartures = Array(sortedDepartures.prefix(settings.numberOfDeparturesToShow))
        
        // Store in dictionary with favorite id as key
        departuresDict[favorite.id.uuidString] = limitedDepartures
    }
    
    // MARK: - Timer Management
    
    private func setupRefreshTimers() {
        // Cancel existing timers
        stopRefreshTimers()
        
        // Get refresh interval from settings
        let settings = StorageService.shared.getUserSettings()
        let dataInterval = settings.refreshInterval
        let visualInterval: TimeInterval = settings.visualRefreshInterval
        
        // Create new data refresh timer (pour les requêtes serveur)
        dataRefreshTimer = Timer.scheduledTimer(withTimeInterval: dataInterval, repeats: true) { [weak self] _ in
            self?.refreshDepartures()
        }
        
        // Create new visual refresh timer (pour les mises à jour visuelles)
        visualRefreshTimer = Timer.scheduledTimer(withTimeInterval: visualInterval, repeats: true) { [weak self] _ in
            self?.updateVisualDepartures()
        }
    }
    
    func stopRefreshTimers() {
        dataRefreshTimer?.invalidate()
        dataRefreshTimer = nil
        
        visualRefreshTimer?.invalidate()
        visualRefreshTimer = nil
    }
    
    // MARK: - Favorite Management
    
    func removeFavorite(at indexSet: IndexSet) {
        guard let modelContext = modelContext else {
            return
        }
        
        for index in indexSet {
            let favorite = favorites[index]
            
            // Delete from SwiftData
            do {
                let descriptor = FetchDescriptor<TransportFavoriteModel>(
                    predicate: #Predicate { $0.id == favorite.id }
                )
                let models = try modelContext.fetch(descriptor)
                
                if let model = models.first {
                    modelContext.delete(model)
                    try modelContext.save()
                }
                
                // Also delete from StorageService for compatibility
                StorageService.shared.removeFavorite(id: favorite.id)
                
                // Update local arrays
                favorites.remove(at: index)
                updateActiveFavorites()
                
            } catch {
                print("Error removing favorite: \(error)")
                // Fallback to StorageService
                StorageService.shared.removeFavorite(id: favorite.id)
                favorites.remove(at: index)
                updateActiveFavorites()
            }
        }
    }
    
    func removeFavorite(with id: UUID) {
        guard let modelContext = modelContext else {
            return
        }
        
        // Trouver l'index du favori dans le tableau
        if let index = favorites.firstIndex(where: { $0.id == id }) {
            let favorite = favorites[index]
            
            // Supprimer de SwiftData
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
                favorites.remove(at: index)
                updateActiveFavorites()
                
                // Rafraîchir les données du widget après suppression
                Task {
                    await WidgetService.shared.refreshWidgetData()
                }
                
            } catch {
                print("Error removing favorite by ID: \(error)")
                // Solution de repli vers StorageService
                StorageService.shared.removeFavorite(id: id)
                favorites.removeAll(where: { $0.id == id })
                updateActiveFavorites()
            }
        }
    }
    
    func moveFavorite(from source: IndexSet, to destination: Int) {
        guard let modelContext = modelContext else {
            return
        }
        
        // Update local array
        favorites.move(fromOffsets: source, toOffset: destination)
        
        // Update priorities based on new order (higher index = lower priority)
        for (index, favorite) in favorites.enumerated() {
            let newPriority = favorites.count - index
            
            // Try to update in SwiftData
            do {
                let descriptor = FetchDescriptor<TransportFavoriteModel>(
                    predicate: #Predicate { $0.id == favorite.id }
                )
                let models = try modelContext.fetch(descriptor)
                
                if let model = models.first {
                    model.priority = newPriority
                }
                
                // Also update in StorageService
                StorageService.shared.updateFavoritePriority(id: favorite.id, newPriority: newPriority)
                
            } catch {
                print("Error updating favorite priority: \(error)")
                // Fallback to StorageService
                StorageService.shared.updateFavoritePriority(id: favorite.id, newPriority: newPriority)
            }
        }
        
        // Save changes
        do {
            try modelContext.save()
        } catch {
            print("Error saving favorite order changes: \(error)")
        }
        
        // Update active favorites
        updateActiveFavorites()
    }
}
