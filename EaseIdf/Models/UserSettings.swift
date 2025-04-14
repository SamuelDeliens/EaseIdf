//
//  UserSettings.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 14/04/2025.
//

import Foundation

struct UserSettings: Codable {
    var favorites: [TransportFavorite]
    var apiKey: String?
    var refreshInterval: TimeInterval = 60 // Secondes
    var showOnlyUpcomingDepartures: Bool = true
    var numberOfDeparturesToShow: Int = 3
}
