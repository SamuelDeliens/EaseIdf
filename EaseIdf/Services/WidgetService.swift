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
        
    /// Save departures data for widget access
    func saveWidgetData(departures: [String: [Departure]], activeTransportFavorites: [TransportFavorite]) {
        let userData = WidgetData(
            activeFavorites: activeTransportFavorites,
            departures: departures,
            lastUpdated: Date()
        )
        
        if let encoded = try? JSONEncoder().encode(userData) {
            if let sharedDefaults = UserDefaults(suiteName: "group.com.samueldeliens.EaseIdf") {
                sharedDefaults.set(encoded, forKey: "widgetData")
                
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
        
        print("Widget mis à jour avec \(allDepartures.count) linges avec \(settings.numberOfDeparturesToShow) départs")
    }
    
    /// Schedule periodic background updates for widget data
    func scheduleBackgroundUpdates(interval: TimeInterval = 600) {
        // Configuration de l'intervalle de rafraîchissement
        if let sharedDefaults = UserDefaults(suiteName: "group.com.samueldeliens.EaseIdf") {
            sharedDefaults.set(interval, forKey: "widgetRefreshInterval")
        }
        
        // En production, cette fonction utiliserait BGAppRefreshTask ou BGProcessingTask
        // pour planifier des mises à jour périodiques en arrière-plan
        
        // Pour une implémentation simple, nous pouvons utiliser un timer local
        DispatchQueue.main.async {
            // Planifier la première mise à jour
            Task {
                await self.refreshWidgetData()
            }
        }
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
