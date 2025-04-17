//
//  FavoritesListView.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 14/04/2025.
//

import SwiftUI
import SwiftData

struct FavoritesListView: View {
    @ObservedObject var viewModel: FavoritesViewModel
    @Binding var showEditTransportList: Bool
    @State private var showingAddTransport = false
    
    private let timer = Timer.publish(every: 10, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack {
            // Affichage du temps écoulé depuis la dernière mise à jour des données
            if !viewModel.favorites.isEmpty {
                HStack {
                    Spacer()
                    Text("Dernière mise à jour : \(timeSinceLastRefresh)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
            }
            
            if viewModel.favorites.isEmpty {
                emptyStateView
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
        .onReceive(timer) { _ in
            // Mise à jour du temps écoulé depuis la dernière mise à jour
            viewModel.updateVisualDepartures()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("SettingsChanged"))) { _ in
            // Réinitialiser les timers lorsque les paramètres sont modifiés
            viewModel.stopRefreshTimers()
            viewModel.loadFavorites() // Cela réinitialisera les timers avec les nouveaux paramètres
        }
        .sheet(isPresented: $showingAddTransport) {
            AddTransportView()
                .onDisappear {
                    // Refresh favorites when the sheet is dismissed
                    viewModel.loadFavorites()
                }
        }
    }
    
    private var timeSinceLastRefresh: String {
        let interval = Date().timeIntervalSince(viewModel.lastDataRefresh)
        
        if interval < 60 {
            return "à l'instant"
        } else if interval < 120 {
            return "il y a 1 minute"
        } else if interval < 3600 {
            return "il y a \(Int(interval / 60)) minutes"
        } else if interval < 7200 {
            return "il y a 1 heure"
        } else {
            return "il y a \(Int(interval / 3600)) heures"
        }
    }
    
    private var favoritesList: some View {
        VStack(spacing: 0) {
            // List of favorites
            if showEditTransportList {
                editableList
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.favorites) { favorite in
                            let departures = viewModel.departures[favorite.id.uuidString] ?? []
                            let isActive = viewModel.activeFavorites.contains(where: { $0.id == favorite.id })
                            
                            // Utilisation de SwipeActionView pour le swipe-to-delete
                            SwipeActionView(favorite: favorite, action: {
                                // Action à exécuter lors de la suppression
                                withAnimation {
                                    viewModel.removeFavorite(with: favorite.id)
                                }
                            }) {
                                ZStack(alignment: .topTrailing) {
                                    FavoriteCardView(favorite: favorite, departures: departures)
                                    
                                    // Badge pour indiquer si le favori est inactif
                                    if !isActive {
                                        inactiveBadge
                                            .offset(x: 15, y: -15)
                                    }
                                }
                            }
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
    
    private var inactiveBadge: some View {
        HStack {
            Image(systemName: "moon.fill")
                .font(.body)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.secondary.opacity(0.2))
        )
        .padding(8)
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
            
            Image(systemName: "tram.fill")
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
