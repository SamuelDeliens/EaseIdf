//
//  StopDataService.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 15/04/2025.
//


import Foundation
import Combine
import SwiftData

class StopDataService {
    static let shared = StopDataService()
    
    private init() {}
    
    // MARK: - Properties
    @Published private(set) var isLoading = false
    private var modelContainer: ModelContainer?
    private var modelContext: ModelContext?
    
    // MARK: - Public Methods
    
    /// Initialiser le conteneur de modèle SwiftData
    func initializeModelContainer() {
        if modelContainer == nil {
            modelContainer = DataPersistenceService.shared.getTransportDataContainer()
            modelContext = ModelContext(modelContainer!)
        }
    }
    
    /// Charger les arrêts depuis un fichier JSON local
    func loadStopsFromFile(named filename: String) {
        isLoading = true
        
        // S'assurer que le contexte SwiftData est initialisé
        initializeModelContainer()
        
        guard let modelContext = modelContext else {
            print("Erreur: ModelContext n'est pas initialisé")
            isLoading = false
            return
        }
        
        Task {
            do {
                guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
                    print("Erreur: Fichier \(filename).json introuvable")
                    await MainActor.run {
                        self.isLoading = false
                    }
                    return
                }
                
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                
                // Décodage direct en tant que tableau d'ImportedStop
                let stops = try decoder.decode([ImportedStop].self, from: data)
                print("stops data counted", stops.count)
                
                // Sauvegarder dans SwiftData sur le thread principal
                await MainActor.run {
                    // Effacer d'abord les données existantes
                    let clearDescriptor = FetchDescriptor<TransportStopModel>()
                    if let existingStops = try? modelContext.fetch(clearDescriptor) {
                        for stop in existingStops {
                            modelContext.delete(stop)
                        }
                    }
                    
                    // Ajouter les nouvelles données
                    let batchSize = 200
                    for i in stride(from: 0, to: stops.count, by: batchSize) {
                        let end = min(i + batchSize, stops.count)
                        let batch = stops[i..<end]
                        
                        for stop in batch {
                            let stopModel = TransportStopModel.fromImportedStop(stop)
                            modelContext.insert(stopModel)
                        }
                    }
                    
                    try? modelContext.save()
                    self.isLoading = false
                }
            } catch {
                print("Erreur lors du chargement des arrêts: \(error)")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
    
    /// Obtenir tous les arrêts
    func getAllStops() -> [ImportedStop] {
        guard let modelContext = modelContext else {
            print("Erreur: ModelContext n'est pas initialisé")
            return []
        }
        
        do {
            let stopModels = try DataPersistenceService.shared.fetchAllStops(context: modelContext)
            
            // Convertir les modèles SwiftData en ImportedStop pour la compatibilité
            return stopModels.compactMap { stopModel in
                return ImportedStop(
                    line: stopModel.lineRefs.first ?? "",
                    name_line: nil,
                    ns2_stoppointref: "STIF:StopPoint:Q:\(stopModel.id):",
                    ns2_stopname: stopModel.name,
                    ns2_lines: nil, // Simplification - adapter selon les besoins
                    ns2_location: nil, // Simplification - adapter selon les besoins
                    calculed_latitude: stopModel.latitude,
                    calculed_longitude: stopModel.longitude
                )
            }
        } catch {
            print("Erreur lors de la récupération des arrêts: \(error)")
            return []
        }
    }
    
    /// Rechercher des arrêts par requête
    func searchStops(query: String, type: StopType? = nil) -> [ImportedStop] {
        guard let modelContext = modelContext else {
            print("Erreur: ModelContext n'est pas initialisé")
            return []
        }
        
        do {
            let stopModels: [TransportStopModel]
            
            if query.isEmpty {
                if let type = type {
                    // Filtrer par type spécifique
                    let predicate = #Predicate<TransportStopModel> { stop in
                        stop.type == type.rawValue
                    }
                    let descriptor = FetchDescriptor<TransportStopModel>(predicate: predicate)
                    stopModels = try modelContext.fetch(descriptor)
                } else {
                    // Récupérer tous les arrêts
                    stopModels = try DataPersistenceService.shared.fetchAllStops(context: modelContext)
                }
            } else {
                // Recherche avec query
                stopModels = try DataPersistenceService.shared.searchStops(query: query, context: modelContext)
                
                // Filtrer par type si nécessaire
                if let type = type {
                    return stopModels
                        .filter { $0.type == type.rawValue }
                        .compactMap { stopModel in
                            return ImportedStop(
                                line: stopModel.lineRefs.first ?? "",
                                name_line: nil,
                                ns2_stoppointref: "STIF:StopPoint:Q:\(stopModel.id):",
                                ns2_stopname: stopModel.name,
                                ns2_lines: nil,
                                ns2_location: nil,
                                calculed_latitude: stopModel.latitude,
                                calculed_longitude: stopModel.longitude
                            )
                        }
                }
            }
            
            // Convertir les modèles SwiftData en ImportedStop pour la compatibilité
            return stopModels.compactMap { stopModel in
                return ImportedStop(
                    line: stopModel.lineRefs.first ?? "",
                    name_line: nil,
                    ns2_stoppointref: "STIF:StopPoint:Q:\(stopModel.id):",
                    ns2_stopname: stopModel.name,
                    ns2_lines: nil,
                    ns2_location: nil,
                    calculed_latitude: stopModel.latitude,
                    calculed_longitude: stopModel.longitude
                )
            }
        } catch {
            print("Erreur lors de la recherche d'arrêts: \(error)")
            return []
        }
    }
    
    /// Obtenir les arrêts pour une ligne spécifique
    func getStopsForLine(lineId: String) -> [ImportedStop] {
        guard let modelContext = modelContext else {
            print("Erreur: ModelContext n'est pas initialisé")
            return []
        }
        
        do {
            let stopModels = try DataPersistenceService.shared.fetchStopsForLine(lineId: lineId, context: modelContext)
            
            // Convertir les modèles SwiftData en ImportedStop pour la compatibilité
            return stopModels.compactMap { stopModel in
                return ImportedStop(
                    line: lineId,
                    name_line: nil,
                    ns2_stoppointref: "STIF:StopPoint:Q:\(stopModel.id):",
                    ns2_stopname: stopModel.name,
                    ns2_lines: nil,
                    ns2_location: nil,
                    calculed_latitude: stopModel.latitude,
                    calculed_longitude: stopModel.longitude
                )
            }
        } catch {
            print("Erreur lors de la récupération des arrêts pour la ligne: \(error)")
            return []
        }
    }
}
