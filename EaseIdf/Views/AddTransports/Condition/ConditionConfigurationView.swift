//
//  ConditionConfigurationView.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 15/04/2025.
//


import SwiftUI

struct ConditionConfigurationView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: AddTransportViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Récapitulatif du favori créé
                favoriteRecapSection
                
                // Section pour ajouter de nouvelles conditions
                addConditionSection
                
                // Liste des conditions existantes
                conditionsList
                
                Spacer(minLength: 20)
                
                // Bouton de sauvegarde
                saveButton
            }
            .padding()
        }
        .navigationTitle("Conditions d'affichage")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Annuler") {
                    dismiss()
                }
            }
        }
        // Utiliser un fullScreenCover contrôlé par activeConditionSheet
        .fullScreenCover(isPresented: Binding<Bool>(
            get: { viewModel.activeConditionSheet != .none },
            set: { if !$0 { viewModel.closeConditionSheet() } }
        )) {
            conditionSheetView
        }
    }
    
    // Vue pour le sheet de condition active
    private var conditionSheetView: some View {
        Group {
            switch viewModel.activeConditionSheet {
            case .timeRange:
                NavigationStack {
                    TimeRangeConditionView(
                        viewModel: viewModel,
                        editingIndex: viewModel.editingConditionIndex
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
            case .dayOfWeek:
                NavigationStack {
                    DayOfWeekConditionView(
                        viewModel: viewModel,
                        editingIndex: viewModel.editingConditionIndex
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
            case .location:
                NavigationStack {
                    LocationConditionView(
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
            case .none:
                EmptyView()
            }
        }
    }
    
    private var favoriteRecapSection: some View {
        VStack(spacing: 8) {
            if let line = viewModel.selectedLine {
                LineSelectionHeader(line: line)
            }
            
            if let stop = viewModel.selectedStop {
                HStack {
                    Label(
                        title: { Text(stop.name_stop) },
                        icon: { Image(systemName: "mappin.and.ellipse") }
                    )
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
                    
                    Spacer()
                }
            }
            
            Text(viewModel.displayName)
                .font(.headline)
                .padding(.top, 4)
        }
        .padding(.bottom, 16)
    }
    
    private var addConditionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ajouter une condition")
                .font(.headline)
            
            HStack(spacing: 12) {
                // Bouton pour condition d'heure
                Button {
                    viewModel.addTimeRangeCondition()
                } label: {
                    VStack {
                        Image(systemName: "clock")
                            .font(.title2)
                        Text("Heure")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(10)
                }
                
                // Bouton pour condition de jour
                Button {
                    viewModel.addDayOfWeekCondition()
                } label: {
                    VStack {
                        Image(systemName: "calendar")
                            .font(.title2)
                        Text("Jour")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.green.opacity(0.1))
                    .foregroundColor(.green)
                    .cornerRadius(10)
                }
                
                // Bouton pour condition de position
                Button {
                    viewModel.addLocationCondition()
                } label: {
                    VStack {
                        Image(systemName: "location")
                            .font(.title2)
                        Text("Position")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.orange.opacity(0.1))
                    .foregroundColor(.orange)
                    .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var conditionsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            if viewModel.displayConditions.isEmpty {
                Text("Aucune condition")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                Text("Conditions configurées")
                    .font(.headline)
                    .padding(.top, 8)
                
                // Liste des conditions
                ForEach(Array(viewModel.displayConditions.enumerated()), id: \.element.id) { index, condition in
                    ConditionRow(condition: condition, index: index, viewModel: viewModel)
                        .padding(.vertical, 4)
                }
                
                // Texte d'explication
                Text("Les conditions configurées déterminent quand ce transport sera affiché. Si plusieurs conditions sont actives, toutes doivent être satisfaites pour que le transport soit affiché.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var saveButton: some View {
        Button {
            viewModel.saveConditions()
            dismiss()
        } label: {
            if viewModel.isSaving {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                Text("Enregistrer")
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
        .buttonStyle(.borderedProminent)
        .padding(.horizontal)
        .padding(.bottom)
    }
}

struct ConditionRow: View {
    let condition: DisplayCondition
    let index: Int
    @ObservedObject var viewModel: AddTransportViewModel
    
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
            
            // Boutons d'édition et de suppression
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
                
                Button {
                    viewModel.removeCondition(at: index)
                } label: {
                    Label("Supprimer", systemImage: "trash")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .tint(.red)
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
