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
        
        // Subscribe to auth status changes
        AuthenticationService.shared.$authStatus
            .sink { [weak self] status in
                DispatchQueue.main.async {
                    self?.isAuthenticated = status == .authenticated
                    self?.isValidating = status == .validating
                    self?.showError = status == .invalid
                }
            }
            .store(in: &cancellables)
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
        apiKey = ""
    }
}
