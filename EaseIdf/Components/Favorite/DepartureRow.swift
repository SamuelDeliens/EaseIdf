//
//  DepartureRow.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 20/04/2025.
//


import SwiftUI

struct DepartureRow: View {
    let departure: Departure
    
    var body: some View {
        HStack {
            // Destination
            VStack(alignment: .leading, spacing: 2) {
                Text(departure.destination)
                    .font(.subheadline)
                    .lineLimit(1)
                
                if let delay = departure.delay {
                    Text(formatDelay(delay))
                        .font(.caption)
                        .foregroundColor(getDelayColor(delay))
                }
            }
            
            Spacer()
            
            // Waiting time
            Text(departure.waitingTime)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(getDepartureTimeColor(departure))
        }
    }
    
    private func formatDelay(_ delay: TimeInterval) -> String {
        let minutes = Int(abs(delay) / 60)
        if minutes == 0 {
            return "À l'heure"
        } else if delay > 0 {
            return "Retard: \(minutes) min"
        } else {
            return "Avance: \(minutes) min"
        }
    }
    
    private func getDelayColor(_ delay: TimeInterval) -> Color {
        let minutes = Int(delay / 60)
        if minutes == 0 {
            return .green
        } else if minutes > 0 {
            return minutes > 5 ? .red : .orange
        } else {
            return .blue
        }
    }
    
    // Couleur de la durée d'attente basée sur le temps restant
    private func getDepartureTimeColor(_ departure: Departure) -> Color {
        let minutes = departure.remainingMinutes
        
        if minutes <= 0 {
            return .red     // Imminent ou déjà passé
        } else if minutes <= 3 {
            return .orange  // Très proche
        } else if minutes <= 5 {
            return .yellow  // Proche
        } else {
            return .green   // Temps suffisant
        }
    }
}
