//
//  String.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 18/04/2025.
//


import Foundation

extension String {
    func correctingEncoding() -> String {
        var correctedString = self
        
        // 1. Vérifier s'il y a des séquences UTF-8 mal encodées
        if self.contains("\u{00C3}") {
            // Tenter de redécoder avec différents encodages
            if let data = self.data(using: .utf8) {
                if let latinString = String(data: data, encoding: .isoLatin1) {
                    return latinString
                }
                
                if let windowsString = String(data: data, encoding: .windowsCP1252) {
                    return windowsString
                }
            }
        }
        
        let replacements: [String: String] = [
            "\\u00c3\\u00a9": "é", // é
            "\\u00c3\\u00a8": "è", // è
            "\\u00c3\\u00aa": "ê", // ê
            "\\u00c3\\u00ab": "ë", // ë
            "\\u00c3\\u00a0": "à", // à
            "\\u00c3\\u00b9": "ù", // ù
            "\\u00c3\\u00b4": "ô", // ô
            "\\u00c3\\u00ae": "î", // î
            "\\u00c3\\u00bc": "ü", // ü
            "\\u00c3\\u00a7": "ç", // ç
            "\\u00c3\\u0089": "É", // É
            "\\u00c3\\u0088": "È", // È
            "\\u00c3\\u008a": "Ê", // Ê
            "\\u00c3\\u008b": "Ë", // Ë
            "\\u00c3\\u0080": "À", // À
            "\\u00c3\\u0099": "Ù", // Ù
            "\\u00c3\\u0094": "Ô", // Ô
            "\\u00c3\\u008e": "Î", // Î
            "\\u00c3\\u009c": "Ü", // Ü
            "\\u00c3\\u0087": "Ç"  // Ç
        ]
        
        for (encoded, decoded) in replacements {
            correctedString = correctedString.replacingOccurrences(of: encoded, with: decoded)
        }
        
        return correctedString
    }
    
    func correctingStopName() -> String {
        return self.correctingEncoding()
    }
}
