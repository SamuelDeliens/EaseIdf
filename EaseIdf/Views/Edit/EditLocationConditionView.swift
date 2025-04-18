//
//  StopAnnotation.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 18/04/2025.
//


//
//  EditLocationConditionView.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 15/04/2025.
//

import SwiftUI
import CoreLocation
import MapKit

struct EditLocationConditionView: View {
    @ObservedObject var viewModel: EditFavoriteViewModel
    
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
    
    init(viewModel: EditFavoriteViewModel, editingIndex: Int? = nil) {
        self.viewModel = viewModel
        self.editingIndex = editingIndex
        
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
        } else {
            // Par défaut, utiliser l'arrêt sélectionné comme position
            self.locationName = viewModel.favorite.wrappedValue.stopName != nil ? viewModel.favorite.wrappedValue.stopName! : ""
            
            let stopLatitude = viewModel.favorite.wrappedValue.stopLatitude != nil ? viewModel.favorite.wrappedValue.stopLatitude! : 0.0
            let stopLongitude = viewModel.favorite.wrappedValue.stopLongitude != nil ? viewModel.favorite.wrappedValue.stopLongitude! : 0.0
            
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
                        } else {
                            useStopLocation()
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
    
    private func useStopLocation() {
        self.locationName = viewModel.favorite.wrappedValue.stopName != nil ? viewModel.favorite.wrappedValue.stopName! : ""
        
        let stopLatitude = viewModel.favorite.wrappedValue.stopLatitude != nil ? viewModel.favorite.wrappedValue.stopLatitude! : 0.0
        let stopLongitude = viewModel.favorite.wrappedValue.stopLongitude != nil ? viewModel.favorite.wrappedValue.stopLongitude! : 0.0
        selectedLocation = CLLocationCoordinate2D(
            latitude: stopLatitude,
            longitude: stopLongitude
        )
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
        
        // Ajouter des logs pour vérifier les coordonnées
        for stop in allStops.prefix(5) {
            print("Arrêt: \(stop.name_stop), lat: \(stop.latitude), long: \(stop.longitude)")
            print("Données brutes de localisation: \(String(describing: stop.ns2_location))")
        }
        
        stopAnnotations = allStops.prefix(30).map { stop in
            StopAnnotation(
                id: stop.id_stop,
                name: stop.name_stop,
                coordinate: CLLocationCoordinate2D(
                    latitude: stop.latitude,
                    longitude: stop.longitude
                ),
                isSelected: stop.id_stop == viewModel.favorite.wrappedValue.stopId
            )
        }
    }
    
    private func selectStop(_ annotation: StopAnnotation) {
        // Vérifier que les coordonnées sont valides
        if annotation.coordinate.latitude == 0 && annotation.coordinate.longitude == 0 {
            print("Attention : L'arrêt \(annotation.name) a des coordonnées invalides (0,0)")
            // Peut-être ajouter une alerte pour l'utilisateur
            return
        }
        
        // Mettre à jour les annotations
        for i in 0..<stopAnnotations.count {
            stopAnnotations[i].isSelected = stopAnnotations[i].id == annotation.id
        }
        
        // Mettre à jour la position sélectionnée avec débogage
        selectedLocation = annotation.coordinate
        print("Sélection d'un arrêt avec coordonnées: lat=\(annotation.coordinate.latitude), long=\(annotation.coordinate.longitude)")
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
        
        if isUsingCurrentLocation {
            // S'assurer que nous avons une position actuelle
            if let currentLocation = LocationService.shared.currentLocation?.coordinate {
                locationCoordinate = currentLocation
            } else {
                // Si la position actuelle n'est pas disponible, afficher une alerte
                // et ne pas continuer
                print("Position actuelle non disponible")
                return
            }
        } else if let location = selectedLocation {
            locationCoordinate = location
        } else {
            // Ne pas continuer si aucune coordonnée n'est disponible
            return
        }
        
        // Assurez-vous que les coordonnées sont valides (pas à 0,0)
        if locationCoordinate.latitude == 0.0 && locationCoordinate.longitude == 0.0 {
            print("Coordonnées invalides (0,0)")
            return
        }
        
        let coordinates = Coordinates(
            latitude: locationCoordinate.latitude,
            longitude: locationCoordinate.longitude
        )
        
        let locationCondition = LocationCondition(
            coordinates: coordinates,
            radius: radius
        )
        
        // Afficher les coordonnées enregistrées pour débogage
        print("Enregistrement de la condition avec coordonnées: \(coordinates.latitude), \(coordinates.longitude)")
        
        if let index = editingIndex {
            viewModel.updateLocationCondition(at: index, location: locationCondition)
        } else {
            let newCondition = DisplayCondition(
                type: .location,
                isActive: true,
                locationCondition: locationCondition
            )
            viewModel.addCondition(newCondition)
        }
        
        viewModel.closeConditionSheet()
    }
}
