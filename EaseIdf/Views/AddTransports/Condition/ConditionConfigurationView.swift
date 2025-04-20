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
        
        return AnyView(
            NavigationStack {
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
        )
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
                    saveDayOfWeekCondition: viewModel.saveDayOfWeekCondition,
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
                AddLocationConditionView(
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
                    AddConditionRow(condition: condition, index: index, viewModel: viewModel)
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
            
            // Notifier que les favoris ont changé
            NotificationCenter.default.post(name: NSNotification.Name("FavoritesChanged"), object: nil)
            
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
