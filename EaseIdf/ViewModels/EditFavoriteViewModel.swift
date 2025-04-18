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

class EditFavoriteViewModel: ObservableObject {
    // Propriétés du favori
    @Published var displayName: String
    @Published var priority: Int
    @Published var displayConditions: [DisplayCondition]
    
    // Référence au favori initial
    let favorite: Binding<TransportFavorite>
    
    // États UI
    @Published var showingConditionTypeSelector = false
    @Published var showingSavedAlert = false
    @Published var activeConditionSheet: ConditionSheetType = .none
    @Published var editingConditionIndex: Int? = nil
    
    // Référence au contexte SwiftData
    private var modelContext: ModelContext?
    
    init(favorite: Binding<TransportFavorite>) {
        self.favorite = favorite
        self.displayName = favorite.wrappedValue.displayName
        self.priority = favorite.wrappedValue.priority
        self.displayConditions = favorite.wrappedValue.displayConditions
    }
    
    // MARK: - Méthodes pour gérer la référence au ModelContext
    
    func setModelContext(_ context: ModelContext?) {
        self.modelContext = context
    }
    
    // MARK: - Méthodes pour gérer les conditions
    
    func addCondition(_ condition: DisplayCondition) {
        displayConditions.append(condition)
    }
    
    func removeCondition(at indexSet: IndexSet) {
        displayConditions.remove(atOffsets: indexSet)
    }
    
    func removeCondition(at index: Int) {
        guard index >= 0 && index < displayConditions.count else { return }
        displayConditions.remove(at: index)
    }
    
    func toggleCondition(at index: Int, isActive: Bool) {
        guard index >= 0 && index < displayConditions.count else { return }
        displayConditions[index].isActive = isActive
    }
    
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
    
    func addTimeRangeCondition() {
        editingConditionIndex = nil
        activeConditionSheet = .timeRange
    }
    
    func addDayOfWeekCondition() {
        editingConditionIndex = nil
        activeConditionSheet = .dayOfWeek
    }
    
    func addLocationCondition() {
        editingConditionIndex = nil
        activeConditionSheet = .location
    }
    
    func closeConditionSheet() {
        activeConditionSheet = .none
        editingConditionIndex = nil
    }
    
    // MARK: - Méthodes pour mettre à jour des conditions existantes
    
    func updateTimeRangeCondition(at index: Int, timeRange: TimeRangeCondition) {
        guard index >= 0 && index < displayConditions.count else { return }
        
        var updatedCondition = displayConditions[index]
        updatedCondition.timeRange = timeRange
        displayConditions[index] = updatedCondition
    }
    
    func updateDayOfWeekCondition(at index: Int, dayOfWeek: DayOfWeekCondition) {
        guard index >= 0 && index < displayConditions.count else { return }
        
        var updatedCondition = displayConditions[index]
        updatedCondition.dayOfWeekCondition = dayOfWeek
        displayConditions[index] = updatedCondition
    }
    
    func updateLocationCondition(at index: Int, location: LocationCondition) {
        guard index >= 0 && index < displayConditions.count else { return }
        
        var updatedCondition = displayConditions[index]
        updatedCondition.locationCondition = location
        displayConditions[index] = updatedCondition
    }
    
    // MARK: - Sauvegarde du favori modifié
    
    func saveFavorite(context: ModelContext?) {
        guard !displayName.isEmpty else { return }
        
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
        
        if let context = context ?? modelContext {
            do {
                // Rechercher le modèle existant
                let favoriteId = favorite.wrappedValue.id
                let descriptor = FetchDescriptor<TransportFavoriteModel>(
                    predicate: #Predicate { model in model.id == favoriteId }
                )
                
                let existingModels = try context.fetch(descriptor)
                
                if let existingModel = existingModels.first {
                    // Mettre à jour le modèle existant
                    existingModel.displayName = displayName
                    existingModel.priority = priority
                    
                    // Supprimer les anciennes conditions
                    existingModel.conditions.removeAll()
                    
                    // Ajouter les nouvelles conditions
                    for condition in displayConditions {
                        let conditionModel = DisplayConditionModel.fromStruct(condition)
                        existingModel.conditions.append(conditionModel)
                    }
                    
                    // Sauvegarder les modifications
                    try context.save()
                    
                    // Rafraîchir les widgets
                    Task {
                        await WidgetService.shared.refreshWidgetData()
                    }
                    
                    showingSavedAlert = true
                } else {
                    // Le favori n'existe pas dans SwiftData, utiliser StorageService
                    StorageService.shared.saveFavorite(updatedFavorite)
                    showingSavedAlert = true
                }
            } catch {
                print("Erreur lors de la sauvegarde du favori: \(error)")
                
                // Fallback vers StorageService
                StorageService.shared.saveFavorite(updatedFavorite)
                showingSavedAlert = true
            }
        } else {
            // Pas de contexte disponible, utiliser StorageService
            StorageService.shared.saveFavorite(updatedFavorite)
            showingSavedAlert = true
        }
        
    }
    
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
}

// Enum pour le type de feuille de condition active - similaire à AddTransportViewModel
enum ConditionSheetType {
    case none
    case timeRange
    case dayOfWeek
    case location
}
