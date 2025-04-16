//
//  WidgetData.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 16/04/2025.
//

import Foundation

struct WidgetData: Codable {
    let activeFavorites: [TransportFavorite]
    let departures: [String: [Departure]]
    let lastUpdated: Date
    
    static var placeholder: WidgetData {
        let placeholderDeparture = Departure(
            stopId: "12345",
            lineId: "C01742",
            destination: "Destination",
            expectedDepartureTime: Date().addingTimeInterval(600),
            aimedDepartureTime: nil,
            vehicleJourneyName: nil
        )
        
        let placeholderFavorite = TransportFavorite(
            id: UUID(),
            stopId: "12345",
            lineId: "C01742",
            displayName: "Bus 42",
            displayConditions: [],
            priority: 1
        )
        
        return WidgetData(
            activeFavorites: [placeholderFavorite],
            departures: [placeholderFavorite.id.uuidString: [placeholderDeparture]],
            lastUpdated: Date()
        )
    }
}
