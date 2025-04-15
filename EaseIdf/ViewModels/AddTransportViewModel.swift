//
//  AddTransportViewModel.swift
//  EaseIdf
//
//  Created by Claude on 15/04/2025.
//

import Foundation
import SwiftUI
import Combine
import SwiftData

class AddTransportViewModel: ObservableObject {
    // États de sélection
    @Published var selectedTransportMode: TransportMode?
    @Published var selectedLine: ImportedLine?
    @Published var selectedStop: ImportedStop?
    @Published var selectedDirection: LineDirection?
    @Published var displayName: String = ""
    
    // États d'interface utilisateur
    @Published var searchLineQuery: String = ""
    @Published var searchStopQuery: String = ""
    @Published var showingStopSelection = false
    @Published var showingDirectionSelection = false
    @Published var showingNameInput = false
    @Published var isSaving = false
    @Published var favoriteCreated = false
    
    // Données filtrées
    @Published var filteredLines: [ImportedLine] = []
    @Published var filteredStops: [ImportedStop] = []
    @Published var availableDirections: [LineDirection] = []
    
    // Gestion de l'étape active dans le flux d'ajout
    enum AddTransportStep {
        case selectTransportMode
        case selectLine
        case selectStop
        case selectDirection
        case nameFavorite
    }
    
    @Published var currentStep: AddTransportStep = .selectTransportMode
    
    private var cancellables = Set<AnyCancellable>()
    private var modelContext: ModelContext?
    
    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
        
