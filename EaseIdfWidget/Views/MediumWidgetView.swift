//
//  MediumWidgetView.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 16/04/2025.
//


import SwiftUI
import WidgetKit

struct MediumWidgetView: View {
    @ObservedObject var viewModel: EaseIdfWidgetViewModel
    var entry: WidgetConfigurationEntry
    
    var body: some View {
        if entry.data.departures.isEmpty {
            EmptyStateView()
        } else {
            MediumWidgetContentView(viewModel: viewModel, entry: entry)
        }
    }
}

struct MediumWidgetContentView: View {
    @ObservedObject var viewModel: EaseIdfWidgetViewModel
    var entry: WidgetConfigurationEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Entête du widget
            HStack {
                Text("Prochains passages")
                    .font(.caption)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("Mis à jour à \(viewModel.getUpdateTimeFormatted())")
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
                ForEach(0..<min(3, viewModel.groupsDepartures.count), id: \.self) { groupIndex in
                    let group = viewModel.groupsDepartures[groupIndex]
                    let departuresForGroup = group.departures
                    
                    MediumDeparturesLineView(
                        favorite: group.transportFavorite,
                        departures: group.departures
                    )
                    
                    if groupIndex < min(2, group.departures.count - 1) {
                        Divider()
                            .padding(.horizontal, 16)
                    }
                }
            }
            .padding(.bottom, 8)
        }
    }
}

struct MediumDeparturesLineView: View {
    let favorite: TransportFavorite
    let departures: [Departure]
    
    var body: some View {

        HStack(alignment: .center) {
            Text(favorite.lineShortName ?? "")
                .font(.headline)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .foregroundColor(Color(hex: favorite.lineTextColor  ?? "#000000"))
                .background(Color(hex: favorite.lineColor ?? "#FFFFFF"))
                .cornerRadius(5)
            
            // Stop name and direction
            VStack(alignment: .leading, spacing: 2) {
                // Stop name in bold
                Text(favorite.stopName ?? "")
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
            
            // Departure times
            HStack(spacing: 8) {
                if (!departures.isEmpty) {
                    Text(departures.first!.waitingTime)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.vertical, 2)
                        .padding(.horizontal, 6)
                        .foregroundColor(.green)
                        .cornerRadius(4)
                }
                if (departures.count >= 2) {
                    Text(departures[1].waitingTime)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.vertical, 2)
                        .padding(.horizontal, 6)
                        .foregroundColor(.green)
                        .cornerRadius(4)
                }
            }
        }
        .padding(.horizontal, 16)
    }
}

struct MediumWidgetView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = EaseIdfWidgetViewModel(entry: WidgetConfigurationEntry.placeholder)
        MediumWidgetView(viewModel: viewModel, entry: WidgetConfigurationEntry.placeholder)
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .containerBackground(.fill.tertiary, for: .widget)
    }
}
