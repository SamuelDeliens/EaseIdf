//
//  UserSettingsModel.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 14/04/2025.
//

import Foundation
import SwiftData

@Model
final class UserSettingsModel {
    var apiKey: String?
    var refreshInterval: Double
    var showOnlyUpcomingDepartures: Bool
    var numberOfDeparturesToShow: Int
    
    init(
        apiKey: String? = nil,
        refreshInterval: Double = 60.0,
        showOnlyUpcomingDepartures: Bool = true,
        numberOfDeparturesToShow: Int = 3
    ) {
        self.apiKey = apiKey
        self.refreshInterval = refreshInterval
        self.showOnlyUpcomingDepartures = showOnlyUpcomingDepartures
        self.numberOfDeparturesToShow = numberOfDeparturesToShow
    }
    
    // Convert to struct format
    func toStruct() -> UserSettings {
        return UserSettings(
            favorites: [], // Favorites are handled separately via PersistenceService
            apiKey: apiKey,
            refreshInterval: refreshInterval,
            showOnlyUpcomingDepartures: showOnlyUpcomingDepartures,
            numberOfDeparturesToShow: numberOfDeparturesToShow
        )
    }
    
    // Create from struct
    static func fromStruct(_ settings: UserSettings) -> UserSettingsModel {
        return UserSettingsModel(
            apiKey: settings.apiKey,
            refreshInterval: settings.refreshInterval,
            showOnlyUpcomingDepartures: settings.showOnlyUpcomingDepartures,
            numberOfDeparturesToShow: settings.numberOfDeparturesToShow
        )
    }
}
