//
//  TransportStopModel.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 15/04/2025.
//


import Foundation
import SwiftData

@Model
final class TransportStopModel {
    var id: String
    var name: String
    var type: String
    var latitude: Double
    var longitude: Double
    var lineRefsJSON: String
    
    var lineRefs: [String] {
        get {
            if let data = lineRefsJSON.data(using: .utf8),
               let array = try? JSONDecoder().decode([String].self, from: data) {
                return array
            }
            return []
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
               let jsonString = String(data: data, encoding: .utf8) {
                lineRefsJSON = jsonString
            } else {
                lineRefsJSON = "[]"
            }
        }
    }
    
    init(id: String, name: String, type: String, latitude: Double, longitude: Double, lineRefs: [String]) {
        self.id = id
        self.name = name
        self.type = type
        self.latitude = latitude
        self.longitude = longitude
        if let data = try? JSONEncoder().encode(lineRefs),
           let jsonString = String(data: data, encoding: .utf8) {
            self.lineRefsJSON = jsonString
        } else {
            self.lineRefsJSON = "[]"
        }
    }
    
    // Conversion vers le modèle struct pour compatibilité
    func toStruct() -> TransportStop {
        return TransportStop(
            id: id,
            name: name,
            type: StopType(rawValue: type) ?? .quay,
            coordinates: Coordinates(latitude: latitude, longitude: longitude),
            lines: lineRefs
        )
    }
    
    // Création à partir d'ImportedStop
    static func fromImportedStop(_ stop: ImportedStop) -> TransportStopModel {
        return TransportStopModel(
            id: stop.id_stop,
            name: stop.name_stop,
            type: stop.stop_type,
            latitude: stop.latitude,
            longitude: stop.longitude,
            lineRefs: stop.lines_refs ?? []
        )
    }
}
