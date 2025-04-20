//
//  SettingsView.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 14/04/2025.
//


import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @StateObject private var viewModel = SettingsViewModel(
        authService: AppServices.shared.authService,
        favoritesViewModel: FavoritesViewModel.shared
    )
    
    @State private var showingKeychainDebug = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Clé API")) {
                    SecureField("Clé API Île-de-France Mobilités", text: $viewModel.apiKey)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    
                    Button("Tester la connexion") {
                        Task {
                            await viewModel.testApiKey()
                        }
                    }
                    .disabled(viewModel.apiKey.isEmpty || viewModel.isTestingConnection)
                    
                    if viewModel.isTestingConnection {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    }
                    
                    if viewModel.isConnectionValid {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Connexion valide")
                                .foregroundColor(.green)
                        }
                    }
                }
                
                Section(header: Text("Diagnostic")) {
                    Button("Diagnostiquer la localisation") {
                        let debugInfo = LocationDebugService.shared.debugLocationStatus()
                        print(debugInfo)
                        viewModel.showAlert(message: "Informations de débogage de la localisation envoyées à la console")
                    }
                    
                    Button("Corriger les conditions de localisation") {
                        LocationDebugService.shared.fixLocationConditions()
                        viewModel.showAlert(message: "Correction des conditions de localisation terminée")
                    }
                    
                    Button("Débogage Keychain") {
                        showingKeychainDebug = true
                    }
                }
                
                Section(header: Text("Préférences d'affichage")) {
                    Toggle("Afficher uniquement les prochains départs", isOn: $viewModel.showOnlyUpcomingDepartures)
                    
                    Stepper("Nombre de départs à afficher: \(viewModel.numberOfDeparturesToShow)", value: $viewModel.numberOfDeparturesToShow, in: 1...10)
                }
                
                Section(header: Text("Actualisation")) {
                    VStack {
                        Text("Intervalle d'actualisation: \(viewModel.formatTimeInterval(viewModel.refreshInterval))")
                        
                        Slider(value: $viewModel.refreshInterval, in: 30...600, step: 30) {
                            Text("Intervalle d'actualisation")
                        }
                    }
                    
                    Button(action: {
                        viewModel.toggleRefreshPause()
                    }) {
                        HStack {
                            Image(systemName: viewModel.isRefreshPaused ? "pause.circle.fill" : "play.circle.fill")
                                .foregroundColor(viewModel.isRefreshPaused ? .orange : .green)
                            Text(viewModel.isRefreshPaused ? "Actualisations en pause" : "Actualisations actives")
                                .foregroundColor(viewModel.isRefreshPaused ? .orange : .green)
                        }
                    }
                }
                
                Section {
                    Button("Effacer le cache") {
                        viewModel.clearCache()
                        viewModel.showAlert(message: "Cache effacé avec succès")
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Paramètres")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer") {
                        viewModel.saveSettings()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                // Définir le ModelContext
                viewModel.setModelContext(modelContext)
                viewModel.loadSettings()
            }
            .alert("Paramètres sauvegardés", isPresented: $viewModel.showSavedAlert) {
                Button("OK") { dismiss() }
            }
            .alert(viewModel.alertMessage, isPresented: $viewModel.showAlert) {
                Button("OK", role: .cancel) { }
            }
            .sheet(isPresented: $showingKeychainDebug) {
                KeychainDebugView()
            }
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: UserSettingsModel.self, inMemory: true)
}
