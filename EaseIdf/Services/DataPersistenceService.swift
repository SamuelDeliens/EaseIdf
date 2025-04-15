//
//  DataPersistenceService.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 15/04/2025.
//

import Foundation
import SwiftData

class DataPersistenceService {
    static let shared = DataPersistenceService()
    
    private init() {}
    
    // Modèle container pour les données de transport
    func getTransportDataContainer() -> ModelContainer {
        let schema = Schema([
            TransportStopModel.self,
            TransportLineModel.self
        ])
        
        // Utiliser une configuration en mémoire pour débloquer le build
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true  // Temporairement en mémoire pour débloquer
        )
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer for transport data: \(error)")
        }
    }
    
    // Méthodes pour gérer les arrêts - version simplifiée
    func saveStops(_ stops: [ImportedStop], context: ModelContext) async throws {
        // Suppression des données existantes
        try await clearStops(context: context)
        
        // Réduire la taille du lot pour commencer
        let batchSize = 50
        for i in stride(from: 0, to: stops.count, by: batchSize) {
            let end = min(i + batchSize, stops.count)
            let batch = stops[i..<end]
            
            for stop in batch {
                let stopModel = TransportStopModel.fromImportedStop(stop)
                context.insert(stopModel)
            }
            
            try context.save()
        }
    }
    
    func clearStops(context: ModelContext) async throws {
        // Simplifier pour le débogage
        try? context.delete(model: TransportStopModel.self)
    }
    
    func fetchAllStops(context: ModelContext) throws -> [TransportStopModel] {
        let descriptor = FetchDescriptor<TransportStopModel>()
        return try context.fetch(descriptor)
    }
    
    // Simplifier la recherche pour lignes spécifiques
    func fetchStopsForLine(lineId: String, context: ModelContext) throws -> [TransportStopModel] {
        let allStops = try fetchAllStops(context: context)
        return allStops.filter { $0.lineRefs.contains("STIF:Line::\(lineId):") }
    }
    
    func searchStops(query: String, context: ModelContext) throws -> [TransportStopModel] {
        // Simplifier pour le débogage
        let descriptor = FetchDescriptor<TransportStopModel>()
        let stops = try context.fetch(descriptor)
        
        let lowercasedQuery = query.lowercased()
        return stops.filter {
            $0.name.lowercased().contains(lowercasedQuery) ||
            $0.id.lowercased().contains(lowercasedQuery)
        }
    }
    
    // Méthodes pour gérer les lignes - version simplifiée
    func saveLines(_ lines: [ImportedLine], context: ModelContext) async throws {
        try await clearLines(context: context)
        
        // Réduire la taille du lot
        let batchSize = 200
        for i in stride(from: 0, to: lines.count, by: batchSize) {
            let end = min(i + batchSize, lines.count)
            let batch = lines[i..<end]
            
            for line in batch {
                let lineModel = TransportLineModel.fromImportedLine(line)
                context.insert(lineModel)
            }
            
            try context.save()
        }
    }
    
    func clearLines(context: ModelContext) async throws {
        // Simplifier pour le débogage
        try? context.delete(model: TransportLineModel.self)
    }
    
    func fetchAllLines(context: ModelContext) throws -> [TransportLineModel] {
        let descriptor = FetchDescriptor<TransportLineModel>()
        return try context.fetch(descriptor)
    }
    
    // Simplifier toutes les méthodes de recherche pour éviter les problèmes de prédicat
    func fetchLinesByMode(mode: String, context: ModelContext) throws -> [TransportLineModel] {
        let lines = try fetchAllLines(context: context)
        return lines.filter { $0.transportMode == mode }
    }
    
    func searchLines(query: String, mode: String?, context: ModelContext) throws -> [TransportLineModel] {
        let lines = try fetchAllLines(context: context)
        let lowercasedQuery = query.lowercased()
                        
        return lines.filter { line in
            let modeMatch = mode == nil || line.transportMode == mode
            
            let contentMatch =
                lowercasedQuery == "" ||
                line.name.lowercased().contains(lowercasedQuery) ||
                line.shortName.lowercased().contains(lowercasedQuery) ||
                line.id.lowercased().contains(lowercasedQuery) ||
                (line.privateCode?.lowercased().contains(lowercasedQuery) ?? false) ||
                line.operatorName.lowercased().contains(lowercasedQuery) ||
                (line.shortGroupName?.lowercased().contains(lowercasedQuery) ?? false)
                        
            return modeMatch && contentMatch
        }
    }
}
