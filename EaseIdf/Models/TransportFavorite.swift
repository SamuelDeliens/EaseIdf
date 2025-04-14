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

    init(
        id: UUID = UUID(),
        stopId: String,
        lineId: String?,
        displayName: String,
        displayConditions: [DisplayCondition],
        priority: Int
    ) {
        self.id = id
        self.stopId = stopId
        self.lineId = lineId
        self.displayName = displayName
        self.displayConditions = displayConditions
        self.priority = priority
    }
}
