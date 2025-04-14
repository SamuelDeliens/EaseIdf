//
//  AuthentificationService.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 14/04/2025.
//

import Foundation
import Combine

enum AuthenticationStatus {
    case unauthenticated
    case authenticated
    case validating
    case invalid
}

class AuthenticationService {
    static let shared = AuthenticationService()
    
    private init() {
        // Check if we have a stored API key
        if let savedApiKey = UserDefaults.standard.string(forKey: "IDFMobilite_ApiKey") {
            apiKey = savedApiKey
            authStatus = .authenticated
        } else {
            authStatus = .unauthenticated
        }
    }
    
    // Properties
    @Published private(set) var authStatus: AuthenticationStatus = .unauthenticated
    private var apiKey: String?
    
    // MARK: - Public Methods
    
    /// Save the API key and validate it
    func saveAndValidateApiKey(_ key: String) async -> Bool {
        self.apiKey = key
        self.authStatus = .validating
        
        let isValid = await validateApiKey(key)
        
        if isValid {
            UserDefaults.standard.set(key, forKey: "IDFMobilite_ApiKey")
            self.authStatus = .authenticated
        } else {
            self.authStatus = .invalid
        }
        
        return isValid
    }
    
    /// Get the stored API key
    func getApiKey() -> String? {
        return apiKey
    }
    
    /// Sign out the user by removing the API key
    func signOut() {
        apiKey = nil
        UserDefaults.standard.removeObject(forKey: "IDFMobilite_ApiKey")
        authStatus = .unauthenticated
    }
    
    /// Check if user is authenticated
    func isAuthenticated() -> Bool {
        return authStatus == .authenticated
    }
    
    // MARK: - Private Methods
    
    /// Validate the API key with a simple API call
    private func validateApiKey(_ key: String) async -> Bool {
        let urlString = "https://prim.iledefrance-mobilites.fr/marketplace/stop-monitoring"
        let queryItems = [URLQueryItem(name: "MonitoringRef", value: "STIF:StopPoint:Q:473921:")]
        
        guard var components = URLComponents(string: urlString) else {
            return false
        }
        
        components.queryItems = queryItems
        
        guard let url = components.url else {
            return false
        }
        
        var request = URLRequest(url: url)
        request.addValue(key, forHTTPHeaderField: "apikey")
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                // Consider 401 or 403 as invalid API key
                if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                    return false
                }
                
                // Any 2xx status code indicates a valid key
                return (200...299).contains(httpResponse.statusCode)
            }
            
            return false
        } catch {
            return false
        }
    }
}
