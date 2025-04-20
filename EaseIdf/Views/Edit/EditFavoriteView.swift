//
//  EditFavoriteView.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 17/04/2025.
//


import SwiftUI
import SwiftData

struct EditFavoriteView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @StateObject var viewModel: EditFavoriteViewModel
    let selectedFavorite: Binding<TransportFavorite>
    
    init(favorite: Binding<TransportFavorite>) {
        self._viewModel = StateObject(wrappedValue: EditFavoriteViewModel(
            favorite: favorite,
            favoriteService: AppServices.shared.favoriteService,
            conditionService: AppServices.shared.conditionService
        ))
        self.selectedFavorite = favorite
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Section pour les informations de base
                Section(header: Text("Informations")) {
                    // Affichage de la ligne (non modifiable)
                    if let lineShortName = viewModel.favorite.wrappedValue.lineShortName,
                       let lineColor = viewModel.favorite.wrappedValue.lineColor,
                       let lineTextColor = viewModel.favorite.wrappedValue.lineTextColor {
                        
                        HStack {
                            Text("Ligne")
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text(lineShortName)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .foregroundColor(Color(hex: lineTextColor))
                                .background(Color(hex: lineColor))
                                .cornerRadius(5)
                        }
                    }
                    
                    // Affichage de l'arrêt (non modifiable)
                    if let stopName = viewModel.favorite.wrappedValue.stopName {
                        HStack {
                            Text("Arrêt")
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text(stopName)
                                .lineLimit(1)
                        }
                    }
                    
                    // Nom du favori (modifiable)
                    TextField("Nom du favori", text: $viewModel.displayName)
                }
                
                // Section pour les conditions existantes
                Section(header: Text("Conditions d'affichage")) {
                    ForEach(Array(viewModel.displayConditions.enumerated()), id: \.element.id) { index, condition in
                        EditConditionRow(condition: condition, index: index, viewModel: viewModel)
                            .padding(.vertical, 4)
                    }
                    .onDelete { indexSet in
                        viewModel.removeCondition(at: indexSet)
                    }
                    
                    // Bouton pour ajouter une nouvelle condition
                    Button {
                        viewModel.showingConditionTypeSelector = true
                    } label: {
                        Label("Ajouter une condition", systemImage: "plus.circle")
                    }
                }
                
                // Section pour la priorité
                Section(header: Text("Priorité"), footer: Text("Une priorité plus élevée affichera ce transport avant les autres dans la liste et le widget.")) {
                    Stepper("Priorité: \(viewModel.priority)", value: $viewModel.priority, in: 0...10)
                }
            }
            .navigationTitle("Modifier le favori")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer") {
                        viewModel.saveFavorite(context: modelContext)
                        dismiss()
                    }
                    .disabled(viewModel.displayName.isEmpty)
                }
            }
            .sheet(isPresented: $viewModel.showingConditionTypeSelector) {
                ConditionTypeSelectorView(viewModel: viewModel)
            }
            .fullScreenCover(isPresented: Binding<Bool>(
                get: { viewModel.activeConditionSheet != .none },
                set: { if !$0 { viewModel.closeConditionSheet() } }
            )) {
                conditionSheetView
            }
            .alert("Favori modifié", isPresented: $viewModel.showingSavedAlert) {
                Button("OK") {
                    // Notifier que les favoris ont changé
                    NotificationCenter.default.post(name: NSNotification.Name("FavoritesChanged"), object: nil)
                    dismiss()
                }
            } message: {
                Text("Les modifications ont été enregistrées avec succès.")
            }
            .onAppear {
                viewModel.setModelContext(modelContext)
            }
        }
    }
    
    private var conditionSheetView: some View {
        switch viewModel.activeConditionSheet {
        case .timeRange:
            return AnyView(timeRangeSheet)
        case .dayOfWeek:
            return AnyView(dayOfWeekSheet)
        case .location:
            return AnyView(locationSheet)
        case .none:
            return AnyView(EmptyView())
        }
    }
    
    private var timeRangeSheet: some View {
        let timeRange: TimeRangeCondition? = {
            if let index = viewModel.editingConditionIndex,
               index < viewModel.displayConditions.count {
                return viewModel.displayConditions[index].timeRange
            } else {
                return nil
            }
        }()
        
        return NavigationStack {
            TimeRangeConditionView(
                editingIndex: viewModel.editingConditionIndex,
                saveTimeRangeCondition: viewModel.saveTimeRangeCondition,
                startTime: timeRange?.startTime,
                endTime: timeRange?.endTime
            )
            .navigationTitle("Configuration horaire")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Retour") {
                        viewModel.closeConditionSheet()
                    }
                }
            }
        }
    }
    
    private var dayOfWeekSheet: some View {
        let dayOfWeek: DayOfWeekCondition? = {
            if let index = viewModel.editingConditionIndex,
               index < viewModel.displayConditions.count {
                return viewModel.displayConditions[index].dayOfWeekCondition
            } else {
                return nil
            }
        }()
        
        return AnyView(
            NavigationStack {
                DayOfWeekConditionView(
                    editingIndex: viewModel.editingConditionIndex,
                    saveDayOfWeekCondition: viewModel.saveDayOfWeekConditionEdit,
                    initialDays: dayOfWeek?.days ?? []
                )
                .navigationTitle("Configuration des jours")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Retour") {
                            viewModel.closeConditionSheet()
                        }
                    }
                }
            }
        )
    }
    
    private var locationSheet: some View {
        AnyView(
            NavigationStack {
                EditLocationConditionView(
                    viewModel: viewModel,
                    editingIndex: viewModel.editingConditionIndex
                )
                .navigationTitle("Configuration de position")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Retour") {
                            viewModel.closeConditionSheet()
                        }
                    }
                }
            }
        )
    }
}

// Extension de l'EditFavoriteView pour le preview
struct EditFavoriteView_Previews: PreviewProvider {
    static var previews: some View {
        @State var sampleFavorite = TransportFavorite(
            id: UUID(),
            stopId: "12345",
            lineId: "C01742",
            displayName: "RER A Gare de Lyon",
            displayConditions: [],
            priority: 1,
            lineName: "RER A",
            lineShortName: "A",
            lineColor: "FF0000",
            lineTextColor: "FFFFFF",
            stopName: "Gare de Lyon",
            stopLatitude: 48.8448,
            stopLongitude: 2.3735,
            stopType: "Quay_FR1"
        )
        
        EditFavoriteView(favorite: $sampleFavorite)
    }
}
