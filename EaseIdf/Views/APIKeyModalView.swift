//
//  APIKeyModalView.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 17/04/2025.
//


import SwiftUI

struct APIKeyModalView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: AuthViewModel
    @Binding var show: Bool
    @State private var keyInputField: String = ""
    @FocusState private var isInputFieldFocused: Bool
    
    var body: some View {
        ZStack {
            // Fond semi-transparent
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    // Optionnel: permet de fermer la modale en tapant à l'extérieur
                    // dismiss()
                }
            
            // Contenu de la modale
            VStack(spacing: 20) {
                // Titre et icône
                VStack(spacing: 12) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.blue)
                    
                    Text("Clé API requise")
                        .font(.headline)
                        .fontWeight(.bold)
                }
                .padding(.top, 20)
                
                // Message explicatif
                Text("Pour utiliser EaseIdf, vous devez saisir votre clé API Île-de-France Mobilités. Cette clé est disponible sur le portail de services d'Île-de-France Mobilités.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                // Champ de saisie
                TextField("Clé API", text: $keyInputField)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.horizontal)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .focused($isInputFieldFocused)
                
                // Indicateur de chargement pendant la validation
                if viewModel.isValidating {
                    ProgressView()
                        .padding(.vertical, 5)
                }
                
                // Message d'erreur
                if viewModel.showError {
                    Text("La clé API saisie n'est pas valide. Veuillez réessayer.")
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
                
                // Boutons d'action
                HStack(spacing: 20) {
                    Button("Annuler") {
                        show = false
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Continuer") {
                        viewModel.apiKey = keyInputField
                        Task {
                            await viewModel.validateApiKey()
                            if viewModel.isAuthenticated {
                                show = false
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(keyInputField.isEmpty || viewModel.isValidating)
                }
                .padding(.bottom, 20)
            }
            .frame(width: 320)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(radius: 10)
        }
        .onAppear {
            // Utiliser une valeur par défaut si disponible
            keyInputField = viewModel.apiKey
        }
    }
}

struct APIKeyModalView_Previews: PreviewProvider {
    @State static var showModal = true
    
    static var previews: some View {
        APIKeyModalView(viewModel: AuthViewModel(), show: $showModal)
            .preferredColorScheme(.light)
    }
}
