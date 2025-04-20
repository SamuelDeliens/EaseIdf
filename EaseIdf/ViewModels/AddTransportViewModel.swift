//
//  AddTransportViewModel.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 14/04/2025.
//


import Foundation
import SwiftUI
import Combine
import SwiftData

class AddTransportViewModel: BaseViewModel {
    // MARK: - Services
    
    private let transportService: TransportService
    private let favoriteService: FavoriteService
    private let conditionService: ConditionService
    
    // MARK: - États de sélection
    
    @Published var selectedTransportMode: TransportMode?
    @Published var selectedLine: ImportedLine?
    @Published var selectedStop: ImportedStop?
    @Published var selectedDirection: LineDirection?
    @Published var displayName: String = ""
    
    // MARK: - États d'interface utilisateur
    
    @Published var searchLineQuery: String = ""
    @Published var searchStopQuery: String = ""
    @Published var isSaving = false
    @Published var favoriteCreated = false
    
    // MARK: - Données filtrées
    
    @Published var filteredLines: [ImportedLine] = []
    @Published var filteredStops: [ImportedStop] = []
    @Published var availableDirections: [LineDirection] = []
    
    // MARK: - Propriétés pour les conditions d'affichage
    
    @Published var displayConditions: [DisplayCondition] = []
    @Published var editingConditionIndex: Int? = nil
    
    // MARK: - Gestion de l'étape active dans le flux d'ajout
    
    enum AddTransportStep {
        case selectTransportMode
        case selectLine
        case selectStop
        case selectDirection
        case nameFavorite
    }
    
    enum AddTransportStepAfterNaming {
        case configureConditions
        case saveWithoutConditions
    }
    
    enum ConditionSheetType {
        case none
        case timeRange
        case dayOfWeek
        case location
    }
    
    @Published var currentStep: AddTransportStep = .selectTransportMode
    @Published var afterNamingStep: AddTransportStepAfterNaming = .saveWithoutConditions
    @Published var activeConditionSheet: ConditionSheetType = .none
    
    // MARK: - Initialisation
    
    init(
        modelContext: ModelContext? = nil,
        transportService: TransportService = TransportService(),
        favoriteService: FavoriteService = FavoriteService(),
        conditionService: ConditionService = ConditionService()
    ) {
        self.transportService = transportService
        self.favoriteService = favoriteService
        self.conditionService = conditionService
        
        super.init(modelContext: modelContext)
        
        // Observer les changements de recherche pour filtrer les lignes
        setupSubscriptions()
    }
    
