//
//  TransportFavoriteModel.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 14/04/2025.
//

import Foundation
import SwiftData

@Model
final class TransportFavoriteModel {
    var id: UUID
    var stopId: String
    var lineId: String?
    var displayName: String
    var priority: Int
    var lastUpdated: Date
    
    // Informations supplémentaires sur la ligne
    var lineName: String?
    var lineShortName: String?
    var lineColor: String?
    var lineTextColor: String?
    var lineTransportMode: String?
    
    // Informations supplémentaires sur l'arrêt
    var stopName: String?
    var stopLatitude: Double?
    var stopLongitude: Double?
    var stopType: String?
    
    @Relationship(deleteRule: .cascade)
    var conditions: [DisplayConditionModel]
    
    init(
        id: UUID = UUID(),
        stopId: String,
        lineId: String? = nil,
        displayName: String,
        priority: Int = 0,
        conditions: [DisplayConditionModel] = [],
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
        self.priority = priority
        self.lastUpdated = Date()
        self.conditions = conditions
        
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
    
    // Convert to struct format for use with other services
    func toStruct() -> TransportFavorite {
        return TransportFavorite(
            id: id,
            stopId: stopId,
            lineId: lineId,
            displayName: displayName,
            displayConditions: conditions.map { $0.toStruct() },
            priority: priority,
            lineName: lineName,
            lineShortName: lineShortName,
            lineColor: lineColor,
            lineTextColor: lineTextColor,
            lineTransportMode: lineTransportMode,
            stopName: stopName,
            stopLatitude: stopLatitude,
            stopLongitude: stopLongitude,
            stopType: stopType
        )
    }
    
    // Create from struct
    static func fromStruct(_ favorite: TransportFavorite) -> TransportFavoriteModel {
        let model = TransportFavoriteModel(
            id: favorite.id,
            stopId: favorite.stopId,
            lineId: favorite.lineId,
            displayName: favorite.displayName,
            priority: favorite.priority,
            lineName: favorite.lineName,
            lineShortName: favorite.lineShortName,
            lineColor: favorite.lineColor,
            lineTextColor: favorite.lineTextColor,
            lineTransportMode: favorite.lineTransportMode,
            stopName: favorite.stopName,
            stopLatitude: favorite.stopLatitude,
            stopLongitude: favorite.stopLongitude,
            stopType: favorite.stopType
        )
        
        model.conditions = favorite.displayConditions.map { DisplayConditionModel.fromStruct($0) }
        
        return model
    }
}
