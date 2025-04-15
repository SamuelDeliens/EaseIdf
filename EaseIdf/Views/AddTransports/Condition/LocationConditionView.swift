//
//  LocationConditionView.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 15/04/2025.
//

import SwiftUI
import CoreLocation
import MapKit

struct StopAnnotation: Identifiable {
    let id: String
    let name: String
    let coordinate: CLLocationCoordinate2D
    var isSelected: Bool
}

struct LocationConditionView: View {
    @ObservedObject var viewModel: AddTransportViewModel
    
    // Pour l'édition d'une condition existante
    var editingIndex: Int?
    
    @State private var locationName: String = ""
    @State private var radius: Double = 200
    @State private var selectedLocation: CLLocationCoordinate2D?
    @State private var isUsingCurrentLocation: Bool = true
    @State private var isMapVisible: Bool = false
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522), // Paris
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    // Pour afficher les arrêts
    @State private var stopAnnotations: [StopAnnotation] = []
    
    init(viewModel: AddTransportViewModel, editingIndex: Int? = nil) {
        self.viewModel = viewModel
        self.editingIndex = editingIndex
        
        // Initialiser avec les valeurs existantes ou des valeurs par défaut
        if let index = editingIndex,
           index < viewModel.displayConditions.count,
           let locationCondition = viewModel.displayConditions[index].locationCondition {
            _radius = State(initialValue: locationCondition.radius)
            _selectedLocation = State(initialValue: CLLocationCoordinate2D(
                latitude: locationCondition.coordinates.latitude,
                longitude: locationCondition.coordinates.longitude
            ))
            _isUsingCurrentLocation = State(initialValue: false)
            
            // Si on édite et qu'on a des coordonnées, centrer la carte sur ces coordonnées
            _region = State(initialValue: MKCoordinateRegion(
                center: CLLocationCoordinate2D(
                    latitude: locationCondition.coordinates.latitude,
                    longitude: locationCondition.coordinates.longitude
                ),
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            ))
        } else if let stop = viewModel.selectedStop {
            // Par défaut, utiliser l'arrêt sélectionné comme position
            _locationName = State(initialValue: stop.name_stop)
            
            // Obtenir les coordonnées de l'arrêt
            let stopLatitude = stop.latitude
            let stopLongitude = stop.longitude
            
            _selectedLocation = State(initialValue: CLLocationCoordinate2D(
                latitude: stopLatitude,
                longitude: stopLongitude
            ))
            
            _isUsingCurrentLocation = State(initialValue: false)
            
            // Centrer la carte sur l'arrêt
            _region = State(initialValue: MKCoordinateRegion(
                center: CLLocationCoordinate2D(
                    latitude: stopLatitude,
                    longitude: stopLongitude
                ),
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            ))
        }
    }
    
    var body: some View {
        Form {
            Section(header: Text("Emplacement")) {
                Toggle("Utiliser ma position actuelle", isOn: $isUsingCurrentLocation)
                    .onChange(of: isUsingCurrentLocation) { isCurrentLocation in
                        if isCurrentLocation {
                            useCurrentLocation()
                        } else if let stop = viewModel.selectedStop {
                            // Revenir à l'arrêt sélectionné
                            locationName = stop.name_stop
                            selectedLocation = CLLocationCoordinate2D(
                                latitude: stop.latitude,
                                longitude: stop.longitude
                            )
                            centerMapOnSelectedLocation()
                        }
                    }
                
                if !isUsingCurrentLocation {
                    HStack {
                        TextField("Nom de l'emplacement", text: $locationName)
                            .disabled(true) // Car on ne peut pas chercher d'autres emplacements pour le moment
                        
                        if selectedLocation != nil {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                }
                
                Button("Afficher sur la carte") {
                    isMapVisible.toggle()
                    if isMapVisible {
                        centerMapOnSelectedLocation()
                        loadStopAnnotations()
                    }
                }
            }
            
            if isMapVisible {
                Section {
                    ZStack {
                        Map(coordinateRegion: $region, annotationItems: stopAnnotations) { annotation in
                            MapAnnotation(coordinate: annotation.coordinate) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 28, height: 28)
                                    
                                    Circle()
                                        .fill(Color.blue)
                                        .frame(width: 20, height: 20)
                                    
                                    if annotation.isSelected {
                                        Circle()
                                            .stroke(Color.orange, lineWidth: 3)
                                            .frame(width: 36, height: 36)
                                    }
                                }
                                .onTapGesture {
                                    selectStop(annotation)
                                }
                            }
                        }
                        
                        if let location = selectedLocation {
                            Circle()
                                .fill(Color.orange.opacity(0.3))
                                .frame(width: CGFloat(radius * 2), height: CGFloat(radius * 2))
                                .position(convertCoordinateToPoint(location))
                        }
                    }
                    .frame(height: 300)
                    .cornerRadius(8)
                }
            }
            
            Section(header: Text("Rayon de détection")) {
                VStack {
                    Slider(value: $radius, in: 100...1000, step: 50) {
                        Text("Rayon: \(Int(radius))m")
                    }
                    
                    Text("Rayon: \(Int(radius)) mètres")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Section(footer: Text("Cette condition sera active uniquement lorsque vous serez à proximité de l'emplacement défini, dans le rayon spécifié.")) {
                if selectedLocation == nil && !isUsingCurrentLocation {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Sélectionnez un emplacement sur la carte ou utilisez votre position actuelle.")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            Section {
                Button("Enregistrer") {
                    saveLocationCondition()
                }
                .disabled(selectedLocation == nil && !isUsingCurrentLocation)
                .frame(maxWidth: .infinity)
                .buttonStyle(.borderedProminent)
            }
        }
        .onAppear {
            if isUsingCurrentLocation {
                useCurrentLocation()
            }
        }
    }
    
    private func useCurrentLocation() {
        locationName = "Ma position actuelle"
        
        // Utiliser la position actuelle si disponible
        if let currentLocation = LocationService.shared.currentLocation?.coordinate {
            selectedLocation = currentLocation
            centerMapOnSelectedLocation()
        } else {
            // Demander l'autorisation de localisation si nécessaire
            LocationService.shared.requestAuthorization()
        }
    }
    
    private func centerMapOnSelectedLocation() {
        guard let location = selectedLocation else { return }
        
        region = MKCoordinateRegion(
            center: location,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    }
    
    private func loadStopAnnotations() {
        // Charger tous les arrêts à proximité
        let allStops = StopDataService.shared.getAllStops()
        
        stopAnnotations = allStops.prefix(30).map { stop in
            StopAnnotation(
                id: stop.id_stop,
                name: stop.name_stop,
                coordinate: CLLocationCoordinate2D(
                    latitude: stop.latitude,
                    longitude: stop.longitude
                ),
                isSelected: stop.id_stop == viewModel.selectedStop?.id_stop
            )
        }
    }
    
    private func selectStop(_ annotation: StopAnnotation) {
        // Mettre à jour les annotations
        for i in 0..<stopAnnotations.count {
            stopAnnotations[i].isSelected = stopAnnotations[i].id == annotation.id
        }
        
        // Mettre à jour la position sélectionnée
        selectedLocation = annotation.coordinate
        locationName = annotation.name
        isUsingCurrentLocation = false
        
        // Centrer la carte sur l'arrêt sélectionné
        centerMapOnSelectedLocation()
    }
    
    private func convertCoordinateToPoint(_ coordinate: CLLocationCoordinate2D) -> CGPoint {
        let mapCenter = region.center
        let mapSpan = region.span
        
        // Calculer la position relative par rapport au centre de la carte
        let relativeX = (coordinate.longitude - mapCenter.longitude) / mapSpan.longitudeDelta
        let relativeY = (coordinate.latitude - mapCenter.latitude) / mapSpan.latitudeDelta
        
        // Calculer la position en pixels
        return CGPoint(x: 150 + relativeX * 300, y: 150 - relativeY * 300)
    }
    
    private func saveLocationCondition() {
        guard selectedLocation != nil || isUsingCurrentLocation else {
            return
        }
        
        let locationCoordinate: CLLocationCoordinate2D
        
        if isUsingCurrentLocation, let currentLocation = LocationService.shared.currentLocation?.coordinate {
            // Utiliser la position actuelle
            locationCoordinate = currentLocation
        } else if let location = selectedLocation {
            // Utiliser la position sélectionnée
            locationCoordinate = location
        } else {
            // Fallback sur Paris
            locationCoordinate = CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522)
        }
        
        let coordinates = Coordinates(
            latitude: locationCoordinate.latitude,
            longitude: locationCoordinate.longitude
        )
        
        let locationCondition = LocationCondition(
            coordinates: coordinates,
            radius: radius
        )
        
        if let index = editingIndex {
            // Mettre à jour une condition existante
            viewModel.updateLocationCondition(at: index, location: locationCondition)
        } else {
            // Créer une nouvelle condition
            let newCondition = DisplayCondition(
                type: .location,
                isActive: true,
                locationCondition: locationCondition
            )
            viewModel.addCondition(newCondition)
        }
        
        // Fermer le sheet
        viewModel.closeConditionSheet()
    }
}
