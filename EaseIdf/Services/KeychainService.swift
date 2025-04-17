//
//  KeychainService.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 17/04/2025.
//


import Foundation
import Security

class KeychainService {
    static let shared = KeychainService()
    
    private init() {}
    
    // MARK: - Constants
    
    private let apiKeyAccount = KeychainConstants.apiKeyAccount
    private let service = KeychainConstants.service
    
    // MARK: - Public Methods
    
    /// Save API key to Keychain
    func saveAPIKey(_ apiKey: String) -> Bool {
        // Convert string to data
        guard let apiKeyData = apiKey.data(using: .utf8) else {
            print("Error converting API key to Data")
            return false
        }
        
        // Create query dictionary
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: apiKeyAccount,
            kSecAttrService as String: service,
            kSecValueData as String: apiKeyData
        ]
        
        // First try to update existing key
        var status = SecItemUpdate(query as CFDictionary, [kSecValueData as String: apiKeyData] as CFDictionary)
        
        // If the key doesn't exist yet, add it
        if status == errSecItemNotFound {
            // Add accessibility attribute for new items
            query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
            status = SecItemAdd(query as CFDictionary, nil)
        }
        
        // Check status
        if status != errSecSuccess {
            print("Error saving API key to Keychain: \(status)")
            return false
        }
        
        return true
    }
    
    /// Retrieve API key from Keychain
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
            // Don't print for ItemNotFound as this is an expected state
            if status != errSecItemNotFound {
                print("Error retrieving API key from Keychain: \(status)")
            }
            return nil
        }
        
        // Convert data to string
        guard let data = dataTypeRef as? Data,
              let apiKey = String(data: data, encoding: .utf8) else {
            print("Error converting retrieved API key to String")
            return nil
        }
        
        return apiKey
    }
    
    /// Delete API key from Keychain
    func deleteAPIKey() -> Bool {
        // Create query dictionary
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: apiKeyAccount,
            kSecAttrService as String: service
        ]
        
        // Execute delete
        let status = SecItemDelete(query as CFDictionary)
        
        // Check status
        if status != errSecSuccess && status != errSecItemNotFound {
            print("Error deleting API key from Keychain: \(status)")
            return false
        }
        
        return true
    }
}
