//
//  FavoriteNamingView.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 14/04/2025.
//

import SwiftUI

struct FavoriteNamingView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: AddTransportViewModel
    @State private var showingConditionOptions = false
    
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
                if viewModel.displayName.isEmpty {
                    return
                }
                // Afficher l'écran d'options pour les conditions
                showingConditionOptions = true
            } label: {
                if viewModel.isSaving {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    Text("Continuer")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.displayName.isEmpty || viewModel.isSaving)
            .padding(.horizontal)
            .padding(.bottom)
        }
        .fullScreenCover(isPresented: $showingConditionOptions) {
            // Si l'utilisateur choisit de configurer des conditions
            if viewModel.afterNamingStep == .configureConditions {
                NavigationStack {
                    ConditionConfigurationView(viewModel: viewModel)
                        .navigationTitle("Conditions d'affichage")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Annuler") {
                                    showingConditionOptions = false
                                }
                            }
                        }
                }
            } else {
                // Afficher les options de conditions
                ConditionOptionsView(viewModel: viewModel)
            }
        }
    }
}

#Preview {
    FavoriteNamingView(viewModel: AddTransportViewModel())
}
