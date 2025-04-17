//
//  SwipeActionView.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 15/04/2025.
//

import SwiftUI

struct SwipeActionView<Content: View>: View {
    let favorite: TransportFavorite
    let action: () -> Void
    let content: Content
    
    @State private var offset: CGFloat = 0
    @State private var showingDeleteAlert = false
    @State private var isSwiped = false
    
    init(favorite: TransportFavorite, action: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.favorite = favorite
        self.action = action
        self.content = content()
    }
    
    var body: some View {
        ZStack(alignment: .trailing) {
            // Delete button background
            Rectangle()
                .foregroundColor(.red)
                .cornerRadius(12)
                .overlay(
                    HStack {
                        Spacer()
                        Image(systemName: "trash.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(.trailing, 24)
                    }
                )
            
            // Content
            content
                .offset(x: offset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            // Permettre uniquement le glissement vers la gauche
                            if value.translation.width < 0 {
                                offset = value.translation.width
                                
                                // Si l'offset est significatif, marquer comme "swiped"
                                isSwiped = offset < -10
                            }
                        }
                        .onEnded { value in
                            withAnimation(.spring()) {
                                // Si glissé assez loin, afficher l'alerte de confirmation
                                if value.translation.width < -100 {
                                    showingDeleteAlert = true
                                    isSwiped = true
                                } else {
                                    // Remettre à zéro si pas assez glissé
                                    offset = 0
                                    isSwiped = false
                                }
                            }
                        }
                )
                .alert(isPresented: $showingDeleteAlert) {
                    Alert(
                        title: Text("Supprimer ce favori ?"),
                        message: Text("Êtes-vous sûr de vouloir supprimer \"\(favorite.displayName)\" de vos favoris ?"),
                        primaryButton: .destructive(Text("Supprimer")) {
                            withAnimation {
                                action()
                            }
                        },
                        secondaryButton: .cancel(Text("Annuler")) {
                            withAnimation(.spring()) {
                                // Remettre à zéro l'offset si l'utilisateur annule
                                offset = 0
                                isSwiped = false
                            }
                        }
                    )
                }
        }
    }
}
