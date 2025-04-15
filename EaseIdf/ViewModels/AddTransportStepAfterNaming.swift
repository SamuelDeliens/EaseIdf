//
//  AddTransportStepAfterNaming.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 15/04/2025.
//

import Foundation
import SwiftUI
import Combine

// Extension du AddTransportViewModel pour gérer les conditions d'affichage
extension AddTransportViewModel {
        
    /// Ajouter une nouvelle condition
    func addCondition(_ condition: DisplayCondition) {
        displayConditions.append(condition)
    }
    
    /// Supprimer une condition
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
    
    // MARK: - Méthodes pour enregistrer les conditions
    
    
    /// Enregistrer les conditions configurées avec le favori
    func saveConditions() {
        guard let stop = selectedStop,
              let line = selectedLine else {
            return
        }
        
        isSaving = true
        
        // Créer un nouveau favori avec les conditions configurées
        let favorite = TransportFavorite(
            id: UUID(),
            stopId: stop.id_stop,
            lineId: line.id_line,
            displayName: displayName,
            displayConditions: displayConditions,
            priority: 0 // La priorité peut être ajustée ultérieurement
        )
        
        // Enregistrer le favori dans SwiftData ou UserDefaults
        if let modelContext = modelContext {
            do {
                let favoriteModel = TransportFavoriteModel.fromStruct(favorite)
                modelContext.insert(favoriteModel)
                
                try modelContext.save()
                print("Favori avec conditions enregistré avec succès dans SwiftData")
            } catch {
                print("Erreur lors de l'enregistrement du favori avec conditions dans SwiftData: \(error)")
                // Fallback à UserDefaults
                StorageService.shared.saveFavorite(favorite)
            }
        } else {
            StorageService.shared.saveFavorite(favorite)
        }
        
        DispatchQueue.main.async {
            self.isSaving = false
            self.favoriteCreated = true
        }
    }
    
    /// Passer à l'étape de configuration des conditions après le nommage
    func continueToConditions() {
        afterNamingStep = .configureConditions
    }
}
