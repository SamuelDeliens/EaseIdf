//
//  AddConditionRow.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 20/04/2025.
//


import Foundation
import SwiftUI

struct AddConditionRow: View {
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
        let conditionService = AppServices.shared.conditionService
        return conditionService.getConditionDescription(condition)
    }
}
