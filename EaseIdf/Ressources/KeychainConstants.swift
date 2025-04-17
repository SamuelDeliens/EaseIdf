//
//  KeychainConstants.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 17/04/2025.
//


import Foundation

// Fichier à partager entre l'application principale et l'extension widget
struct KeychainConstants {
    static let apiKeyAccount = "com.samueldeliens.EaseIdf.apiKey"
    static let service = "com.samueldeliens.EaseIdf"
    static let appGroup = "group.com.samueldeliens.EaseIdf"
    
    // Clés pour UserDefaults partagé
    struct SharedUserDefaults {
        static let apiKeyLegacy = "IDFMobilite_ApiKey"
        static let widgetData = "widgetData"
        static let widgetRefreshInterval = "widgetRefreshInterval"
    }
}
