//
//  ImportedStop.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 15/04/2025.
//

import Foundation

struct ImportedStop: Codable, Identifiable {
    // Propriétés correspondant à la structure du JSON
    let line: String
    let name_line: String?
    let ns2_stoppointref: String
    let ns2_stopname: String?
    let ns2_lines: String?
    let ns2_location: String?
    
    // Propriétés dérivées pour la compatibilité avec le reste de l'application
    var id_stop: String {
        // Extrait l'ID de "STIF:StopPoint:Q:15368:"
        let components = ns2_stoppointref.split(separator: ":")
        return components.count >= 4 ? String(components[3]) : ns2_stoppointref
    }
    
    var name_stop: String {
        return ns2_stopname ?? "Arrêt \(id_stop)" // Valeur par défaut constructive
    }
    
    var stop_type: String {
        return "Quay_FR1"
    }
    
    var latitude: Double {
        guard let locationStr = ns2_location,
              let locationData = try? JSONSerialization.jsonObject(with: locationStr.data(using: .utf8) ?? Data(), options: []) as? [String: Any],
              let latString = locationData["ns2:Latitude"] as? String,
              let lat = Double(latString) else {
            return 0.0
        }
        // Conversion simplifiée
        return convertLambert93ToWGS84Lat(x: 0, y: lat) ?? 0.0
    }
    
    var longitude: Double {
        guard let locationStr = ns2_location,
              let locationData = try? JSONSerialization.jsonObject(with: locationStr.data(using: .utf8) ?? Data(), options: []) as? [String: Any],
              let longString = locationData["ns2:Longitude"] as? String,
              let long = Double(longString) else {
            return 0.0
        }
        // Conversion simplifiée
        return convertLambert93ToWGS84Long(x: long, y: 0) ?? 0.0
    }
    
    var lines_refs: [String]? {
        guard let linesStr = ns2_lines else {
            return [line]
        }
        
        do {
            let linesData = try JSONSerialization.jsonObject(with: linesStr.data(using: .utf8) ?? Data(), options: []) as? [String: Any]
            
            if let lineRefs = linesData?["ns2:LineRef"] as? [String] {
                return lineRefs
            } else if let lineRef = linesData?["ns2:LineRef"] as? String {
                return [lineRef]
            }
        } catch {
            print("Erreur lors de l'extraction des lignes: \(error)")
        }
        return [line]
    }
    
    // Conformité à Identifiable
    var id: String { id_stop }
    
    // Méthodes de conversion de coordonnées (à implémenter avec les formules correctes)
    private func convertLambert93ToWGS84Lat(x: Double, y: Double) -> Double? {
        // Implémentation simplifiée - à remplacer par une conversion correcte
        // Remarque: Lambert93 utilise un système de coordonnées différent et nécessite une conversion mathématique
        return 48.85 // Valeur par défaut pour Paris pendant le développement
    }
    
    private func convertLambert93ToWGS84Long(x: Double, y: Double) -> Double? {
        // Implémentation simplifiée - à remplacer par une conversion correcte
        return 2.35 // Valeur par défaut pour Paris pendant le développement
    }
    
    // Méthodes existantes
    func toTransportStop() -> TransportStop {
        return TransportStop(
            id: id_stop,
            name: name_stop,
            type: getStopType(),
            coordinates: Coordinates(latitude: latitude, longitude: longitude),
            lines: lines_refs
        )
    }
    
    func getStopType() -> StopType {
        // Par défaut, considérons qu'il s'agit d'un quai (Quay)
        return .quay
    }
}
