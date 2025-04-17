//
//  APIKeyModalView.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 17/04/2025.
//


import SwiftUI

struct APIKeyModalView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var viewModel: AuthViewModel
    @Binding var show: Bool
    @State private var keyInputField: String = ""
    @FocusState private var isInputFieldFocused: Bool
    
    var body: some View {
        ZStack {
            // Fond semi-transparent (style Apple)
            Color.black.opacity(colorScheme == .dark ? 0.5 : 0.2)
                .ignoresSafeArea()
                .onTapGesture {
                    // Fermeture optionnelle en tapant à l'extérieur - désactivée pour les modales importantes
                    // self.show = false
                }
                .blur(radius: 0.5)
            
            // Effet visuel de fond flouté (style Apple)
            Rectangle()
                .fill(Material.ultraThinMaterial)
                .ignoresSafeArea()
            
            // Contenu de la modale
            VStack(spacing: 20) {
                // Titre et icône
                VStack(spacing: 12) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.blue)
                        .padding(.top, 6)
                    
                    Text("Clé API requise")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                .padding(.top, 16)
                
                // Message explicatif
                Text("Pour utiliser EaseIdf, vous devez saisir votre clé API Île-de-France Mobilités. Cette clé est disponible sur le portail de services d'Île-de-France Mobilités.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.bottom, 4)
                
                // Champ de saisie
                TextField("Clé API", text: $keyInputField)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
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
                
                // Boutons d'action style iOS
                HStack(spacing: 20) {
                    Button("Annuler") {
                        self.show = false
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray5))
                    .foregroundColor(.primary)
                    .cornerRadius(10)
                    
                    Button("Continuer") {
                        viewModel.apiKey = keyInputField
                        Task {
                            await viewModel.validateApiKey()
                            if viewModel.isAuthenticated {
                                self.show = false
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(keyInputField.isEmpty || viewModel.isValidating ? Color.blue.opacity(0.5) : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .disabled(keyInputField.isEmpty || viewModel.isValidating)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .frame(width: min(UIScreen.main.bounds.width - 60, 340))
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.gray.opacity(0.1), lineWidth: 1)
            )
        }
        .onAppear {
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
