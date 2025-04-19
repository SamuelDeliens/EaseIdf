//
//  TransportStop.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 14/04/2025.
//

import Foundation

struct TransportStop: Identifiable, Codable {
    let id: String           // ID_REF_A (Ex: "50001173")
    let name: String         // Nom de l'arrêt
    let type: StopType       // Type d'arrêt (quai, zone, pôle d'échange...)
    let coordinates: Coordinates
    let lines: [String]?     // LineRefs associés à cet arrêt
    
    // Identifiant compatible avec l'API IDF
    var monitoringRef: String {
        // Format requis par l'API: "STIF:StopPoint:Q:473921:"
        return "STIF:StopPoint:Q:\(id):"
    }
}
