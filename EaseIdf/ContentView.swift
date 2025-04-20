//
//  ContentView.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 14/04/2025.
//


import SwiftUI
import SwiftData

struct ContentView: View {
    // Contexte SwiftData automatiquement injecté
    @Environment(\.modelContext) private var modelContext
    
    // ViewModels
    @StateObject private var authViewModel = AuthViewModel(authService: AppServices.shared.authService)
    @StateObject private var favoritesViewModel = FavoritesViewModel(
        modelContext: nil, // Sera défini dans onAppear
        favoriteService: AppServices.shared.favoriteService,
        conditionService: AppServices.shared.conditionService
    )
    
    // États UI
    @State private var showingSettings = false
    @State private var showingAddTransport = false
    @State private var initialLoadComplete = false
    @State private var showEditTransportList = false
    @State private var showAuthModal = true
    
    var body: some View {
        NavigationStack {
            VStack {
                // Bannière d'authentification si nécessaire
                if !authViewModel.isAuthenticated {
                    authenticationBanner
                }
                
                // Vue principale de la liste des favoris
                FavoritesListView(viewModel: favoritesViewModel, showEditTransportList: $showEditTransportList)
            }
            .navigationTitle("EaseIdf")
            .toolbar {
                // Bouton d'édition
                ToolbarItem(placement: .topBarTrailing) {
                    Button(showEditTransportList ? "Terminer" : "Modifier") {
                        withAnimation {
                            showEditTransportList.toggle()
                        }
                    }
                }
                
                // Bouton d'ajout
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        showingAddTransport = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
                
                // Bouton des paramètres
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gear")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
                    .environment(\.modelContext, modelContext)
                    .onDisappear {
                        // On recharge les favoris car les paramètres ont pu changer
                        favoritesViewModel.loadFavorites()
                    }
            }
            .sheet(isPresented: $showingAddTransport) {
                AddTransportView()
                    .environment(\.modelContext, modelContext)
                    .onDisappear {
                        favoritesViewModel.loadFavorites()
                    }
            }
            .onAppear {
                // Vérifier si l'authentification est nécessaire
                showAuthModal = !authViewModel.isAuthenticated
                
                // Configurer les ViewModels avec le contexte de modèle
                if !initialLoadComplete {
                    // S'assurer que le ModelContext est défini dans les services et ViewModels
                    favoritesViewModel.setModelContext(modelContext)
                    AppServices.shared.favoriteService.setModelContext(modelContext)
                    
                    // Vérifier si les données de base sont chargées
                    validateBaseDataLoaded()
                    
                    initialLoadComplete = true
                    
                    // Charger les favoris
                    favoritesViewModel.loadFavorites()
                    print("🔄 Chargement initial des favoris")
                }
            }
        }
        .overlay {
            // Afficher la modale de clé API si nécessaire
            if showAuthModal {
                APIKeyModalView(viewModel: authViewModel, show: $showAuthModal)
            }
        }
    }
    
    // Bannière d'authentification
    private var authenticationBanner: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 14))
                .foregroundColor(.orange)
                .padding(.bottom, 4)
            
            Text("Authentification requise")
                .font(.subheadline)
                .fontWeight(.bold)
            
            Button("clé API") {
                showAuthModal = true
            }
        }
        .padding(.top, 5)
    }
    
    // Vérifier que les données de base sont chargées
    private func validateBaseDataLoaded() {
        let transportService = AppServices.shared.transportService
        
        // Vérifier si les données sont toujours manquantes après le splash screen
        if transportService.getAllLines().isEmpty ||
           transportService.getAllStops().isEmpty {
            print("⚠️ Des données sont manquantes après le splash screen, rechargement...")
            
            Task {
                await AppServices.shared.initializeBaseData()
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(PersistenceService.shared.getModelContainer())
}
