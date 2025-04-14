//
//  TransportFavorite.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 14/04/2025.
//

import Foundation

struct TransportFavorite: Identifiable, Codable {
    let id: UUID = UUID()
    let stopId: String
    let lineId: String?  // Optionnel car on peut vouloir tous les passages à un arrêt
    let displayName: String
    var displayConditions: [DisplayCondition]
    var priority: Int
}
