//
//  TimeRangeConditionView.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 15/04/2025.
//

import SwiftUI

struct TimeRangeConditionView: View {
    var editingIndex: Int?

    let saveTimeRangeCondition: (Int?, TimeRangeCondition) -> Void
    
    @State private var startTime: Date
    @State private var endTime: Date
    
    // Initialisation avec AddTransportViewModel
    init(editingIndex: Int? = nil,
         saveTimeRangeCondition: @escaping (Int?, TimeRangeCondition) -> Void,
         startTime: Date?,
         endTime: Date?
    ) {
        self.editingIndex = editingIndex
        self.saveTimeRangeCondition = saveTimeRangeCondition
        
        var calendar = Calendar.current
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: Date())
        dateComponents.hour = 8
        dateComponents.minute = 0
        
        _startTime = startTime != nil ? State(initialValue: startTime!) : State(initialValue: calendar.date(from: dateComponents) ?? Date())
        
        dateComponents.hour = 10
        dateComponents.minute = 0
        _endTime = endTime != nil ? State(initialValue: endTime!) : State(initialValue: calendar.date(from: dateComponents) ?? Date())
    }
    
    var body: some View {
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
            
            Section {
                Button("Enregistrer") {
                    saveTimeRangeCondition(
                        self.editingIndex,
                        TimeRangeCondition(
                            startTime: startTime,
                            endTime: endTime
                    ))
                }
                .disabled(!isTimeRangeValid)
                .frame(maxWidth: .infinity)
                .buttonStyle(.borderedProminent)
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
