//
//  StopRow.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 20/04/2025.
//


import Foundation
import SwiftUI

struct StopRow: View {
    let stop: ImportedStop
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(stop.name_stop)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(stopTypeLabel(stop.getStopType()))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
    
    private func stopTypeLabel(_ type: StopType) -> String {
        switch type {
        case .quay:
            return "Arrêt"
        case .operatorQuay:
            return "Arrêt transporteur"
        case .monomodalStop:
            return "Zone d'arrêt"
        case .multimodalStop:
            return "Zone de correspondance"
        case .generalGroup:
            return "Pôle d'échanges"
        case .entrance:
            return "Accès"
        }
    }
}
