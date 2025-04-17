//
//  KeychainDebugHelper.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 17/04/2025.
//


import Foundation
import SwiftUI

struct KeychainDebugHelper {
    
    /// Resets all stored credentials by removing API key from Keychain and legacy storage
    static func resetAllCredentials() {
        // 1. Delete from Keychain
        _ = KeychainService.shared.deleteAPIKey()
        
        // 2. Clear from UserDefaults (legacy storage)
        UserDefaults.standard.removeObject(forKey: "IDFMobilite_ApiKey")
        
        // 3. Clear from shared UserDefaults (for widget)
        if let sharedDefaults = UserDefaults(suiteName: KeychainConstants.appGroup) {
            sharedDefaults.removeObject(forKey: KeychainConstants.SharedUserDefaults.apiKeyLegacy)
        }
        
        print("🔐 Keychain Debug: Toutes les clés API ont été supprimées")
    }
    
    /// Checks current API key state
    static func checkApiKeyState() -> String {
        var report = "📋 État de la clé API:\n"
        
        if let keychainKey = KeychainService.shared.getAPIKey() {
            let maskedKey = maskApiKey(keychainKey)
            report += "✅ Keychain: \(maskedKey)\n"
        } else {
            report += "❌ Keychain: Aucune clé trouvée\n"
        }
        
        if let userDefaultsKey = UserDefaults.standard.string(forKey: "IDFMobilite_ApiKey") {
            let maskedKey = maskApiKey(userDefaultsKey)
            report += "⚠️ UserDefaults (legacy): \(maskedKey)\n"
        } else {
            report += "✓ UserDefaults (legacy): Aucune clé trouvée\n"
        }
        
        if let sharedDefaults = UserDefaults(suiteName: KeychainConstants.appGroup),
           let sharedKey = sharedDefaults.string(forKey: KeychainConstants.SharedUserDefaults.apiKeyLegacy) {
            let maskedKey = maskApiKey(sharedKey)
            report += "⚠️ Shared UserDefaults (widget): \(maskedKey)\n"
        } else {
            report += "✓ Shared UserDefaults (widget): Aucune clé trouvée\n"
        }
        
        print(report)
        return report
    }
    
    /// Masks API key for display
    private static func maskApiKey(_ apiKey: String) -> String {
        if apiKey.count <= 8 {
            return "****" // Trop court pour masquer
        }
        
        // Montrer 4 premiers et 4 derniers caractères
        let prefix = String(apiKey.prefix(4))
        let suffix = String(apiKey.suffix(4))
        return "\(prefix)****\(suffix) [\(apiKey.count) caractères]"
    }
}

// MARK: - SwiftUI Debug View
struct KeychainDebugView: View {
    @State private var keyState = "Appuyez sur Vérifier pour voir l'état actuel"
    @State private var showingConfirmation = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Débogage Keychain")
                .font(.title)
                .padding(.top)
            
            ScrollView {
                Text(keyState)
                    .font(.system(.body, design: .monospaced))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.horizontal)
            }
            
            HStack(spacing: 20) {
                Button("Vérifier") {
                    keyState = KeychainDebugHelper.checkApiKeyState()
                }
                .buttonStyle(.bordered)
                
                Button("Réinitialiser") {
                    showingConfirmation = true
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
            .padding(.bottom)
        }
        .alert("Réinitialiser les clés API?", isPresented: $showingConfirmation) {
            Button("Annuler", role: .cancel) {}
            Button("Réinitialiser", role: .destructive) {
                KeychainDebugHelper.resetAllCredentials()
                keyState = KeychainDebugHelper.checkApiKeyState()
            }
        } message: {
            Text("Cela supprimera toutes les clés API stockées. Vous devrez vous reconnecter.")
        }
    }
}

#Preview {
    KeychainDebugView()
}
