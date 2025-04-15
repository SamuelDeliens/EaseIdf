//
//  LocationService.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 14/04/2025.
//

import Foundation
import CoreLocation
import Combine

class LocationService: NSObject {
    static let shared = LocationService()
    
    private let locationManager = CLLocationManager()
    private var locationUpdateTimer: Timer?
    
    // Publishers
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var locationError: Error?
    
    private override init() {
        super.init()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters // Sufficient for our needs
    }
    
    // MARK: - Public Methods
    
    /// Request location permissions
    func requestAuthorization() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            // Informer l'utilisateur que les autorisations sont nécessaires
            locationError = NSError(
                domain: "LocationServiceError",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "L'accès à la localisation est nécessaire pour afficher les transports à proximité."]
            )
        case .authorizedWhenInUse, .authorizedAlways:
            // Déjà autorisé, commencer les mises à jour
            locationManager.startUpdatingLocation()
        @unknown default:
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    /// Start location updates with a specified interval
    func startLocationUpdates(interval: TimeInterval = 60) {
        locationManager.startUpdatingLocation()
        
        // Set up a timer to periodically fetch location
        locationUpdateTimer?.invalidate()
        locationUpdateTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.locationManager.requestLocation()
        }
    }
    
    /// Stop location updates
    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
        locationUpdateTimer?.invalidate()
    }
    
    /// Check if a location is within a specified radius of a point
    func isLocation(_ targetCoordinates: Coordinates, withinRadius radius: Double) -> Bool {
        guard let currentLocation = currentLocation else {
            return false
        }
        
        let targetLocation = CLLocation(
            latitude: targetCoordinates.latitude,
            longitude: targetCoordinates.longitude
        )
        
        let distance = currentLocation.distance(from: targetLocation)
        return distance <= radius
    }
    
    /// Calculate distance between current location and specified coordinates
    func distanceToLocation(_ targetCoordinates: Coordinates) -> Double? {
        guard let currentLocation = currentLocation else {
            return nil
        }
        
        let targetLocation = CLLocation(
            latitude: targetCoordinates.latitude,
            longitude: targetCoordinates.longitude
        )
        
        return currentLocation.distance(from: targetLocation)
    }
    
    /// Check if location services are available and enabled
    var isLocationAvailable: Bool {
        return CLLocationManager.locationServicesEnabled() && 
               (authorizationStatus == .authorizedWhenInUse || 
                authorizationStatus == .authorizedAlways)
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationService: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        
        if manager.authorizationStatus == .authorizedWhenInUse || 
           manager.authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            currentLocation = location
            locationError = nil
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationError = error
    }
}
