//
//  FavoriteCardView.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 14/04/2025.
//


import SwiftUI

struct FavoriteCardView: View {
    let favorite: TransportFavorite
    let departures: [Departure]
    
    // Variables pour les informations importées depuis les favoris
    private var lineColor: Color {
        Color(hex: favorite.lineColor ?? "007AFF")
    }
    
    private var textColor: Color {
        Color(hex: favorite.lineTextColor ?? "FFFFFF")
    }
    
    private var stopName: String {
        favorite.stopName ?? favorite.displayName
    }
    
    private var lineShortName: String? {
        favorite.lineShortName
    }
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with line info
            HStack {
                // Line badge/logo
                if let shortName = lineShortName {
                    Text(shortName)
                        .font(.headline)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .foregroundColor(textColor)
                        .background(lineColor)
                        .cornerRadius(5)
                }
                
                // Stop name and direction
                VStack(alignment: .leading, spacing: 2) {
                    // Stop name in bold
                    Text(stopName)
                        .font(.headline)
                        .fontWeight(.bold)
                        .lineLimit(1)
                    
                    // Direction in smaller text if available
                    if let direction = getDirection(departure: departures.first, favorite: favorite) {
                        Text(direction)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                .padding(.leading, 4)
                
                Spacer()
                
                // Next departure or no departures indicator
                if let nextDeparture = departures.first {
                    Text(nextDeparture.waitingTime)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(getDepartureColor(nextDeparture))
                } else {
                    HStack(spacing: 2) {
                        Image(systemName: "clock.badge.exclamationmark")
                            .font(.headline)
                            .foregroundColor(.red)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemBackground))
            
            // Additional departures if expanded
            if isExpanded && departures.count > 1 {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(departures.dropFirst()) { departure in
                        DepartureRow(departure: departure)
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(Color(.systemBackground))
                        
                        if departure.id != departures.last?.id {
                            Divider()
                                .padding(.leading)
                        }
                    }
                }
            }
        }
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        .contentShape(Rectangle())
        .onTapGesture {
            if departures.count > 1 {
                withAnimation {
                    isExpanded.toggle()
                }
            }
        }
        .onChange(of: isExpanded) { _ in
            // Émet une notification pour forcer le recalcul des dimensions quand l'expansion change
            NotificationCenter.default.post(name: Notification.Name("FavoriteCardExpandedStateChanged"), object: nil)
        }
        .id("\(favorite.id)-\(isExpanded)-\(departures.count)") // Force redraw when expanded state changes
    }
    
    // Couleur du temps d'attente basée sur les minutes restantes
    private func getDepartureColor(_ departure: Departure) -> Color {
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
