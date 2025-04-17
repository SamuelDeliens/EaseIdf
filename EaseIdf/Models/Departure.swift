//
//  Departure.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 14/04/2025.
//

import Foundation

struct Departure: Identifiable, Codable {
    let id: UUID = UUID()
    let stopId: String
    let lineId: String
    let destination: String
    let expectedDepartureTime: Date
    let aimedDepartureTime: Date?
    let vehicleJourneyName: String?
    var delay: TimeInterval? {
        guard let aimed = aimedDepartureTime else { return nil }
        return expectedDepartureTime.timeIntervalSince(aimed)
    }
    
    // Pour l'affichage des temps d'attente
    var waitingTime: String {
        let minutes = Int(expectedDepartureTime.timeIntervalSinceNow / 60)
        if minutes <= 0 {
            return "Imminent"
        } else if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return "\(hours)h\(remainingMinutes)"
        }
    }
    
    // Nouvelle méthode: savoir si le départ est déjà passé
    var isPassed: Bool {
        return expectedDepartureTime < Date()
    }
    
    // Nouvelle méthode: récupérer les minutes restantes (pour filtrage)
    var remainingMinutes: Int {
        return max(0, Int(expectedDepartureTime.timeIntervalSinceNow / 60))
    }
}
