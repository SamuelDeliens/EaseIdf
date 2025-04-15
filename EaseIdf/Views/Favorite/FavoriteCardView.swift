//
//  FavoriteCardView.swift
//  EaseIdf
//
//  Created by Claude on 15/04/2025.
//

import SwiftUI

struct FavoriteCardView: View {
    let favorite: TransportFavorite
    let departures: [Departure]
    let lineData: ImportedLine?
    let stopData: ImportedStop?
    
    @State private var isExpanded = false
    
    init(favorite: TransportFavorite, departures: [Departure]) {
        self.favorite = favorite
        self.departures = departures
        
        // Try to get line data if we have a lineId
        if let lineId = favorite.lineId {
            self.lineData = LineDataService.shared.getAllLines().first { $0.id_line == lineId }
        } else {
            self.lineData = nil
        }
        
        // Try to get stop data
        self.stopData = StopDataService.shared.getAllStops().first { $0.id_stop == favorite.stopId }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with line info
            HStack {
                // Line badge/logo
                if let line = lineData {
                    Text(line.shortname_line)
                        .font(.headline)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .foregroundColor(Color(hex: line.textColor))
                        .background(Color(hex: line.color))
                        .cornerRadius(5)
                }
                
                // Stop name and direction
                VStack(alignment: .leading, spacing: 2) {
                    // Stop name in bold
                    Text(stopData?.name_stop ?? favorite.displayName)
                        .font(.headline)
                        .fontWeight(.bold)
                        .lineLimit(1)
                    
                    // Direction in smaller text if available
                    if let direction = getDirection() {
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
                        .foregroundColor(.green)
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
            
            // Expand button if there are multiple departures
            if departures.count > 1 {
                Button {
                    withAnimation {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack {
                        Spacer()
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.vertical, 6)
                    .background(Color(.systemBackground))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    // Cette méthode est maintenant correctement placée à l'intérieur de la structure FavoriteCardView
    // Elle a donc accès aux propriétés comme 'departures' et 'favorite'
    private func getDirection() -> String? {
        // First try to get direction from the first departure
        if let firstDeparture = departures.first {
            return firstDeparture.destination
        }
        
        // Otherwise try to get from line data
        if let lineId = favorite.lineId, let line = lineData {
            // Get directions for this line
            let directions = LineDataService.shared.getDirectionsForLine(lineId: lineId)
            if directions.count == 1 {
                return directions.first?.direction
            } else if directions.count > 1 {
                // If multiple directions, try to find from display name
                let displayName = favorite.displayName.lowercased()
                for direction in directions {
                    if displayName.contains(direction.direction.lowercased()) {
                        return direction.direction
                    }
                }
                // Fall back to first direction
                return directions.first?.direction
            }
            
            // If no specific direction found, use group name
            return line.shortname_groupoflines
        }
        
        return nil
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
                .foregroundColor(.green)
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
}
