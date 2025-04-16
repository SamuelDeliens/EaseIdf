//
//  MediumWidgetView.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 16/04/2025.
//


// EaseIdfWidget/Views/MediumWidgetView.swift
import SwiftUI
import WidgetKit

struct MediumWidgetView: View {
    var entry: WidgetConfigurationEntry
    
    var body: some View {
        if entry.data.departures.isEmpty {
            EmptyStateView()
        } else {
            MediumWidgetContentView(entry: entry)
        }
    }
}

struct MediumWidgetContentView: View {
    var entry: WidgetConfigurationEntry
    
    // Organiser les départs par arrêt/ligne
    private var groupedDepartures: [(key: String, departures: [Departure])] {
        let grouped = Dictionary(grouping: entry.data.departures) { departure in
            return "\(departure.stopId)-\(departure.lineId)"
        }
        
        // Trier par priorité si disponible, sinon par temps d'attente du premier départ
        let sortedPairs = grouped.sorted { group1, group2 in
            let favorite1 = entry.data.favorites.first { $0.stopId == group1.value.first?.stopId && $0.lineId == group1.value.first?.lineId }
            let favorite2 = entry.data.favorites.first { $0.stopId == group2.value.first?.stopId && $0.lineId == group2.value.first?.lineId }
            
            // Si les deux ont des favoris avec priorité
            if let priority1 = favorite1?.priority, let priority2 = favorite2?.priority {
                return priority1 > priority2
            }
            
            // Sinon trier par temps d'attente
            guard let departure1 = group1.value.first, let departure2 = group2.value.first else {
                return false
            }
            
            return departure1.expectedDepartureTime < departure2.expectedDepartureTime
        }
        
        // Convertir le type (key: String, value: [Departure]) en (key: String, departures: [Departure])
        return sortedPairs.map { (key: $0.key, departures: $0.value) }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Entête du widget
            HStack {
                Text("Prochains passages")
                    .font(.caption)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("Mis à jour à \(formatTime(entry.data.lastUpdated))")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 4)
            
            // Divider line
            Divider()
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            
            // Content - show up to 3 lines/stops
            VStack(spacing: 12) {
                // Limiter à 3 groupes maximum
                ForEach(0..<min(3, groupedDepartures.count), id: \.self) { groupIndex in
                    let group = groupedDepartures[groupIndex]
                    let departuresForGroup = group.departures
                    
                    if let firstDeparture = departuresForGroup.first {
                        DepartureGroupView(
                            lineId: firstDeparture.lineId,
                            stopId: firstDeparture.stopId,
                            destination: firstDeparture.destination,
                            departures: departuresForGroup.prefix(2).map { $0.waitingTime },
                            favorites: entry.data.favorites
                        )
                    }
                    
                    if groupIndex < min(2, groupedDepartures.count - 1) {
                        Divider()
                            .padding(.horizontal, 16)
                    }
                }
            }
            .padding(.bottom, 8)
        }
    }
    
    // Formater l'heure (HH:mm)
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

struct DepartureGroupView: View {
    let lineId: String
    let stopId: String
    let destination: String
    let departures: [String] // waiting times
    let favorites: [TransportFavorite]
    
    var body: some View {
        HStack(alignment: .center) {
            // Line code badge
            Text(getLineCode())
                .font(.caption)
                .fontWeight(.bold)
                .padding(.vertical, 2)
                .padding(.horizontal, 6)
                .background(getLineColor())
                .foregroundColor(.white)
                .cornerRadius(4)
            
            // Stop and destination info
            VStack(alignment: .leading, spacing: 2) {
                Text(getStopName())
                    .font(.caption)
                    .lineLimit(1)
                
                Text(destination)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Departure times
            HStack(spacing: 8) {
                ForEach(departures, id: \.self) { waitingTime in
                    Text(waitingTime)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.vertical, 2)
                        .padding(.horizontal, 6)
                        .background(Color.green.opacity(0.2))
                        .foregroundColor(.green)
                        .cornerRadius(4)
                }
            }
        }
        .padding(.horizontal, 16)
    }
    
    // Obtenir le code de ligne
    private func getLineCode() -> String {
        if let favorite = favorites.first(where: { $0.lineId == lineId }) {
            let components = favorite.displayName.components(separatedBy: " ")
            if let firstWord = components.first {
                return firstWord
            }
        }
        return lineId.components(separatedBy: ":").last ?? lineId
    }
    
    // Obtenir le nom de l'arrêt
    private func getStopName() -> String {
        if let favorite = favorites.first(where: { $0.stopId == stopId }) {
            let parts = favorite.displayName.components(separatedBy: "(")
            if parts.count > 1, let stopPart = parts.last {
                return stopPart.replacingOccurrences(of: ")", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            }
            return favorite.displayName
        }
        return "Arrêt \(stopId)"
    }
    
    // Obtenir la couleur de la ligne
    private func getLineColor() -> Color {
        // À remplacer par une vraie recherche dans les données
        // Pour l'instant, utiliser des couleurs basées sur l'ID
        let hash = abs(lineId.hashValue)
        let colors: [Color] = [.blue, .red, .green, .orange, .purple, .teal]
        return colors[hash % colors.count]
    }
}

struct MediumWidgetView_Previews: PreviewProvider {
    static var previews: some View {
        MediumWidgetView(entry: WidgetConfigurationEntry.placeholder)
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .containerBackground(.fill.tertiary, for: .widget)
    }
}
