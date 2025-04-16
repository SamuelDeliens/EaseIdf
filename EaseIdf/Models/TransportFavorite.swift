//
//  TransportFavorite.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 14/04/2025.
//

import Foundation

struct TransportFavorite: Identifiable, Codable {
    let id: UUID
    let stopId: String
    let lineId: String?
    let displayName: String
    var displayConditions: [DisplayCondition]
    var priority: Int
    
    // Informations supplémentaires sur la ligne
    let lineName: String?
    let lineShortName: String?
    let lineColor: String?
    let lineTextColor: String?
    let lineTransportMode: String?
    
    // Informations supplémentaires sur l'arrêt
    let stopName: String?
    let stopLatitude: Double?
    let stopLongitude: Double?
    let stopType: String?

    init(
        id: UUID = UUID(),
        stopId: String,
        lineId: String?,
        displayName: String,
        displayConditions: [DisplayCondition],
        priority: Int,
        lineName: String? = nil,
        lineShortName: String? = nil,
        lineColor: String? = nil,
        lineTextColor: String? = nil,
        lineTransportMode: String? = nil,
        stopName: String? = nil,
        stopLatitude: Double? = nil,
        stopLongitude: Double? = nil,
        stopType: String? = nil
    ) {
        self.id = id
        self.stopId = stopId
        self.lineId = lineId
        self.displayName = displayName
        self.displayConditions = displayConditions
        self.priority = priority
        
        // Informations sur la ligne
        self.lineName = lineName
        self.lineShortName = lineShortName
        self.lineColor = lineColor
        self.lineTextColor = lineTextColor
        self.lineTransportMode = lineTransportMode
        
        // Informations sur l'arrêt
        self.stopName = stopName
        self.stopLatitude = stopLatitude
        self.stopLongitude = stopLongitude
        self.stopType = stopType
    }
}
