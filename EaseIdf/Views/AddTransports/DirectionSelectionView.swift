//
//  DirectionSelectionView.swift
//  EaseIdf
//
//  Created by Claude on 15/04/2025.
//

import SwiftUI

struct DirectionSelectionView: View {
    @ObservedObject var viewModel: AddTransportViewModel
    
    var body: some View {
        VStack {
            // Ligne et arrêt sélectionnés
            if let line = viewModel.selectedLine, let stop = viewModel.selectedStop {
                VStack(spacing: 8) {
                    LineSelectionHeader(line: line)
                    
                    HStack {
                        Label(
                            title: { Text(stop.name_stop) },
                            icon: { Image(systemName: "mappin.and.ellipse") }
                        )
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                        .padding(.vertical, 4)
                        .background(Color(.systemGray5))
                        .cornerRadius(8)
                        
                        Spacer()
                    }
                }
                .padding(.horizontal)
                .padding(.top)
            }
            
            Text("Sélectionnez une direction")
                .font(.headline)
                .padding(.top)
            
            // Liste des directions
            if viewModel.availableDirections.isEmpty {
                ContentUnavailableView(
                    "Aucune direction disponible",
                    systemImage: "arrow.up.and.down",
                    description: Text("Les données de direction ne sont pas disponibles pour cette ligne.")
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.availableDirections) { direction in
                            Button {
                                withAnimation {
                                    viewModel.selectDirection(direction)
                                }
                            } label: {
                                DirectionRow(direction: direction)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
            }
        }
    }
}

struct DirectionRow: View {
    let direction: LineDirection
    
    var body: some View {
        HStack {
            Circle()
                .fill(Color(hex: direction.color))
                .frame(width: 12, height: 12)
            
            Text(direction.lineName)
                .font(.headline)
                .foregroundColor(.primary)
            
            Image(systemName: "arrow.right")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(direction.direction)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}
