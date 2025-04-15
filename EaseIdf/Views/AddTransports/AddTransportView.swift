//
//  AddTransportView.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 14/04/2025.
//

import SwiftUI
import SwiftData


struct AddTransportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = AddTransportViewModel()
    
    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.currentStep {
                case .selectTransportMode:
                    TransportModeSelectionView(viewModel: viewModel)
                        .transition(.opacity)
                    
                case .selectLine:
                    LineSelectionView(viewModel: viewModel)
                        .transition(.opacity)
                    
                case .selectStop:
                    StopSelectionView(viewModel: viewModel)
                        .transition(.opacity)
                    
                case .selectDirection:
                    DirectionSelectionView(viewModel: viewModel)
                        .transition(.opacity)
                    
                case .nameFavorite:
                    FavoriteNamingView(viewModel: viewModel)
                        .transition(.opacity)
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if viewModel.currentStep != .selectTransportMode {
                        Button("Retour") {
                            navigateBack()
                        }
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                // Passer le contexte de modèle au ViewModel
                viewModel.setModelContext(modelContext)
                
                // Vérifier si des données sont disponibles
                viewModel.checkDataAvailability()
                
                // Essayer de précharger les données si nécessaire
                Task {
                    await viewModel.loadTransportData()
                }
            }
            .onDisappear {
                viewModel.reset()
            }
            .alert("Transport ajouté", isPresented: $viewModel.favoriteCreated) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Le transport a été ajouté à vos favoris.")
            }
        }
    }
    
    private var navigationTitle: String {
        switch viewModel.currentStep {
        case .selectTransportMode:
            return "Type de transport"
        case .selectLine:
            return "Sélectionner une ligne"
        case .selectStop:
            return "Sélectionner un arrêt"
        case .selectDirection:
            return "Sélectionner une direction"
        case .nameFavorite:
            return "Nommer le favori"
        }
    }
    
    private func navigateBack() {
        withAnimation {
            switch viewModel.currentStep {
            case .selectLine:
                viewModel.currentStep = .selectTransportMode
                viewModel.selectedTransportMode = nil
            case .selectStop:
                viewModel.currentStep = .selectLine
                viewModel.selectedLine = nil
            case .selectDirection:
                viewModel.currentStep = .selectStop
                viewModel.selectedStop = nil
            case .nameFavorite:
                if viewModel.availableDirections.count > 1 {
                    viewModel.currentStep = .selectDirection
                    viewModel.selectedDirection = nil
                } else {
                    viewModel.currentStep = .selectStop
                    viewModel.selectedStop = nil
                }
            default:
                break
            }
        }
    }
}

#Preview {
    AddTransportView()
        .modelContainer(PersistenceService.shared.getModelContainer())
}
