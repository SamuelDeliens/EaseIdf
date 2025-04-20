//
//  DirectionRow.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 20/04/2025.
//


import Foundation
import SwiftUI

struct DirectionRow: View {
    let direction: LineDirection
    
    var body: some View {
        HStack {
            Circle()
                .fill(Color(hex: direction.color))
                .frame(width: 12, height: 12)
            
            Text(direction.lineName)
                .font(.headline)
                .foregroundColor(.primary)
            
            Image(systemName: "arrow.right")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(direction.direction)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}
