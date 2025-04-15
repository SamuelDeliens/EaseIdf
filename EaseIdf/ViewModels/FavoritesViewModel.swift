//
//  FavoritesViewModel.swift
//  EaseIdf
//
//  Created by Claude on 15/04/2025.
//

import Foundation
import SwiftData
import Combine

class FavoritesViewModel: ObservableObject {
    @Published var favorites: [TransportFavorite] = []
    @Published var activeFavorites: [TransportFavorite] = []
    @Published var departures: [String: [Departure]] = [:]
    @Published var isLoading = false
    @Published var error: Error?
    
    private var cancellables = Set<AnyCancellable>()
    private var refreshTimer: Timer?
    private var modelContext: ModelContext?
    
    init() {
        // Initial loading will be triggered when modelContext is set
    }
    
    func setModelContext(_ context: ModelContext?) {
        self.modelContext = context
        loadFavorites()
    }
    
    // MARK: - Data Loading
    
    func loadFavorites() {
        if let modelContext = modelContext {
            // Try to load from SwiftData
            do {
                let descriptor = FetchDescriptor<TransportFavoriteModel>(
                    sortBy: [SortDescriptor(\.priority, order: .reverse)]
                )
                let favoriteModels = try modelContext.fetch(descriptor)
                
                // Convert models to structs
                favorites = favoriteModels.map { $0.toStruct() }
                
                // Filter active favorites based on conditions
                updateActiveFavorites()
                
                // Load departures for active favorites
                refreshDepartures()
                
                // Start refresh timer
                setupRefreshTimer()
                
            } catch {
                print("Error fetching favorites from SwiftData: \(error)")
                
                // Fallback to UserDefaults via StorageService
                favorites = StorageService.shared.getUserSettings().favorites
                updateActiveFavorites()
                refreshDepartures()
                setupRefreshTimer()
            }
        } else {
            // Fallback to UserDefaults via StorageService
            favorites = StorageService.shared.getUserSettings().favorites
            updateActiveFavorites()
            refreshDepartures()
            setupRefreshTimer()
        }
    }
    
    func updateActiveFavorites() {
        activeFavorites = ConditionEvaluationService.shared.getCurrentlyActiveTransportFavorites()
    }
    
    func refreshDepartures() {
        guard !activeFavorites.isEmpty else { return }
        
        isLoading = true
        error = nil
        
        // Create a task group to fetch departures in parallel
        Task {
            var newDepartures: [String: [Departure]] = [:]
            
            do {
                for favorite in activeFavorites {
                    // Fetch departures for this favorite
                    let favoriteDepartures = try await IDFMobiliteService.shared.fetchDepartures(
                        for: favorite.stopId,
                        lineId: favorite.lineId
                    )
                    
                    // Sort by departure time
                    let sortedDepartures = favoriteDepartures.sorted {
                        $0.expectedDepartureTime < $1.expectedDepartureTime
                    }
                    
                    // Limit number of departures based on user settings
                    let settings = StorageService.shared.getUserSettings()
                    let limitedDepartures = Array(sortedDepartures.prefix(settings.numberOfDeparturesToShow))
                    
                    // Store in dictionary with favorite id as key
                    newDepartures[favorite.id.uuidString] = limitedDepartures
                }
                
                // Update published property on main thread
                await MainActor.run {
                    self.departures = newDepartures
                    self.isLoading = false
                }
                
                // Update widget data
                await WidgetService.shared.refreshWidgetData()
                
            } catch {
                await MainActor.run {
                    self.error = error
                    self.isLoading = false
                }
            }
        }
    }
    
    // MARK: - Timer Management
    
    private func setupRefreshTimer() {
        // Cancel existing timer
        refreshTimer?.invalidate()
        
        // Get refresh interval from settings
        let settings = StorageService.shared.getUserSettings()
        let interval = settings.refreshInterval
        
        // Create new timer
        refreshTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.updateActiveFavorites()
            self?.refreshDepartures()
        }
    }
    
    func stopRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    // MARK: - Favorite Management
    
    func removeFavorite(at indexSet: IndexSet) {
        guard let modelContext = modelContext else {
            return
        }
        
        for index in indexSet {
            let favorite = favorites[index]
            
            // Delete from SwiftData
            do {
                let descriptor = FetchDescriptor<TransportFavoriteModel>(
                    predicate: #Predicate { $0.id == favorite.id }
                )
                let models = try modelContext.fetch(descriptor)
                
                if let model = models.first {
                    modelContext.delete(model)
                    try modelContext.save()
                }
                
                // Also delete from StorageService for compatibility
                StorageService.shared.removeFavorite(id: favorite.id)
                
                // Update local arrays
                favorites.remove(at: index)
                updateActiveFavorites()
                
            } catch {
                print("Error removing favorite: \(error)")
                // Fallback to StorageService
                StorageService.shared.removeFavorite(id: favorite.id)
                favorites.remove(at: index)
                updateActiveFavorites()
            }
        }
    }
    
    func moveFavorite(from source: IndexSet, to destination: Int) {
        guard let modelContext = modelContext else {
            return
        }
        
        // Update local array
        favorites.move(fromOffsets: source, toOffset: destination)
        
        // Update priorities based on new order (higher index = lower priority)
        for (index, favorite) in favorites.enumerated() {
            let newPriority = favorites.count - index
            
            // Try to update in SwiftData
            do {
                let descriptor = FetchDescriptor<TransportFavoriteModel>(
                    predicate: #Predicate { $0.id == favorite.id }
                )
                let models = try modelContext.fetch(descriptor)
                
                if let model = models.first {
                    model.priority = newPriority
                }
                
                // Also update in StorageService
                StorageService.shared.updateFavoritePriority(id: favorite.id, newPriority: newPriority)
                
            } catch {
                print("Error updating favorite priority: \(error)")
                // Fallback to StorageService
                StorageService.shared.updateFavoritePriority(id: favorite.id, newPriority: newPriority)
            }
        }
        
        // Save changes
        do {
            try modelContext.save()
        } catch {
            print("Error saving favorite order changes: \(error)")
        }
        
        // Update active favorites
        updateActiveFavorites()
    }
}
