//
//  FavoritesViewModel.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 14/04/2025.
//


import Foundation
import SwiftData
import Combine

/// ViewModel pour la gestion des favoris
class FavoritesViewModel: BaseViewModel {
    // MARK: - Services utilisés
    
    private let favoriteService: FavoriteService
    private let conditionService: ConditionService
    
    // MARK: - Propriétés publiques
    
    @Published var favorites: [TransportFavorite] = []
    @Published var activeFavorites: [TransportFavorite] = []
    @Published var departures: [String: [Departure]] = [:]
    @Published var showingDeleteAlert = false
    @Published var selectedFavorite: TransportFavorite?
    @Published var showEditFavorite = false
    
    // Singleton pour l'accès global
    static var shared: FavoritesViewModel?
    
    // MARK: - Initialisation
    
    init(
        modelContext: ModelContext? = nil,
        favoriteService: FavoriteService = FavoriteService(),
        conditionService: ConditionService = ConditionService()
    ) {
        self.favoriteService = favoriteService
        self.conditionService = conditionService
        
        super.init(modelContext: modelContext)
        
        // Définir comme instance partagée si aucune n'existe encore
        if FavoritesViewModel.shared == nil {
            FavoritesViewModel.shared = self
        }
        
        // Subscribing to favorite service changes
        setupSubscriptions()
    }
    
    // MARK: - Configuration
    
    override func setModelContext(_ context: ModelContext?) {
        super.setModelContext(context)
        favoriteService.setModelContext(context)
        loadFavorites()
    }
    
    private func setupSubscriptions() {
        // Observer les changements d'état de chargement
        favoriteService.$isLoading
            .sink { [weak self] isLoading in
                self?.isLoading = isLoading
            }
            .store(in: &cancellables)
        
        // Observer les erreurs
        favoriteService.$error
            .compactMap { $0 }
            .sink { [weak self] error in
                self?.error = error
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Actions publiques
    
    /// Charger tous les favoris
    func loadFavorites() {
        favoriteService.loadFavorites()
        updateLocalState()
    }
    
    /// Rafraîchir les données de départs
    func refreshDepartures() {
        favoriteService.refreshDepartures()
        updateLocalState()
    }
    
    /// Supprimer un favori avec confirmation
    func prepareDeleteFavorite(_ favorite: TransportFavorite) {
        selectedFavorite = favorite
        showingDeleteAlert = true
    }
    
    /// Confirmer la suppression d'un favori
    func confirmDeleteFavorite() {
        guard let favorite = selectedFavorite else { return }
        
        favoriteService.removeFavorite(with: favorite.id)
        showingDeleteAlert = false
        selectedFavorite = nil
        
        // Mettre à jour les données locales après suppression
        updateLocalState()
    }
    
    /// Modifier un favori
    func editFavorite(_ favorite: TransportFavorite) {
        selectedFavorite = favorite
        showEditFavorite = true
    }
    
    /// Réordonner les favoris
    func moveFavorite(from source: IndexSet, to destination: Int) {
        favoriteService.moveFavorite(from: source, to: destination)
        updateLocalState()
    }
    
    /// Obtenir les départs pour un favori spécifique
    func getDepartures(for favorite: TransportFavorite) -> [Departure] {
        return departures[favorite.id.uuidString] ?? []
    }
    
    /// Vérifier si un favori est actif (visible)
    func isFavoriteActive(_ favorite: TransportFavorite) -> Bool {
        return activeFavorites.contains(where: { $0.id == favorite.id })
    }
    
    /// Obtenir le temps depuis la dernière mise à jour
    func getTimeSinceLastRefresh() -> String {
        return favoriteService.getTimeSinceLastRefresh()
    }
    
    // MARK: - Méthodes privées
    
    /// Mettre à jour l'état local depuis le service
    private func updateLocalState() {
        favorites = favoriteService.favorites
        activeFavorites = favoriteService.activeFavorites
        departures = favoriteService.departures
    }
    
    // MARK: - Gestion des timers
    
    /// Démarrer les timers de rafraîchissement
    func setupRefreshTimers() {
        favoriteService.setupRefreshTimers()
    }
    
    /// Arrêter les timers de rafraîchissement
    func stopRefreshTimers() {
        favoriteService.stopRefreshTimers()
    }
}
