//
//  AddConditionView.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 14/04/2025.
//

import SwiftUI
import SwiftData

struct AddConditionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var favorite: TransportFavoriteModel
    
    @State private var conditionType = "timeRange"
    @State private var isActive = true
    
    // Time range condition
    @State private var startTime = Date()
    @State private var endTime = Date().addingTimeInterval(3600) // +1 hour
    
    // Day of week condition
    @State private var selectedDays: Set<Int> = []
    
    // Location condition
    @State private var latitude = 0.0
    @State private var longitude = 0.0
    @State private var radius = 300.0
    @State private var useCurrentLocation = true
    
    private let conditionTypes = [
        ("timeRange", "Plage horaire", "clock.fill"),
        ("dayOfWeek", "Jours de la semaine", "calendar"),
        ("location", "Localisation", "location.fill")
    ]
    
    private let weekdays = [
        (1, "Dimanche"), (2, "Lundi"), (3, "Mardi"),
        (4, "Mercredi"), (5, "Jeudi"), (6, "Vendredi"), (7, "Samedi")
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Type de condition")) {
                    Picker("Type", selection: $conditionType) {
                        ForEach(conditionTypes, id: \.0) { type in
                            Label(type.1, systemImage: type.2)
                                .tag(type.0)
                        }
                    }
                }
                
                // Different inputs based on condition type
                switch conditionType {
                case "timeRange":
                    timeRangeSection
                case "dayOfWeek":
                    dayOfWeekSection
                case "location":
                    locationSection
                default:
                    EmptyView()
                }
                
                Section {
                    Toggle("Condition active", isOn: $isActive)
                }
                
                Section {
                    Button("Ajouter") {
                        addCondition()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationTitle("Nouvelle Condition")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                if let currentLocation = LocationService.shared.currentLocation {
                    latitude = currentLocation.coordinate.latitude
                    longitude = currentLocation.coordinate.longitude
                }
            }
        }
    }
    
    // MARK: - Condition Type Sections
    
    private var timeRangeSection: some View {
        Section(header: Text("Plage horaire")) {
            DatePicker("Heure de début", selection: $startTime, displayedComponents: .hourAndMinute)
            DatePicker("Heure de fin", selection: $endTime, displayedComponents: .hourAndMinute)
        }
    }
    
    private var dayOfWeekSection: some View {
        Section(header: Text("Jours de la semaine")) {
            ForEach(weekdays, id: \.0) { day in
                Toggle(day.1, isOn: Binding(
                    get: { selectedDays.contains(day.0) },
                    set: { isSelected in
                        if isSelected {
                            selectedDays.insert(day.0)
                        } else {
                            selectedDays.remove(day.0)
                        }
                    }
                ))
            }
        }
    }
    
    private var locationSection: some View {
        Section(header: Text("Localisation")) {
            Toggle("Utiliser ma position actuelle", isOn: $useCurrentLocation)
                .onChange(of: useCurrentLocation) {
                    if useCurrentLocation, let currentLocation = LocationService.shared.currentLocation {
                        latitude = currentLocation.coordinate.latitude
                        longitude = currentLocation.coordinate.longitude
                    }
                }
            
            if !useCurrentLocation {
                HStack {
                    Text("Latitude:")
                    Spacer()
                    TextField("Latitude", value: $latitude, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
                
                HStack {
                    Text("Longitude:")
                    Spacer()
                    TextField("Longitude", value: $longitude, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
            }
            
            VStack(alignment: .leading) {
                Text("Rayon: \(Int(radius)) mètres")
                Slider(value: $radius, in: 100...5000, step: 100)
            }
        }
    }
    
    // MARK: - Methods
    
    private func addCondition() {
        let newCondition = DisplayConditionModel(
            conditionType: conditionType,
            isActive: isActive
        )
        
        // Set specific properties based on condition type
        switch conditionType {
        case "timeRange":
            newCondition.startTime = startTime
            newCondition.endTime = endTime
            
        case "dayOfWeek":
            let dayIdsString = selectedDays.map { String($0) }.sorted().joined(separator: ",")
            newCondition.dayOfWeekData = dayIdsString
            
        case "location":
            newCondition.latitude = latitude
            newCondition.longitude = longitude
            newCondition.radius = radius
            
        default:
            break
        }
        
        // Add to favorite's conditions
        favorite.conditions.append(newCondition)
        
        // Save and dismiss
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    // Create a temporary favorite for the preview
    let preview = PreviewContainer(TransportFavoriteModel.self, DisplayConditionModel.self)
    let favorite = TransportFavoriteModel(stopId: "12345", displayName: "Test Favorite")
    
    return AddConditionView(favorite: favorite)
        .modelContainer(preview.container)
}

// Helper for SwiftUI previews with SwiftData
struct PreviewContainer {
    let container: ModelContainer
    
    init(_ types: any PersistentModel.Type...) {
        let schema = Schema(types)
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create preview container: \(error)")
        }
    }
}
