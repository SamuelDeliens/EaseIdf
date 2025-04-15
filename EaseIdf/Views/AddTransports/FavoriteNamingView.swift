//
//  FavoriteNamingView.swift
//  EaseIdf
//
//  Created by Claude on 15/04/2025.
//

import SwiftUI

struct FavoriteNamingView: View {
    @ObservedObject var viewModel: AddTransportViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            // Récapitulatif des sélections
            VStack(spacing: 8) {
                if let line = viewModel.selectedLine {
                    LineSelectionHeader(line: line)
                }
                
                if let stop = viewModel.selectedStop {
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
            }
            .padding(.horizontal)
            
            Text("Nommez votre favori")
                .font(.headline)
                .padding(.top)
            
            TextField("Nom du favori", text: $viewModel.displayName)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
                .padding(.horizontal)
            
            Text("Ce nom apparaîtra dans la liste de vos favoris.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Spacer()
            
            Button {
                viewModel.saveFavorite()
            } label: {
                if viewModel.isSaving {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    Text("Ajouter aux favoris")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.displayName.isEmpty || viewModel.isSaving)
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
}
