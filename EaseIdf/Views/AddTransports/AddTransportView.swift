//
//  AddTransportView.swift
//  EaseIdf
//
//  Created by Claude on 15/04/2025.
//

import SwiftUI

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
}
