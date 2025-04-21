import Foundation
import SwiftData
import Combine

/// Gestionnaire d'état centralisé pour l'application
class AppStateManager: ObservableObject {
    // MARK: - États partagés
    
    // État d'authentification
    @Published var isAuthenticated: Bool = false
    @Published var isApiKeyValidating: Bool = false
    
    // État de l'application
    @Published var isDataLoaded: Bool = false
    @Published var isOfflineMode: Bool = false
    @Published var lastRefreshTime: Date = Date()
    
    // État de la localisation
    @Published var isLocationAvailable: Bool = false
    @Published var currentCoordinates: Coordinates?
    
    // État du mode d'édition
    @Published var isEditingFavorites: Bool = false
    
    // MARK: - Services partagés
    private let authService: AuthenticationService
    private let favoriteService: FavoriteService
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Singleton
    static let shared = AppStateManager()
    
    private init() {
        // Initialiser les services
        self.authService = AppServices.shared.authService
        self.favoriteService = AppServices.shared.favoriteService
        
        // Vérifier l'état d'authentification initial
        self.isAuthenticated = authService.isAuthenticated()
        
        // S'abonner aux changements d'état d'authentification
        setupSubscriptions()
        
        // Vérifier l'état de la localisation
        checkLocationStatus()
    }
    
    // MARK: - Configuration
    private func setupSubscriptions() {
        // Observer les changements d'authentification
        authService.$authStatus
            .sink { [weak self] status in
                self?.isAuthenticated = status == .authenticated
                self?.isApiKeyValidating = status == .validating
            }
            .store(in: &cancellables)
        
        // Observer les changements de localisation
        LocationService.shared.$currentLocation
            .sink { [weak self] location in
                if let location = location {
                    self?.isLocationAvailable = true
                    self?.currentCoordinates = Coordinates(
                        latitude: location.coordinate.latitude,
                        longitude: location.coordinate.longitude
                    )
                } else {
                    self?.isLocationAvailable = false
                    self?.currentCoordinates = nil
                }
            }
            .store(in: &cancellables)
        
        // Observer le dernier refresh des données
        NotificationCenter.default.publisher(for: .refreshDataCompleted)
            .sink { [weak self] _ in
                self?.lastRefreshTime = Date()
            }
            .store(in: &cancellables)
    }
    
    private func checkLocationStatus() {
        isLocationAvailable = LocationService.shared.isLocationAvailable
        if let location = LocationService.shared.currentLocation {
            currentCoordinates = Coordinates(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
        }
    }
    
    // MARK: - Actions d'authentification
    
    /// Valider la clé API
    func validateApiKey(_ key: String) async -> Bool {
        return await authService.saveAndValidateApiKey(key)
    }
    
    /// Déconnexion
    func signOut() {
        authService.signOut()
    }
    
    // MARK: - Actions de données
    
    /// Déclencher un rafraîchissement des données
    func refreshData() {
        favoriteService.refreshDepartures()
        NotificationCenter.default.post(name: .refreshDataStarted, object: nil)
    }
    
    /// Basculer le mode d'édition des favoris
    func toggleEditMode() {
        isEditingFavorites.toggle()
    }
}

// Extension pour définir des notifications personnalisées
extension Notification.Name {
    static let refreshDataStarted = Notification.Name("refreshDataStarted")
    static let refreshDataCompleted = Notification.Name("refreshDataCompleted")
    static let favoritesChanged = Notification.Name("favoritesChanged")
    static let settingsChanged = Notification.Name("settingsChanged")
}