//
//  ContentView.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 14/04/2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var favoritesViewModel = FavoritesViewModel()
    @State private var showingSettings = false
    @State private var showingAddTransport = false
    
    var body: some View {
        NavigationStack {
            if authViewModel.isAuthenticated {
                VStack {
                    // Affichage de la liste des favoris
                    FavoritesListView(viewModel: favoritesViewModel)
                }
                .navigationTitle("EaseIdf")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: {
                            showingSettings = true
                        }) {
                            Image(systemName: "gear")
                        }
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: {
                            showingAddTransport = true
                        }) {
                            Image(systemName: "plus")
                        }
                    }
                }
                .sheet(isPresented: $showingSettings) {
                    SettingsView()
                }
                .sheet(isPresented: $showingAddTransport) {
                    AddTransportView()
                        .onDisappear {
                            // Refresh favorites when the sheet is dismissed
                            favoritesViewModel.loadFavorites()
                        }
                }
                .onAppear {
                    // Pass the model context to the favorites view model
                    favoritesViewModel.setModelContext(modelContext)
                }
            } else {
                // Authentication view
                AuthenticationView(viewModel: authViewModel)
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(PersistenceService.shared.getModelContainer())
}
