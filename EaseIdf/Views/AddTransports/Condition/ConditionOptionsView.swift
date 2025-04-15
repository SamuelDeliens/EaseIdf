//
//  ConditionOptionsView.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 15/04/2025.
//


import SwiftUI

struct ConditionOptionsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: AddTransportViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            // Icône
            Image(systemName: "slider.horizontal.3")
                .font(.system(size: 60))
                .foregroundColor(.blue)
                .padding(.top, 30)
            
            // Titre
            Text("Configurer des conditions?")
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Description
            Text("Vous pouvez configurer des conditions pour déterminer quand ce transport sera affiché sur votre écran d'accueil.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 30)
            
            Spacer()
            
            // Options
            VStack(spacing: 16) {
                Button {
                    viewModel.afterNamingStep = .configureConditions
                } label: {
                    HStack {
                        Image(systemName: "gear")
                        Text("Configurer maintenant")
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                Button {
                    viewModel.saveFavorite()
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle")
                        Text("Enregistrer sans conditions")
                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemGray5))
                    .foregroundColor(.primary)
                    .cornerRadius(10)
                }
            }
            .padding(.horizontal)
            
            Text("Vous pourrez toujours configurer les conditions plus tard depuis vos favoris.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.bottom, 20)
        }
        .padding()
    }
}

#Preview {
    ConditionOptionsView(viewModel: AddTransportViewModel())
}
