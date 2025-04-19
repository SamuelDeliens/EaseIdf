//
//  DepartureSimulationService.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 19/04/2025.
//


import Foundation

class DepartureSimulationService {
    static let shared = DepartureSimulationService()
    
    private init() {}
    
    /// Génère des départs simulés pour un favori donné
    func generateSimulatedDepartures(for favorite: TransportFavorite, count: Int = 5) -> [Departure] {
        var departures: [Departure] = []
        
        // Obtenir l'heure actuelle comme point de départ
        let now = Date()
        
        // Destinations possibles en fonction du type de transport
        let destinations = getDestinationsForTransportMode(favorite.lineTransportMode)
        
        // Générer plusieurs départs échelonnés
        for i in 0..<count {
            // Intervalle de temps croissant entre les départs (5-10 min pour le premier, puis de plus en plus)
            let minutesOffset = Double(i) * (5.0 + Double.random(in: 0...5.0))
            
            // Sélectionner une destination aléatoire
            let destination = destinations.randomElement() ?? "Terminus"
            
            // Créer un nouveau départ
            let departure = Departure(
                stopId: favorite.stopId,
                lineId: favorite.lineId ?? "",
                destination: destination,
                expectedDepartureTime: now.addingTimeInterval(minutesOffset * 60),
                aimedDepartureTime: now.addingTimeInterval((minutesOffset - Double.random(in: -2...2)) * 60), // Ajouter un léger retard/avance
                vehicleJourneyName: getJourneyName(for: favorite.lineTransportMode)
            )
            
            departures.append(departure)
        }
        
        return departures
    }
    
    /// Obtient des destinations simulées en fonction du mode de transport
    private func getDestinationsForTransportMode(_ transportMode: String?) -> [String] {
        switch transportMode?.lowercased() {
        case "metro":
            return ["Château de Vincennes", "La Défense", "Mairie de Montreuil", "Gare du Nord", 
                    "Châtelet", "Nation", "Bastille", "Saint-Lazare", "Montparnasse"]
        case "rer":
            return ["Saint-Rémy-lès-Chevreuse", "Massy-Palaiseau", "Aéroport CDG", "Marne-la-Vallée", 
                    "Cergy-le-Haut", "Robinson", "Versailles Chantiers", "Saint-Germain-en-Laye"]
        case "tram":
            return ["Porte de Versailles", "La Courneuve", "Porte d'Orléans", "Villejuif", 
                    "IUT de Vélizy", "Viroflay Rive Droite", "Sarcelles", "Épinay-sur-Seine"]
        case "bus":
            return ["Gare de l'Est", "Hôpital Necker", "Gare de Lyon", "Place d'Italie", 
                    "Porte de Clignancourt", "Porte de la Chapelle", "Mairie du 15e", "École Militaire"]
        case "rail":
            return ["Paris Gare du Nord", "Paris Montparnasse", "Paris Est", "Paris Saint-Lazare", 
                    "Melun", "Meaux", "Rambouillet", "Pontoise", "Chantilly"]
        default:
            return ["Terminus", "Destination finale", "Terminus du service"]
        }
    }
    
    /// Obtient un nom de trajet simulé pour le mode de transport
    private func getJourneyName(for transportMode: String?) -> String? {
        switch transportMode?.lowercased() {
        case "metro":
            return "RATP-M\(Int.random(in: 1...14))-\(String(format: "%03d", Int.random(in: 1...999)))"
        case "rer":
            let lines = ["A", "B", "C", "D", "E"]
            return "RATP-RER\(lines.randomElement() ?? "A")-\(String(format: "%03d", Int.random(in: 1...999)))"
        case "tram":
            return "RATP-T\(Int.random(in: 1...13))-\(String(format: "%03d", Int.random(in: 1...999)))"
        case "bus":
            return "RATP-B\(Int.random(in: 20...100))-\(String(format: "%03d", Int.random(in: 1...999)))"
        default:
            return nil
        }
    }
    
    /// Actualise les départs simulés pour tenir compte du temps qui passe
    func refreshSimulatedDepartures(_ departures: [Departure]) -> [Departure] {
        let now = Date()
        
        // Filtrer les départs déjà passés
        var updatedDepartures = departures.filter { $0.expectedDepartureTime > now }
        
        // Si des départs sont passés, en générer de nouveaux pour compléter
        if updatedDepartures.count < departures.count {
            let lastDeparture = departures.last ?? updatedDepartures.last
            let newCount = departures.count - updatedDepartures.count
            
            for i in 0..<newCount {
                // Créer un nouveau départ en se basant sur le dernier connu
                if let last = lastDeparture {
                    let minutesOffset = Double(i + 1) * (5.0 + Double.random(in: 0...5.0))
                    let baseTime = last.expectedDepartureTime
                    
                    let newDeparture = Departure(
                        stopId: last.stopId,
                        lineId: last.lineId,
                        destination: last.destination,
                        expectedDepartureTime: baseTime.addingTimeInterval(minutesOffset * 60),
                        aimedDepartureTime: baseTime.addingTimeInterval((minutesOffset - Double.random(in: -2...2)) * 60),
                        vehicleJourneyName: last.vehicleJourneyName
                    )
                    
                    updatedDepartures.append(newDeparture)
                }
            }
        }
        
        // Trier les départs par heure
        return updatedDepartures.sorted { $0.expectedDepartureTime < $1.expectedDepartureTime }
    }
}
