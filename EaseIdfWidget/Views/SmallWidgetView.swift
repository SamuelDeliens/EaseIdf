//
//  SmallWidgetView.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 16/04/2025.
//


import SwiftUI
import WidgetKit

struct SmallWidgetView: View {
    var entry: WidgetConfigurationEntry
    
    var body: some View {
        if entry.data.departures.isEmpty {
            EmptyStateView()
        } else {
            SmallWidgetContentView(entry: entry)
        }
    }
}

struct SmallWidgetContentView: View {
    var entry: WidgetConfigurationEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            // En-tête avec la ligne et la destination
            if let firstDeparture = entry.data.departures.first {
                HStack(alignment: .center, spacing: 4) {
                    // Badge de ligne (fictif pour l'instant, à remplacer par les vraies données)
                    Text(getLineCode(for: firstDeparture.lineId))
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.vertical, 2)
                        .padding(.horizontal, 6)
                        .background(getLineColor(for: firstDeparture.lineId))
                        .foregroundColor(.white)
                        .cornerRadius(4)
                    
                    // Nom de l'arrêt
                    VStack(alignment: .leading, spacing: 0) {
                        Text(getStopName(for: firstDeparture.stopId))
                            .font(.caption)
                            .fontWeight(.medium)
                            .lineLimit(1)
                        
                        Text(firstDeparture.destination)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.top, 12)
                .padding(.bottom, 4)
                
                // Liste des départs (limitée aux 2 premiers)
                VStack(spacing: 8) {
                    ForEach(0..<min(2, entry.data.departures.count), id: \.self) { index in
                        let departure = entry.data.departures[index]
                        HStack {
                            Text("\(getLineCode(for: departure.lineId))")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            Text(departure.waitingTime)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.green)
                        }
                        .padding(.horizontal, 12)
                    }
                }
                
                Spacer()
                
                // Affichage de la dernière mise à jour
                HStack {
                    Spacer()
                    Text("Mis à jour à \(formatTime(entry.data.lastUpdated))")
                        .font(.system(size: 7))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 2)
            }
        }
    }
    
    // Formater l'heure (HH:mm)
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    // Obtenir le code de ligne à partir de l'identifiant
    private func getLineCode(for lineId: String) -> String {
        // À remplacer par une vraie recherche dans les données
        if let favorite = entry.data.favorites.first(where: { $0.lineId == lineId }) {
            let components = favorite.displayName.components(separatedBy: " ")
            if let firstWord = components.first {
                return firstWord
            }
        }
        return lineId.components(separatedBy: ":").last ?? lineId
    }
    
    // Obtenir le nom de l'arrêt à partir de l'identifiant
    private func getStopName(for stopId: String) -> String {
        if let favorite = entry.data.favorites.first(where: { $0.stopId == stopId }) {
            let parts = favorite.displayName.components(separatedBy: "(")
            if parts.count > 1, let stopPart = parts.last {
                return stopPart.replacingOccurrences(of: ")", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            }
            return favorite.displayName
        }
        return "Arrêt \(stopId)"
    }
    
    // Obtenir la couleur de la ligne à partir de l'identifiant
    private func getLineColor(for lineId: String) -> Color {
        // À remplacer par une vraie recherche dans les données
        // Pour l'instant, utiliser des couleurs basées sur l'ID
        let hash = abs(lineId.hashValue)
        let colors: [Color] = [.blue, .red, .green, .orange, .purple, .teal]
        return colors[hash % colors.count]
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "bus")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            
            Text("Aucun passage")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Ajoutez des favoris dans l'app")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

struct SmallWidgetView_Previews: PreviewProvider {
    static var previews: some View {
        SmallWidgetView(entry: WidgetConfigurationEntry.placeholder)
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .containerBackground(.fill.tertiary, for: .widget)
    }
}
