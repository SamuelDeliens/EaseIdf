//
//  DayOfWeekConditionView.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 15/04/2025.
//

import SwiftUI

struct DayOfWeekConditionView: View {
    @ObservedObject var viewModel: AddTransportViewModel
    
    // Pour l'édition d'une condition existante
    var editingIndex: Int?
    
    @State private var selectedDays: Set<Weekday> = []
    
    init(viewModel: AddTransportViewModel, editingIndex: Int? = nil) {
        self.viewModel = viewModel
        self.editingIndex = editingIndex
        
        // Initialiser avec les valeurs existantes ou des valeurs par défaut
        var initialDays: Set<Weekday> = []
        
        if let index = editingIndex,
           index < viewModel.displayConditions.count,
           let dayCondition = viewModel.displayConditions[index].dayOfWeekCondition {
            // Si on édite une condition existante, utiliser ses jours
            initialDays = Set(dayCondition.days)
        } else {
            // Par défaut, sélectionner les jours de semaine (lundi-vendredi)
            initialDays = [.monday, .tuesday, .wednesday, .thursday, .friday]
        }
        
        _selectedDays = State(initialValue: initialDays)
    }
    
    var body: some View {
        Form {
            Section(header: Text("Sélectionnez les jours")) {
                ForEach(Weekday.allCases, id: \.self) { day in
                    Toggle(isOn: Binding(
                        get: { selectedDays.contains(day) },
                        set: { isSelected in
                            if isSelected {
                                selectedDays.insert(day)
                            } else {
                                selectedDays.remove(day)
                            }
                        }
                    )) {
                        Text(dayName(day))
                    }
                }
            }
            
            Section {
                Button("Tous les jours") {
                    selectedDays = Set(Weekday.allCases)
                }
                
                Button("Jours ouvrés (Lun-Ven)") {
                    selectedDays = [.monday, .tuesday, .wednesday, .thursday, .friday]
                }
                
                Button("Week-end (Sam-Dim)") {
                    selectedDays = [.saturday, .sunday]
                }
                
                Button("Aucun jour") {
                    selectedDays = []
                }
            }
            
            Section(footer: Text("Cette condition sera active uniquement les jours sélectionnés.")) {
                // Vérification de la validité
                if selectedDays.isEmpty {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Sélectionnez au moins un jour.")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            Section {
                Button("Enregistrer") {
                    saveDayOfWeekCondition()
                }
                .disabled(selectedDays.isEmpty)
                .frame(maxWidth: .infinity)
                .buttonStyle(.borderedProminent)
            }
        }
    }
    
    private func dayName(_ day: Weekday) -> String {
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
    
    private func saveDayOfWeekCondition() {
        let dayOfWeekCondition = DayOfWeekCondition(
            days: Array(selectedDays)
        )
        
        if let index = editingIndex {
            // Mettre à jour une condition existante
            viewModel.updateDayOfWeekCondition(at: index, dayOfWeek: dayOfWeekCondition)
        } else {
            // Créer une nouvelle condition
            let newCondition = DisplayCondition(
                type: .dayOfWeek,
                isActive: true,
                dayOfWeekCondition: dayOfWeekCondition
            )
            viewModel.addCondition(newCondition)
        }
        
        // Fermer le sheet
        viewModel.closeConditionSheet()
    }
}
