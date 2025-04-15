//
//  LineDataService.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 14/04/2025.
//


import Foundation
import Combine
import SwiftData

class LineDataService {
    static let shared = LineDataService()
    
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
    
    /// Charger les lignes depuis un fichier JSON local
    func loadLinesFromFile(named filename: String) {
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
                // Charger les lignes depuis le fichier JSON
                let lines = try await loadLinesFromJSONFile(named: filename)
                print("line data counted", lines.count)
                
                // Passer au thread principal pour interagir avec SwiftData
                await MainActor.run {
                    do {
                        // Version synchrone de clearLines
                        let descriptor = FetchDescriptor<TransportLineModel>()
                        if let existingLines = try? modelContext.fetch(descriptor) {
                            for line in existingLines {
                                modelContext.delete(line)
                            }
                        }
                        
                        // Ajouter les lignes par lots
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
                        
                        self.isLoading = false
                    } catch {
                        print("Erreur lors de l'enregistrement des lignes: \(error)")
                        self.isLoading = false
                    }
                }
            } catch {
                print("Erreur lors du chargement des lignes depuis JSON: \(error)")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
    
    func loadLinesFromJSONFile(named filename: String) async throws -> [ImportedLine] {
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
            let lineModels = try DataPersistenceService.shared.fetchAllLines(context: modelContext)
            
            // Convertir les modèles SwiftData en ImportedLine pour la compatibilité
            return lineModels.map { $0.toImportedLine() }
        } catch {
            print("Erreur lors de la récupération des lignes: \(error)")
            return []
        }
    }
    
    /// Get directions for a line based on shortname_groupoflines
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
            
            // Most lines have directions in format "ORIGIN - DESTINATION"
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
                // If we can't split by dash, just use the whole group name as one direction
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
    
    /// Filter lines by transport mode
    func getLinesByMode(_ mode: TransportMode?) -> [ImportedLine] {
        guard let modelContext = modelContext else {
            print("Erreur: ModelContext n'est pas initialisé")
            return []
        }
        
        do {
            if let mode = mode {
                let lineModels = try DataPersistenceService.shared.fetchLinesByMode(mode: mode.rawValue, context: modelContext)
                return lineModels.map { $0.toImportedLine() }
            } else {
                let lineModels = try DataPersistenceService.shared.fetchAllLines(context: modelContext)
                return lineModels.map { $0.toImportedLine() }
            }
        } catch {
            print("Erreur lors de la récupération des lignes par mode: \(error)")
            return []
        }
    }
    
    /// Search lines by query
    func searchLines(query: String, mode: TransportMode? = nil) -> [ImportedLine] {
        guard let modelContext = modelContext else {
            print("Erreur: ModelContext n'est pas initialisé")
            return []
        }
        
        do {
            let lineModels = try DataPersistenceService.shared.searchLines(
                query: query,
                mode: mode?.rawValue,
                context: modelContext
            )
            
            return lineModels.map { $0.toImportedLine() }
        } catch {
            print("Erreur lors de la recherche de lignes: \(error)")
            return []
        }
    }
}
