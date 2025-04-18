//
//  DayOfWeekConditionViewAdapted.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 17/04/2025.
//


import SwiftUI

struct DayOfWeekConditionView: View {
    let editingIndex: Int?
    let saveDayOfWeekCondition: (Int?, DayOfWeekCondition) -> Void
    
    var initialDays: [Weekday] = [.monday, .tuesday, .wednesday, .thursday, .friday]
    
    @State private var selectedDays: Set<Weekday> = []
    
    init(
        editingIndex: Int? = nil,
        saveDayOfWeekCondition: @escaping (Int?, DayOfWeekCondition) -> Void,
        initialDays: [Weekday]
    ) {
        self.editingIndex = editingIndex
        self.saveDayOfWeekCondition = saveDayOfWeekCondition
                        
        self.initialDays = initialDays.isEmpty ? self.initialDays : initialDays
        _selectedDays = State(initialValue: Set(initialDays))
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
                    saveDayOfWeekCondition(
                        self.editingIndex,
                        DayOfWeekCondition(
                            days: Array(self.selectedDays)
                        )
                    )
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
}
