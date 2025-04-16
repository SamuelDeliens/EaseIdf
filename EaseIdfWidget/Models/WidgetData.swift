//
//  WidgetData.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 16/04/2025.
//

import WidgetKit
import SwiftUI

// Structure pour représenter les données du widget
struct WidgetData: Codable {
    let departures: [Departure]
    let favorites: [TransportFavorite]
    let lastUpdated: Date
    
    static var placeholder: WidgetData {
        let placeholderDeparture = Departure(
            stopId: "12345",
            lineId: "C01742",
            destination: "Destination",
            expectedDepartureTime: Date().addingTimeInterval(600),
            aimedDepartureTime: nil,
            vehicleJourneyName: nil
        )
        
        let placeholderFavorite = TransportFavorite(
            id: UUID(),
            stopId: "12345",
            lineId: "C01742",
            displayName: "Bus 42",
            displayConditions: [],
            priority: 1
        )
        
        return WidgetData(
            departures: [placeholderDeparture],
            favorites: [placeholderFavorite],
            lastUpdated: Date()
        )
    }
}

// Configuration de l'entrée du widget
struct WidgetConfigurationEntry: TimelineEntry {
    let date: Date
    let data: WidgetData
    let isPlaceholder: Bool
    
    static var placeholder: WidgetConfigurationEntry {
        WidgetConfigurationEntry(
            date: Date(),
            data: WidgetData.placeholder,
            isPlaceholder: true
        )
    }
}

// Provider pour gérer les mises à jour du widget
struct EaseIdfWidgetProvider: TimelineProvider {
    private func getSharedUserDefaults() -> UserDefaults? {
        return UserDefaults(suiteName: "group.com.samueldeliens.EaseIdf")
    }
    
    func placeholder(in context: Context) -> WidgetConfigurationEntry {
        return WidgetConfigurationEntry.placeholder
    }
    
    func getSnapshot(in context: Context, completion: @escaping (WidgetConfigurationEntry) -> ()) {
        let entry: WidgetConfigurationEntry
        
        if context.isPreview && !loadWidgetData() {
            // Pour les aperçus, utiliser des données fictives si aucune donnée n'est disponible
            entry = WidgetConfigurationEntry.placeholder
        } else if let widgetData = loadWidgetDataFromDefaults() {
            // Utiliser les données réelles
            entry = WidgetConfigurationEntry(
                date: Date(),
                data: widgetData,
                isPlaceholder: false
            )
        } else {
            // Utiliser un placeholder si les données ne sont pas disponibles
            entry = WidgetConfigurationEntry.placeholder
        }
        
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetConfigurationEntry>) -> ()) {
        getSnapshot(in: context) { entry in
            // Calculer la prochaine mise à jour
            let refreshDate = calculateNextRefreshDate(for: entry)
            
            // Créer la timeline avec l'entrée actuelle
            let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
            completion(timeline)
        }
    }
    
    // Charger les données du widget depuis les UserDefaults partagés
    private func loadWidgetDataFromDefaults() -> WidgetData? {
        guard let sharedDefaults = getSharedUserDefaults(),
              let data = sharedDefaults.data(forKey: "widgetData") else {
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(WidgetData.self, from: data)
        } catch {
            print("Erreur lors du décodage des données du widget: \(error)")
            return nil
        }
    }
    
    // Vérifier si des données sont disponibles
    private func loadWidgetData() -> Bool {
        guard let sharedDefaults = getSharedUserDefaults() else {
            return false
        }
        return sharedDefaults.data(forKey: "widgetData") != nil
    }
    
    // Calculer la prochaine date de rafraîchissement
    private func calculateNextRefreshDate(for entry: WidgetConfigurationEntry) -> Date {
        // Par défaut, rafraîchir dans 15 minutes
        let defaultRefreshInterval: TimeInterval = 15 * 60
        
        // Utiliser l'intervalle configuré par l'utilisateur si disponible
        let refreshInterval: TimeInterval
        if let sharedDefaults = getSharedUserDefaults(),
           let interval = sharedDefaults.object(forKey: "widgetRefreshInterval") as? TimeInterval {
            refreshInterval = max(interval, 60) // Au moins 1 minute
        } else {
            refreshInterval = defaultRefreshInterval
        }
        
        return Date().addingTimeInterval(refreshInterval)
    }
}
