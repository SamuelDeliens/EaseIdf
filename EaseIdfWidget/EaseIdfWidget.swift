//
//  EaseIdfWidget.swift
//  EaseIdfWidget
//
//  Created by Samuel DELIENS on 16/04/2025.
//


import WidgetKit
import SwiftUI

struct EaseIdfWidget: Widget {
    let kind: String = "EaseIdfWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: EaseIdfWidgetProvider()) { entry in
            EaseIdfWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Prochains Passages")
        .description("Affiche les prochains passages de vos transports préférés.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct EaseIdfWidgetEntryView: View {
    @Environment(\.widgetFamily) var widgetFamily
    
    var entry: EaseIdfWidgetProvider.Entry
    @StateObject private var viewModel: EaseIdfWidgetViewModel
    
    init(entry: EaseIdfWidgetProvider.Entry) {
        self.entry = entry
        // Initialiser le viewModel en utilisant @StateObject
        _viewModel = StateObject(wrappedValue: EaseIdfWidgetViewModel(entry: entry))
    }
    
    var body: some View {
        switch widgetFamily {
        case .systemSmall:
            SmallWidgetView(viewModel: viewModel, entry: entry)
        case .systemMedium:
            MediumWidgetView(viewModel: viewModel, entry: entry)
        default:
            // Fallback sur le petit widget pour les autres tailles
            SmallWidgetView(viewModel: viewModel, entry: entry)
        }
    }
}

struct EaseIdfWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Aperçu du petit widget
            EaseIdfWidgetEntryView(entry: WidgetConfigurationEntry.placeholder)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .containerBackground(.fill.tertiary, for: .widget)
            
            // Aperçu du widget moyen
            EaseIdfWidgetEntryView(entry: WidgetConfigurationEntry.placeholder)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .containerBackground(.fill.tertiary, for: .widget)
        }
    }
}
