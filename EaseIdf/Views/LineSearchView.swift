//
//  LineSearchView.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 14/04/2025.
//

import SwiftUI

struct LineSearchView: View {
    @Environment(\.dismiss) private var dismiss
    
    @Binding var selectedLineId: String
    @State private var searchText = ""
    @State private var lines: [TransportLine] = []
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var transportModeFilter: TransportMode? = nil
    
    var body: some View {
        NavigationStack {
            VStack {
                searchBar
                
                filterSection
                
                if isLoading {
                    loadingView
                } else if let error = errorMessage {
                    errorView(message: error)
                } else if lines.isEmpty {
                    emptyView
                } else {
                    searchResults
                }
            }
            .navigationTitle("Rechercher une ligne")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                // Load cached lines if available
                if let cachedLines = StorageService.shared.getCachedLines() {
                    lines = cachedLines
                } else {
                    // Fetch lines if no cached data
                    fetchLines()
                }
            }
        }
    }
    
    private var searchBar: some View {
        HStack {
            TextField("Nom de ligne ou ID", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .disableAutocorrection(true)
            
            Button {
                if let cachedLines = StorageService.shared.getCachedLines() {
                    lines = cachedLines
                } else {
                    fetchLines()
                }
            } label: {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.blue)
            }
            .disabled(isLoading)
        }
        .padding()
    }
    
    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                Button {
                    transportModeFilter = nil
                } label: {
                    Text("Tous")
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(transportModeFilter == nil ? Color.blue : Color.gray.opacity(0.2))
                        .foregroundColor(transportModeFilter == nil ? .white : .primary)
                        .cornerRadius(20)
                }
                
                ForEach(TransportMode.allCases, id: \.self) { mode in
                    Button {
                        transportModeFilter = mode
                    } label: {
                        HStack {
                            Image(systemName: iconForTransportMode(mode))
                            Text(labelForTransportMode(mode))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(transportModeFilter == mode ? Color.blue : Color.gray.opacity(0.2))
                        .foregroundColor(transportModeFilter == mode ? .white : .primary)
                        .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var loadingView: some View {
        VStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
            Text("Chargement des lignes...")
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
                fetchLines()
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
            Image(systemName: "tram.fill")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            if transportModeFilter != nil {
                Text("Aucune ligne de ce type")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                Button("Afficher toutes les lignes") {
                    transportModeFilter = nil
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            } else {
                Text("Aucune ligne disponible")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                Text("Vérifiez votre connexion et votre clé API.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var searchResults: some View {
        List {
            ForEach(filteredLines) { line in
                lineRow(line)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedLineId = line.id
                        dismiss()
                    }
            }
        }
    }
    
    private func lineRow(_ line: TransportLine) -> some View {
        HStack {
            // Line icon/badge
            ZStack {
                Circle()
                    .fill(colorForTransportMode(line.transportMode))
                    .frame(width: 40, height: 40)
                
                Text(line.name)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(line.name)
                    .font(.headline)
                
                HStack {
                    Image(systemName: iconForTransportMode(line.transportMode))
                        .foregroundColor(.secondary)
                    
                    Text(labelForTransportMode(line.transportMode))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let submode = line.transportSubmode, !submode.isEmpty {
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(submode)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Text("Opérateur: \(line.operator_.name)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.leading, 8)
            
            Spacer()
            
            Text(line.id)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    private var filteredLines: [TransportLine] {
        var result = lines
        
        // Apply mode filter if selected
        if let modeFilter = transportModeFilter {
            result = result.filter { $0.transportMode == modeFilter }
        }
        
        // Apply search text filter if not empty
        if !searchText.isEmpty {
            let lowercasedQuery = searchText.lowercased()
            
            result = result.filter { line in
                line.name.lowercased().contains(lowercasedQuery) ||
                line.id.lowercased().contains(lowercasedQuery) ||
                (line.privateCode?.lowercased().contains(lowercasedQuery) ?? false) ||
                line.operator_.name.lowercased().contains(lowercasedQuery)
            }
        }
        
        return result
    }
    
    private func fetchLines() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await Task.sleep(nanoseconds: 2 * 1_000_000_000) // Simulate network delay
                
                // In a real implementation, this would call the API
                // let lines = try await IDFMobiliteService.shared.fetchLines()
                
                // For now, just use some mock data
                let mockLines = createMockLines()
                
                DispatchQueue.main.async {
                    self.lines = mockLines
                    
                    // Cache the results
                    StorageService.shared.cacheTransportLines(mockLines)
                    
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Impossible de charger les lignes. Vérifiez votre connexion et votre clé API."
                    self.isLoading = false
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func colorForTransportMode(_ mode: TransportMode) -> Color {
        switch mode {
        case .bus:
            return .blue
        case .tram:
            return .green
        case .metro:
            return .purple
        case .rail:
            return .orange
        case .rer:
            return .red
        case .other:
            return .gray
        }
    }
    
    private func iconForTransportMode(_ mode: TransportMode) -> String {
        switch mode {
        case .bus:
            return "bus.fill"
        case .tram:
            return "tram.fill"
        case .metro:
            return "train.side.front.car"
        case .rail:
            return "train.side.front.car"
        case .rer:
            return "train.side.front.car"
        case .other:
            return "tram"
        }
    }
    
    private func labelForTransportMode(_ mode: TransportMode) -> String {
        switch mode {
        case .bus:
            return "Bus"
        case .tram:
            return "Tramway"
        case .metro:
            return "Métro"
        case .rail:
            return "Train"
        case .rer:
            return "RER"
        case .other:
            return "Autre"
        }
    }
    
    // MARK: - Mock Data for Preview
    
    private func createMockLines() -> [TransportLine] {
        return [
            TransportLine(
                id: "C01742",
                name: "RER A",
                privateCode: "100100241",
                transportMode: .rer,
                transportSubmode: "suburban",
                operator_: Operator(id: "RATP", name: "RATP")
            )
        ]
    }
}

extension TransportMode: CaseIterable {
    static var allCases: [TransportMode] {
        return [.bus, .tram, .metro, .rail, .rer, .other]
    }
}

// Preview wrapper with binding
struct LineSearchView_Previews: PreviewProvider {
    static var previews: some View {
        LineSearchPreview()
    }
    
    struct LineSearchPreview: View {
        @State private var lineId = ""
        
        var body: some View {
            LineSearchView(selectedLineId: $lineId)
        }
    }
}
