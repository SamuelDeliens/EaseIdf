//
//  ConditionService.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 20/04/2025.
//


import Foundation
import CoreLocation
import SwiftData

/// Service pour gérer les conditions d'affichage des favoris
class ConditionService {
    
    // MARK: - Propriétés
    
    private var locationService: LocationService
    
    // MARK: - Initialisation
    
    init(locationService: LocationService = LocationService.shared) {
        self.locationService = locationService
    }
    
    // MARK: - Méthodes publiques
    
    /// Évaluer si toutes les conditions pour un favori sont actuellement remplies
    func evaluateConditions(for favorite: TransportFavorite) -> Bool {
        // S'il n'y a pas de conditions, toujours afficher le favori
        if favorite.displayConditions.isEmpty {
            return true
        }
        
        // Si aucune condition n'est active, ignorer
        let activeConditions = favorite.displayConditions.filter { $0.isActive }
        if activeConditions.isEmpty {
            return true
        }
        
        // Toutes les conditions actives doivent être remplies
        for condition in activeConditions {
            if !evaluateCondition(condition) {
                return false
            }
        }
        
        return true
    }
    
    /// Obtenir une liste de favoris qui devraient être affichés selon les conditions actuelles
    func getCurrentlyActiveTransportFavorites(favorites: [TransportFavorite]) -> [TransportFavorite] {
        // Filtrer les favoris actifs selon les conditions et trier par priorité
        let activeAndSortedFavorites = favorites
            .filter { evaluateConditions(for: $0) }
            .sorted { $0.priority > $1.priority } // Trier par priorité (plus grand en premier)
        
        return activeAndSortedFavorites
    }
    
    // MARK: - Méthodes privées
    
    /// Évaluer une condition individuelle
    private func evaluateCondition(_ condition: DisplayCondition) -> Bool {
        switch condition.type {
        case .timeRange:
            return evaluateTimeRangeCondition(condition.timeRange)
            
        case .dayOfWeek:
            return evaluateDayOfWeekCondition(condition.dayOfWeekCondition)
            
        case .location:
            return evaluateLocationCondition(condition.locationCondition)
        }
    }
    
    /// Évaluer une condition de plage horaire
    private func evaluateTimeRangeCondition(_ condition: TimeRangeCondition?) -> Bool {
        guard let condition = condition else {
            return false
        }
        
        let now = Date()
        
        // Récupérer uniquement les composants de temps
        let calendar = Calendar.current
        let nowComponents = calendar.dateComponents([.hour, .minute], from: now)
        let startComponents = calendar.dateComponents([.hour, .minute], from: condition.startTime)
        let endComponents = calendar.dateComponents([.hour, .minute], from: condition.endTime)
        
        // Créer des heures de comparaison pour aujourd'hui
        let today = calendar.startOfDay(for: now)
        
        guard let startTime = calendar.date(bySettingHour: startComponents.hour ?? 0, 
                                           minute: startComponents.minute ?? 0, 
                                           second: 0, 
                                           of: today),
              let endTime = calendar.date(bySettingHour: endComponents.hour ?? 0, 
                                         minute: endComponents.minute ?? 0, 
                                         second: 0, 
                                         of: today),
              let currentTime = calendar.date(bySettingHour: nowComponents.hour ?? 0, 
                                             minute: nowComponents.minute ?? 0, 
                                             second: 0, 
                                             of: today) else {
            return false
        }
        
        // Gérer le cas où l'heure de fin est antérieure à l'heure de début (s'étend sur minuit)
        if endTime < startTime {
            return currentTime >= startTime || currentTime <= endTime
        } else {
            return currentTime >= startTime && currentTime <= endTime
        }
    }
    
    /// Évaluer une condition de jour de la semaine
    private func evaluateDayOfWeekCondition(_ condition: DayOfWeekCondition?) -> Bool {
        guard let condition = condition else {
            return false
        }
        
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        
        // Convertir le jour de la semaine du calendrier (1 = dimanche) à notre enum Weekday
        guard let today = Weekday(rawValue: weekday) else {
            return false
        }
        
        return condition.days.contains(today)
    }
    
