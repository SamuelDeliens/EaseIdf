//
//  BaseViewModel.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 20/04/2025.
//


import Foundation
import SwiftData
import Combine

/// ViewModel de base fournissant des fonctionnalités communes à tous les ViewModels
class BaseViewModel: ObservableObject {
    // MARK: - Propriétés
    
    // Contexte SwiftData
    var modelContext: ModelContext?
    
    // Gestion d'état commun
    @Published var isLoading = false
    @Published var error: Error?
    @Published var showAlert = false
    @Published var alertMessage = ""
    
    // Stockage des souscriptions pour éviter les fuites de mémoire
    var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialisation
    
    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
    }
    
    // MARK: - Méthodes publiques
    
    /// Définit le ModelContext pour ce ViewModel
    func setModelContext(_ context: ModelContext?) {
        self.modelContext = context
    }
    
    /// Afficher une alerte
    func showAlert(message: String) {
        self.alertMessage = message
        self.showAlert = true
    }
    
    /// Afficher une erreur
    func showError(_ error: Error) {
        self.error = error
        self.alertMessage = error.localizedDescription
        self.showAlert = true
    }
    
    /// Démarrer le chargement
    func startLoading() {
        DispatchQueue.main.async {
            self.isLoading = true
        }
    }
    
    /// Arrêter le chargement
    func stopLoading() {
        DispatchQueue.main.async {
            self.isLoading = false
        }
    }
    
    /// Exécuter une tâche avec gestion automatique de l'état de chargement
    func performTask<T>(_ task: () async throws -> T) async -> T? {
        await MainActor.run {
            self.startLoading()
        }
        
        do {
            let result = try await task()
            
            await MainActor.run {
                self.stopLoading()
            }
            
            return result
        } catch {
            await MainActor.run {
                self.stopLoading()
                self.showError(error)
            }
            return nil
        }
    }
    
    // MARK: - Helpers pour SwiftData
    
    /// Exécuter une fonction SwiftData et gérer les erreurs
    func performModelAction<T>(_ action: (ModelContext) throws -> T) -> T? {
        guard let context = modelContext else {
            showAlert(message: "Erreur: le contexte SwiftData n'est pas disponible")
            return nil
        }
        
        do {
            return try action(context)
        } catch {
            showError(error)
            return nil
        }
    }
    
    /// Sauvegarder les modifications du contexte
    func saveContext() {
        guard let context = modelContext else { return }
        
        do {
            try context.save()
        } catch {
            showError(error)
        }
    }
}
