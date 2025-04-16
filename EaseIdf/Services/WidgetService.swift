//
//  WidgetService.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 14/04/2025.
//

import Foundation
import WidgetKit
import SwiftUI

class WidgetService {
    static let shared = WidgetService()
    
    private init() {}
    
    // MARK: - Widget Data Management
    
    /// Save departures data for widget access
    func saveWidgetData(departures: [Departure], activeTransportFavorites: [TransportFavorite]) {
        let userData = WidgetData(
            departures: departures,
            favorites: activeTransportFavorites,
            lastUpdated: Date()
        )
        
        if let encoded = try? JSONEncoder().encode(userData) {
            if let sharedDefaults = UserDefaults(suiteName: "group.com.samueldeliens.EaseIdf") {
                sharedDefaults.set(encoded, forKey: "widgetData")
                
                // Refresh all widgets
                refreshWidgets()
            }
        }
    }
    
    /// Refresh widget data by fetching latest departures for active favorites
    func refreshWidgetData() async {
        let activeFavorites = ConditionEvaluationService.shared.getCurrentlyActiveTransportFavorites()
        var allDepartures: [Departure] = []
        
        // Log pour débogage
        print("Refresh du widget: \(activeFavorites.count) favoris actifs")
        
        for favorite in activeFavorites {
            do {
                let departures = try await IDFMobiliteService.shared.fetchDepartures(
                    for: favorite.stopId,
                    lineId: favorite.lineId
                )
                
                allDepartures.append(contentsOf: departures)
                print("Récupération de \(departures.count) départs pour le favori \(favorite.displayName)")
            } catch {
                print("Erreur lors de la récupération des départs pour le widget: \(error.localizedDescription)")
            }
        }
        
        // Limit the number of departures per favorite if needed
        let settings = StorageService.shared.getUserSettings()
        let limitedDepartures = limitDepartures(allDepartures, settings: settings)
        
        // Save for widget access
        saveWidgetData(departures: limitedDepartures, activeTransportFavorites: activeFavorites)
        
        print("Widget mis à jour avec \(limitedDepartures.count) départs")
    }
    
    /// Schedule periodic background updates for widget data
    func scheduleBackgroundUpdates(interval: TimeInterval = 600) {
        // Configuration de l'intervalle de rafraîchissement
        if let sharedDefaults = UserDefaults(suiteName: "group.com.samueldeliens.EaseIdf") {
            sharedDefaults.set(interval, forKey: "widgetRefreshInterval")
        }
        
        // En production, cette fonction utiliserait BGAppRefreshTask ou BGProcessingTask
        // pour planifier des mises à jour périodiques en arrière-plan
        
        // Pour une implémentation simple, nous pouvons utiliser un timer local
        DispatchQueue.main.async {
            // Planifier la première mise à jour
            Task {
                await self.refreshWidgetData()
            }
        }
    }
    
    /// Force refresh of widget data - useful when user performs manual refresh
    func forceRefreshWidgetData() async {
        await refreshWidgetData()
    }
    
    // MARK: - Private Helper Methods
    
