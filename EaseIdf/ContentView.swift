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
    @State private var showingSettings = false
    
    var body: some View {
        NavigationStack {
            if authViewModel.isAuthenticated {
                VStack {
                    Text("Mes Transports")
                        .font(.largeTitle)
                        .padding()
                    
                    Spacer()
                    
                    Text("Vos favoris apparaîtront ici")
                        .foregroundColor(.secondary)
                    
                    Spacer()
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
                }
                .sheet(isPresented: $showingSettings) {
                    SettingsView()
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
