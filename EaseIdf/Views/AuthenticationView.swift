//
//  AuthenticationView.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 14/04/2025.
//

import SwiftUI

struct AuthenticationView: View {
    @ObservedObject var viewModel: AuthViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Bienvenue sur EaseIdf")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Veuillez entrer votre clé API Île-de-France Mobilités")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(alignment: .leading) {
                Text("Clé API")
                    .font(.headline)
                
                TextField("Saisissez votre clé API", text: $viewModel.apiKey)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                
                Text("Vous pouvez obtenir votre clé API sur le portail Île-de-France Mobilités")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            
            Button("Se connecter") {
                Task {
                    await viewModel.validateApiKey()
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.apiKey.isEmpty)
            
            if viewModel.isValidating {
                ProgressView()
                    .padding()
            }
            
            if viewModel.showError {
                Text("Clé API invalide. Veuillez réessayer.")
                    .foregroundColor(.red)
            }
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    AuthenticationView(viewModel: AuthViewModel())
}
