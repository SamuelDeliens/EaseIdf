//
//  ImportedStop.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 15/04/2025.
//

import Foundation

struct ImportedStop: Codable, Identifiable {
    var id: String { id_stop }
    
    let line: String
    let name_line: String?
    let ns2_stoppointref: String
    let ns2_stopname: String?
    let ns2_lines: String?
    let ns2_location: String?
    
    let calculed_latitude: Double?
    let calculed_longitude: Double?
    
    // Propriété pour suivre si le décodage a réussi
    let locationParsingSucceeded: Bool
    
    // Variable stockée pour rawLocationData, initialisée lors de la construction
    let rawLocationData: [String: Any]?
    
    // Clés de codage pour la localisation
    enum LocationKeys: String, CodingKey {
        case longitude = "ns2:Longitude"
        case latitude = "ns2:Latitude"
        case srsName = "@srsName"
    }
    
    private enum CodingKeys: String, Swift.CodingKey {
        case line
        case name_line
        case ns2_stoppointref
        case ns2_stopname
        case ns2_lines
        case ns2_location
    }
    
    // MARK: - Initialiseurs
    
    // Décodeur personnalisé
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        line = try container.decode(String.self, forKey: .line)
        name_line = try container.decodeIfPresent(String.self, forKey: .name_line)
        ns2_stoppointref = try container.decode(String.self, forKey: .ns2_stoppointref)
        ns2_stopname = try container.decodeIfPresent(String.self, forKey: .ns2_stopname)
        ns2_lines = try container.decodeIfPresent(String.self, forKey: .ns2_lines)
        ns2_location = try container.decodeIfPresent(String.self, forKey: .ns2_location)
        
        calculed_latitude = nil
        calculed_longitude = nil
        
