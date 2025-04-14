//
//  StopMonitoringResponse.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 14/04/2025.
//

import Foundation

struct StopMonitoringResponse: Codable {
    // Structure à adapter selon le format exact de la réponse SIRI Lite
    // Cette structure sera complétée lorsque vous commencerez à travailler avec l'API
    let deliveryTimeStamp: String?
    let monitoringRef: String?
    let monitoredStopVisits: [MonitoredStopVisit]?
}

struct MonitoredStopVisit: Codable, Identifiable {
    let id = UUID()
    let monitoringRef: String?
    let lineRef: String?
    let destinationName: String?
    let expectedArrivalTime: String?
    let expectedDepartureTime: String?
}
