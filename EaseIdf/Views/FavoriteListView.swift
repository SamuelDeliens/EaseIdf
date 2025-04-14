//
//  FavoriteListView.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 14/04/2025.
//

import SwiftUI
import SwiftData

struct FavoriteListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \TransportFavoriteModel.priority, order: .reverse)
    private var favorites: [TransportFavoriteModel]
    
    @State private var showingAddFavoriteSheet = false
    @State private var editingFavorite: TransportFavoriteModel?
    
    var body: some View {
        NavigationStack {
            List {
                if favorites.isEmpty {
                    emptyStateView
                } else {
                    ForEach(favorites) { favorite in
                        favoriteRow(for: favorite)
                            .swipeActions {
                                Button(role: .destructive) {
                                    deleteFavorite(favorite)
                                } label: {
                                    Label("Supprimer", systemImage: "trash")
                                }
                                
                                Button {
                                    editingFavorite = favorite
                                } label: {
                                    Label("Modifier", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                    }
                    .onMove { indices, newOffset in
                        updatePriorities(from: indices, to: newOffset)
                    }
                }
            }
            .navigationTitle("Vos Favoris")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddFavoriteSheet = true
                    } label: {
                        Label("Ajouter", systemImage: "plus")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
            .sheet(isPresented: $showingAddFavoriteSheet) {
                AddFavoriteView()
            }
            .sheet(item: $editingFavorite) { favorite in
                EditFavoriteView(favorite: favorite)
            }
        }
    }
    
    // MARK: - Subviews
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "star.fill")
                .font(.system(size: 50))
                .foregroundColor(.yellow.opacity(0.7))
            
            Text("Aucun favori")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Ajoutez des arrêts et des lignes à vos favoris pour voir rapidement leurs prochains passages.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button {
                showingAddFavoriteSheet = true
            } label: {
                Text("Ajouter un favori")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top)
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
    
    private func favoriteRow(for favorite: TransportFavoriteModel) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(favorite.displayName)
                    .font(.headline)
                
                Spacer()
                
                if !favorite.conditions.isEmpty {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.blue)
                        .font(.caption)
                }
            }
            
            HStack {
                Text("Arrêt: \(favorite.stopId)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let lineId = favorite.lineId {
                    Text("• Ligne: \(lineId)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if !favorite.conditions.isEmpty {
                Text("\(favorite.conditions.count) condition(s) d'affichage")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.top, 2)
            }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Helper Methods
    
    private func deleteFavorite(_ favorite: TransportFavoriteModel) {
        modelContext.delete(favorite)
        try? modelContext.save()
    }
    
    private func updatePriorities(from source: IndexSet, to destination: Int) {
        // Get the items to move
        var itemsToMove = source.map { favorites[$0] }
        
        // Create a copy of the current favorites list
        var updatedFavorites = favorites
        
        // Remove the items at the source indices
        for index in source.sorted(by: >) {
            updatedFavorites.remove(at: index)
        }
        
        // Insert the items at the destination index
        updatedFavorites.insert(contentsOf: itemsToMove, at: destination)
        
        // Update priorities based on the new order (highest priority = highest number)
        for (index, favorite) in updatedFavorites.enumerated().reversed() {
            favorite.priority = index
        }
        
        try? modelContext.save()
    }
}

struct AddFavoriteView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var stopId = ""
    @State private var lineId = ""
    @State private var displayName = ""
    @State private var showingStopSearchSheet = false
    @State private var showingLineSearchSheet = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Informations")) {
                    TextField("Nom à afficher", text: $displayName)
                    
                    HStack {
                        TextField("ID de l'arrêt", text: $stopId)
                        
                        Button {
                            showingStopSearchSheet = true
                        } label: {
                            Image(systemName: "magnifyingglass")
                        }
                    }
                    
                    HStack {
                        TextField("ID de la ligne (optionnel)", text: $lineId)
                        
                        Button {
                            showingLineSearchSheet = true
                        } label: {
                            Image(systemName: "magnifyingglass")
                        }
                    }
                }
                
                Section {
                    Button("Ajouter") {
                        addFavorite()
                    }
                    .disabled(stopId.isEmpty || displayName.isEmpty)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationTitle("Nouveau Favori")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
            }
            // Ces sheets seront implémentés dans la prochaine étape
            .sheet(isPresented: $showingStopSearchSheet) {
                Text("Rechercher un arrêt")
            }
            .sheet(isPresented: $showingLineSearchSheet) {
                Text("Rechercher une ligne")
            }
        }
    }
    
    private func addFavorite() {
        let newFavorite = TransportFavoriteModel(
            stopId: stopId,
            lineId: lineId.isEmpty ? nil : lineId,
            displayName: displayName
        )
        
        modelContext.insert(newFavorite)
        try? modelContext.save()
        
        dismiss()
    }
}

