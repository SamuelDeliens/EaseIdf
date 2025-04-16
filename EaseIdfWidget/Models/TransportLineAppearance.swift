//
//  TransportLineAppearance.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 16/04/2025.
//

import SwiftUI

struct TransportLineAppearance {
    // Couleurs des lignes de métro de Paris
    static let metroColors: [String: (background: Color, text: Color)] = [
        "1": (Color(hex: "FFCD00"), .black),
        "2": (Color(hex: "003CA6"), .white),
        "3": (Color(hex: "837902"), .white),
        "3bis": (Color(hex: "6EC4E8"), .black),
        "4": (Color(hex: "CF009E"), .white),
        "5": (Color(hex: "FF7E2E"), .black),
        "6": (Color(hex: "6ECA97"), .black),
        "7": (Color(hex: "FA9ABA"), .black),
        "7bis": (Color(hex: "6ECA97"), .black),
        "8": (Color(hex: "E19BDF"), .black),
        "9": (Color(hex: "B6BD00"), .black),
        "10": (Color(hex: "C9910D"), .white),
        "11": (Color(hex: "704B1C"), .white),
        "12": (Color(hex: "007852"), .white),
        "13": (Color(hex: "6EC4E8"), .black),
        "14": (Color(hex: "62259D"), .white)
    ]
    
    // Couleurs des RER
    static let rerColors: [String: (background: Color, text: Color)] = [
        "A": (Color(hex: "FF1744"), .white),
        "B": (Color(hex: "2979FF"), .white),
        "C": (Color(hex: "FFEB3B"), .black),
        "D": (Color(hex: "4CAF50"), .white),
        "E": (Color(hex: "FF5722"), .white)
    ]
    
    // Couleurs des tramways
    static let tramColors: [String: (background: Color, text: Color)] = [
        "T1": (Color(hex: "2E8B57"), .white),
        "T2": (Color(hex: "FF4500"), .white),
        "T3a": (Color(hex: "FF69B4"), .white),
        "T3b": (Color(hex: "00CED1"), .black),
        "T4": (Color(hex: "9370DB"), .white),
        "T5": (Color(hex: "3CB371"), .white),
        "T6": (Color(hex: "FF8C00"), .white),
        "T7": (Color(hex: "8A2BE2"), .white),
        "T8": (Color(hex: "20B2AA"), .white),
        "T9": (Color(hex: "32CD32"), .white),
        "T10": (Color(hex: "FF6347"), .white),
        "T11": (Color(hex: "4682B4"), .white),
        "T12": (Color(hex: "DA70D6"), .white),
        "T13": (Color(hex: "8FBC8F"), .white)
    ]
    
    // Récupérer les couleurs pour une ligne donnée
    static func getColors(for lineCode: String, mode: String?) -> (background: Color, text: Color) {
        // D'abord vérifier par mode (plus fiable)
        if let mode = mode?.lowercased() {
            switch mode {
            case "metro":
                if let colors = metroColors[lineCode] {
                    return colors
                }
            case "rer":
                if let colors = rerColors[lineCode] {
                    return colors
                }
            case "tram":
                if let colors = tramColors[lineCode] {
                    return colors
                }
            default:
                break
            }
        }
        
        // Essayer de détecter le mode à partir du code de ligne
        if metroColors.keys.contains(lineCode) {
            return metroColors[lineCode]!
        } else if rerColors.keys.contains(lineCode) {
            return rerColors[lineCode]!
        } else if tramColors.keys.contains(lineCode) {
            return tramColors[lineCode]!
        } else if lineCode.hasPrefix("T") {
            // Tramway générique
            return (Color(hex: "4CAF50"), .white)
        } else if lineCode.hasPrefix("M") {
            // Métro générique
            return (Color(hex: "0078D7"), .white)
        } else if lineCode.hasPrefix("R") {
            // RER générique
            return (Color(hex: "FF4081"), .white)
        } else if lineCode.hasPrefix("B") {
            // Bus générique
            return (Color(hex: "FF9800"), .white)
        }
        
        // Couleur par défaut
        return (Color(hex: "007AFF"), .white)
    }
}

// Extension pour créer des couleurs à partir de codes hexadécimaux
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
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
