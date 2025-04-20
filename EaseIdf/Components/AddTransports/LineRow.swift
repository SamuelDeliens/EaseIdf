//
//  LineRow.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 20/04/2025.
//


import Foundation
import SwiftUI

struct LineRow: View {
    let line: ImportedLine
    
    var body: some View {
        HStack {
            Text(line.shortname_line)
                .font(.headline)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .foregroundColor(Color(hex: line.textColor))
                .background(Color(hex: line.color))
                .cornerRadius(5)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(line.name_line)
                    .font(.subheadline)
                    .lineLimit(1)
                
                if let groupName = line.shortname_groupoflines {
                    Text(groupName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}
