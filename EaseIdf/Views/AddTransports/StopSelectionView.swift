//
//  StopSelectionView.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 14/04/2025.
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
