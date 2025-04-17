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
    @StateObject private var viewModel = SettingsViewModel()
    
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
                        // Vous pourriez afficher une alerte avec ces informations
                    }
                    
                    Button("Corriger les conditions de localisation") {
                        LocationDebugService.shared.fixLocationConditions()
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
                }
                
                Section {
                    Button("Effacer le cache") {
                        viewModel.clearCache()
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
                // Set the model context after the view has appeared
                viewModel.loadSettings()
            }
            .alert("Paramètres sauvegardés", isPresented: $viewModel.showSavedAlert) {
                Button("OK") { dismiss() }
            }
        }
        .onAppear {
            // Pass the model context to the view model after view appears
            viewModel.setModelContext(modelContext)
            viewModel.loadSettings()
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: UserSettingsModel.self, inMemory: true)
}
