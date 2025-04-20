//
//  TransportService.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 20/04/2025.
//


import Foundation
import SwiftData
import Combine

/// Service centralisant toutes les opérations liées aux données de transport
class TransportService {
    // MARK: - Propriétés
    
    // Conteneur de modèle pour les données de transport
    private var modelContainer: ModelContainer?
    private var modelContext: ModelContext?
    
    // Statut de chargement
    @Published private(set) var isLoadingLines = false
    @Published private(set) var isLoadingStops = false
    
    // MARK: - Initialisation
    
    init() {
        initializeModelContainer()
    }
    
    /// Initialiser le conteneur de modèle SwiftData
    func initializeModelContainer() {
        if modelContainer == nil {
            modelContainer = DataPersistenceService.shared.getTransportDataContainer()
            modelContext = ModelContext(modelContainer!)
        }
    }
    
    // MARK: - Méthodes publiques pour les lignes
    
    /// Charger les lignes depuis un fichier JSON local
    func loadLinesFromFile(named filename: String) async -> Bool {
        guard let modelContext = modelContext else {
            print("Erreur: ModelContext n'est pas initialisé")
            return false
        }
        
        self.isLoadingLines = true
        
        do {
            // Charger les lignes depuis le fichier JSON
            let lines = try await loadLinesFromJSONFile(named: filename)
            print("Lignes chargées depuis le fichier: \(lines.count)")
            
            // Passer au thread principal pour interagir avec SwiftData
            await MainActor.run {
                do {
                    // Effacer d'abord les données existantes
                    let descriptor = FetchDescriptor<TransportLineModel>()
                    if let existingLines = try? modelContext.fetch(descriptor) {
                        for line in existingLines {
                            modelContext.delete(line)
                        }
                    }
                    
                    // Ajouter les nouvelles données par lots
                    let batchSize = 100
                    for i in stride(from: 0, to: lines.count, by: batchSize) {
                        let end = min(i + batchSize, lines.count)
                        let batch = Array(lines[i..<end])
                        
                        for line in batch {
                            let lineModel = TransportLineModel.fromImportedLine(line)
                            modelContext.insert(lineModel)
                        }
                        
                        try modelContext.save()
                    }
                    
                    self.isLoadingLines = false
                    
                    return true
                } catch {
                    print("Erreur lors de l'enregistrement des lignes: \(error)")
                    self.isLoadingLines = false
                    return false
                }
            }
            
            return true
        } catch {
            print("Erreur lors du chargement des lignes depuis JSON: \(error)")
            await MainActor.run {
                self.isLoadingLines = false
            }
            return false
        }
    }
    
    /// Charger le contenu du fichier JSON
    private func loadLinesFromJSONFile(named filename: String) async throws -> [ImportedLine] {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
            throw NSError(domain: "FileNotFound", code: 404, userInfo: [NSLocalizedDescriptionKey: "File \(filename).json not found"])
        }
        
        let data = try Data(contentsOf: url)
        
        // Si le JSON commence par un tableau, nous pouvons le décoder directement
        let decoder = JSONDecoder()
        
