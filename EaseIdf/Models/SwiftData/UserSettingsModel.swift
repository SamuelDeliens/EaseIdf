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
    // ApiKey is no longer stored in SwiftData
    var refreshInterval: Double
    var visualRefreshInterval: Double
    var showOnlyUpcomingDepartures: Bool
    var numberOfDeparturesToShow: Int
    var lastAppLaunch: Date
    var lastFullDataRefresh: Date?
    
    init(
        refreshInterval: Double = 300.0,
        visualRefreshInterval: Double = 60.0,
        showOnlyUpcomingDepartures: Bool = true,
        numberOfDeparturesToShow: Int = 3,
        lastAppLaunch: Date = Date(),
        lastFullDataRefresh: Date? = nil
    ) {
        self.refreshInterval = refreshInterval
        self.visualRefreshInterval = visualRefreshInterval
        self.showOnlyUpcomingDepartures = showOnlyUpcomingDepartures
        self.numberOfDeparturesToShow = numberOfDeparturesToShow
        self.lastAppLaunch = lastAppLaunch
        self.lastFullDataRefresh = lastFullDataRefresh
    }
    
    // Convert to struct format
    func toStruct() -> UserSettings {
        return UserSettings(
            favorites: [], // Favorites are handled separately via PersistenceService
            apiKey: KeychainService.shared.getAPIKey(), // Get API key from Keychain instead
            refreshInterval: refreshInterval,
            visualRefreshInterval: visualRefreshInterval,
            showOnlyUpcomingDepartures: showOnlyUpcomingDepartures,
            numberOfDeparturesToShow: numberOfDeparturesToShow,
            lastAppLaunch: lastAppLaunch,
            lastFullDataRefresh: lastFullDataRefresh
        )
    }
    
    // Create from struct
    static func fromStruct(_ settings: UserSettings) -> UserSettingsModel {
        return UserSettingsModel(
            refreshInterval: settings.refreshInterval,
            visualRefreshInterval: settings.visualRefreshInterval,
            showOnlyUpcomingDepartures: settings.showOnlyUpcomingDepartures,
            numberOfDeparturesToShow: settings.numberOfDeparturesToShow,
            lastAppLaunch: settings.lastAppLaunch,
            lastFullDataRefresh: settings.lastFullDataRefresh
        )
    }
}
