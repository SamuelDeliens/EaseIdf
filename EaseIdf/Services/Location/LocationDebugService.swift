//
//  LocationDebugService.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 16/04/2025.
//

import Foundation
import CoreLocation

class LocationDebugService {
    static let shared = LocationDebugService()
    
    private init() {}
    
    func debugLocationStatus() -> String {
        var debugInfo = ""
        
        // Vérifier si les services de localisation sont activés
        let locationServicesEnabled = CLLocationManager.locationServicesEnabled()
        debugInfo += "Services de localisation activés: \(locationServicesEnabled)\n"
        
        // Vérifier le statut d'autorisation
        let authStatus = LocationService.shared.authorizationStatus
        debugInfo += "Statut d'autorisation: \(authorizationStatusString(authStatus))\n"
        
        // Vérifier si une position actuelle est disponible
        if let currentLocation = LocationService.shared.currentLocation {
            debugInfo += "Position actuelle disponible: Oui\n"
            debugInfo += "Latitude: \(currentLocation.coordinate.latitude)\n"
            debugInfo += "Longitude: \(currentLocation.coordinate.longitude)\n"
            debugInfo += "Précision: \(currentLocation.horizontalAccuracy) mètres\n"
            debugInfo += "Timestamp: \(currentLocation.timestamp)\n"
        } else {
            debugInfo += "Position actuelle disponible: Non\n"
        }
        
        // Vérifier s'il y a des erreurs de localisation
        if let locationError = LocationService.shared.locationError {
            debugInfo += "Erreur de localisation: \(locationError.localizedDescription)\n"
        }
        
        return debugInfo
    }
    
    func fixLocationConditions() {
        // Tenter de récupérer tous les favoris avec des conditions de position
        let allFavorites = PersistenceService.shared.getAllFavorites()
        var updated = false
        
        for favorite in allFavorites {
            // Vérifier les conditions de localisation avec coordonnées à (0,0)
            for (index, condition) in favorite.displayConditions.enumerated() {
                if condition.type == .location,
                   let locationCondition = condition.locationCondition,
                   locationCondition.coordinates.latitude == 0.0 && 
                   locationCondition.coordinates.longitude == 0.0 {
                    
                    // Cette condition a des coordonnées à (0,0), tentons de la corriger
                    if let currentLocation = LocationService.shared.currentLocation {
                        // Créer une copie modifiable
                        var modifiedFavorite = favorite
                        var modifiedCondition = condition
                        
                        // Remplacer les coordonnées par la position actuelle
                        let newCoordinates = Coordinates(
                            latitude: currentLocation.coordinate.latitude,
                            longitude: currentLocation.coordinate.longitude
                        )
                        
                        let newLocationCondition = LocationCondition(
                            coordinates: newCoordinates,
                            radius: locationCondition.radius
                        )
                        
                        modifiedCondition.locationCondition = newLocationCondition
                        modifiedFavorite.displayConditions[index] = modifiedCondition
                        
                        // Sauvegarder les modifications
                        StorageService.shared.saveFavorite(modifiedFavorite)
                        updated = true
                    }
                }
            }
        }
        
        if updated {
            print("Des conditions de localisation ont été mises à jour avec des coordonnées valides")
        } else {
            print("Aucune condition de localisation à corriger n'a été trouvée")
        }
    }
    
    private func authorizationStatusString(_ status: CLAuthorizationStatus) -> String {
        switch status {
        case .notDetermined:
            return "Non déterminé"
        case .restricted:
            return "Restreint"
        case .denied:
            return "Refusé"
        case .authorizedWhenInUse:
            return "Autorisé en utilisation"
        case .authorizedAlways:
            return "Toujours autorisé"
        @unknown default:
            return "Inconnu"
        }
    }
}