    /// Évaluer une condition de localisation
    private func evaluateLocationCondition(_ condition: LocationCondition?) -> Bool {
        guard let condition = condition else {
            return false
        }
        
        return locationService.isLocation(
            condition.coordinates, 
            withinRadius: condition.radius
        )
    }
    
    // MARK: - Méthodes de création et de mise à jour des conditions
    
    /// Créer une nouvelle condition de plage horaire avec des valeurs par défaut
    func createDefaultTimeRangeCondition() -> TimeRangeCondition {
        let calendar = Calendar.current
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: Date())
        
        // Par défaut, 8h-10h du matin
        dateComponents.hour = 8
        dateComponents.minute = 0
        let startTime = calendar.date(from: dateComponents) ?? Date()
        
        dateComponents.hour = 10
        dateComponents.minute = 0
        let endTime = calendar.date(from: dateComponents) ?? Date()
        
        return TimeRangeCondition(
            startTime: startTime,
            endTime: endTime
        )
    }
    
    /// Créer une nouvelle condition de jour de la semaine avec des valeurs par défaut
    func createDefaultDayOfWeekCondition() -> DayOfWeekCondition {
        // Par défaut, jours de semaine (lundi-vendredi)
        return DayOfWeekCondition(
            days: [.monday, .tuesday, .wednesday, .thursday, .friday]
        )
    }
    
    /// Créer une nouvelle condition de localisation avec des valeurs par défaut
    func createDefaultLocationCondition() -> LocationCondition? {
        // Utiliser la position actuelle si disponible
        if let currentLocation = locationService.currentLocation?.coordinate {
            return LocationCondition(
                coordinates: Coordinates(
                    latitude: currentLocation.latitude,
                    longitude: currentLocation.longitude
                ),
                radius: 200 // 200 mètres par défaut
            )
        }
        return nil
    }
    
    /// Créer une condition complète à partir d'un type donné
    func createCondition(ofType type: ConditionType) -> DisplayCondition? {
        var condition = DisplayCondition(type: type, isActive: true)
        
        switch type {
        case .timeRange:
            condition.timeRange = createDefaultTimeRangeCondition()
            
        case .dayOfWeek:
            condition.dayOfWeekCondition = createDefaultDayOfWeekCondition()
            
        case .location:
            if let locationCondition = createDefaultLocationCondition() {
                condition.locationCondition = locationCondition
            } else {
                return nil
            }
        }
        
        return condition
    }
    
    /// Convertir une liste de DisplayConditionModel en DisplayCondition
    func convertToDisplayConditions(_ models: [DisplayConditionModel]) -> [DisplayCondition] {
        return models.map { $0.toStruct() }
    }
    
    /// Convertir une liste de DisplayCondition en DisplayConditionModel
    func convertToDisplayConditionModels(_ conditions: [DisplayCondition]) -> [DisplayConditionModel] {
        return conditions.map { DisplayConditionModel.fromStruct($0) }
    }
    
    /// Descriptif textuel d'une condition pour l'affichage dans l'UI
    func getConditionDescription(_ condition: DisplayCondition) -> String {
        switch condition.type {
        case .timeRange:
            guard let timeRange = condition.timeRange else {
                return "Horaire non configuré"
            }
            
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            
            let startTime = formatter.string(from: timeRange.startTime)
            let endTime = formatter.string(from: timeRange.endTime)
            
            return "Entre \(startTime) et \(endTime)"
            
        case .dayOfWeek:
            guard let dayCondition = condition.dayOfWeekCondition, !dayCondition.days.isEmpty else {
                return "Jours non configurés"
            }
            
            let dayNames = dayCondition.days.map { getDayName($0) }.joined(separator: ", ")
            return "Les jours suivants : \(dayNames)"
            
        case .location:
            guard let locationCondition = condition.locationCondition else {
                return "Position non configurée"
            }
            
            return "Dans un rayon de \(Int(locationCondition.radius))m autour de la position définie"
        }
    }
    
    /// Obtenir le nom du jour de la semaine
    private func getDayName(_ day: Weekday) -> String {
        switch day {
        case .monday: return "Lundi"
        case .tuesday: return "Mardi"
        case .wednesday: return "Mercredi"
        case .thursday: return "Jeudi"
        case .friday: return "Vendredi"
        case .saturday: return "Samedi"
        case .sunday: return "Dimanche"
        }
    }
}
