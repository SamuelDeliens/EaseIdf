//
//  StopMonitoringResponse.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 14/04/2025.
//

import Foundation

struct StopMonitoringResponse: Codable {
    let deliveryTimeStamp: String?
    let monitoringRef: String?
    let monitoredStopVisits: [MonitoredStopVisit]?
    
    // Constructeur pour créer une instance à partir de SIRIResponse
    static func from(siriResponse: SIRIResponse) -> StopMonitoringResponse? {
        guard let stopMonitoringDelivery = siriResponse.siri.serviceDelivery.stopMonitoringDelivery?.first,
              let monitoredStopVisits = stopMonitoringDelivery.monitoredStopVisit else {
            return nil
        }
        
        return StopMonitoringResponse(
            deliveryTimeStamp: stopMonitoringDelivery.responseTimestamp,
            monitoringRef: monitoredStopVisits.first?.monitoringRef.value,
            monitoredStopVisits: monitoredStopVisits
        )
    }
}
