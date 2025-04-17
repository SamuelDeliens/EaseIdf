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
    var refreshInterval: TimeInterval = 300 // 5 minutes par défaut pour les requêtes serveur
    var visualRefreshInterval: TimeInterval = 60 // 1 minute fixe pour les updates visuelles
    var showOnlyUpcomingDepartures: Bool = true
    var numberOfDeparturesToShow: Int = 3
    var lastAppLaunch: Date = Date()
    var isRefreshPaused: Bool = false
    
    // Nouvelle propriété pour suivre la dernière mise à jour de données complète
    var lastFullDataRefresh: Date?
}
