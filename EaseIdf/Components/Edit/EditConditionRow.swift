//
//  EditConditionRow.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 20/04/2025.
//


import SwiftUI

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
