//
//  DisplayCondition.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 14/04/2025.
//

import Foundation

struct DisplayCondition: Identifiable, Codable {
    let id: UUID = UUID()
    let type: ConditionType
    var isActive: Bool = true
    
    // Union des différents types de conditions possibles
    var timeRange: TimeRangeCondition?
    var dayOfWeekCondition: DayOfWeekCondition?
    var locationCondition: LocationCondition?
}

enum ConditionType: String, Codable {
    case timeRange
    case dayOfWeek
    case location
}

struct TimeRangeCondition: Codable {
    var startTime: Date
    var endTime: Date
}

struct DayOfWeekCondition: Codable {
    var days: [Weekday]
}

enum Weekday: Int, Codable, CaseIterable, Hashable {
    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday
}

struct LocationCondition: Codable {
    var coordinates: Coordinates
    var radius: Double // en mètres
}
