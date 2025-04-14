//
//  ContentView.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 14/04/2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var favorites: [TransportFavoriteModel]
    
    @State private var showingAddFavoriteSheet = false
    @State private var isRefreshing = false
    @State private var activeTransportFavorites: [TransportFavorite] = []
    @State private var departures: [String: [Departure]] = [:]
    @State private var showingSettingsSheet = false
    
    // Timer for auto-refresh
    @State private var refreshTimer: Timer?
    
    var body: some View {
        NavigationStack {
            VStack {
                if activeTransportFavorites.isEmpty {
                    emptyStateView
                } else {
                    departuresList
                }
            }
            .navigationTitle("EaseIdf")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showingSettingsSheet = true
                    }) {
                        Image(systemName: "gear")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddFavoriteSheet = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        refreshData()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                            .animation(isRefreshing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isRefreshing)
                    }
                }
            }
            .sheet(isPresented: $showingAddFavoriteSheet) {
                FavoriteListView()
            }
            .sheet(isPresented: $showingSettingsSheet) {
                SettingsView()
            }
            .onAppear {
                setupRefreshTimer()
                refreshData()
            }
            .onDisappear {
                refreshTimer?.invalidate()
            }
        }
    }
    
    // MARK: - Subviews
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "tram.fill")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("Aucun transport à afficher")
                .font(.title)
                .foregroundColor(.secondary)
            
            Text("Ajoutez des favoris et définissez des conditions d'affichage pour voir les prochains passages.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding()
            
            Button(action: {
                showingAddFavoriteSheet = true
            }) {
                Text("Ajouter un favori")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
    
    private var departuresList: some View {
        List {
            ForEach(activeTransportFavorites) { favorite in
                if let departuresForStop = departures[favorite.stopId] {
                    Section(header: Text(favorite.displayName)) {
                        if departuresForStop.isEmpty {
                            Text("Aucun passage à venir")
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(departuresForStop) { departure in
                                DepartureRow(departure: departure)
                            }
                        }
                    }
                }
            }
        }
        .refreshable {
            await refreshDataAsync()
        }
    }
    
    // MARK: - Methods
    
    private func setupRefreshTimer() {
        let settings = StorageService.shared.getUserSettings()
        
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: settings.refreshInterval, repeats: true) { _ in
            refreshData()
        }
    }
    
    private func refreshData() {
        isRefreshing = true
        
        Task {
            await refreshDataAsync()
            
            DispatchQueue.main.async {
                isRefreshing = false
            }
        }
    }
    
    private func refreshDataAsync() async {
        // Get active favorites based on current conditions
        let active = ConditionEvaluationService.shared.getCurrentlyActiveTransportFavorites()
        
        // Fetch departures for each active favorite
        var allDepartures: [String: [Departure]] = [:]
        
        for favorite in active {
            do {
                let favoriteDepartures = try await IDFMobiliteService.shared.fetchDepartures(
                    for: favorite.stopId,
                    lineId: favorite.lineId
                )
                
                // Sort departures by expected departure time
                let sortedDepartures = favoriteDepartures.sorted {
                    $0.expectedDepartureTime < $1.expectedDepartureTime
                }
                
                allDepartures[favorite.stopId] = sortedDepartures
                
            } catch {
                print("Error fetching departures for \(favorite.displayName): \(error.localizedDescription)")
            }
        }
        
        // Update the widget data
        WidgetService.shared.saveWidgetData(
            departures: allDepartures.values.flatMap { $0 },
            activeTransportFavorites: active
        )
        
        // Update state on main thread
        DispatchQueue.main.async {
            self.activeTransportFavorites = active
            self.departures = allDepartures
        }
    }
}

struct DepartureRow: View {
    let departure: Departure
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(departure.destination)
                    .font(.headline)
                
                if let delay = departure.delay {
                    if delay > 0 {
                        Text("Retard: \(Int(delay / 60)) min")
                            .font(.caption)
                            .foregroundColor(.red)
                    } else if delay < 0 {
                        Text("En avance: \(Int(abs(delay) / 60)) min")
                            .font(.caption)
                            .foregroundColor(.green)
                    } else {
                        Text("À l'heure")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
            
            Spacer()
            
            Text(departure.waitingTime)
                .font(.title2)
                .fontWeight(.bold)
                .padding(8)
                .background(departure.expectedDepartureTime.timeIntervalSinceNow < 300 ? Color.red.opacity(0.2) : Color.green.opacity(0.2))
                .cornerRadius(8)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ContentView()
}
