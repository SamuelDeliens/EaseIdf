//
//  EaseIdfApp.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 14/04/2025.
//

import SwiftUI
import SwiftData

@main
struct EaseIdfApp: App {
    var sharedModelContainer: ModelContainer = PersistenceService.shared.getModelContainer()
    var transportDataContainer: ModelContainer = DataPersistenceService.shared.getTransportDataContainer()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    LocationService.shared.requestAuthorization()
                    LocationService.shared.startLocationUpdates()
                    
                    // Initialiser les services SwiftData
                    LineDataService.shared.initializeModelContainer()
                    StopDataService.shared.initializeModelContainer()
                    
                    // Charger les données
                    LineDataService.shared.loadLinesFromFile(named: "transport_lines")
                    StopDataService.shared.loadStopsFromFile(named: "transport_stops")
                    
                    let settings = StorageService.shared.getUserSettings()
                    WidgetService.shared.scheduleBackgroundUpdates(interval: settings.refreshInterval)
                    
                    Task {
                        await WidgetService.shared.refreshWidgetData()
                    }
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
