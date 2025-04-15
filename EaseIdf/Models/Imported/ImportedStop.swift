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
        // Implémentation réelle de la conversion Lambert93 vers WGS84
        // Constantes Lambert93
        let a = 6378137.0 // semi-major axis
        let e = 0.08181919106 // first eccentricity
        let lc = 3.0 // origin longitude in rad
        let phi0 = 46.5 * .pi / 180.0 // origin latitude in rad
        let xs = 700000.0 // x shift
        let ys = 6600000.0 // y shift
        
        // Conversion simplifiée
        let x93 = x - xs
        let y93 = y - ys
        
        // Latitude isométrique à l'origine
        let lat0 = log(tan(.pi/4.0 + phi0/2.0) * pow((1.0 - e * sin(phi0)) / (1.0 + e * sin(phi0)), e/2.0))
        
        // Calcul de la latitude isométrique
        let lat = lat0 - y93 / (a * 0.7256077650)
        
        // Calcul de la latitude
        var phi = 2.0 * atan(exp(lat)) - .pi/2.0
        
        // Itérations pour améliorer la précision
        for _ in 0..<4 {
            let es = e * sin(phi)
            phi = 2.0 * atan(pow((1.0 + es) / (1.0 - es), e/2.0) * exp(lat)) - .pi/2.0
        }
        
        return phi * 180.0 / .pi
    }
    
    private func convertLambert93ToWGS84Long(x: Double, y: Double) -> Double? {
        // Constantes Lambert93
        let lc = 3.0 // origin longitude in rad
        let xs = 700000.0 // x shift
        
        // Conversion simplifiée
        let x93 = x - xs
        
        // Calcul de la longitude
        let lambda = lc + x93 / (6378137.0 * 0.7256077650)
        
        return lambda * 180.0 / .pi
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
