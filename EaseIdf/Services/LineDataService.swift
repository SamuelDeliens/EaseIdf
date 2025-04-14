//
//  LineDataService.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 14/04/2025.
//

import Foundation
import Combine

class LineDataService {
    static let shared = LineDataService()
    
    private init() {
        loadCachedData()
    }
    
    // MARK: - Properties
    
    @Published private(set) var importedLines: [ImportedLine] = []
    @Published private(set) var isLoading = false
    
    // MARK: - Public Methods
    
    /// Load lines from a local JSON file
    func loadLinesFromFile(named filename: String) {
        isLoading = true
        
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
            print("Error: File \(filename).json not found in bundle")
            isLoading = false
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let lines = try JSONDecoder().decode([ImportedLine].self, from: data)
            self.importedLines = lines
            
            // Cache the loaded data
            cacheImportedLines(lines)
            
            // Also convert and cache as TransportLine objects for compatibility
            let transportLines = lines.map { $0.toTransportLine() }
            StorageService.shared.cacheTransportLines(transportLines)
            
            isLoading = false
        } catch {
            print("Error loading lines from JSON: \(error)")
            isLoading = false
        }
    }
    
    /// Load lines from JSON data string
    func loadLinesFromJSONString(_ jsonString: String) {
        isLoading = true
        
        guard let data = jsonString.data(using: .utf8) else {
            print("Error: Could not convert JSON string to data")
            isLoading = false
            return
        }
        
        do {
            let lines = try JSONDecoder().decode([ImportedLine].self, from: data)
            self.importedLines = lines
            
            // Cache the loaded data
            cacheImportedLines(lines)
            
            // Also convert and cache as TransportLine objects for compatibility
            let transportLines = lines.map { $0.toTransportLine() }
            StorageService.shared.cacheTransportLines(transportLines)
            
            isLoading = false
        } catch {
            print("Error parsing JSON string: \(error)")
            isLoading = false
        }
    }
    
    /// Get directions for a line based on shortname_groupoflines
    func getDirectionsForLine(lineId: String) -> [LineDirection] {
        guard let line = importedLines.first(where: { $0.id_line == lineId }),
              let groupName = line.shortname_groupoflines else {
            return []
        }
        
        // Most lines have directions in format "ORIGIN - DESTINATION"
        let parts = groupName.split(separator: "-")
        
        if parts.count >= 2 {
            return parts.map { direction in
                LineDirection(
                    lineName: line.shortname_line,
                    direction: direction.trimmingCharacters(in: .whitespacesAndNewlines),
                    lineId: line.id_line,
                    color: line.color,
                    textColor: line.textColor,
                    transportMode: line.transportModeEnum
                )
            }
        } else {
            // If we can't split by dash, just use the whole group name as one direction
            return [
                LineDirection(
                    lineName: line.shortname_line,
                    direction: groupName.trimmingCharacters(in: .whitespacesAndNewlines),
                    lineId: line.id_line,
                    color: line.color,
                    textColor: line.textColor,
                    transportMode: line.transportModeEnum
                )
            ]
        }
    }
    
    /// Filter lines by transport mode
    func getLinesByMode(_ mode: TransportMode?) -> [ImportedLine] {
        if let mode = mode {
            return importedLines.filter { $0.transportModeEnum == mode }
        } else {
            return importedLines
        }
    }
    
    /// Search lines by query
    func searchLines(query: String, mode: TransportMode? = nil) -> [ImportedLine] {
        let lowercasedQuery = query.lowercased()
        
        let filteredByMode = getLinesByMode(mode)
        
        if query.isEmpty {
            return filteredByMode
        }
        
        return filteredByMode.filter { line in
            line.name_line.lowercased().contains(lowercasedQuery) ||
            line.shortname_line.lowercased().contains(lowercasedQuery) ||
            line.id_line.lowercased().contains(lowercasedQuery) ||
            (line.privatecode?.lowercased().contains(lowercasedQuery) ?? false) ||
            line.operatorname.lowercased().contains(lowercasedQuery) ||
            (line.shortname_groupoflines?.lowercased().contains(lowercasedQuery) ?? false)
        }
    }
    
    // MARK: - Private Methods
    
    private func cacheImportedLines(_ lines: [ImportedLine]) {
        if let encoded = try? JSONEncoder().encode(lines) {
            UserDefaults.standard.set(encoded, forKey: "cachedImportedLines")
            UserDefaults.standard.set(Date(), forKey: "importedLinesLastUpdated")
        }
    }
    
    private func loadCachedData() {
        if let data = UserDefaults.standard.data(forKey: "cachedImportedLines"),
           let lines = try? JSONDecoder().decode([ImportedLine].self, from: data) {
            self.importedLines = lines
        }
    }
}
