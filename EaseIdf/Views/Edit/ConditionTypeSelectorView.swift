//
//  ConditionTypeSelectorView.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 17/04/2025.
//


import SwiftUI

struct ConditionTypeSelectorView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: EditFavoriteViewModel
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Icône
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
                    .padding(.top, 30)
                
                // Titre
                Text("Ajouter une condition")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Description
                Text("Choisissez le type de condition que vous souhaitez ajouter pour déterminer quand ce transport sera affiché.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 30)
                
                Spacer()
                
                // Options
                VStack(spacing: 16) {
                    conditionButton(
                        icon: "clock",
                        title: "Condition d'horaire",
                        description: "Afficher le transport uniquement à certaines heures",
                        color: .blue,
                        action: {
                            viewModel.addTimeRangeCondition()
                            dismiss()
                        }
                    )
                    
                    conditionButton(
                        icon: "calendar",
                        title: "Condition de jour",
                        description: "Afficher le transport certains jours de la semaine",
                        color: .green,
                        action: {
                            viewModel.addDayOfWeekCondition()
                            dismiss()
                        }
                    )
                    
                    conditionButton(
                        icon: "location",
                        title: "Condition de position",
                        description: "Afficher le transport uniquement à proximité d'un lieu",
                        color: .orange,
                        action: {
                            viewModel.addLocationCondition()
                            dismiss()
                        }
                    )
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Bouton d'annulation
                Button("Annuler") {
                    dismiss()
                }
                .padding(.bottom, 30)
            }
            .navigationTitle("Nouvelle condition")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func conditionButton(
        icon: String,
        title: String,
        description: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 15) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(color)
                    .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Preview
struct ConditionTypeSelectorView_Previews: PreviewProvider {
    static var previews: some View {
        @State var sampleFavorite = TransportFavorite(
            id: UUID(),
            stopId: "12345",
            lineId: "C01742",
            displayName: "RER A Gare de Lyon",
            displayConditions: [],
            priority: 1
        )
        
        ConditionTypeSelectorView(viewModel: EditFavoriteViewModel(favorite: $sampleFavorite))
    }
}
