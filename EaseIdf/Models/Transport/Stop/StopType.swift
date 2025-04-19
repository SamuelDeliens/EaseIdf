//
//  StopType.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 14/04/2025.
//

import Foundation

enum StopType: String, Codable {
    case quay = "Quay_FR1"           // Arrêt
    case operatorQuay = "Quay_LOC"   // Arrêt transporteur
    case monomodalStop = "monomodalStopPlace"  // Zone d'arrêt
    case multimodalStop = "multimodalStopPlace" // Zone de correspondance
    case generalGroup = "GeneralGroupOfEntities" // Pôle d'échanges
    case entrance = "StopPlaceEntrance" // Accès
}
