//
//  StopDataService.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 15/04/2025.
//


import Foundation
import Combine

class StopDataService {
    static let shared = StopDataService()
    
    private init() {
        loadCachedData()
    }
    
    // MARK: - Properties
    
    @Published private(set) var importedStops: [ImportedStop] = []
    @Published private(set) var isLoading = false
    
    // MARK: - Public Methods
    
    /// Charger les arrêts depuis un fichier JSON local
    func loadStopsFromFile(named filename: String) {
        isLoading = true
        
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
            print("Erreur: Fichier \(filename).json introuvable dans le bundle")
            isLoading = false
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let stops = try JSONDecoder().decode([ImportedStop].self, from: data)
            self.importedStops = stops
            
            // Mettre en cache les données chargées
            cacheImportedStops(stops)
            
            // Convertir et mettre en cache en tant qu'objets TransportStop pour compatibilité
            let transportStops = stops.map { $0.toTransportStop() }
            StorageService.shared.cacheTransportStops(transportStops)
            
            isLoading = false
        } catch {
            print("Erreur lors du chargement des arrêts depuis JSON: \(error)")
            isLoading = false
        }
    }
    
    /// Charger les arrêts depuis une chaîne JSON
    func loadStopsFromJSONString(_ jsonString: String) {
        isLoading = true
        
        guard let data = jsonString.data(using: .utf8) else {
            print("Erreur: Impossible de convertir la chaîne JSON en données")
            isLoading = false
            return
        }
        
        do {
            let stops = try JSONDecoder().decode([ImportedStop].self, from: data)
            self.importedStops = stops
            
            // Mettre en cache les données chargées
            cacheImportedStops(stops)
            
            // Convertir et mettre en cache en tant qu'objets TransportStop pour compatibilité
            let transportStops = stops.map { $0.toTransportStop() }
            StorageService.shared.cacheTransportStops(transportStops)
            
            isLoading = false
        } catch {
            print("Erreur lors de l'analyse de la chaîne JSON: \(error)")
            isLoading = false
        }
    }
    
    /// Filtrer les arrêts par type d'arrêt
    func getStopsByType(_ type: StopType?) -> [ImportedStop] {
        if let type = type {
            return importedStops.filter { stop in
                let stopType = stop.getStopType()
                return stopType == type
            }
        } else {
            return importedStops
        }
    }
    
    /// Rechercher des arrêts par requête
    func searchStops(query: String, type: StopType? = nil) -> [ImportedStop] {
        let lowercasedQuery = query.lowercased()
        
        let filteredByType = getStopsByType(type)
        
        if query.isEmpty {
            return filteredByType
        }
        
        return filteredByType.filter { stop in
            stop.name_stop.lowercased().contains(lowercasedQuery) ||
            stop.id_stop.lowercased().contains(lowercasedQuery)
        }
    }
    
    /// Obtenir les arrêts pour une ligne spécifique
    func getStopsForLine(lineId: String) -> [ImportedStop] {
        return importedStops.filter { stop in
            stop.lines_refs?.contains(lineId) ?? false
        }
    }
    
    /// Obtenir les arrêts à proximité d'un emplacement
    func getStopsNearLocation(latitude: Double, longitude: Double, radiusInMeters: Double) -> [ImportedStop] {
        let location = Coordinates(latitude: latitude, longitude: longitude)
        
        return importedStops.filter { stop in
            let stopCoordinates = Coordinates(latitude: stop.latitude, longitude: stop.longitude)
            let distance = calculateDistance(from: location, to: stopCoordinates)
            return distance <= radiusInMeters
        }
    }
    
    // MARK: - Private Methods
    
    private func cacheImportedStops(_ stops: [ImportedStop]) {
        if let encoded = try? JSONEncoder().encode(stops) {
            UserDefaults.standard.set(encoded, forKey: "cachedImportedStops")
            UserDefaults.standard.set(Date(), forKey: "importedStopsLastUpdated")
        }
    }
    
    private func loadCachedData() {
        if let data = UserDefaults.standard.data(forKey: "cachedImportedStops"),
           let stops = try? JSONDecoder().decode([ImportedStop].self, from: data) {
            self.importedStops = stops
        }
    }
    
    /// Calculer la distance entre deux coordonnées en mètres
    private func calculateDistance(from point1: Coordinates, to point2: Coordinates) -> Double {
        let earthRadius = 6371000.0 // Rayon de la Terre en mètres
        
        let lat1 = point1.latitude * .pi / 180
        let lon1 = point1.longitude * .pi / 180
        let lat2 = point2.latitude * .pi / 180
        let lon2 = point2.longitude * .pi / 180
        
        let dLat = lat2 - lat1
        let dLon = lon2 - lon1
        
        let a = sin(dLat/2) * sin(dLat/2) + cos(lat1) * cos(lat2) * sin(dLon/2) * sin(dLon/2)
        let c = 2 * atan2(sqrt(a), sqrt(1-a))
        
        return earthRadius * c
    }
}
