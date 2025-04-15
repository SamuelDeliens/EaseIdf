//
//  SIRIResponse.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 14/04/2025.
//


import Foundation

// Structure principale
struct SIRIResponse: Codable {
    let siri: Siri
    
    enum CodingKeys: String, CodingKey {
        case siri = "Siri"
    }
}

struct Siri: Codable {
    let serviceDelivery: ServiceDelivery
    
    enum CodingKeys: String, CodingKey {
        case serviceDelivery = "ServiceDelivery"
    }
}

struct ServiceDelivery: Codable {
    let responseTimestamp: String
    let stopMonitoringDelivery: [StopMonitoringDelivery]?
    
    enum CodingKeys: String, CodingKey {
        case responseTimestamp = "ResponseTimestamp"
        case stopMonitoringDelivery = "StopMonitoringDelivery"
    }
}

struct StopMonitoringDelivery: Codable {
    let responseTimestamp: String
    let version: String
    let status: String
    let monitoredStopVisit: [MonitoredStopVisit]?
    
    enum CodingKeys: String, CodingKey {
        case responseTimestamp = "ResponseTimestamp"
        case version = "Version"
        case status = "Status"
        case monitoredStopVisit = "MonitoredStopVisit"
    }
}

struct MonitoredStopVisit: Codable {
    let recordedAtTime: String
    let monitoringRef: MonitoringRefWrapper
    let monitoredVehicleJourney: MonitoredVehicleJourney
    
    enum CodingKeys: String, CodingKey {
        case recordedAtTime = "RecordedAtTime"
        case monitoringRef = "MonitoringRef"
        case monitoredVehicleJourney = "MonitoredVehicleJourney"
    }
}

struct MonitoringRefWrapper: Codable {
    let value: String
}

struct MonitoredVehicleJourney: Codable {
    let lineRef: LineRefWrapper
    let directionName: [TextWrapper]?
    let destinationRef: DestinationRefWrapper?
    let destinationName: [TextWrapper]?
    let monitoredCall: MonitoredCall
    
    enum CodingKeys: String, CodingKey {
        case lineRef = "LineRef"
        case directionName = "DirectionName"
        case destinationRef = "DestinationRef"
        case destinationName = "DestinationName"
        case monitoredCall = "MonitoredCall"
    }
}

struct LineRefWrapper: Codable {
    let value: String
}

struct DestinationRefWrapper: Codable {
    let value: String
}

struct TextWrapper: Codable {
    let value: String
}

struct MonitoredCall: Codable {
    let stopPointName: [TextWrapper]?
    let destinationDisplay: [TextWrapper]?
    let expectedDepartureTime: String?
    let expectedArrivalTime: String?
    let departureStatus: String?
    let arrivalStatus: String?
    let vehicleAtStop: Bool?
    
    enum CodingKeys: String, CodingKey {
        case stopPointName = "StopPointName"
        case destinationDisplay = "DestinationDisplay"
        case expectedDepartureTime = "ExpectedDepartureTime"
        case expectedArrivalTime = "ExpectedArrivalTime"
        case departureStatus = "DepartureStatus"
        case arrivalStatus = "ArrivalStatus"
        case vehicleAtStop = "VehicleAtStop"
    }
}

// Extension pour convertir vers le modèle Departure
extension SIRIResponse {
    func toDepartures() -> [Departure] {
        guard let stopMonitoringDelivery = siri.serviceDelivery.stopMonitoringDelivery?.first,
              let visits = stopMonitoringDelivery.monitoredStopVisit else {
            print("Aucun StopMonitoringDelivery ou MonitoredStopVisit trouvé")
            return []
        }
        
        print("Nombre de visites trouvées: \(visits.count)")
        
        // Créer un formateur de date ISO 8601 plus flexible
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let departures = visits.compactMap { visit -> Departure? in
            // Vérifier les données requises
            guard let expectedDepartureTimeString = visit.monitoredVehicleJourney.monitoredCall.expectedDepartureTime else {
                print("Pas d'heure de départ prévue pour une visite")
                return nil
            }
            
            var expectedDepartureTime: Date?
            
            // Premier essai avec le formateur complet
            expectedDepartureTime = dateFormatter.date(from: expectedDepartureTimeString)
            
            // Si ça échoue, essayer de nettoyer la chaîne de caractères
            if expectedDepartureTime == nil {
                print("Premier essai échoué, tentative de nettoyage de la date: \(expectedDepartureTimeString)")
                
                // Enlever les millisecondes si présentes
                let cleanedDateString = expectedDepartureTimeString.replacingOccurrences(of: "\\.\\d+", with: "", options: .regularExpression)
                
                // Créer un formateur sans les millisecondes
                let simpleFormatter = ISO8601DateFormatter()
                expectedDepartureTime = simpleFormatter.date(from: cleanedDateString)
                
                if expectedDepartureTime == nil {
                    print("Impossible de parser la date même après nettoyage")
                    return nil
                }
            }
            
            let lineRef = visit.monitoredVehicleJourney.lineRef.value
            let lineId = extractId(from: lineRef)
            
            let stopRef = visit.monitoringRef.value
            let stopId = extractId(from: stopRef)
            
            let destination = visit.monitoredVehicleJourney.destinationName?.first?.value
                ?? visit.monitoredVehicleJourney.monitoredCall.destinationDisplay?.first?.value
                ?? "Destination inconnue"
            
            print("Créé un départ pour la ligne \(lineId) vers \(destination) à \(expectedDepartureTime!)")
            
            return Departure(
                stopId: stopId,
                lineId: lineId,
                destination: destination,
                expectedDepartureTime: expectedDepartureTime!,
                aimedDepartureTime: nil,
                vehicleJourneyName: nil
            )
        }
        
        print("Nombre de départs convertis: \(departures.count)")
        return departures
    }
    
    private func extractId(from ref: String) -> String {
        // Extract the ID from a reference like "STIF:Line::C01742:"
        let components = ref.split(separator: ":")
        if components.count >= 4 {
            return String(components[3])
        }
        return ref
    }
}
