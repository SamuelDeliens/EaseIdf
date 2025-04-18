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
    
    @ObservedObject var viewModel: EditFavoriteViewModel
    let selectedEditTransport: Binding<TransportFavorite>
    
    init(favorite: Binding<TransportFavorite>) {
        self._viewModel = ObservedObject(wrappedValue: EditFavoriteViewModel(favorite: favorite))
        self.selectedEditTransport = favorite
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
                Button("OK") { dismiss() }
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

struct EditConditionRow: View {
    let condition: DisplayCondition
    let index: Int
    @ObservedObject var viewModel: EditFavoriteViewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                // Icône de la condition
                Image(systemName: conditionIcon)
                    .foregroundColor(conditionColor)
                    .font(.headline)
                
                // Nom de la condition
                Text(conditionTitle)
                    .font(.headline)
                
                Spacer()
                
                // Toggle pour activer/désactiver
                Toggle("", isOn: Binding(
                    get: { condition.isActive },
                    set: { viewModel.toggleCondition(at: index, isActive: $0) }
                ))
                .labelsHidden()
            }
            
            // Détails de la condition
            Text(conditionDetails)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.leading, 28)
                .padding(.top, 2)
            
            // Bouton d'édition
            HStack {
                Spacer()
                
                Button {
                    viewModel.editCondition(at: index)
                } label: {
                    Label("Modifier", systemImage: "pencil")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(10)
    }
    
    // Icône en fonction du type de condition
    private var conditionIcon: String {
        switch condition.type {
        case .timeRange:
            return "clock.fill"
        case .dayOfWeek:
            return "calendar"
        case .location:
            return "location.fill"
        }
    }
    
    // Couleur en fonction du type de condition
    private var conditionColor: Color {
        switch condition.type {
        case .timeRange:
            return .blue
        case .dayOfWeek:
            return .green
        case .location:
            return .orange
        }
    }
    
    // Titre en fonction du type de condition
    private var conditionTitle: String {
        switch condition.type {
        case .timeRange:
            return "Condition d'horaire"
        case .dayOfWeek:
            return "Condition de jour"
        case .location:
            return "Condition de position"
        }
    }
    
    // Détails de la condition
    private var conditionDetails: String {
        switch condition.type {
        case .timeRange:
            guard let timeRange = condition.timeRange else {
                return "Horaire non configuré"
            }
            
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            
            let startTime = formatter.string(from: timeRange.startTime)
            let endTime = formatter.string(from: timeRange.endTime)
            
            return "Entre \(startTime) et \(endTime)"
            
        case .dayOfWeek:
            guard let dayCondition = condition.dayOfWeekCondition, !dayCondition.days.isEmpty else {
                return "Jours non configurés"
            }
            
            let dayNames = dayCondition.days.map { getDayName($0) }.joined(separator: ", ")
            return "Les jours suivants : \(dayNames)"
            
        case .location:
            guard let locationCondition = condition.locationCondition else {
                return "Position non configurée"
            }
            
            return "Dans un rayon de \(Int(locationCondition.radius))m autour de la position définie"
        }
    }
    
    // Nom du jour de la semaine
    private func getDayName(_ day: Weekday) -> String {
        switch day {
        case .monday: return "Lundi"
        case .tuesday: return "Mardi"
        case .wednesday: return "Mercredi"
        case .thursday: return "Jeudi"
        case .friday: return "Vendredi"
        case .saturday: return "Samedi"
        case .sunday: return "Dimanche"
        }
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
