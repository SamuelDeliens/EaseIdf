//
//  ImportedStop.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 15/04/2025.
//

import Foundation

struct ImportedStop: Codable, Identifiable {
    let id_stop: String          // Identifiant de l'arrêt
    let name_stop: String        // Nom de l'arrêt
    let stop_type: String        // Type d'arrêt (quai, zone, etc.)
    let latitude: Double         // Latitude
    let longitude: Double        // Longitude
    let lines_refs: [String]?    // Références des lignes passant par cet arrêt
    
    // Conformité à Identifiable
    var id: String { id_stop }
    
    // Conversion vers le modèle TransportStop
    func toTransportStop() -> TransportStop {
        return TransportStop(
            id: id_stop,
            name: name_stop,
            type: getStopType(),
            coordinates: Coordinates(latitude: latitude, longitude: longitude),
            lines: lines_refs
        )
    }
    
    // Conversion du type d'arrêt string vers l'énumération StopType
    func getStopType() -> StopType {
        switch stop_type.lowercased() {
        case "quay", "quay_fr1": return .quay
        case "quay_loc", "operatorquay": return .operatorQuay
        case "monomodalstopplace", "monomodal": return .monomodalStop
        case "multimodalstopplace", "multimodal": return .multimodalStop
        case "generalgroupofentities", "pole": return .generalGroup
        case "stopplaceentrance", "entrance": return .entrance
        default: return .quay // Type par défaut
        }
    }
}
