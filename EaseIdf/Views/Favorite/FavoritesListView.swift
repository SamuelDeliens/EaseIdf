//
//  FavoritesListView.swift
//  EaseIdf
//
//  Modified to support enhanced swipe actions
//


import SwiftUI
import SwiftData

struct FavoritesListView: View {
    @ObservedObject var viewModel: FavoritesViewModel
    @Binding var showEditTransportList: Bool
    
    @State private var showEditTransport = false
    @State private var selectedEditTransport = TransportFavorite(
        id: UUID(),
        stopId: "",
        lineId: nil,
        displayName: "",
        displayConditions: [],
        priority: 0
    )
    
    @State private var showingAddTransport = false
        
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
        .sheet(isPresented: $showEditTransport) {
            EditFavoriteView(favorite: $selectedEditTransport)
                .onDisappear {
                    viewModel.loadFavorites()
                        Task {
                            await WidgetService.shared.refreshWidgetData()
                        }
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
                    VStack(spacing: 16) {
                        ForEach(viewModel.favorites) { favorite in
                            let departures = viewModel.departures[favorite.id.uuidString] ?? []
                            let isActive = viewModel.activeFavorites.contains(where: { $0.id == favorite.id })
                            
                            // Utilisation de SwipeActionsView pour le swipe à deux niveaux
                            SwipeActionsView(
                                favorite: favorite,
                                deleteAction: {
                                    // Action de suppression
                                    withAnimation {
                                        viewModel.removeFavorite(with: favorite.id)
                                    }
                                },
                                editAction: {
                                    viewModel.stopRefreshTimers()
                                    selectedEditTransport = favorite
                                    showEditTransport = true
                                }
                            ) {
                                ZStack(alignment: .topTrailing) {
                                    FavoriteCardView(favorite: favorite, departures: departures)
                                    
                                    // Badge pour indiquer si le favori est inactif
                                    if !isActive {
                                        inactiveBadge
                                            .offset(x: 10, y: -10)
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .fixedSize(horizontal: false, vertical: true)
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
                .font(.system(size: 16))
        }
        .padding(5)
        .background(
            Circle()
                .fill(Color.secondary.opacity(0.2))
        )
    }
    
    private var editableList: some View {
        List {
            ForEach(viewModel.favorites) { favorite in
                HStack {
                    Image(systemName: "line.3.horizontal")
                        .foregroundColor(.secondary)
                    
                    Text(favorite.displayName)
                    
                    Spacer()
                    
                    if !viewModel.activeFavorites.contains(where: { $0.id == favorite.id }) {
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
