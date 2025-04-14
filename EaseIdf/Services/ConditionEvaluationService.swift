//
//  ConditionEvaluationService.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 14/04/2025.
//

import Foundation
import CoreLocation

class ConditionEvaluationService {
    static let shared = ConditionEvaluationService()
    
    private init() {}
        
    /// Evaluate if all conditions for a favorite are currently met
    func evaluateConditions(for favorite: TransportFavorite) -> Bool {
        // If there are no conditions, always show the favorite
        if favorite.displayConditions.isEmpty {
            return true
        }
        
        // If any condition is not active, ignore it
        let activeConditions = favorite.displayConditions.filter { $0.isActive }
        if activeConditions.isEmpty {
            return true
        }
        
        // All active conditions must be met
        for condition in activeConditions {
            if !evaluateCondition(condition) {
                return false
            }
        }
        
        return true
    }
    
    /// Get a list of favorites that should be displayed based on current conditions
    func getCurrentlyActiveTransportFavorites() -> [TransportFavorite] {
        let allFavorites = StorageService.shared.getUserSettings().favorites
        
        let activeAndSortedFavorites = allFavorites
            .filter { evaluateConditions(for: $0) }
            .sorted { $0.priority > $1.priority } // Sort by priority (higher first)
        
        return activeAndSortedFavorites
    }
    
    // MARK: - Private Methods
    
    /// Evaluate a single condition
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
    
    private func evaluateTimeRangeCondition(_ condition: TimeRangeCondition?) -> Bool {
        guard let condition = condition else {
            return false
        }
        
        let now = Date()
        
        // Get just the time components
        let calendar = Calendar.current
        let nowComponents = calendar.dateComponents([.hour, .minute], from: now)
        let startComponents = calendar.dateComponents([.hour, .minute], from: condition.startTime)
        let endComponents = calendar.dateComponents([.hour, .minute], from: condition.endTime)
        
        // Create comparison times for today
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
        
        // Handle the case where end time is earlier than start time (spans midnight)
        if endTime < startTime {
            return currentTime >= startTime || currentTime <= endTime
        } else {
            return currentTime >= startTime && currentTime <= endTime
        }
    }
    
    private func evaluateDayOfWeekCondition(_ condition: DayOfWeekCondition?) -> Bool {
        guard let condition = condition else {
            return false
        }
        
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        
        // Convert from Calendar's weekday (1 = Sunday) to our Weekday enum
        guard let today = Weekday(rawValue: weekday) else {
            return false
        }
        
        return condition.days.contains(today)
    }
    
    private func evaluateLocationCondition(_ condition: LocationCondition?) -> Bool {
        guard let condition = condition else {
            return false
        }
        
        return LocationService.shared.isLocation(
            condition.coordinates, 
            withinRadius: condition.radius
        )
    }
}