        // Initialiser rawLocationData
        if let locationStr = ns2_location {
            do {
                if let data = locationStr.data(using: .utf8),
                   let jsonObj = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    self.rawLocationData = jsonObj
                    self.locationParsingSucceeded = true
                } else {
                    self.rawLocationData = nil
                    self.locationParsingSucceeded = false
                }
            } catch {
                print("Erreur lors du parsing de location pour \(ns2_stopname ?? "arrêt inconnu"): \(error)")
                self.rawLocationData = nil
                self.locationParsingSucceeded = false
            }
        } else {
            self.rawLocationData = nil
            self.locationParsingSucceeded = false
        }
    }
    
    // Constructeur standard
    init(line: String, name_line: String?, ns2_stoppointref: String, ns2_stopname: String?, ns2_lines: String?, ns2_location: String?, calculed_latitude: Double?, calculed_longitude: Double?) {
        self.line = line
        self.name_line = name_line
        self.ns2_stoppointref = ns2_stoppointref
        self.ns2_stopname = ns2_stopname
        self.ns2_lines = ns2_lines
        self.ns2_location = ns2_location
        
        self.calculed_latitude = calculed_latitude
        self.calculed_longitude = calculed_longitude
        
        // Initialiser rawLocationData
        if let locationStr = ns2_location {
            do {
                if let data = locationStr.data(using: .utf8),
                   let jsonObj = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    self.rawLocationData = jsonObj
                    self.locationParsingSucceeded = true
                } else {
                    self.rawLocationData = nil
                    self.locationParsingSucceeded = false
                }
            } catch {
                print("Erreur lors du parsing de location pour \(ns2_stopname ?? "arrêt inconnu"): \(error)")
                self.rawLocationData = nil
                self.locationParsingSucceeded = false
            }
        } else {
            self.rawLocationData = nil
            self.locationParsingSucceeded = false
        }
    }
    
    // MARK: - Propriétés dérivées
    
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
        if let calculated = calculed_latitude {
            return calculated
        }
        
        if let locationData = rawLocationData {
            return getLatitude(from: locationData)
        }
        
        return 48.8566 // fallback = Paris
    }

    var longitude: Double {
        if let calculated = calculed_longitude {
            return calculated
        }
        
        if let locationData = rawLocationData {
            return getLongitude(from: locationData)
        }
        
        return 2.3522 // Paris par défaut
    }
    
    // MARK: - Fonctions d'extraction de coordonnées
    
    private func getLatitude(from locationData: [String: Any]) -> Double {
        let srsName = locationData["@srsName"] as? String
        
        if let latString = locationData["ns2:Latitude"] as? String,
           let latValue = Double(latString) {
            
            // Si c'est Lambert93, convertir en WGS84
            if srsName == "EPSG:2154" {
                if let longString = locationData["ns2:Longitude"] as? String,
                   let longValue = Double(longString),
                   let wgs84Lat = convertLambert93ToWGS84(x: latValue, y: longValue).lat {
                    return wgs84Lat
                }
            } else {
                return latValue
            }
        }

        return 48.8566 // Paris par défaut
    }
    
    private func getLongitude(from locationData: [String: Any]) -> Double {
        let srsName = locationData["@srsName"] as? String
        
        if let longString = locationData["ns2:Longitude"] as? String,
           let longValue = Double(longString) {
            
            // Si c'est Lambert93, convertir en WGS84
            if srsName == "EPSG:2154" {
                if let latString = locationData["ns2:Latitude"] as? String,
                   let latValue = Double(latString),
                   let wgs84Long = convertLambert93ToWGS84(x: latValue, y: longValue).lon {
                    return wgs84Long
                }
            } else {
                // Si ce n'est pas Lambert93, supposer que c'est déjà WGS84
                return longValue
            }
        }
        
        return 2.3522 // Paris par défaut
    }
    
    var lines_refs: [String]? {
        guard let linesStr = ns2_lines else {
            return [line]
        }
        
        do {
            if let data = linesStr.data(using: .utf8),
               let linesData = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                
                if let lineRefs = linesData["ns2:LineRef"] as? [String] {
                    return lineRefs
                } else if let lineRef = linesData["ns2:LineRef"] as? String {
                    return [lineRef]
                }
            }
        } catch {
            print("Erreur lors de l'extraction des lignes: \(error)")
        }
        return [line]
    }
    
    // MARK: - Méthodes de conversion Lambert93 vers WGS84
    
    func convertLambert93ToWGS84(x: Double, y: Double) -> (lat: Double?, lon: Double?) {
        let GRS80E = 0.081819191042816
        let n = 0.7256077650532670
        let C = 11754255.4261
        let XS = 700000.0
        let YS = 12655612.0499
        let lonMeridien = 3 * Double.pi / 180

        let R = sqrt(pow((x - XS), 2) + pow((y - YS), 2))
        let gamma = atan((x - XS) / (YS - y))
        let latiso = log(C / R) / n
        var phi = 2 * atan(exp(latiso)) - Double.pi / 2

        for _ in 0..<6 {
            phi = 2 * atan(pow((1 + GRS80E * sin(phi)) / (1 - GRS80E * sin(phi)), GRS80E / 2) * exp(latiso)) - Double.pi / 2
        }

        let latitude = phi * 180 / Double.pi
        let longitude = (lonMeridien + gamma / n) * 180 / Double.pi

        return (lat: latitude, lon: longitude)
    }
    
    // MARK: - Méthodes utilitaires
    
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
    
    // MARK: - Méthodes de débogage
    
    func debugDescription() -> String {
        var debug = "ImportedStop: \(name_stop) (ID: \(id_stop))\n"
        debug += "  StopPointRef: \(ns2_stoppointref)\n"
        debug += "  Location parsing succeeded: \(locationParsingSucceeded)\n"
        
        if let locationStr = ns2_location {
            debug += "  Raw Location: \(locationStr)\n"
        } else {
            debug += "  Raw Location: nil\n"
        }
        
        debug += "  Parsed coordinates: (\(latitude), \(longitude))\n"
        
        if let rawData = rawLocationData {
            debug += "  Parsed location data: \(rawData)\n"
        }
        
        if let linesRefs = lines_refs {
            debug += "  Lines: \(linesRefs.joined(separator: ", "))\n"
        }
        
        return debug
    }
}
