//
//  FavoritesListView.swift
//  EaseIdf
//
//  Created by Claude on 15/04/2025.
//

import SwiftUI
import SwiftData

struct FavoritesListView: View {
    @ObservedObject var viewModel: FavoritesViewModel
    @State private var isEditing = false
    @State private var showingAddTransport = false
    
    var body: some View {
        VStack {
            if viewModel.favorites.isEmpty {
                emptyStateView
            } else if viewModel.activeFavorites.isEmpty {
                noActiveView
            } else {
                favoritesList
            }
        }
        .overlay(
            Group {
                if viewModel.isLoading {
                    loadingOverlay
                }
            }
        )
        .onAppear {
            viewModel.updateActiveFavorites()
            viewModel.refreshDepartures()
        }
        .sheet(isPresented: $showingAddTransport) {
            AddTransportView()
                .onDisappear {
                    // Refresh favorites when the sheet is dismissed
                    viewModel.loadFavorites()
                }
        }
    }
    
    private var favoritesList: some View {
        VStack(spacing: 0) {
            // Edit button
            HStack {
                Spacer()
                Button(isEditing ? "Terminé" : "Modifier") {
                    withAnimation {
                        isEditing.toggle()
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 8)
            
            // List of favorites
            if isEditing {
                editableList
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.activeFavorites) { favorite in
                            let departures = viewModel.departures[favorite.id.uuidString] ?? []
                            FavoriteCardView(favorite: favorite, departures: departures)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
                .refreshable {
                    viewModel.updateActiveFavorites()
                    viewModel.refreshDepartures()
                }
            }
        }
    }
    
    private var editableList: some View {
        List {
            ForEach(viewModel.favorites) { favorite in
                HStack {
                    Image(systemName: "line.3.horizontal")
                        .foregroundColor(.secondary)
                    
                    Text(favorite.displayName)
                    
                    Spacer()
                    
                    if viewModel.activeFavorites.contains(where: { $0.id == favorite.id }) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else {
                        Image(systemName: "moon.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .onDelete { indexSet in
                viewModel.removeFavorite(at: indexSet)
            }
            .onMove { source, destination in
                viewModel.moveFavorite(from: source, to: destination)
            }
        }
        .environment(\.editMode, .constant(.active))
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "train.side.front.car")
                .font(.system(size: 70))
                .foregroundColor(.secondary)
            
            Text("Aucun favori")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Ajoutez vos lignes et arrêts préférés pour les voir ici.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Button {
                showingAddTransport = true
            } label: {
                Label("Ajouter un transport", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top, 10)
            
            Spacer()
        }
    }
    
    private var noActiveView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("Aucun favori actif")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Vos favoris sont configurés pour s'afficher à certains moments ou endroits spécifiques.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            HStack(spacing: 16) {
                Button {
                    isEditing = true
                } label: {
                    Text("Gérer mes favoris")
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                Button {
                    showingAddTransport = true
                } label: {
                    Label("Ajouter", systemImage: "plus")
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            
            Spacer()
        }
    }
    
    private var loadingOverlay: some View {
        Color.black.opacity(0.1)
            .ignoresSafeArea()
            .overlay(
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
                    .padding()
                    .background(Color(.systemBackground).opacity(0.8))
                    .cornerRadius(10)
            )
            .allowsHitTesting(true)
    }
}

struct FavoritesListView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = FavoritesViewModel()
        return FavoritesListView(viewModel: viewModel)
    }
}
