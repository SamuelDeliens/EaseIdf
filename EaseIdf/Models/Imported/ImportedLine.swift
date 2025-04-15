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
    let valid_fromdate: String?
    let valid_todate: String?
    let status: String?
    let privatecode: String?
        
    private var _picto: PictoUnion?
    
    var picto: String? {
        switch _picto {
        case .string(let value):
            return value
        case .object(let obj):
            return obj["url"]
        case nil:
            return nil
        }
    }
    
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
    
    enum PictoUnion: Codable {
        case string(String)
        case object([String: String])
    }
    
    init(
        id_line: String,
        name_line: String,
        shortname_line: String,
        transportmode: String,
        transportsubmode: String? = nil,
        type: String? = nil,
        operatorref: String,
        operatorname: String,
        additionaloperators: String? = nil,
        networkname: String? = nil,
        colourweb_hexa: String? = nil,
        textcolourweb_hexa: String? = nil,
        colourprint_cmjn: String? = nil,
        textcolourprint_hexa: String? = nil,
        accessibility: String? = nil,
        audiblesigns_available: String? = nil,
        visualsigns_available: String? = nil,
        id_groupoflines: String? = nil,
        shortname_groupoflines: String? = nil,
        notice_title: String? = nil,
        notice_text: String? = nil,
        valid_fromdate: String? = nil,
        valid_todate: String? = nil,
        status: String? = nil,
        privatecode: String? = nil
    ) {
        self.id_line = id_line
        self.name_line = name_line
        self.shortname_line = shortname_line
        self.transportmode = transportmode
        self.transportsubmode = transportsubmode
        self.type = type
        self.operatorref = operatorref
        self.operatorname = operatorname
        self.additionaloperators = additionaloperators
        self.networkname = networkname
        self.colourweb_hexa = colourweb_hexa
        self.textcolourweb_hexa = textcolourweb_hexa
        self.colourprint_cmjn = colourprint_cmjn
        self.textcolourprint_hexa = textcolourprint_hexa
        self.accessibility = accessibility
        self.audiblesigns_available = audiblesigns_available
        self.visualsigns_available = visualsigns_available
        self.id_groupoflines = id_groupoflines
        self.shortname_groupoflines = shortname_groupoflines
        self.notice_title = notice_title
        self.notice_text = notice_text
        self.valid_fromdate = valid_fromdate
        self.valid_todate = valid_todate
        self.status = status
        self.privatecode = privatecode
        self._picto = nil
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Décodage des champs normaux
        id_line = try container.decode(String.self, forKey: .id_line)
        name_line = try container.decode(String.self, forKey: .name_line)
        shortname_line = try container.decode(String.self, forKey: .shortname_line)
        transportmode = try container.decode(String.self, forKey: .transportmode)
        transportsubmode = try container.decodeIfPresent(String.self, forKey: .transportsubmode)
        type = try container.decodeIfPresent(String.self, forKey: .type)
        operatorref = try container.decode(String.self, forKey: .operatorref)
        operatorname = try container.decode(String.self, forKey: .operatorname)
        additionaloperators = try container.decodeIfPresent(String.self, forKey: .additionaloperators)
        networkname = try container.decodeIfPresent(String.self, forKey: .networkname)
        colourweb_hexa = try container.decodeIfPresent(String.self, forKey: .colourweb_hexa)
        textcolourweb_hexa = try container.decodeIfPresent(String.self, forKey: .textcolourweb_hexa)
        colourprint_cmjn = try container.decodeIfPresent(String.self, forKey: .colourprint_cmjn)
        textcolourprint_hexa = try container.decodeIfPresent(String.self, forKey: .textcolourprint_hexa)
        accessibility = try container.decodeIfPresent(String.self, forKey: .accessibility)
        audiblesigns_available = try container.decodeIfPresent(String.self, forKey: .audiblesigns_available)
        visualsigns_available = try container.decodeIfPresent(String.self, forKey: .visualsigns_available)
        id_groupoflines = try container.decodeIfPresent(String.self, forKey: .id_groupoflines)
        shortname_groupoflines = try container.decodeIfPresent(String.self, forKey: .shortname_groupoflines)
        notice_title = try container.decodeIfPresent(String.self, forKey: .notice_title)
        notice_text = try container.decodeIfPresent(String.self, forKey: .notice_text)
        valid_fromdate = try container.decodeIfPresent(String.self, forKey: .valid_fromdate)
        valid_todate = try container.decodeIfPresent(String.self, forKey: .valid_todate)
        status = try container.decodeIfPresent(String.self, forKey: .status)
        privatecode = try container.decodeIfPresent(String.self, forKey: .privatecode)
        
        // Décodage du champ picto qui peut être soit une chaîne, soit un objet
        do {
            if let pictoString = try? container.decodeIfPresent(String.self, forKey: ._picto) {
                _picto = .string(pictoString)
            } else if let pictoDict = try? container.decodeIfPresent([String: String].self, forKey: ._picto) {
                _picto = .object(pictoDict)
            } else {
                _picto = nil
            }
        } catch {
            _picto = nil
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
    
    enum CodingKeys: String, CodingKey {
        case id_line, name_line, shortname_line, transportmode, transportsubmode, type
        case operatorref, operatorname, additionaloperators, networkname
        case colourweb_hexa, textcolourweb_hexa, colourprint_cmjn, textcolourprint_hexa
        case accessibility, audiblesigns_available, visualsigns_available
        case id_groupoflines, shortname_groupoflines, notice_title, notice_text
        case _picto = "picto"
        case valid_fromdate, valid_todate, status, privatecode
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

struct PictoValue: Codable {
    let url: String?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let stringValue = try? container.decode(String.self) {
            url = stringValue
        } else if let objectValue = try? container.decode([String: String].self) {
            url = objectValue["url"]
        } else {
            url = nil
        }
    }
}
