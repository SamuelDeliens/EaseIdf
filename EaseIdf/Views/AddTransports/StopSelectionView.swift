//
//  StopSelectionView.swift
//  EaseIdf
//
//  Created by Claude on 15/04/2025.
//

import SwiftUI

struct StopSelectionView: View {
    @ObservedObject var viewModel: AddTransportViewModel
    
    var body: some View {
        VStack {
            // Ligne sélectionnée
            if let line = viewModel.selectedLine {
                LineSelectionHeader(line: line)
                    .padding(.horizontal)
                    .padding(.top)
            }
            
            // Barre de recherche
            TextField("Rechercher un arrêt", text: $viewModel.searchStopQuery)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal)
                .padding(.top, 8)
            
            // Liste des arrêts ou indicateur de chargement
            if viewModel.isLoading {
                Spacer()
                ProgressView("Chargement des arrêts...")
                Spacer()
            } else if viewModel.filteredStops.isEmpty {
                ContentUnavailableView(
                    viewModel.searchStopQuery.isEmpty ? "Aucun arrêt disponible" : "Aucun résultat",
                    systemImage: viewModel.searchStopQuery.isEmpty ? "mappin.and.ellipse" : "magnifyingglass",
                    description: Text(viewModel.searchStopQuery.isEmpty ?
                                     "Aucun arrêt n'est disponible pour cette ligne." :
                                     "Essayez une autre recherche.")
                )
                // Bouton pour recharger les données
                Button {
                    Task {
                        await viewModel.loadTransportData()
                    }
                } label: {
                    Label("Recharger les données", systemImage: "arrow.clockwise")
                        .padding()
                }
                .buttonStyle(.bordered)
                .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.filteredStops) { stop in
                            Button {
                                withAnimation {
                                    viewModel.selectStop(stop)
                                }
                            } label: {
                                StopRow(stop: stop)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
            }
        }
        .onAppear {
            viewModel.filterStops(query: viewModel.searchStopQuery)
            
            // Si aucun arrêt n'est trouvé, vérifier si des données sont disponibles
            if viewModel.filteredStops.isEmpty && !viewModel.isLoading {
                Task {
                    await viewModel.loadTransportData()
                }
            }
        }
    }
}

struct LineSelectionHeader: View {
    let line: ImportedLine
    
    var body: some View {
        HStack {
            Text(line.shortname_line)
                .font(.headline)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .foregroundColor(Color(hex: line.textColor))
                .background(Color(hex: line.color))
                .cornerRadius(5)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(line.name_line)
                    .font(.subheadline)
                    .lineLimit(1)
                
                if let groupName = line.shortname_groupoflines {
                    Text(groupName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(10)
    }
}

struct StopRow: View {
    let stop: ImportedStop
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(stop.name_stop)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(stopTypeLabel(stop.getStopType()))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
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
}