        // Observer les changements de recherche pour filtrer les lignes
        $searchLineQuery
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] query in
                self?.filterLines(query: query)
            }
            .store(in: &cancellables)
        
        // Observer les changements de recherche pour filtrer les arrêts
        $searchStopQuery
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] query in
                self?.filterStops(query: query)
            }
            .store(in: &cancellables)
    }
    
    // Mise à jour du ModelContext si nécessaire
    func setModelContext(_ context: ModelContext?) {
        self.modelContext = context
    }
    
    // Filtrer les lignes en fonction du mode de transport et de la requête
    func filterLines(query: String) {
        if isLoading {
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self, !self.isLoading else { return }
            
            if let mode = self.selectedTransportMode {
                self.filteredLines = LineDataService.shared.searchLines(query: query, mode: mode)
            } else {
                self.filteredLines = LineDataService.shared.searchLines(query: query)
            }
        }
    }
    
    // Filtrer les arrêts pour la ligne sélectionnée
    func filterStops(query: String) {
        // Exécuter sur le thread principal car les opérations SwiftData doivent y rester
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let line = self.selectedLine, !self.isLoading else { return }
            
            let stopsForLine = StopDataService.shared.getStopsForLine(lineId: line.id_line)
            
            if query.isEmpty {
                self.filteredStops = stopsForLine
            } else {
                self.filteredStops = stopsForLine.filter { stop in
                    stop.name_stop.lowercased().contains(query.lowercased()) ||
                    stop.id_stop.lowercased().contains(query.lowercased())
                }
            }
        }
    }
    
    // Sélectionner un mode de transport
    func selectTransportMode(_ mode: TransportMode) {
        self.selectedTransportMode = mode
        self.searchLineQuery = ""
        self.filterLines(query: "")
        self.currentStep = .selectLine
    }
    
    // Sélectionner une ligne
    func selectLine(_ line: ImportedLine) {
        self.selectedLine = line
        self.searchStopQuery = ""
        
        // Récupérer les arrêts pour cette ligne
        let stopsForLine = StopDataService.shared.getStopsForLine(lineId: line.id_line)
        self.filteredStops = stopsForLine
        
        // Récupérer les directions disponibles
        self.availableDirections = LineDataService.shared.getDirectionsForLine(lineId: line.id_line)
        
        self.currentStep = .selectStop
    }
    
    // Sélectionner un arrêt
    func selectStop(_ stop: ImportedStop) {
        self.selectedStop = stop
        
        if availableDirections.count > 1 {
            // S'il y a plusieurs directions, passer à l'étape de sélection de direction
            self.currentStep = .selectDirection
        } else if availableDirections.count == 1 {
            // S'il n'y a qu'une seule direction, la sélectionner automatiquement
            self.selectedDirection = availableDirections.first
            self.currentStep = .nameFavorite
            self.setDefaultDisplayName()
        } else {
            // Aucune direction disponible, passer directement à l'étape de nommage
            self.currentStep = .nameFavorite
            self.setDefaultDisplayName()
        }
    }
    
    // Sélectionner une direction
    func selectDirection(_ direction: LineDirection) {
        self.selectedDirection = direction
        self.currentStep = .nameFavorite
        self.setDefaultDisplayName()
    }
    
    // Définir un nom d'affichage par défaut
    private func setDefaultDisplayName() {
        var name = ""
        
        if let line = selectedLine {
            name += line.shortname_line
        }
        
        if let direction = selectedDirection {
            name += " → \(direction.direction)"
        }
        
        if let stop = selectedStop {
            name += " (\(stop.name_stop))"
        }
        
        self.displayName = name
    }
    
    // Enregistrer le transport favori
    func saveFavorite() {
        guard let stop = selectedStop,
              let line = selectedLine else {
            return
        }
        
        isSaving = true
        
        // Créer un nouveau favori
        let favorite = TransportFavorite(
            id: UUID(),
            stopId: stop.id_stop,
            lineId: line.id_line,
            displayName: displayName,
            displayConditions: [],
            priority: 0
        )
        
        // Enregistrer le favori dans SwiftData
        if let modelContext = modelContext {
            // Créer le modèle sur le thread principal
            DispatchQueue.main.async {
                // Utiliser SwiftData pour l'enregistrement
                let favoriteModel = TransportFavoriteModel.fromStruct(favorite)
                modelContext.insert(favoriteModel)
                
                do {
                    try modelContext.save()
                    print("Favori enregistré avec succès dans SwiftData")
                } catch {
                    // En cas d'erreur, utiliser le stockage de secours
                    print("Erreur lors de l'enregistrement du favori dans SwiftData: \(error)")
                    StorageService.shared.saveFavorite(favorite)
                    print("Favori enregistré avec le système de secours")
                }
                
                self.isSaving = false
                self.favoriteCreated = true
            }
        } else {
            // Fallback vers l'ancien système
            StorageService.shared.saveFavorite(favorite)
            
            DispatchQueue.main.async {
                self.isSaving = false
                self.favoriteCreated = true
            }
        }
    }
    
    // Vérifier si des données sont disponibles
    func checkDataAvailability() {
        if filteredLines.isEmpty && selectedTransportMode != nil && !isLoading {
            print("Aucune ligne trouvée pour le mode \(String(describing: selectedTransportMode))")
            
            // Essayer de rafraîchir les données
            Task {
                await loadTransportData()
            }
        }
    }
    
    // Charger les données si nécessaire
    func loadTransportData() async {
        if LineDataService.shared.getAllLines().isEmpty {
            // Charger les données des lignes depuis le fichier
            LineDataService.shared.loadLinesFromFile(named: "transport_lines")
        }
        
        if StopDataService.shared.getAllStops().isEmpty {
            // Charger les données des arrêts depuis le fichier
            StopDataService.shared.loadStopsFromFile(named: "transport_stops")
        }
        
        // Rechargement des filtres après chargement des données
        await MainActor.run {
            if let mode = selectedTransportMode {
                self.filterLines(query: searchLineQuery)
            }
            
            if let line = selectedLine {
                self.filterStops(query: searchStopQuery)
            }
        }
    }
    
    // Variable pour indiquer si le chargement est en cours
    var isLoading: Bool {
        return LineDataService.shared.isLoading || StopDataService.shared.isLoading
    }
    
    // Réinitialiser le flux d'ajout
    func reset() {
        selectedTransportMode = nil
        selectedLine = nil
        selectedStop = nil
        selectedDirection = nil
        displayName = ""
        searchLineQuery = ""
        searchStopQuery = ""
        filteredLines = []
        filteredStops = []
        availableDirections = []
        currentStep = .selectTransportMode
        favoriteCreated = false
    }
}
