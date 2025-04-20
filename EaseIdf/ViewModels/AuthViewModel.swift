//
//  AuthViewModel.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 14/04/2025.
//


import Foundation
import Combine

/// ViewModel pour la gestion de l'authentification
class AuthViewModel: BaseViewModel {
    // MARK: - État de l'authentification
    
    @Published var isAuthenticated = false
    @Published var isValidating = false
    @Published var showError = false
    @Published var apiKey: String = ""
    
    // MARK: - Service d'authentification
    
    private let authService: AuthenticationService
    
    // MARK: - Initialisation
    
    init(authService: AuthenticationService = AuthenticationService.shared) {
        self.authService = authService
        
        super.init()
        
        // Vérifier l'état d'authentification initial
        isAuthenticated = authService.isAuthenticated()
        
        // Charger la clé API stockée si disponible
        if let key = authService.getApiKey() {
            apiKey = key
        }
        
        // S'abonner aux changements de statut d'authentification
        subscribeToAuthChanges()
    }
    
    /// S'abonner aux changements de statut d'authentification
    private func subscribeToAuthChanges() {
        authService.$authStatus
            .sink { [weak self] status in
                DispatchQueue.main.async {
                    self?.isAuthenticated = status == .authenticated
                    self?.isValidating = status == .validating
                    self?.showError = status == .invalid
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Actions d'authentification
    
    /// Valider la clé API
    func validateApiKey() async {
        DispatchQueue.main.async {
            self.isValidating = true
            self.showError = false
        }
        
        let isValid = await authService.saveAndValidateApiKey(apiKey)
        
        DispatchQueue.main.async {
            self.isValidating = false
            self.isAuthenticated = isValid
            self.showError = !isValid
        }
    }
    
    /// Déconnexion
    func signOut() {
        authService.signOut()
        isAuthenticated = false
        apiKey = ""
    }
}
