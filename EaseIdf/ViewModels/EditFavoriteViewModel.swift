//
//  EditFavoriteViewModel.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 17/04/2025.
//


import Foundation
import SwiftUI
import SwiftData
import Combine

/// ViewModel pour l'édition des favoris
class EditFavoriteViewModel: BaseViewModel {
    // MARK: - Services
    
    private let favoriteService: FavoriteService
    private let conditionService: ConditionService
    
    // MARK: - Propriétés du favori
    
    @Published var displayName: String
    @Published var priority: Int
    @Published var displayConditions: [DisplayCondition]
    
    // MARK: - Référence au favori initial
    
    let favorite: Binding<TransportFavorite>
    
    // MARK: - États UI
    
    @Published var showingConditionTypeSelector = false
    @Published var showingSavedAlert = false
    @Published var activeConditionSheet: ConditionSheetType = .none
    @Published var editingConditionIndex: Int? = nil
    
    // MARK: - Initialisation
    
    init(
        favorite: Binding<TransportFavorite>,
        modelContext: ModelContext? = nil,
        favoriteService: FavoriteService = FavoriteService(),
        conditionService: ConditionService = ConditionService()
    ) {
        self.favorite = favorite
        self.displayName = favorite.wrappedValue.displayName
        self.priority = favorite.wrappedValue.priority
        self.displayConditions = favorite.wrappedValue.displayConditions
        self.favoriteService = favoriteService
        self.conditionService = conditionService
        
        super.init(modelContext: modelContext)
    }
    
    // MARK: - Méthodes pour gérer les conditions
    
    /// Ajouter une nouvelle condition
    func addCondition(_ condition: DisplayCondition) {
        displayConditions.append(condition)
    }
    
    /// Supprimer une condition
    func removeCondition(at indexSet: IndexSet) {
        for index in indexSet.sorted(by: >) {
            if index < displayConditions.count {
                displayConditions.remove(at: index)
            }
        }
    }
    
    /// Supprimer une condition par index
    func removeCondition(at index: Int) {
        guard index >= 0 && index < displayConditions.count else { return }
        displayConditions.remove(at: index)
    }
    
    /// Activer/désactiver une condition
    func toggleCondition(at index: Int, isActive: Bool) {
        guard index >= 0 && index < displayConditions.count else { return }
        displayConditions[index].isActive = isActive
    }
    
    /// Éditer une condition
    func editCondition(at index: Int) {
        guard index >= 0 && index < displayConditions.count else { return }
        
        editingConditionIndex = index
        
        // Définir le type de sheet à afficher en fonction du type de condition
        switch displayConditions[index].type {
        case .timeRange:
            activeConditionSheet = .timeRange
        case .dayOfWeek:
            activeConditionSheet = .dayOfWeek
        case .location:
            activeConditionSheet = .location
        }
    }
    
    // MARK: - Méthodes pour créer de nouvelles conditions
    
    /// Ajouter une nouvelle condition de plage horaire
    func addTimeRangeCondition() {
        editingConditionIndex = nil
        activeConditionSheet = .timeRange
    }
    
    /// Ajouter une nouvelle condition de jour de la semaine
    func addDayOfWeekCondition() {
        editingConditionIndex = nil
        activeConditionSheet = .dayOfWeek
    }
    
    /// Ajouter une nouvelle condition de localisation
    func addLocationCondition() {
        editingConditionIndex = nil
        activeConditionSheet = .location
    }
    
    /// Fermer la feuille de condition active
    func closeConditionSheet() {
        activeConditionSheet = .none
        editingConditionIndex = nil
    }
    
    // MARK: - Méthodes pour mettre à jour des conditions existantes
    
    /// Mettre à jour une condition de plage horaire
    func updateTimeRangeCondition(at index: Int, timeRange: TimeRangeCondition) {
        guard index >= 0 && index < displayConditions.count else { return }
        
        var updatedCondition = displayConditions[index]
        updatedCondition.timeRange = timeRange
        displayConditions[index] = updatedCondition
    }
    
    /// Mettre à jour une condition de jour de la semaine
    func updateDayOfWeekCondition(at index: Int, dayOfWeek: DayOfWeekCondition) {
        guard index >= 0 && index < displayConditions.count else { return }
        
        var updatedCondition = displayConditions[index]
        updatedCondition.dayOfWeekCondition = dayOfWeek
        displayConditions[index] = updatedCondition
    }
    
    /// Mettre à jour une condition de localisation
    func updateLocationCondition(at index: Int, location: LocationCondition) {
        guard index >= 0 && index < displayConditions.count else { return }
        
        var updatedCondition = displayConditions[index]
        updatedCondition.locationCondition = location
        displayConditions[index] = updatedCondition
    }
    
    // MARK: - Méthodes pour sauvegarder les conditions
    
    /// Sauvegarder une condition de plage horaire
    func saveTimeRangeCondition(editingIndex: Int?, timeRangeCondition: TimeRangeCondition) {
        if let index = editingIndex {
            updateTimeRangeCondition(at: index, timeRange: timeRangeCondition)
        } else {
            let newCondition = DisplayCondition(
                type: .timeRange,
                isActive: true,
                timeRange: timeRangeCondition
            )
            addCondition(newCondition)
        }
        
        // Fermer le sheet
        closeConditionSheet()
    }
    
    /// Sauvegarder une condition de jour de la semaine
    func saveDayOfWeekConditionEdit(editingIndex: Int?, dayOfWeekCondition: DayOfWeekCondition) {
        if let index = editingIndex {
            // Mettre à jour une condition existante
            updateDayOfWeekCondition(at: index, dayOfWeek: dayOfWeekCondition)
        } else {
            // Créer une nouvelle condition
            let newCondition = DisplayCondition(
                type: .dayOfWeek,
                isActive: true,
                dayOfWeekCondition: dayOfWeekCondition
            )
            addCondition(newCondition)
        }
        
        closeConditionSheet()
    }
    
    // MARK: - Sauvegarde du favori modifié
    
    /// Sauvegarder les modifications du favori
    func saveFavorite(context: ModelContext?) {
        guard !displayName.isEmpty else { return }
        
        // Définir le contexte de modèle s'il est fourni
        if let context = context {
            self.modelContext = context
        }
        
        startLoading()
        
        // Créer un nouveau favori avec les valeurs modifiées
        let updatedFavorite = TransportFavorite(
            id: favorite.id,
            stopId: favorite.wrappedValue.stopId,
            lineId: favorite.wrappedValue.lineId,
            displayName: displayName,
            displayConditions: displayConditions,
            priority: priority,
            lineName: favorite.wrappedValue.lineName,
            lineShortName: favorite.wrappedValue.lineShortName,
            lineColor: favorite.wrappedValue.lineColor,
            lineTextColor: favorite.wrappedValue.lineTextColor,
            lineTransportMode: favorite.wrappedValue.lineTransportMode,
            stopName: favorite.wrappedValue.stopName,
            stopLatitude: favorite.wrappedValue.stopLatitude,
            stopLongitude: favorite.wrappedValue.stopLongitude,
            stopType: favorite.wrappedValue.stopType
        )
        
        // Sauvegarder via le service de favoris
        favoriteService.saveFavorite(updatedFavorite)
        
        // Mettre à jour le favori lié
        favorite.wrappedValue = updatedFavorite
        
        // Rafraîchir les widgets
        Task {
            await WidgetService.shared.refreshWidgetData()
        }
        
        stopLoading()
        showingSavedAlert = true
    }
}

// Enum pour le type de feuille de condition active
enum ConditionSheetType {
    case none
    case timeRange
    case dayOfWeek
    case location
}
