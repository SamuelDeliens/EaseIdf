//
//  FavoritesListView.swift
//  EaseIdf
//
//  Modified to support enhanced swipe actions
//


import SwiftUI
import SwiftData

struct FavoritesListView: View {
    // ViewModel
    @ObservedObject var viewModel: FavoritesViewModel
    
    // États UI
    @Binding var showEditTransportList: Bool
    @State private var showingDeleteAlert = false
    @State private var showEditTransport = false
    @State private var showingAddTransport = false
    
    var body: some View {
        VStack {
            // Affichage du temps écoulé depuis la dernière mise à jour des données
            if !viewModel.favorites.isEmpty {
                HStack {
                    Spacer()
                    Text("Dernière mise à jour : \(viewModel.getTimeSinceLastRefresh())")
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
            // Charger les favoris et leurs conditions
            viewModel.loadFavorites()
            
            // Rafraîchir les données de départs
            viewModel.refreshDepartures()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("SettingsChanged"))) { _ in
            // Réinitialiser les timers lorsque les paramètres sont modifiés
            viewModel.stopRefreshTimers()
            viewModel.loadFavorites() // Cela réinitialisera les timers avec les nouveaux paramètres
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("FavoritesChanged"))) { _ in
            // Recharger les favoris quand ils sont modifiés (ajout/suppression/modification)
            viewModel.loadFavorites()
        }
        .sheet(isPresented: $showingAddTransport) {
            AddTransportView()
                .onDisappear {
                    // Refresh favorites when the sheet is dismissed
                    viewModel.loadFavorites()
                }
        }
        .sheet(isPresented: $showEditTransport) {
            if let favorite = viewModel.selectedFavorite {
                EditFavoriteView(favorite: Binding(
                    get: { favorite },
                    set: { newValue in
                        // Cette implémentation sera appelée lorsque le favori est modifié
                        viewModel.loadFavorites()
                    }
                ))
                .onDisappear {
                    viewModel.loadFavorites()
                    Task {
                        await WidgetService.shared.refreshWidgetData()
                    }
                }
            }
        }
        .alert(isPresented: $viewModel.showingDeleteAlert) {
            Alert(
                title: Text("Supprimer ce favori ?"),
                message: Text("Êtes-vous sûr de vouloir supprimer \"\(viewModel.selectedFavorite?.displayName ?? "")\" de vos favoris ?"),
                primaryButton: .destructive(Text("Supprimer")) {
                    withAnimation {
                        viewModel.confirmDeleteFavorite()
                    }
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    private var favoritesList: some View {
        VStack(spacing: 0) {
            // List of favorites
            if showEditTransportList {
                editableList
            } else {
                List {
                    ForEach(viewModel.favorites) { favorite in
                        let departures = viewModel.getDepartures(for: favorite)
                        let isActive = viewModel.isFavoriteActive(favorite)
                        
                        // Utilisation de SwipeActionsView pour le swipe à deux niveaux
                        ZStack(alignment: .topTrailing) {
                            FavoriteCardView(favorite: favorite, departures: departures)
                                .id("card-\(favorite.id)")
                            
                            // Badge pour indiquer si le favori est inactif
                            if !isActive {
                                inactiveBadge
                                    .offset(x: 10, y: -10)
                            }
                        }
                        .swipeActions {
                            Button {
                                viewModel.prepareDeleteFavorite(favorite)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            .tint(Color(.red))
                            
                            Button {
                                viewModel.editFavorite(favorite)
                                showEditTransport = true
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(Color(.blue))
                        }
                        .listRowInsets(EdgeInsets(top: 7, leading: 14, bottom: 7, trailing: 14))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                }
                .listStyle(PlainListStyle())
                .padding(.vertical)
                .refreshable {
                    // Simplement recharger les favoris, ce qui mettra également à jour les actifs
                    viewModel.loadFavorites()
                    // Puis rafraîchir les départs
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
                    
                    if !viewModel.isFavoriteActive(favorite) {
                        Image(systemName: "moon.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .onDelete { indexSet in
                // Créer un tableau temporaire des favoris à supprimer
                let favoritesToDelete = indexSet.map { viewModel.favorites[$0] }
                
                // Supprimer chaque favori
                for favorite in favoritesToDelete {
                    viewModel.prepareDeleteFavorite(favorite)
                    viewModel.confirmDeleteFavorite()
                }
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
