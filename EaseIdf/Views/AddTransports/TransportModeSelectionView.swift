//
//  TransportModeSelectionView.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 14/04/2025.
//

import SwiftUI

struct TransportModeSelectionView: View {
    @ObservedObject var viewModel: AddTransportViewModel
    
    private let modes: [(TransportMode, String, String)] = [
        (.bus, "Bus", "bus.fill"),
        (.metro, "Métro", "tram.fill"),
        (.tram, "Tramway", "tram"),
        (.rer, "RER", "train.side.front.car"),
        (.rail, "Train", "train.side.front.car"),
        (.other, "Autre", "questionmark.circle")
    ]
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Choisissez le type de transport")
                .font(.headline)
                .padding(.top)
            
            if viewModel.isLoading {
                Spacer()
                ProgressView("Chargement des données...")
                    .padding()
                Spacer()
            } else {
                ForEach(modes, id: \.0) { mode, name, icon in
                    Button {
                        withAnimation {
                            viewModel.selectTransportMode(mode)
                        }
                    } label: {
                        HStack {
                            Image(systemName: icon)
                                .font(.title2)
                                .frame(width: 40)
                            
                            Text(name)
                                .font(.title3)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Essayer de charger les données si nécessaire
                Button {
                    Task {
                        await viewModel.loadTransportData()
                    }
                } label: {
                    Label("Rafraîchir les données", systemImage: "arrow.clockwise")
                        .padding()
                }
                .padding(.top)
                
                Spacer()
            }
        }
        .padding()
    }
}
