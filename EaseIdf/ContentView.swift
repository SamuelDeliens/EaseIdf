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
    @State private var initialLoadComplete = false
    
    @State var showEditTransportList = false
    @State var showAuthModal = true
    
    var body: some View {
        NavigationStack {
            VStack {
                if !authViewModel.isAuthenticated {
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
                
                FavoritesListView(viewModel: favoritesViewModel, showEditTransportList: $showEditTransportList)
            }
            .navigationTitle("EaseIdf")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(showEditTransportList ? "Done" : "Edit") {
                        withAnimation {
                            showEditTransportList.toggle()
                        }
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        showingAddTransport = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
                
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
            }
            .sheet(isPresented: $showingAddTransport) {
                AddTransportView()
                    .onDisappear {
                        // Refresh favorites when the sheet is dismissed
                        favoritesViewModel.loadFavorites()
                    }
            }
            .onAppear {
                showAuthModal = !authViewModel.isAuthenticated
                
                if !initialLoadComplete {
                    // S'assurer que les données sont chargées au moins une fois
                    Task {
                        // Pass the model context to the favorites view model
                        favoritesViewModel.setModelContext(modelContext)
                        
                        if LineDataService.shared.getAllLines().isEmpty ||
                           StopDataService.shared.getAllStops().isEmpty {
                            print("⚠️ Des données sont manquantes après le splash screen, rechargement...")
                            
                            if LineDataService.shared.getAllLines().isEmpty {
                                LineDataService.shared.loadLinesFromFile(named: "transport_lines")
                            }
                            
                            if StopDataService.shared.getAllStops().isEmpty {
                                StopDataService.shared.loadStopsFromFile(named: "transport_stops")
                            }
                        }
                        
                        initialLoadComplete = true
                    }
                }
            }
        }
        .overlay {
            if showAuthModal {
                APIKeyModalView(viewModel: authViewModel, show: $showAuthModal)
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(PersistenceService.shared.getModelContainer())
}
