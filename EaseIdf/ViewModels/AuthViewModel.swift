//
//  AuthViewModel.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 14/04/2025.
//

import Foundation
import Combine

class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isValidating = false
    @Published var showError = false
    @Published var apiKey: String = ""
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        isAuthenticated = AuthenticationService.shared.isAuthenticated()
        
        // Load stored API key if available
        if let key = AuthenticationService.shared.getApiKey() {
            apiKey = key
        }
    }
    
    func validateApiKey() async {
        DispatchQueue.main.async {
            self.isValidating = true
            self.showError = false
        }
        
        let isValid = await AuthenticationService.shared.saveAndValidateApiKey(apiKey)
        
        DispatchQueue.main.async {
            self.isValidating = false
            self.isAuthenticated = isValid
            self.showError = !isValid
        }
    }
    
    func signOut() {
        AuthenticationService.shared.signOut()
        isAuthenticated = false
    }
}
