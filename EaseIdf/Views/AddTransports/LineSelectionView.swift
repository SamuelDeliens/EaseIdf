//
//  LineSelectionView.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 14/04/2025.
//

import SwiftUI

struct LineSelectionView: View {
    @ObservedObject var viewModel: AddTransportViewModel
    
    var body: some View {
        VStack {
            // Barre de recherche
            TextField("Rechercher une ligne", text: $viewModel.searchLineQuery)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal)
                .padding(.top)
            
            // Mode de transport sélectionné
            HStack {
                if let mode = viewModel.selectedTransportMode {
                    Label(
                        title: { Text(transportModeTitle(mode)) },
                        icon: { Image(systemName: transportModeIcon(mode)) }
                    )
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
                }
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 4)
            
            // Liste des lignes ou indicateur de chargement
            if viewModel.isLoading {
                Spacer()
                ProgressView("Chargement des lignes...")
                Spacer()
            } else if viewModel.filteredLines.isEmpty {
                ContentUnavailableView(
                    viewModel.searchLineQuery.isEmpty ? "Aucune ligne disponible" : "Aucun résultat",
                    systemImage: viewModel.searchLineQuery.isEmpty ? "tram" : "magnifyingglass",
                    description: Text(viewModel.searchLineQuery.isEmpty ?
                                     "Aucune ligne n'est disponible pour ce mode de transport." :
                                     "Essayez une autre recherche.")
                )
                // Bouton pour recharger les données
                Button {
                    Task {
                        await viewModel.loadTransportData()
                    }
                } label: {
                    Label("Recharger les données", systemImage: "arrow.clockwise")
                        .padding()
                }
                .buttonStyle(.bordered)
                .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.filteredLines) { line in
                            Button {
                                withAnimation {
                                    viewModel.selectLine(line)
                                }
                            } label: {
                                LineRow(line: line)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .onAppear {
            viewModel.filterLines(query: viewModel.searchLineQuery)
            
            // Si aucune ligne n'est trouvée, vérifier si des données sont disponibles
            if viewModel.filteredLines.isEmpty && !viewModel.isLoading {
                Task {
                    await viewModel.loadTransportData()
                }
            }
        }
    }
    
    private func transportModeTitle(_ mode: TransportMode) -> String {
        switch mode {
        case .bus: return "Bus"
        case .metro: return "Métro"
        case .tram: return "Tramway"
        case .rail: return "Train"
        case .rer: return "RER"
        case .other: return "Autre"
        }
    }
    
    private func transportModeIcon(_ mode: TransportMode) -> String {
        switch mode {
        case .bus: return "bus.fill"
        case .metro: return "tram.fill"
        case .tram: return "tram"
        case .rail, .rer: return "train.side.front.car"
        case .other: return "questionmark.circle"
        }
    }
}

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

// Extension pour convertir les chaînes de couleur hexadécimales en Color
extension Color {
    init(hex: String?) {
        let hexString = hex?.trimmingCharacters(in: CharacterSet.alphanumerics.inverted) ?? "007AFF"
        var int: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hexString.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
