//
//  DisplayConditionModel.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 14/04/2025.
//

import Foundation
import SwiftData

@Model
final class DisplayConditionModel {
    var id: UUID
    var conditionType: String // "timeRange", "dayOfWeek", "location"
    var isActive: Bool
    
    // Time range condition data
    var startTime: Date?
    var endTime: Date?
    
    // Day of week condition data - stored as comma-separated string of integers
    var dayOfWeekData: String?
    
    // Location condition data
    var latitude: Double?
    var longitude: Double?
    var radius: Double?
    
    init(
        id: UUID = UUID(),
        conditionType: String,
        isActive: Bool = true,
        startTime: Date? = nil,
        endTime: Date? = nil,
        dayOfWeekData: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        radius: Double? = nil
    ) {
        self.id = id
        self.conditionType = conditionType
        self.isActive = isActive
        self.startTime = startTime
        self.endTime = endTime
        self.dayOfWeekData = dayOfWeekData
        self.latitude = latitude
        self.longitude = longitude
        self.radius = radius
    }
    
    // Convert to struct format for use with other services
    func toStruct() -> DisplayCondition {
        let type = ConditionType(rawValue: conditionType) ?? .timeRange
        var displayCondition = DisplayCondition(type: type, isActive: isActive)
        
        switch type {
        case .timeRange:
            if let start = startTime, let end = endTime {
                displayCondition.timeRange = TimeRangeCondition(startTime: start, endTime: end)
            }
            
        case .dayOfWeek:
            if let dayData = dayOfWeekData {
                let dayIds = dayData.components(separatedBy: ",")
                    .compactMap { Int($0) }
                    .compactMap { Weekday(rawValue: $0) }
                displayCondition.dayOfWeekCondition = DayOfWeekCondition(days: dayIds)
            }
            
        case .location:
            if let lat = latitude, let long = longitude, let rad = radius {
                let coordinates = Coordinates(latitude: lat, longitude: long)
                displayCondition.locationCondition = LocationCondition(coordinates: coordinates, radius: rad)
            }
        }
        
        return displayCondition
    }
    
    // Create from struct
    static func fromStruct(_ condition: DisplayCondition) -> DisplayConditionModel {
        let model = DisplayConditionModel(
            id: condition.id,
            conditionType: condition.type.rawValue,
            isActive: condition.isActive
        )
        
        // Set specific condition data based on type
        switch condition.type {
        case .timeRange:
            if let timeRange = condition.timeRange {
                model.startTime = timeRange.startTime
                model.endTime = timeRange.endTime
            }
            
        case .dayOfWeek:
            if let dayOfWeekCondition = condition.dayOfWeekCondition {
                let dayIds = dayOfWeekCondition.days.map { String($0.rawValue) }.joined(separator: ",")
                model.dayOfWeekData = dayIds
            }
            
        case .location:
            if let locationCondition = condition.locationCondition {
                model.latitude = locationCondition.coordinates.latitude
                model.longitude = locationCondition.coordinates.longitude
                model.radius = locationCondition.radius
            }
        }
        
        return model
    }
}