    /// Refresh all widgets
    private func refreshWidgets() {
        #if os(iOS)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }
    
    /// Limit the number of departures according to user settings
    private func limitDepartures(_ departures: [Departure], settings: UserSettings) -> [Departure] {
        // Filtrer les départs futurs si l'option est activée
        var filteredDepartures = departures
        if settings.showOnlyUpcomingDepartures {
            filteredDepartures = departures.filter { $0.expectedDepartureTime > Date() }
        }
        
        // Regrouper par arrêt et ligne
        let groupedDepartures = Dictionary(grouping: filteredDepartures) {
            return "\($0.stopId)-\($0.lineId)"
        }
        
        var limitedDepartures: [Departure] = []
        
        for (_, departuresForStopAndLine) in groupedDepartures {
            // Trier par heure de départ
            let sortedDepartures = departuresForStopAndLine.sorted {
                $0.expectedDepartureTime < $1.expectedDepartureTime
            }
            
            // Limiter au nombre spécifié dans les paramètres
            let limited = Array(sortedDepartures.prefix(settings.numberOfDeparturesToShow))
            limitedDepartures.append(contentsOf: limited)
        }
        
        // Trier tous les départs par heure pour l'affichage final
        return limitedDepartures.sorted { $0.expectedDepartureTime < $1.expectedDepartureTime }
    }
    
    // MARK: - Widget Configuration
    
    /// Get colors for a specific transport line - useful for widget
    func getColorsForLine(_ lineId: String, transportMode: TransportMode? = nil) -> (background: Color, text: Color) {
        // Récupérer le code court de la ligne (par exemple "14" à partir de "STIF:Line::C01742:")
        let lineCode = getLineShortCode(lineId)
        
        // Déterminer le mode si non spécifié
        let mode = transportMode?.rawValue ?? guessTransportMode(lineCode)
        
        // Utiliser les couleurs standards RATP/SNCF
        switch mode {
        case "metro":
            if let lineNumber = extractNumberFromCode(lineCode) {
                if let colors = getMetroColors(lineNumber) {
                    return colors
                }
            }
        case "rer":
            if lineCode.count >= 1 {
                let letter = String(lineCode.prefix(1))
                if let colors = getRERColors(letter) {
                    return colors
                }
            }
        case "tram":
            if let tramNumber = extractNumberFromTramCode(lineCode) {
                if let colors = getTramColors(tramNumber) {
                    return colors
                }
            }
        default:
            break
        }
        
        // Couleur par défaut basée sur le mode de transport
        return getDefaultColorForMode(mode)
    }
    
    // MARK: - Color Helpers
    
    private func getLineShortCode(_ lineId: String) -> String {
        // Extraire le code court à partir de l'ID complet
        if lineId.contains(":") {
            let components = lineId.split(separator: ":")
            if components.count >= 4 {
                return String(components[3])
            }
        }
        return lineId
    }
    
    private func guessTransportMode(_ lineCode: String) -> String {
        if lineCode.hasPrefix("M") || (Int(lineCode) != nil && Int(lineCode)! < 15) {
            return "metro"
        } else if lineCode.contains("RER") || (lineCode.count == 1 && "ABCDE".contains(lineCode)) {
            return "rer"
        } else if lineCode.hasPrefix("T") {
            return "tram"
        } else {
            return "bus"
        }
    }
    
    private func extractNumberFromCode(_ code: String) -> String? {
        if let number = code.first(where: { $0.isNumber }) {
            return String(number)
        }
        return nil
    }
    
    private func extractNumberFromTramCode(_ code: String) -> String? {
        // Extract tram number from codes like "T1", "T3a", etc.
        let pattern = "T(\\d+)"
        if let regex = try? NSRegularExpression(pattern: pattern) {
            let range = NSRange(code.startIndex..., in: code)
            if let match = regex.firstMatch(in: code, range: range) {
                let numberRange = match.range(at: 1)
                if let range = Range(numberRange, in: code) {
                    return String(code[range])
                }
            }
        }
        return nil
    }
    
    private func getMetroColors(_ lineNumber: String) -> (Color, Color)? {
        let metroColors: [String: (Color, Color)] = [
            "1": (Color(hex: "FFCD00"), .black),
            "2": (Color(hex: "003CA6"), .white),
            "3": (Color(hex: "837902"), .white),
            "4": (Color(hex: "CF009E"), .white),
            "5": (Color(hex: "FF7E2E"), .black),
            "6": (Color(hex: "6ECA97"), .black),
            "7": (Color(hex: "FA9ABA"), .black),
            "8": (Color(hex: "E19BDF"), .black),
            "9": (Color(hex: "B6BD00"), .black),
            "10": (Color(hex: "C9910D"), .white),
            "11": (Color(hex: "704B1C"), .white),
            "12": (Color(hex: "007852"), .white),
            "13": (Color(hex: "6EC4E8"), .black),
            "14": (Color(hex: "62259D"), .white)
        ]
        return metroColors[lineNumber]
    }
    
    private func getRERColors(_ letter: String) -> (Color, Color)? {
        let rerColors: [String: (Color, Color)] = [
            "A": (Color(hex: "FF1744"), .white),
            "B": (Color(hex: "2979FF"), .white),
            "C": (Color(hex: "FFEB3B"), .black),
            "D": (Color(hex: "4CAF50"), .white),
            "E": (Color(hex: "FF5722"), .white)
        ]
        return rerColors[letter]
    }
    
    private func getTramColors(_ number: String) -> (Color, Color)? {
        let tramColors: [String: (Color, Color)] = [
            "1": (Color(hex: "2E8B57"), .white),
            "2": (Color(hex: "FF4500"), .white),
            "3": (Color(hex: "00CED1"), .black),
            "4": (Color(hex: "9370DB"), .white),
            "5": (Color(hex: "3CB371"), .white),
            "6": (Color(hex: "FF8C00"), .white),
            "7": (Color(hex: "8A2BE2"), .white),
            "8": (Color(hex: "20B2AA"), .white),
            "9": (Color(hex: "32CD32"), .white)
        ]
        return tramColors[number]
    }
    
    private func getDefaultColorForMode(_ mode: String) -> (Color, Color) {
        switch mode {
        case "metro":
            return (Color(hex: "0078D7"), .white)
        case "rer":
            return (Color(hex: "FF4081"), .white)
        case "tram":
            return (Color(hex: "4CAF50"), .white)
        case "bus":
            return (Color(hex: "FF9800"), .white)
        default:
            return (Color(hex: "007AFF"), .white)
        }
    }
}

// Extension pour créer une couleur à partir d'un code hex
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// Structure pour les données de widget
struct WidgetData: Codable {
    let departures: [Departure]
    let favorites: [TransportFavorite]
    let lastUpdated: Date
}
