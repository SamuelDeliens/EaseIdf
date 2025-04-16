//
//  EaseIdfWidgetViewModel.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 16/04/2025.
//


import Foundation
import SwiftData
import Combine

class EaseIdfWidgetViewModel: ObservableObject {
    private let entry: WidgetConfigurationEntry
    @Published var groupsDepartures: [GroupDeparture] = []
    
    init(entry: WidgetConfigurationEntry) {
        self.entry = entry
        
        // Pré-calculer les données au moment de l'initialisation
        computeGroupDepartures()
    }
    
    private func computeGroupDepartures() {
        var result: [GroupDeparture] = []
        
        for activeFavorite in entry.data.activeFavorites {
            if let departures = entry.data.departures[activeFavorite.id.uuidString], !departures.isEmpty {
                result.append(GroupDeparture(
                    id: activeFavorite.id,
                    transportFavorite: activeFavorite,
                    departures: departures
                ))
            }
        }
        
        self.groupsDepartures = result
    }
    
    // Ajout de méthodes d'aide si nécessaire pour vos vues
    func getUpdateTimeFormatted() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: entry.data.lastUpdated)
    }
}
