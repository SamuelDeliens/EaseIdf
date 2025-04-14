//
//  WidgetService.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 14/04/2025.
//

import Foundation
import WidgetKit

class WidgetService {
    static let shared = WidgetService()
    
    private init() {}
    
    // MARK: - Widget Data Management
    
    /// Save departures data for widget access
    func saveWidgetData(departures: [Departure], activeTransportFavorites: [TransportFavorite]) {
        let userData = WidgetData(
            departures: departures,
            favorites: activeTransportFavorites,
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
        var allDepartures: [Departure] = []
        
        for favorite in activeFavorites {
            do {
                let departures = try await IDFMobiliteService.shared.fetchDepartures(
                    for: favorite.stopId,
                    lineId: favorite.lineId
                )
                
                allDepartures.append(contentsOf: departures)
            } catch {
                print("Error refreshing departures for widget: \(error.localizedDescription)")
            }
        }
        
        // Limit the number of departures per favorite if needed
        let settings = StorageService.shared.getUserSettings()
        let limitedDepartures = limitDepartures(allDepartures, settings: settings)
        
        // Save for widget access
        saveWidgetData(departures: limitedDepartures, activeTransportFavorites: activeFavorites)
    }
    
    /// Schedule periodic background updates for widget data
    func scheduleBackgroundUpdates(interval: TimeInterval = 600) {
        // This would typically use BGAppRefreshTask in a real implementation
        // For now, we'll just set up a user default for the refresh interval
        if let sharedDefaults = UserDefaults(suiteName: "group.com.samueldeliens.EaseIdf") {
            sharedDefaults.set(interval, forKey: "widgetRefreshInterval")
        }
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
        // Filter upcoming departures if enabled
        var filteredDepartures = departures
        if settings.showOnlyUpcomingDepartures {
            filteredDepartures = departures.filter { $0.expectedDepartureTime > Date() }
        }
        
        // Group by stop and line, then limit per group
        let groupedDepartures = Dictionary(grouping: filteredDepartures) { 
            return "\($0.stopId)-\($0.lineId)" 
        }
        
        var limitedDepartures: [Departure] = []
        
        for (_, departuresForStopAndLine) in groupedDepartures {
            // Sort by departure time
            let sortedDepartures = departuresForStopAndLine.sorted { 
                $0.expectedDepartureTime < $1.expectedDepartureTime 
            }
            
            // Take only the specified number
            let limited = Array(sortedDepartures.prefix(settings.numberOfDeparturesToShow))
            limitedDepartures.append(contentsOf: limited)
        }
        
        // Sort all departures by time for final output
        return limitedDepartures.sorted { $0.expectedDepartureTime < $1.expectedDepartureTime }
    }
}

// Data structure for widget
struct WidgetData: Codable {
    let departures: [Departure]
    let favorites: [TransportFavorite]
    let lastUpdated: Date
}
