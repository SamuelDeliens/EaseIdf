//
//  SwipeActionsView.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 17/04/2025.
//


import SwiftUI

struct SwipeActionsView<Content: View>: View {
    let favorite: TransportFavorite
    let deleteAction: () -> Void
    let editAction: () -> Void
    let content: Content
    
    @State private var offset: CGFloat = 0
    @State private var startOffset: CGFloat = 0
    @State private var isSwiped: Bool = false
    @State private var isSwipeComplete: Bool = false
    @State private var isSwipeHold: Bool = false
    @State private var showingDeleteAlert = false
        
    private let swipeButtonWidth: CGFloat = 80
    private let securityLeftSide: CGFloat = 100
    
    init(favorite: TransportFavorite, deleteAction: @escaping () -> Void, editAction: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.favorite = favorite
        self.deleteAction = deleteAction
        self.editAction = editAction
        self.content = content()
    }
    
    var body: some View {
        GeometryReader { geometry in
            let swipeSpace = min(abs(offset), geometry.size.width * 0.8)
            
            let normalWidthDeleteFrame = max(0.0, geometry.size.width - (swipeSpace * 1.5))
            let normalWidthEditFrame = min(swipeSpace/2, swipeButtonWidth)
            let specWidthEditFrame = swipeSpace
            
            ZStack(alignment: .trailing) {
                
                HStack(spacing: 0) {
                    Spacer()
                    
                    Rectangle()
                        .frame(width: max(0.0, geometry.size.width - securityLeftSide), height: geometry.size.height)
                        .foregroundColor(.blue)
                }
                
                HStack(spacing: 0) {
                    Spacer()
                    
                    Rectangle()
                        .frame(width: isSwipeComplete ? 0.0 : geometry.size.width - securityLeftSide, height: geometry.size.height)
                        .foregroundColor(.red)
                        .overlay(
                            HStack(spacing: 0) {
                                Spacer()
                                    .frame(width: max(0.0, normalWidthDeleteFrame - securityLeftSide))
                                
                                Image(systemName: isSwiped ? "trash.fill" : "trash")
                                    .font(.title3)
                                    .foregroundColor(.white)
                            }
                                .padding(25)
                                .onTapGesture {
                                    if isSwiped {
                                        showingDeleteAlert = true
                                    }
                            }
                        )
                }
                
                HStack(spacing: 0) {
                    Spacer()
                    
                    Rectangle()
                        .frame(width: isSwipeComplete ? specWidthEditFrame : normalWidthEditFrame, height: geometry.size.height)
                        .foregroundColor(.blue)
                        .overlay(
                            HStack(spacing: 0) {
                                Image(systemName: "pencil")
                                    .font(.title3)
                                    .foregroundColor(.white)
                                
                                Spacer()
                            }
                                .padding(25)
                                .onTapGesture {
                                    withAnimation(.spring()) {
                                        isSwiped = false
                                        offset = 0
                                    }
                                    editAction()
                                }
                        )
                }
            }
            .cornerRadius(12)
            .frame(height: geometry.size.height)
            
            
            content
                .offset(x: offset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            isSwipeHold = true
                            
                            if offset + value.translation.width < securityLeftSide / 2 {
                                offset = startOffset + value.translation.width
                            }
                            
                            if offset + value.translation.width < 0 {
                                offset = startOffset + value.translation.width
                            }
                            
                            if offset <= -swipeButtonWidth * 2 {
                                isSwipeComplete = true
                            } else {
                                isSwipeComplete = false
                            }
                        }
                        .onEnded { value in
                            withAnimation(.spring()) {
                                isSwipeHold = false
                                let velocity = value.predictedEndTranslation.width - value.translation.width
                                                                
                                //Swipe vers la gauche
                                if value.translation.width < 0 {
                                    // Cas swipe déjà activé
                                    if (isSwiped) {
                                        //Si suffisement vitesse => valide swipe
                                        if value.translation.width <= -swipeButtonWidth / 2 || velocity < -200 {
                                            isSwipeComplete = true
                                        }
                                        //Si pas assez de vitesse ou autre => change rien
                                        else {
                                            offset = -swipeButtonWidth * 2
                                        }
                                    }
                                    
                                    //Cas swipe pas encore activé
                                    //Si suffisement vitesse => active swipe
                                    if value.translation.width <= -swipeButtonWidth / 2 || velocity < -60 {
                                        isSwiped = true
                                        offset = -swipeButtonWidth * 2
                                    }

                                    else {
                                        isSwiped = false
                                        offset = 0
                                    }
                                }

                                //Swipe vers la droite
                                else if value.translation.width > 0 {
                                    if isSwiped {
                                        if velocity > 200 || value.translation.width > 50 {
                                            isSwiped = false
                                            offset = 0
                                        }
                                    } else {
                                        offset = 0
                                    }
                                }
                                
                                // Si Swipe valide => edit
                                if (isSwipeComplete) {
                                    editAction()
                                    isSwiped = false
                                    isSwipeComplete = false
                                    offset = 0
                                }
                            }
                            
                            //redefinis startOffset avec offset => reprendre swipe au bon endroit
                            startOffset = offset
                        }
                )
                .alert(isPresented: $showingDeleteAlert) {
                    Alert(
                        title: Text("Supprimer ce favori ?"),
                        message: Text("Êtes-vous sûr de vouloir supprimer \"\(favorite.displayName)\" de vos favoris ?"),
                        primaryButton: .destructive(Text("Supprimer")) {
                            withAnimation {
                                deleteAction()
                            }
                        },
                        secondaryButton: .cancel(Text("Annuler")) {
                            withAnimation(.spring()) {
                                isSwiped = false
                                isSwipeComplete = false
                                offset = 0
                                startOffset = 0
                            }
                        }
                    )
                }
            }
        .frame(minHeight: 67)
    }
}
