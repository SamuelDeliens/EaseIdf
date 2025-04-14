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

    var body: some Scene {
            WindowGroup {
                ContentView()
                    .onAppear {
                        LocationService.shared.requestAuthorization()
                        LocationService.shared.startLocationUpdates()
                        
                        LineDataService.shared.loadLinesFromFile(named: "transport_lines")
                        
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
