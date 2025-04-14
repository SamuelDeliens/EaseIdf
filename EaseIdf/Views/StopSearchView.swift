//
//  StopSearchView.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 14/04/2025.
//

import SwiftUI
import MapKit

struct StopSearchView: View {
    @Environment(\.dismiss) private var dismiss
    
    @Binding var selectedStopId: String
    @State private var searchText = ""
    @State private var stops: [TransportStop] = []
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var mapPosition: MapCameraPosition = .automatic
    
    var body: some View {
        NavigationStack {
            VStack {
                searchBar
                
                if isLoading {
                    loadingView
                } else if let error = errorMessage {
                    errorView(message: error)
                } else if stops.isEmpty {
                    emptyView
                } else {
                    searchResults
                }
            }
            .navigationTitle("Rechercher un arrêt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                // Load cached stops if available
                if let cachedStops = StorageService.shared.getCachedStops() {
                    stops = cachedStops
                }
            }
        }
    }
    
    private var searchBar: some View {
        HStack {
            TextField("Nom d'arrêt ou ID", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .disableAutocorrection(true)
            
            Button {
                performSearch()
            } label: {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.blue)
            }
            .disabled(searchText.isEmpty || isLoading)
        }
        .padding()
    }
    
    private var loadingView: some View {
        VStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
            Text("Recherche en cours...")
                .foregroundColor(.secondary)
                .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("Erreur")
                .font(.title)
                .fontWeight(.bold)
            
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button("Réessayer") {
                performSearch()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "mappin.slash")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            if searchText.isEmpty {
                Text("Saisissez un nom d'arrêt")
                    .font(.title2)
                    .foregroundColor(.secondary)
            } else {
                Text("Aucun arrêt trouvé")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                Text("Essayez une recherche différente ou vérifiez votre clé API.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var searchResults: some View {
        VStack {
            // Map view showing stop locations
            Map(position: $mapPosition) {
                ForEach(stops) { stop in
                    Marker(stop.name, coordinate: stop.coordinates.locationCoordinate)
                        .tint(colorForTransportType(stop.type))
                }
            }
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal)
            
            // List of stops
            List {
                ForEach(filteredStops) { stop in
                    stopRow(stop)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedStopId = stop.id
                            dismiss()
                        }
                }
            }
        }
    }
    
    private func stopRow(_ stop: TransportStop) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Circle()
                    .fill(colorForTransportType(stop.type))
                    .frame(width: 8, height: 8)
                
                Text(stop.name)
                    .font(.headline)
                
                Spacer()
                
                Text(stop.id)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text(stopTypeLabel(stop.type))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let lines = stop.lines, !lines.isEmpty {
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(lines.count) ligne(s)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func colorForTransportType(_ type: StopType) -> Color {
        switch type {
        case .quay, .operatorQuay:
            return .blue
        case .monomodalStop:
            return .green
        case .multimodalStop:
            return .orange
        case .generalGroup:
            return .red
        case .entrance:
            return .purple
        }
    }
    
    private func stopTypeLabel(_ type: StopType) -> String {
        switch type {
        case .quay:
            return "Arrêt"
        case .operatorQuay:
            return "Arrêt transporteur"
        case .monomodalStop:
            return "Zone d'arrêt"
        case .multimodalStop:
            return "Zone de correspondance"
        case .generalGroup:
            return "Pôle d'échanges"
        case .entrance:
            return "Accès"
        }
    }
    
    private var filteredStops: [TransportStop] {
        if searchText.isEmpty {
            return stops
        }
        
        let lowercasedQuery = searchText.lowercased()
        
        return stops.filter { stop in
            stop.name.lowercased().contains(lowercasedQuery) ||
            stop.id.lowercased().contains(lowercasedQuery)
        }
    }
    
    private func performSearch() {
        isLoading = true
        errorMessage = nil
        
        // For this implementation, we'll use mock data since we don't have a real API to call
        // In a real app, you would call IDFMobiliteService.shared.searchStops(query: searchText)
        
        Task {
            do {
                try await Task.sleep(nanoseconds: 2 * 1_000_000_000) // Simulate network delay
                
                // In a real implementation, this would call the API
                // let searchResults = try await IDFMobiliteService.shared.searchStops(query: searchText)
                
                // For now, just use some mock data
                let mockStops = createMockStops()
                
                DispatchQueue.main.async {
                    self.stops = mockStops
                    self.isLoading = false
                    
                    // Update map position
                    if !mockStops.isEmpty {
                        // Center map on the first stop
                        let firstStop = mockStops[0]
                        self.mapPosition = .region(MKCoordinateRegion(
                            center: firstStop.coordinates.locationCoordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                        ))
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Impossible de rechercher les arrêts. Vérifiez votre connexion et votre clé API."
                    self.isLoading = false
                }
            }
        }
    }
    
    // MARK: - Mock Data for Preview
    
    private func createMockStops() -> [TransportStop] {
        return [
            TransportStop(
                id: "473921",
                name: "Châtelet les Halles",
                type: .multimodalStop,
                coordinates: Coordinates(latitude: 48.8588, longitude: 2.3470),
                lines: ["C01742", "C01743", "C01744"]
            ),
            TransportStop(
                id: "474123",
                name: "Gare du Nord",
                type: .multimodalStop,
                coordinates: Coordinates(latitude: 48.8809, longitude: 2.3553),
                lines: ["C01742", "C01756"]
            ),
            TransportStop(
                id: "475321",
                name: "Saint-Lazare",
                type: .multimodalStop,
                coordinates: Coordinates(latitude: 48.8764, longitude: 2.3242),
                lines: ["C01749", "C01750"]
            ),
            TransportStop(
                id: "476123",
                name: "La Défense",
                type: .generalGroup,
                coordinates: Coordinates(latitude: 48.8918, longitude: 2.2362),
                lines: ["C01742", "C01751", "C01752"]
            ),
            TransportStop(
                id: "477432",
                name: "Montparnasse",
                type: .multimodalStop,
                coordinates: Coordinates(latitude: 48.8421, longitude: 2.3219),
                lines: ["C01754", "C01755"]
            )
        ]
    }
}

// Preview wrapper with binding
struct StopSearchView_Previews: PreviewProvider {
    static var previews: some View {
        StopSearchPreview()
    }
    
    struct StopSearchPreview: View {
        @State private var stopId = ""
        
        var body: some View {
            StopSearchView(selectedStopId: $stopId)
        }
    }
}