struct EditFavoriteView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var favorite: TransportFavoriteModel
    
    @State private var showingConditionSheet = false
    @State private var showingStopSearchSheet = false
    @State private var showingLineSearchSheet = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Informations")) {
                    TextField("Nom à afficher", text: $favorite.displayName)
                    
                    HStack {
                        TextField("ID de l'arrêt", text: $favorite.stopId)
                        
                        Button {
                            showingStopSearchSheet = true
                        } label: {
                            Image(systemName: "magnifyingglass")
                        }
                    }
                    
                    HStack {
                        TextField("ID de la ligne (optionnel)", text: Binding(
                            get: { favorite.lineId ?? "" },
                            set: { favorite.lineId = $0.isEmpty ? nil : $0 }
                        ))
                        
                        Button {
                            showingLineSearchSheet = true
                        } label: {
                            Image(systemName: "magnifyingglass")
                        }
                    }
                }
                
                Section(header: Text("Conditions d'affichage")) {
                    if favorite.conditions.isEmpty {
                        Button {
                            showingConditionSheet = true
                        } label: {
                            Label("Ajouter une condition", systemImage: "plus.circle")
                        }
                    } else {
                        ForEach(favorite.conditions) { condition in
                            ConditionRow(condition: condition)
                        }
                        .onDelete(perform: deleteCondition)
                        
                        Button {
                            showingConditionSheet = true
                        } label: {
                            Label("Ajouter une condition", systemImage: "plus.circle")
                        }
                    }
                }
            }
            .navigationTitle("Modifier Favori")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Enregistrer") {
                        try? modelContext.save()
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingConditionSheet) {
                AddConditionView(favorite: favorite)
            }
            // Ces sheets seront implémentés dans la prochaine étape
            .sheet(isPresented: $showingStopSearchSheet) {
                Text("Rechercher un arrêt")
            }
            .sheet(isPresented: $showingLineSearchSheet) {
                Text("Rechercher une ligne")
            }
        }
    }
    
    private func deleteCondition(at offsets: IndexSet) {
        for index in offsets {
            let conditionToDelete = favorite.conditions[index]
            modelContext.delete(conditionToDelete)
        }
        try? modelContext.save()
    }
}

// Simple view to display condition information
struct ConditionRow: View {
    let condition: DisplayConditionModel
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: iconForCondition)
                        .foregroundColor(condition.isActive ? .blue : .gray)
                    
                    Text(titleForCondition)
                        .font(.subheadline)
                        .foregroundColor(condition.isActive ? .primary : .gray)
                }
                
                Text(detailsForCondition)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { condition.isActive },
                set: { condition.isActive = $0 }
            ))
            .labelsHidden()
        }
    }
    
    private var iconForCondition: String {
        switch condition.conditionType {
        case "timeRange":
            return "clock.fill"
        case "dayOfWeek":
            return "calendar"
        case "location":
            return "location.fill"
        default:
            return "questionmark.circle"
        }
    }
    
    private var titleForCondition: String {
        switch condition.conditionType {
        case "timeRange":
            return "Plage horaire"
        case "dayOfWeek":
            return "Jours de la semaine"
        case "location":
            return "Localisation"
        default:
            return "Condition"
        }
    }
    
    private var detailsForCondition: String {
        switch condition.conditionType {
        case "timeRange":
            if let start = condition.startTime, let end = condition.endTime {
                let formatter = DateFormatter()
                formatter.timeStyle = .short
                return "De \(formatter.string(from: start)) à \(formatter.string(from: end))"
            }
            return "Horaires non définis"
            
        case "dayOfWeek":
            if let dayData = condition.dayOfWeekData {
                let dayNames = ["Dimanche", "Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi"]
                let dayIds = dayData.components(separatedBy: ",")
                    .compactMap { Int($0) }
                    .map { $0 - 1 } // Adjust for 0-based array
                    .filter { $0 >= 0 && $0 < dayNames.count }
                    .map { dayNames[$0] }
                
                return dayIds.joined(separator: ", ")
            }
            return "Jours non définis"
            
        case "location":
            if let lat = condition.latitude, let long = condition.longitude, let radius = condition.radius {
                return "Rayon de \(Int(radius))m autour de (\(String(format: "%.4f", lat)), \(String(format: "%.4f", long)))"
            }
            return "Localisation non définie"
            
        default:
            return "Détails non disponibles"
        }
    }
}

#Preview {
    FavoriteListView()
}