    private func setupSubscriptions() {
        // Filtrer les lignes lors des changements de requête
        $searchLineQuery
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] query in
                self?.filterLines(query: query)
            }
            .store(in: &cancellables)
        
        // Filtrer les arrêts lors des changements de requête
        $searchStopQuery
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] query in
                self?.filterStops(query: query)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Méthodes de filtrage
    
    /// Filtrer les lignes en fonction du mode de transport et de la requête
    func filterLines(query: String) {
        if isLoading {
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self, !self.isLoading else { return }
            
            if let mode = self.selectedTransportMode {
                self.filteredLines = self.transportService.searchLines(query: query, mode: mode)
            } else {
                self.filteredLines = self.transportService.searchLines(query: query)
            }
        }
    }
    
    /// Filtrer les arrêts pour la ligne sélectionnée
    func filterStops(query: String) {
        // Exécuter sur le thread principal car les opérations SwiftData doivent y rester
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let line = self.selectedLine, !self.isLoading else { return }
            
            let stopsForLine = self.transportService.getStopsForLine(lineId: line.id_line)
            
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
    
    // MARK: - Méthodes de sélection
    
    /// Sélectionner un mode de transport
    func selectTransportMode(_ mode: TransportMode) {
        self.selectedTransportMode = mode
        self.searchLineQuery = ""
        self.filterLines(query: "")
        self.currentStep = .selectLine
    }
    
    /// Sélectionner une ligne
    func selectLine(_ line: ImportedLine) {
        self.selectedLine = line
        self.searchStopQuery = ""
        
        // Récupérer les arrêts pour cette ligne
        let stopsForLine = transportService.getStopsForLine(lineId: line.id_line)
        self.filteredStops = stopsForLine
        
        // Récupérer les directions disponibles
        self.availableDirections = transportService.getDirectionsForLine(lineId: line.id_line)
        
        self.currentStep = .selectStop
    }
    
    /// Sélectionner un arrêt
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
    
    /// Sélectionner une direction
    func selectDirection(_ direction: LineDirection) {
        self.selectedDirection = direction
        self.currentStep = .nameFavorite
        self.setDefaultDisplayName()
    }
    
    /// Définir un nom d'affichage par défaut
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
    
    // MARK: - Chargement des données
    
    /// Charger les données de transport si nécessaire
    func loadTransportData() async {
        startLoading()
        
        // Charger les données manquantes
        var success = true
        
        if transportService.getAllLines().isEmpty {
            success = await transportService.loadLinesFromFile(named: "transport_lines")
            if !success {
                await MainActor.run {
                    self.showAlert(message: "Erreur lors du chargement des lignes")
                }
            }
        }
        
        if transportService.getAllStops().isEmpty {
            success = await transportService.loadStopsFromFile(named: "transport_stops")
            if !success {
                await MainActor.run {
                    self.showAlert(message: "Erreur lors du chargement des arrêts")
                }
            }
        }
        
        // Recharger les filtres après chargement des données
        await MainActor.run {
            if let mode = selectedTransportMode {
                self.filterLines(query: searchLineQuery)
            }
            
            if let line = selectedLine {
                self.filterStops(query: searchStopQuery)
            }
            
            self.stopLoading()
        }
    }
    
    /// Vérifier si des données sont disponibles
    func checkDataAvailability() {
        if filteredLines.isEmpty && selectedTransportMode != nil && !isLoading {
            print("Aucune ligne trouvée pour le mode \(String(describing: selectedTransportMode))")
            
            // Essayer de rafraîchir les données
            Task {
                await loadTransportData()
            }
        }
    }
    
    // MARK: - Enregistrement des favoris
    
    /// Enregistrer le transport favori sans conditions
    func saveFavorite() {
        guard let stop = selectedStop,
              let line = selectedLine else {
            return
        }
        
        isSaving = true
        
        // Créer un nouveau favori avec les informations complètes
        let favorite = TransportFavorite(
            id: UUID(),
            stopId: stop.id_stop,
            lineId: line.id_line,
            displayName: displayName,
            displayConditions: [],
            priority: 0,
            lineName: line.name_line,
            lineShortName: line.shortname_line,
            lineColor: line.colourweb_hexa ?? "007AFF",
            lineTextColor: line.textcolourweb_hexa ?? "FFFFFF",
            lineTransportMode: line.transportmode,
            stopName: stop.name_stop,
            stopLatitude: stop.latitude,
            stopLongitude: stop.longitude,
            stopType: stop.stop_type
        )
        
        // Enregistrer le favori via le service
        favoriteService.saveFavorite(favorite)
        
        DispatchQueue.main.async {
            self.isSaving = false
            self.favoriteCreated = true
        }
    }
    
    /// Enregistrer les conditions configurées avec le favori
    func saveConditions() {
        guard let stop = selectedStop,
              let line = selectedLine else {
            return
        }
        
        isSaving = true
        
        // Créer un nouveau favori avec les conditions configurées et les informations complètes
        let favorite = TransportFavorite(
            id: UUID(),
            stopId: stop.id_stop,
            lineId: line.id_line,
            displayName: displayName,
            displayConditions: displayConditions,
            priority: 0,
            lineName: line.name_line,
            lineShortName: line.shortname_line,
            lineColor: line.colourweb_hexa ?? "007AFF",
            lineTextColor: line.textcolourweb_hexa ?? "FFFFFF",
            lineTransportMode: line.transportmode,
            stopName: stop.name_stop,
            stopLatitude: stop.latitude,
            stopLongitude: stop.longitude,
            stopType: stop.stop_type
        )
        
        // Enregistrer le favori via le service
        favoriteService.saveFavorite(favorite)
        
        DispatchQueue.main.async {
            self.isSaving = false
            self.favoriteCreated = true
        }
    }
    
    // MARK: - Gestion des conditions
    
    /// Ajouter une nouvelle condition
    func addCondition(_ condition: DisplayCondition) {
        displayConditions.append(condition)
    }
    
    /// Supprimer une condition
    func removeCondition(at index: Int) {
        guard index >= 0 && index < displayConditions.count else { return }
        displayConditions.remove(at: index)
    }
    
    /// Activer/désactiver une condition
    func toggleCondition(at index: Int, isActive: Bool) {
        guard index >= 0 && index < displayConditions.count else { return }
        displayConditions[index].isActive = isActive
    }
    
    /// Éditer une condition
    func editCondition(at index: Int) {
        guard index >= 0 && index < displayConditions.count else { return }
        
        editingConditionIndex = index
        
        // Définir le type de sheet à afficher en fonction du type de condition
        switch displayConditions[index].type {
        case .timeRange:
            activeConditionSheet = .timeRange
        case .dayOfWeek:
            activeConditionSheet = .dayOfWeek
        case .location:
            activeConditionSheet = .location
        }
    }
    
    // MARK: - Méthodes pour créer de nouvelles conditions
    
    /// Ajouter une nouvelle condition de plage horaire
    func addTimeRangeCondition() {
        editingConditionIndex = nil
        activeConditionSheet = .timeRange
    }
    
    /// Ajouter une nouvelle condition de jour de la semaine
    func addDayOfWeekCondition() {
        editingConditionIndex = nil
        activeConditionSheet = .dayOfWeek
    }
    
    /// Ajouter une nouvelle condition de localisation
    func addLocationCondition() {
        editingConditionIndex = nil
        activeConditionSheet = .location
    }
    
    func closeConditionSheet() {
        activeConditionSheet = .none
        editingConditionIndex = nil
    }
    
    // MARK: - Méthodes pour mettre à jour des conditions existantes
    
    /// Mettre à jour une condition de plage horaire
    func updateTimeRangeCondition(at index: Int, timeRange: TimeRangeCondition) {
        guard index >= 0 && index < displayConditions.count else { return }
        
        var updatedCondition = displayConditions[index]
        updatedCondition.timeRange = timeRange
        displayConditions[index] = updatedCondition
    }
    
    /// Mettre à jour une condition de jour de la semaine
    func updateDayOfWeekCondition(at index: Int, dayOfWeek: DayOfWeekCondition) {
        guard index >= 0 && index < displayConditions.count else { return }
        
        var updatedCondition = displayConditions[index]
        updatedCondition.dayOfWeekCondition = dayOfWeek
        displayConditions[index] = updatedCondition
    }
    
    /// Mettre à jour une condition de localisation
    func updateLocationCondition(at index: Int, location: LocationCondition) {
        guard index >= 0 && index < displayConditions.count else { return }
        
        var updatedCondition = displayConditions[index]
        updatedCondition.locationCondition = location
        displayConditions[index] = updatedCondition
    }
    
    // MARK: - Méthodes pour sauvegarder les conditions
    
    /// Sauvegarder une condition de plage horaire
    func saveTimeRangeCondition(editingIndex: Int?, timeRangeCondition: TimeRangeCondition) {
        if let index = editingIndex {
            updateTimeRangeCondition(at: index, timeRange: timeRangeCondition)
        } else {
            let newCondition = DisplayCondition(
                type: .timeRange,
                isActive: true,
                timeRange: timeRangeCondition
            )
            addCondition(newCondition)
        }
        
        // Fermer le sheet
        closeConditionSheet()
    }
    
    /// Sauvegarder une condition de jour de la semaine
    func saveDayOfWeekCondition(editingIndex: Int?, dayOfWeekCondition: DayOfWeekCondition) {
        if let index = editingIndex {
            // Mettre à jour une condition existante
            updateDayOfWeekCondition(at: index, dayOfWeek: dayOfWeekCondition)
        } else {
            // Créer une nouvelle condition
            let newCondition = DisplayCondition(
                type: .dayOfWeek,
                isActive: true,
                dayOfWeekCondition: dayOfWeekCondition
            )
            addCondition(newCondition)
        }
        
        closeConditionSheet()
    }
    
    /// Passer à l'étape de configuration des conditions après le nommage
    func continueToConditions() {
        afterNamingStep = .configureConditions
    }
    
    // MARK: - Réinitialisation
    
    /// Réinitialiser le flux d'ajout
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
        displayConditions = []
        currentStep = .selectTransportMode
        afterNamingStep = .saveWithoutConditions
        favoriteCreated = false
    }
}
