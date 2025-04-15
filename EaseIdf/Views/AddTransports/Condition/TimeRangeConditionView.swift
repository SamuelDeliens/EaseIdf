//
//  TimeRangeConditionView.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 15/04/2025.
//

import SwiftUI

struct TimeRangeConditionView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: AddTransportViewModel
    
    // Pour l'édition d'une condition existante
    var editingIndex: Int?
    
    @State private var startTime: Date
    @State private var endTime: Date
    
    init(viewModel: AddTransportViewModel, editingIndex: Int? = nil) {
        self.viewModel = viewModel
        self.editingIndex = editingIndex
        
        // Initialiser avec les valeurs existantes ou des valeurs par défaut
        if let index = editingIndex,
           index < viewModel.displayConditions.count,
           let timeRange = viewModel.displayConditions[index].timeRange {
            _startTime = State(initialValue: timeRange.startTime)
            _endTime = State(initialValue: timeRange.endTime)
        } else {
            // Valeurs par défaut: 8h - 10h
            var calendar = Calendar.current
            var dateComponents = calendar.dateComponents([.year, .month, .day], from: Date())
            
            // Start time: 8:00 AM
            dateComponents.hour = 8
            dateComponents.minute = 0
            _startTime = State(initialValue: calendar.date(from: dateComponents) ?? Date())
            
            // End time: 10:00 AM
            dateComponents.hour = 10
            dateComponents.minute = 0
            _endTime = State(initialValue: calendar.date(from: dateComponents) ?? Date())
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Plage horaire")) {
                    DatePicker("Heure de début", selection: $startTime, displayedComponents: .hourAndMinute)
                    DatePicker("Heure de fin", selection: $endTime, displayedComponents: .hourAndMinute)
                }
                
                Section(footer: Text("Cette condition sera active seulement pendant la plage horaire définie. Si l'heure de fin est antérieure à l'heure de début, la condition sera considérée comme s'étalant sur deux jours (par exemple, de 22:00 à 6:00).")) {
                    Button("Présélections") {
                        showPresetOptions()
                    }
                }
                
                Section {
                    // Vérification de la validité des horaires
                    if !isTimeRangeValid {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("L'heure de début et de fin ne peuvent pas être identiques.")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
            .navigationTitle("Configuration horaire")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer") {
                        saveTimeRangeCondition()
                    }
                    .disabled(!isTimeRangeValid)
                }
            }
        }
    }
    
    private var isTimeRangeValid: Bool {
        // Les horaires peuvent être n'importe lesquels, tant qu'ils ne sont pas identiques
        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.hour, .minute], from: startTime)
        let endComponents = calendar.dateComponents([.hour, .minute], from: endTime)
        
        return startComponents != endComponents
    }
    
    private func saveTimeRangeCondition() {
        let timeRangeCondition = TimeRangeCondition(
            startTime: startTime,
            endTime: endTime
        )
        
        if let index = editingIndex {
            // Mettre à jour une condition existante
            viewModel.updateTimeRangeCondition(at: index, timeRange: timeRangeCondition)
        } else {
            // Créer une nouvelle condition
            let newCondition = DisplayCondition(
                type: .timeRange,
                isActive: true,
                timeRange: timeRangeCondition
            )
            viewModel.addCondition(newCondition)
        }
        
        dismiss()
    }
    
    private func showPresetOptions() {
        // Créer une alerte avec différentes préselections d'horaires
        // Cette fonction devrait utiliser un ActionSheet, mais comme ce code est pour démonstration,
        // nous allons simplement définir quelques préréglages communs ici
        
        let alertController = UIAlertController(
            title: "Préselections d'horaires",
            message: "Choisissez une plage horaire prédéfinie",
            preferredStyle: .actionSheet
        )
        
        let calendar = Calendar.current
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: Date())
        
        // Matin (7h-9h)
        alertController.addAction(UIAlertAction(title: "Matin (7h-9h)", style: .default) { _ in
            dateComponents.hour = 7
            dateComponents.minute = 0
            self.startTime = calendar.date(from: dateComponents) ?? Date()
            
            dateComponents.hour = 9
            dateComponents.minute = 0
            self.endTime = calendar.date(from: dateComponents) ?? Date()
        })
        
        // Midi (12h-14h)
        alertController.addAction(UIAlertAction(title: "Midi (12h-14h)", style: .default) { _ in
            dateComponents.hour = 12
            dateComponents.minute = 0
            self.startTime = calendar.date(from: dateComponents) ?? Date()
            
            dateComponents.hour = 14
            dateComponents.minute = 0
            self.endTime = calendar.date(from: dateComponents) ?? Date()
        })
        
        // Soir (17h-19h)
        alertController.addAction(UIAlertAction(title: "Soir (17h-19h)", style: .default) { _ in
            dateComponents.hour = 17
            dateComponents.minute = 0
            self.startTime = calendar.date(from: dateComponents) ?? Date()
            
            dateComponents.hour = 19
            dateComponents.minute = 0
            self.endTime = calendar.date(from: dateComponents) ?? Date()
        })
        
        // Nuit (22h-6h)
        alertController.addAction(UIAlertAction(title: "Nuit (22h-6h)", style: .default) { _ in
            dateComponents.hour = 22
            dateComponents.minute = 0
            self.startTime = calendar.date(from: dateComponents) ?? Date()
            
            dateComponents.hour = 6
            dateComponents.minute = 0
            self.endTime = calendar.date(from: dateComponents) ?? Date()
        })
        
        // Annuler
        alertController.addAction(UIAlertAction(title: "Annuler", style: .cancel))
        
        // Présenter l'alerte
        UIApplication.shared.windows.first?.rootViewController?.present(alertController, animated: true)
    }
}