        do {
            // Essayons d'abord de décoder comme un tableau d'ImportedLine
            return try decoder.decode([ImportedLine].self, from: data)
        } catch {
            print("Direct decoding failed: \(error)")
            
            // Si ça échoue, essayons d'examiner la structure du JSON
            if let json = try? JSONSerialization.jsonObject(with: data, options: []) {
                print("JSON structure: \(type(of: json))")
                
                // Selon la structure réelle, nous pouvons adapter notre approche
                if let recordsDict = json as? [String: Any], let records = recordsDict["records"] as? [[String: Any]] {
                    // Structure comme { "records": [ {...}, {...} ] }
                    let recordsData = try JSONSerialization.data(withJSONObject: records, options: [])
                    let recordsArray = try decoder.decode([Record].self, from: recordsData)
                    return recordsArray.compactMap { $0.fields }
                }
            }
            
            // Si nous n'avons pas pu traiter la structure, relance l'erreur
            throw error
        }
    }
    
    struct Record: Codable {
        let fields: ImportedLine
    }
    
    /// Obtenir toutes les lignes
    func getAllLines() -> [ImportedLine] {
        guard let modelContext = modelContext else {
            print("Erreur: ModelContext n'est pas initialisé")
            return []
        }
        
        do {
            let descriptor = FetchDescriptor<TransportLineModel>()
            let lineModels = try modelContext.fetch(descriptor)
            
            // Convertir les modèles SwiftData en ImportedLine pour la compatibilité
            return lineModels.map { $0.toImportedLine() }
        } catch {
            print("Erreur lors de la récupération des lignes: \(error)")
            return []
        }
    }
    
    /// Rechercher des lignes par requête et mode
    func searchLines(query: String, mode: TransportMode? = nil) -> [ImportedLine] {
        guard let modelContext = modelContext else {
            print("Erreur: ModelContext n'est pas initialisé")
            return []
        }
        
        do {
            let allLines = try DataPersistenceService.shared.fetchAllLines(context: modelContext)
            
            // Filtrer en mémoire (plus sûr que les prédicats complexes)
            return allLines.filter { line in
                // Filtrer par mode si spécifié
                let modeMatch = mode == nil || line.transportMode == mode?.rawValue
                
                // Si la requête est vide, filtrer uniquement par mode
                if query.isEmpty {
                    return modeMatch
                }
                
                // Sinon, filtrer par requête et mode
                let lowercasedQuery = query.lowercased()
                let contentMatch = line.name.lowercased().contains(lowercasedQuery) ||
                                   line.shortName.lowercased().contains(lowercasedQuery) ||
                                   line.id.lowercased().contains(lowercasedQuery) ||
                                   (line.privateCode?.lowercased().contains(lowercasedQuery) ?? false) ||
                                   line.operatorName.lowercased().contains(lowercasedQuery) ||
                                   (line.shortGroupName?.lowercased().contains(lowercasedQuery) ?? false)
                
                return modeMatch && contentMatch
            }.map { $0.toImportedLine() }
        } catch {
            print("Erreur lors de la recherche de lignes: \(error)")
            return []
        }
    }
    
    /// Obtenir les directions pour une ligne
    func getDirectionsForLine(lineId: String) -> [LineDirection] {
        guard let modelContext = modelContext else {
            print("Erreur: ModelContext n'est pas initialisé")
            return []
        }
        
        do {
            let predicate = #Predicate<TransportLineModel> { line in
                line.id == lineId
            }
            
            let descriptor = FetchDescriptor<TransportLineModel>(predicate: predicate)
            let lines = try modelContext.fetch(descriptor)
            
            guard let line = lines.first, let groupName = line.shortGroupName else {
                return []
            }
            
            // La plupart des lignes ont des directions au format "ORIGINE - DESTINATION"
            let parts = groupName.split(separator: "-")
            
            if parts.count >= 2 {
                return parts.map { direction in
                    LineDirection(
                        lineName: line.shortName,
                        direction: direction.trimmingCharacters(in: .whitespacesAndNewlines),
                        lineId: line.id,
                        color: line.color,
                        textColor: line.textColor,
                        transportMode: TransportMode(rawValue: line.transportMode) ?? .other
                    )
                }
            } else {
                // Si nous ne pouvons pas découper par tiret, utiliser tout le nom de groupe comme une direction
                return [
                    LineDirection(
                        lineName: line.shortName,
                        direction: groupName.trimmingCharacters(in: .whitespacesAndNewlines),
                        lineId: line.id,
                        color: line.color,
                        textColor: line.textColor,
                        transportMode: TransportMode(rawValue: line.transportMode) ?? .other
                    )
                ]
            }
        } catch {
            print("Erreur lors de la récupération des directions pour la ligne: \(error)")
            return []
        }
    }
    
    // MARK: - Méthodes publiques pour les arrêts
    
    /// Charger les arrêts depuis un fichier JSON local
    func loadStopsFromFile(named filename: String) async -> Bool {
        self.isLoadingStops = true
        
        // S'assurer que le contexte SwiftData est initialisé
        initializeModelContainer()
        
        guard let modelContext = modelContext else {
            print("Erreur: ModelContext n'est pas initialisé")
            isLoadingStops = false
            return false
        }
        
        do {
            guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
                print("Erreur: Fichier \(filename).json introuvable")
                await MainActor.run {
                    self.isLoadingStops = false
                }
                return false
            }
            
            let data = try Data(contentsOf: url)
            
            // Convertir les données en String pour correction
            if let jsonString = String(data: data, encoding: .utf8) {
                let correctedString = jsonString.correctingEncoding()
                
                // Reconvertir la chaîne corrigée en Data
                if let correctedData = correctedString.data(using: .utf8) {
                    // Utiliser un décodeur standard
                    let decoder = JSONDecoder()
                    
                    let stops = try decoder.decode([ImportedStop].self, from: correctedData)
                    print("Arrêts chargés depuis le fichier: \(stops.count)")
                    
                    // Sauvegarder dans SwiftData sur le thread principal
                    await MainActor.run {
                        // Effacer d'abord les données existantes
                        let clearDescriptor = FetchDescriptor<TransportStopModel>()
                        if let existingStops = try? modelContext.fetch(clearDescriptor) {
                            for stop in existingStops {
                                modelContext.delete(stop)
                            }
                        }
                        
                        // Ajouter les nouvelles données par lots
                        let batchSize = 200
                        for i in stride(from: 0, to: stops.count, by: batchSize) {
                            let end = min(i + batchSize, stops.count)
                            let batch = stops[i..<end]
                            
                            for stop in batch {
                                let stopModel = TransportStopModel.fromImportedStop(stop)
                                modelContext.insert(stopModel)
                            }
                            
                            try? modelContext.save()
                        }
                        
                        self.isLoadingStops = false
                    }
                    
                    return true
                }
            }
            
            await MainActor.run {
                self.isLoadingStops = false
            }
            return false
            
        } catch {
            print("Erreur lors du chargement des arrêts: \(error)")
            await MainActor.run {
                self.isLoadingStops = false
            }
            return false
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
                    ns2_lines: nil,
                    ns2_location: nil,
                    calculed_latitude: stopModel.latitude,
                    calculed_longitude: stopModel.longitude
                )
            }
        } catch {
            print("Erreur lors de la récupération des arrêts: \(error)")
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
    
    // MARK: - Méthodes pour récupérer les prochains départs
    
    /// Récupérer les prochains départs pour un arrêt et une ligne
    func fetchDepartures(for stopId: String, lineId: String?) async throws -> [Departure] {
        // En mode de développement, on peut utiliser des données simulées
        #if DEBUG
        if AppEnvironment.useSimulatedData {
            // Créer un favori temporaire pour la simulation
            let tempFavorite = TransportFavorite(
                id: UUID(),
                stopId: stopId,
                lineId: lineId,
                displayName: "Simulation",
                displayConditions: [],
                priority: 0
            )
            
            return DepartureSimulationService.shared.generateSimulatedDepartures(for: tempFavorite)
        }
        #endif
        
        // Sinon, appeler l'API réelle
        return try await IDFMobiliteService.shared.fetchDepartures(
            for: stopId,
            lineId: lineId
        )
    }
    
    // MARK: - Utilitaires pour les statuts de chargement
    
    var isLoading: Bool {
        return isLoadingLines || isLoadingStops
    }
}
