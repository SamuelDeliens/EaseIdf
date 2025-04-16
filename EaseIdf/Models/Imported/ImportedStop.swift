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
        guard let locationStr = ns2_location else {
            print("Aucune donnée de localisation pour l'arrêt \(name_stop)")
            return 48.8566 // Paris par défaut
        }
        
        // Analyser les données JSON
        do {
            if let data = locationStr.data(using: .utf8),
               let locationData = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                
                // Vérifier le système de coordonnées
                let srsName = locationData["@srsName"] as? String
                
                // Extraire les valeurs de longitude et latitude
                guard let longString = locationData["ns2:Longitude"] as? String,
                      let latString = locationData["ns2:Latitude"] as? String,
                      let x = Double(longString),
                      let y = Double(latString) else {
                    print("Données de coordonnées invalides pour l'arrêt \(name_stop)")
                    return 48.8566 // Paris par défaut
                }
                
                // Si c'est Lambert93, convertir en WGS84
                if srsName == "EPSG:2154" {
                    if let wgs84Lat = convertLambert93ToWGS84Lat(x: x, y: y) {
                        return wgs84Lat
                    }
                } else {
                    // Si ce n'est pas Lambert93, supposer que c'est déjà WGS84
                    return y
                }
            }
        } catch {
            print("Erreur lors du parsing des données de localisation: \(error)")
        }
        
        return 48.8566 // Paris par défaut
    }

    var longitude: Double {
        guard let locationStr = ns2_location else {
            print("Aucune donnée de localisation pour l'arrêt \(name_stop)")
            return 2.3522 // Paris par défaut
        }
        
        // Analyser les données JSON
        do {
            if let data = locationStr.data(using: .utf8),
               let locationData = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                
                // Vérifier le système de coordonnées
                let srsName = locationData["@srsName"] as? String
                
                // Extraire les valeurs de longitude et latitude
                guard let longString = locationData["ns2:Longitude"] as? String,
                      let latString = locationData["ns2:Latitude"] as? String,
                      let x = Double(longString),
                      let y = Double(latString) else {
                    print("Données de coordonnées invalides pour l'arrêt \(name_stop)")
                    return 2.3522 // Paris par défaut
                }
                
                // Si c'est Lambert93, convertir en WGS84
                if srsName == "EPSG:2154" {
                    if let wgs84Long = convertLambert93ToWGS84Long(x: x, y: y) {
                        return wgs84Long
                    }
                } else {
                    // Si ce n'est pas Lambert93, supposer que c'est déjà WGS84
                    return x
                }
            }
        } catch {
            print("Erreur lors du parsing des données de localisation: \(error)")
        }
        
        return 2.3522 // Paris par défaut
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
        // Paramètres de l'ellipsoïde GRS80
        let a = 6378137.0        // Demi-grand axe (m)
        let f = 1.0 / 298.257222101 // Aplatissement
        let e = sqrt(2*f - f*f)  // Première excentricité
        
        // Paramètres de la projection Lambert 93
        let lambda0 = 3.0 * .pi / 180.0  // Méridien central (3° Est)
        let phi0 = 46.5 * .pi / 180.0    // Latitude d'origine (46.5° Nord)
        let phi1 = 44.0 * .pi / 180.0    // 1er parallèle automécoïque
        let phi2 = 49.0 * .pi / 180.0    // 2ème parallèle automécoïque
        let x0 = 700000.0        // Décalage en X (m)
        let y0 = 6600000.0       // Décalage en Y (m)
        
        // Calcul des constantes de la projection
        let m1 = cos(phi1) / sqrt(1.0 - e*e * sin(phi1)*sin(phi1))
        let m2 = cos(phi2) / sqrt(1.0 - e*e * sin(phi2)*sin(phi2))
        let t0 = tan(.pi/4.0 - phi0/2.0) / pow((1.0 - e*sin(phi0))/(1.0 + e*sin(phi0)), e/2.0)
        let t1 = tan(.pi/4.0 - phi1/2.0) / pow((1.0 - e*sin(phi1))/(1.0 + e*sin(phi1)), e/2.0)
        let t2 = tan(.pi/4.0 - phi2/2.0) / pow((1.0 - e*sin(phi2))/(1.0 + e*sin(phi2)), e/2.0)
        let n = log(m1/m2) / log(t1/t2)
        let c = m1 * pow(t1, n) / n
        let r0 = a * c * pow(t0, n)
        
        // Coordonnées Lambert93 centrées
        let X = x - x0
        let Y = y - y0
        
        // Coordonnées polaires
        let rho = sqrt(X*X + (r0-Y)*(r0-Y)) * (n >= 0 ? 1 : -1)
        let theta = atan(X / (r0 - Y))
        
        // Latitude en coordonnées géographiques
        let t = pow(rho/(a*c), 1.0/n)
        var phi = .pi/2.0 - 2.0 * atan(t) // Latitude approchée
        
        // Itérations pour améliorer la précision
        var phiPrev: Double
        for _ in 0..<10 {
            phiPrev = phi
            phi = .pi/2.0 - 2.0 * atan(t * pow((1.0 - e*sin(phi))/(1.0 + e*sin(phi)), e/2.0))
            if abs(phi - phiPrev) < 1e-11 {
                break
            }
        }
        
        // Conversion en degrés
        return phi * 180.0 / .pi
    }

    private func convertLambert93ToWGS84Long(x: Double, y: Double) -> Double? {
        // Paramètres de l'ellipsoïde GRS80
        let a = 6378137.0        // Demi-grand axe (m)
        let f = 1.0 / 298.257222101 // Aplatissement
        let e = sqrt(2*f - f*f)  // Première excentricité
        
        // Paramètres de la projection Lambert 93
        let lambda0 = 3.0 * .pi / 180.0  // Méridien central (3° Est)
        let phi0 = 46.5 * .pi / 180.0    // Latitude d'origine (46.5° Nord)
        let phi1 = 44.0 * .pi / 180.0    // 1er parallèle automécoïque
        let phi2 = 49.0 * .pi / 180.0    // 2ème parallèle automécoïque
        let x0 = 700000.0        // Décalage en X (m)
        let y0 = 6600000.0       // Décalage en Y (m)
        
        // Calcul des constantes de la projection
        let m1 = cos(phi1) / sqrt(1.0 - e*e * sin(phi1)*sin(phi1))
        let m2 = cos(phi2) / sqrt(1.0 - e*e * sin(phi2)*sin(phi2))
        let t0 = tan(.pi/4.0 - phi0/2.0) / pow((1.0 - e*sin(phi0))/(1.0 + e*sin(phi0)), e/2.0)
        let t1 = tan(.pi/4.0 - phi1/2.0) / pow((1.0 - e*sin(phi1))/(1.0 + e*sin(phi1)), e/2.0)
        let t2 = tan(.pi/4.0 - phi2/2.0) / pow((1.0 - e*sin(phi2))/(1.0 + e*sin(phi2)), e/2.0)
        let n = log(m1/m2) / log(t1/t2)
        let c = m1 * pow(t1, n) / n
        let r0 = a * c * pow(t0, n)
        
        // Coordonnées Lambert93 centrées
        let X = x - x0
        let Y = y - y0
        
        // Coordonnées polaires
        let theta = atan(X / (r0 - Y))
        
        // Longitude en coordonnées géographiques
        let lambda = theta/n + lambda0
        
        // Conversion en degrés
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
