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
    
    @Relationship(deleteRule: .cascade)
    var conditions: [DisplayConditionModel]
    
    init(
        id: UUID = UUID(),
        stopId: String,
        lineId: String? = nil,
        displayName: String,
        priority: Int = 0,
        conditions: [DisplayConditionModel] = []
    ) {
        self.id = id
        self.stopId = stopId
        self.lineId = lineId
        self.displayName = displayName
        self.priority = priority
        self.lastUpdated = Date()
        self.conditions = conditions
    }
    
    // Convert to struct format for use with other services
    func toStruct() -> TransportFavorite {
        return TransportFavorite(
            id: id,
            stopId: stopId,
            lineId: lineId,
            displayName: displayName,
            displayConditions: conditions.map { $0.toStruct() },
            priority: priority
        )
    }
    
    // Create from struct
    static func fromStruct(_ favorite: TransportFavorite) -> TransportFavoriteModel {
        let model = TransportFavoriteModel(
            id: favorite.id,
            stopId: favorite.stopId,
            lineId: favorite.lineId,
            displayName: favorite.displayName,
            priority: favorite.priority
        )
        
        model.conditions = favorite.displayConditions.map { DisplayConditionModel.fromStruct($0) }
        
        return model
    }
}
