//
//  TransportLine.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 14/04/2025.
//

import Foundation

struct TransportLine: Identifiable, Codable {
    let id: String           // ID_REF (Ex: "C00019")
    let name: String         // Nom de la ligne (Ex: "T4")
    let privateCode: String? // Code technique (Ex: "100100103")
    let transportMode: TransportMode
    let transportSubmode: String?
    let operator_: Operator
    
    // Identifiant compatible avec l'API IDF
    var lineRef: String {
        // Format requis par l'API: "STIF:Line::C01742:"
        return "STIF:Line::\(id):"
    }
}
