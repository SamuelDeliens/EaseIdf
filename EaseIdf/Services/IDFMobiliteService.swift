//
//  IDFMobiliteService.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 14/04/2025.
//

import Foundation
import Combine

enum IDFMobiliteError: Error {
    case invalidURL
    case invalidResponse
    case decodingError
    case networkError(Error)
    case apiError(String)
    case noApiKey
}

class IDFMobiliteService {
    // Singleton pattern
    static let shared = IDFMobiliteService()
    
    private init() {}
    
    // Base URLs
    private let baseURL = "https://prim.iledefrance-mobilites.fr/marketplace"
    private let stopMonitoringEndpoint = "/stop-monitoring"
    private let referentialStopsURL = "/icar/getData"
    private let referentialLinesURL = "/ilico/getData"
    
    private var apiKey: String? {
        return UserDefaults.standard.string(forKey: "IDFMobilite_ApiKey")
    }
    
    // MARK: - Public methods
    
    /// Fetch upcoming departures for a specific stop
    func fetchDepartures(for stopId: String, lineId: String? = nil) async throws -> [Departure] {
        guard let apiKey = apiKey else {
            throw IDFMobiliteError.noApiKey
        }
        
        var urlComponents = URLComponents(string: baseURL + stopMonitoringEndpoint)
        var queryItems = [
            URLQueryItem(name: "MonitoringRef", value: "STIF:StopPoint:Q:\(stopId):")
        ]
        
        if let lineId = lineId {
            queryItems.append(URLQueryItem(name: "LineRef", value: "STIF:Line::\(lineId):"))
        }
        
        urlComponents?.queryItems = queryItems
        
        guard let url = urlComponents?.url else {
            throw IDFMobiliteError.invalidURL
        }
                
        var request = URLRequest(url: url)
        request.addValue(apiKey, forHTTPHeaderField: "apikey")
        request.timeoutInterval = 15 // Timeout raisonnable
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw IDFMobiliteError.invalidResponse
            }
                        
            switch httpResponse.statusCode {
            case 200...299:
                // Essayer de parser les données
                return try parseStopMonitoringResponse(data)
            case 401, 403:
                throw IDFMobiliteError.apiError("Clé API invalide")
            case 404:
                throw IDFMobiliteError.apiError("Ressource non trouvée")
            case 429:
                throw IDFMobiliteError.apiError("Trop de requêtes")
            case 500...599:
                throw IDFMobiliteError.apiError("Erreur serveur")
            default:
                throw IDFMobiliteError.apiError("Erreur HTTP \(httpResponse.statusCode)")
            }
        } catch let error as IDFMobiliteError {
            print("IDFMobilite error: \(error)")
            throw error
        } catch {
            print("Network error: \(error)")
            throw IDFMobiliteError.networkError(error)
        }
    }
    
    /// Search for stops by name
    func searchStops(query: String) async throws -> [TransportStop] {
        guard let apiKey = apiKey else {
            throw IDFMobiliteError.noApiKey
        }
        
        // Implementation will depend on the specific API capabilities
        // This is a placeholder for the search functionality
        
        return []
    }
    
    /// Fetch all available transport lines
    func fetchLines() async throws -> [TransportLine] {
        guard let apiKey = apiKey else {
            throw IDFMobiliteError.noApiKey
        }
        
        let urlComponents = URLComponents(string: baseURL + referentialLinesURL)
        guard let url = urlComponents?.url else {
            throw IDFMobiliteError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.addValue(apiKey, forHTTPHeaderField: "apikey")
        
        // Additional query parameters would be added here
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw IDFMobiliteError.invalidResponse
            }
            
            // Parse the response and convert to TransportLine objects
            return try parseLinesResponse(data)
            
        } catch let error as IDFMobiliteError {
            throw error
        } catch {
            throw IDFMobiliteError.networkError(error)
        }
    }
    
    // MARK: - Private helper methods
    
    private func parseStopMonitoringResponse(_ data: Data) throws -> [Departure] {
        do {
            // Décodage de la réponse au format SIRI
            let decoder = JSONDecoder()
            let siriResponse = try decoder.decode(SIRIResponse.self, from: data)
                        
            // Conversion en array de Departure
            return siriResponse.toDepartures()
        } catch {
            print("Erreur de décodage: \(error)")
            
            // Si l'erreur est liée au décodage, essayons d'imprimer la réponse brute pour le débogage
            if let responseString = String(data: data, encoding: .utf8) {
                print("Réponse brute: \(responseString.prefix(500))...") // Limiter pour éviter un log trop long
            }
            
            throw IDFMobiliteError.decodingError
        }
    }
    
    private func parseLinesResponse(_ data: Data) throws -> [TransportLine] {
        // Placeholder function - implement based on actual response format
        return []
    }
    
    private func extractId(from ref: String) -> String {
        // Extract the ID from a reference like "STIF:Line::C01742:"
        let components = ref.split(separator: ":")
        if components.count >= 4 {
            return String(components[3])
        }
        return ref
    }
}
