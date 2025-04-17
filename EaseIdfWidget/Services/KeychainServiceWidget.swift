//
//  KeychainServiceWidget.swift
//  EaseIdfWidgetExtension
//
//  Created by Samuel DELIENS on 17/04/2025.
//

import Foundation
import Security

// Version simplifiée pour le widget (uniquement lecture de la clé API)
class KeychainServiceWidget {
    static let shared = KeychainServiceWidget()
    
    private init() {}
    
    // MARK: - Constants
    
    private let apiKeyAccount = KeychainConstants.apiKeyAccount
    private let service = KeychainConstants.service
    
    // MARK: - Public Methods
    
    /// Retrieve API key from Keychain - read-only for widget use
    func getAPIKey() -> String? {
        // Create query dictionary
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: apiKeyAccount,
            kSecAttrService as String: service,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        // Execute query
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        // Check status
        if status != errSecSuccess {
            // Fallback to shared UserDefaults for migration period
            if let sharedDefaults = UserDefaults(suiteName: KeychainConstants.appGroup),
               let legacyKey = sharedDefaults.string(forKey: KeychainConstants.SharedUserDefaults.apiKeyLegacy) {
                return legacyKey
            }
            return nil
        }
        
        // Convert data to string
        guard let data = dataTypeRef as? Data,
              let apiKey = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return apiKey
    }
}
