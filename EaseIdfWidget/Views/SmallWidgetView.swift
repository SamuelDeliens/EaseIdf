//
//  SmallWidgetView.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 16/04/2025.
//


import SwiftUI
import WidgetKit

struct SmallWidgetView: View {
    @ObservedObject var viewModel: EaseIdfWidgetViewModel
    var entry: WidgetConfigurationEntry
    
    var body: some View {
        if entry.data.departures.isEmpty {
            EmptyStateView()
        } else {
            SmallWidgetContentView(viewModel: viewModel, entry: entry)
        }
    }
}

struct SmallWidgetContentView: View {
    @ObservedObject var viewModel: EaseIdfWidgetViewModel
    var entry: WidgetConfigurationEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            VStack(spacing: 8) {
                // Limiter à 2 groupes maximum
                ForEach(0..<min(2, viewModel.groupsDepartures.count), id: \.self) { groupIndex in
                    let group = viewModel.groupsDepartures[groupIndex]
                    
                    SmallDeparturesLineView(
                        favorite: group.transportFavorite,
                        departures: group.departures
                    )
                }
            }
                
            Spacer()
            
            Divider()
                .padding(.horizontal, 16)
                .padding(.bottom, 2)
            
            HStack {
                Spacer()
                Text("Mis à jour à \(viewModel.getUpdateTimeFormatted())")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
        }
        .padding(4)
    }
}

struct SmallDeparturesLineView: View {
    let favorite: TransportFavorite
    let departures: [Departure]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            if let direction = getDirection(departure: departures.first, favorite: favorite) {
                Text(direction)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            HStack(alignment: .center) {
                Text(favorite.lineShortName ?? "")
                    .font(.headline)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .foregroundColor(Color(hex: favorite.lineTextColor ?? "#000000"))
                    .background(Color(hex: favorite.lineColor ?? "#FFFFFF"))
                    .cornerRadius(5)
                
                VStack(alignment: .leading, spacing: 0) {
                    if (!departures.isEmpty) {
                        Text(departures.first!.waitingTime)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                            .cornerRadius(4)
                            .lineLimit(1)
                    }
                    if (departures.count >= 2) {
                        Text(departures[1].waitingTime)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                            .cornerRadius(4)
                            .lineLimit(1)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
}

struct SmallWidgetView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = EaseIdfWidgetViewModel(entry: WidgetConfigurationEntry.placeholder)
        SmallWidgetView(viewModel: viewModel, entry: WidgetConfigurationEntry.placeholder)
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .containerBackground(.fill.tertiary, for: .widget)
    }
}
