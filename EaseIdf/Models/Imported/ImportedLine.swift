//
//  ImportedLine.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 14/04/2025.
//

import Foundation

struct ImportedLine: Codable, Identifiable {
    let id_line: String
    let name_line: String
    let shortname_line: String
    let transportmode: String
    let transportsubmode: String?
    let type: String?
    let operatorref: String
    let operatorname: String
    let additionaloperators: String?
    let networkname: String?
    let colourweb_hexa: String?
    let textcolourweb_hexa: String?
    let colourprint_cmjn: String?
    let textcolourprint_hexa: String?
    let accessibility: String?
    let audiblesigns_available: String?
    let visualsigns_available: String?
    let id_groupoflines: String?
    let shortname_groupoflines: String?
    let notice_title: String?
    let notice_text: String?
    let picto: String?
    let valid_fromdate: String?
    let valid_todate: String?
    let status: String?
    let privatecode: String?
    
    // Identifiable conformance
    var id: String { id_line }
    
    // Convenience computed properties
    var transportModeEnum: TransportMode {
        switch transportmode.lowercased() {
        case "bus": return .bus
        case "tram": return .tram
        case "metro": return .metro
        case "rail": return .rail
        case "rer": return .rer
        default: return .other
        }
    }
    
    var color: String {
        colourweb_hexa ?? "007AFF" // Default iOS blue if no color provided
    }
    
    var textColor: String {
        textcolourweb_hexa ?? "FFFFFF"
    }
    
    // Convert to TransportLine model used in the app
    func toTransportLine() -> TransportLine {
        return TransportLine(
            id: id_line,
            name: name_line.isEmpty ? shortname_line : name_line,
            privateCode: privatecode,
            transportMode: transportModeEnum,
            transportSubmode: transportsubmode,
            operator_: Operator(id: operatorref, name: operatorname)
        )
    }
    
    // For displaying line with direction information
    func getDisplayName() -> String {
        if let groupName = shortname_groupoflines, !groupName.isEmpty {
            return "\(shortname_line) - \(groupName)"
        } else {
            return shortname_line
        }
    }
}

// MARK: - Direction Model

struct LineDirection: Identifiable {
    let id = UUID()
    let lineName: String
    let direction: String
    let lineId: String
    let color: String
    let textColor: String
    let transportMode: TransportMode
    
    // Used for display in UI
    var displayName: String {
        "\(lineName) → \(direction)"
    }
}
