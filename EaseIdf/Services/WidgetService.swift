//
//  WidgetService.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 14/04/2025.
//

import Foundation
import WidgetKit
import SwiftUI

class WidgetService {
    static let shared = WidgetService()
    
    private init() {}
    
    private var dataRefreshTimer: Timer?
    private var visualRefreshTimer: Timer?
    private var lastDataRefresh: Date = Date()
    
    /// Save departures data for widget access
    func saveWidgetData(departures: [String: [Departure]], activeTransportFavorites: [TransportFavorite]) {
        let userData = WidgetData(
            activeFavorites: activeTransportFavorites,
            departures: departures,
            lastUpdated: Date()
        )
        
        if let encoded = try? JSONEncoder().encode(userData) {
            if let sharedDefaults = UserDefaults(suiteName: KeychainConstants.appGroup) {
                sharedDefaults.set(encoded, forKey: KeychainConstants.SharedUserDefaults.widgetData)
                
                // Refresh all widgets
                refreshWidgets()
            }
        }
    }
    
    /// Refresh widget data by fetching latest departures for active favorites
    func refreshWidgetData() async {
        let activeFavorites = ConditionEvaluationService.shared.getCurrentlyActiveTransportFavorites()
        var allDepartures: [String: [Departure]] = [:]
        
        let settings = StorageService.shared.getUserSettings()
        lastDataRefresh = Date()
        
        // Log pour débogage
        print("Refresh du widget: \(activeFavorites.count) favoris actifs")
        
        for favorite in activeFavorites {
            do {
                let departures = try await IDFMobiliteService.shared.fetchDepartures(
                    for: favorite.stopId,
                    lineId: favorite.lineId
                )
                
                let limitedDepartures = limitDepartures(departures, settings: settings)
                
                allDepartures[favorite.id.uuidString] = limitedDepartures
                print("Récupération de \(departures.count) départs pour le favori \(favorite.displayName)")
            } catch {
                print("Erreur lors de la récupération des départs pour le widget: \(error.localizedDescription)")
            }
        }
        
        // Save for widget access
        saveWidgetData(departures: allDepartures, activeTransportFavorites: activeFavorites)
        
        print("Widget mis à jour avec \(allDepartures.count) lignes avec \(settings.numberOfDeparturesToShow) départs")
    }
    
    /// Update widget visually without fetching new data
    func updateWidgetVisually() async {
        if let sharedDefaults = UserDefaults(suiteName: KeychainConstants.appGroup),
           let data = sharedDefaults.data(forKey: KeychainConstants.SharedUserDefaults.widgetData),
           let widgetData = try? JSONDecoder().decode(WidgetData.self, from: data) {
            
            let activeFavorites = ConditionEvaluationService.shared.getCurrentlyActiveTransportFavorites()
            var updatedDepartures = widgetData.departures
            
            // Mise à jour des favoris actifs
            saveWidgetData(departures: updatedDepartures, activeTransportFavorites: activeFavorites)
            
            // Refresh widgets pour montrer les mises à jour visuelles
            refreshWidgets()
        }
    }
    
    /// Schedule periodic background updates for widget data
    func scheduleBackgroundUpdates(interval: TimeInterval = 600) {
        // Annuler les timers existants
        dataRefreshTimer?.invalidate()
        visualRefreshTimer?.invalidate()
        
        // Configuration de l'intervalle de rafraîchissement des données
        if let sharedDefaults = UserDefaults(suiteName: KeychainConstants.appGroup) {
            sharedDefaults.set(interval, forKey: KeychainConstants.SharedUserDefaults.widgetRefreshInterval)
        }
        
        // Créer un nouveau timer pour les mises à jour de données (intervalles longs)
        dataRefreshTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task {
                await self?.refreshWidgetData()
            }
        }
        
        // Créer un nouveau timer pour les mises à jour visuelles (60 secondes)
        visualRefreshTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task {
                await self?.updateWidgetVisually()
            }
        }
        
        // En production, cette fonction utiliserait BGAppRefreshTask ou BGProcessingTask
        // pour planifier des mises à jour périodiques en arrière-plan
        
        // Planifier la première mise à jour
        Task {
            await self.refreshWidgetData()
        }
    }
    
    func stopBackgroundUpdate() {
        dataRefreshTimer?.invalidate()
        visualRefreshTimer?.invalidate()
    }
    
    /// Force refresh of widget data - useful when user performs manual refresh
    func forceRefreshWidgetData() async {
        await refreshWidgetData()
    }
    
    // MARK: - Private Helper Methods
    
    /// Refresh all widgets
    private func refreshWidgets() {
#if os(iOS)
        WidgetCenter.shared.reloadAllTimelines()
#endif
    }
    
    /// Limit the number of departures according to user settings
    private func limitDepartures(_ departures: [Departure], settings: UserSettings) -> [Departure] {
        var filteredDepartures = departures
        if settings.showOnlyUpcomingDepartures {
            filteredDepartures = departures.filter { $0.expectedDepartureTime > Date() }
        }
        
        // Regrouper par arrêt et ligne
        let groupedDepartures = Dictionary(grouping: filteredDepartures) {
            return "\($0.stopId)-\($0.lineId)"
        }
        
        var limitedDepartures: [Departure] = []
        
        for (_, departuresForStopAndLine) in groupedDepartures {
            // Trier par heure de départ
            let sortedDepartures = departuresForStopAndLine.sorted {
                $0.expectedDepartureTime < $1.expectedDepartureTime
            }
            
            // Limiter au nombre spécifié dans les paramètres
            let limited = Array(sortedDepartures.prefix(settings.numberOfDeparturesToShow))
            limitedDepartures.append(contentsOf: limited)
        }
        
        // Trier tous les départs par heure pour l'affichage final
        return limitedDepartures.sorted { $0.expectedDepartureTime < $1.expectedDepartureTime }
    }
}
