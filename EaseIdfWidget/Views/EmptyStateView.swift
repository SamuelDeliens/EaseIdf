//
//  EmptyStateView.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 16/04/2025.
//

import SwiftUI

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "tram.fill")
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
