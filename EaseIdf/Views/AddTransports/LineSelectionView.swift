//
//  LineSelectionView.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 14/04/2025.
//

import SwiftUI

struct LineSelectionView: View {
    @ObservedObject var viewModel: AddTransportViewModel
    
    var body: some View {
        VStack {
            // Barre de recherche
            TextField("Rechercher une ligne", text: $viewModel.searchLineQuery)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal)
                .padding(.top)
            
            // Mode de transport sélectionné
            HStack {
                if let mode = viewModel.selectedTransportMode {
                    Label(
                        title: { Text(transportModeTitle(mode)) },
                        icon: { Image(systemName: transportModeIcon(mode)) }
                    )
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
                }
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 4)
            
            // Liste des lignes ou indicateur de chargement
            if viewModel.isLoading {
                Spacer()
                ProgressView("Chargement des lignes...")
                Spacer()
            } else if viewModel.filteredLines.isEmpty {
                ContentUnavailableView(
                    viewModel.searchLineQuery.isEmpty ? "Aucune ligne disponible" : "Aucun résultat",
                    systemImage: viewModel.searchLineQuery.isEmpty ? "tram" : "magnifyingglass",
                    description: Text(viewModel.searchLineQuery.isEmpty ?
                                     "Aucune ligne n'est disponible pour ce mode de transport." :
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
                        ForEach(viewModel.filteredLines) { line in
                            Button {
                                withAnimation {
                                    viewModel.selectLine(line)
                                }
                            } label: {
                                LineRow(line: line)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .onAppear {
            viewModel.filterLines(query: viewModel.searchLineQuery)
            
            // Si aucune ligne n'est trouvée, vérifier si des données sont disponibles
            if viewModel.filteredLines.isEmpty && !viewModel.isLoading {
                Task {
                    await viewModel.loadTransportData()
                }
            }
        }
    }
    
    private func transportModeTitle(_ mode: TransportMode) -> String {
        switch mode {
        case .bus: return "Bus"
        case .metro: return "Métro"
        case .tram: return "Tramway"
        case .rail: return "Train"
        case .rer: return "RER"
        case .other: return "Autre"
        }
    }
    
    private func transportModeIcon(_ mode: TransportMode) -> String {
        switch mode {
        case .bus: return "bus.fill"
        case .metro: return "tram.fill"
        case .tram: return "tram"
        case .rail, .rer: return "train.side.front.car"
        case .other: return "questionmark.circle"
        }
    }
}
