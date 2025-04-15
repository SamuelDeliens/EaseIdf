//
//  TransportLineModel.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 15/04/2025.
//


import Foundation
import SwiftData

@Model
final class TransportLineModel {
    var id: String
    var name: String
    var shortName: String
    var privateCode: String?
    var transportMode: String
    var transportSubmode: String?
    var operatorId: String
    var operatorName: String
    var color: String
    var textColor: String
    var shortGroupName: String?
    
    init(id: String, name: String, shortName: String, privateCode: String?, transportMode: String, 
         transportSubmode: String?, operatorId: String, operatorName: String, 
         color: String, textColor: String, shortGroupName: String?) {
        self.id = id
        self.name = name
        self.shortName = shortName
        self.privateCode = privateCode
        self.transportMode = transportMode
        self.transportSubmode = transportSubmode
        self.operatorId = operatorId
        self.operatorName = operatorName
        self.color = color
        self.textColor = textColor
        self.shortGroupName = shortGroupName
    }
    
    // Conversion vers le modèle struct pour compatibilité
    func toStruct() -> TransportLine {
        return TransportLine(
            id: id,
            name: name,
            privateCode: privateCode,
            transportMode: TransportMode(rawValue: transportMode) ?? .other,
            transportSubmode: transportSubmode,
            operator_: Operator(id: operatorId, name: operatorName)
        )
    }
    
    // Conversion vers ImportedLine pour compatibilité
    func toImportedLine() -> ImportedLine {
        // Cette méthode nécessite une implémentation personnalisée en fonction de la structure exacte d'ImportedLine
        // Voici une implémentation simplifiée
        return ImportedLine(
            id_line: id,
            name_line: name,
            shortname_line: shortName,
            transportmode: transportMode,
            transportsubmode: transportSubmode,
            type: nil,
            operatorref: operatorId,
            operatorname: operatorName,
            additionaloperators: nil,
            networkname: nil,
            colourweb_hexa: color,
            textcolourweb_hexa: textColor,
            colourprint_cmjn: nil,
            textcolourprint_hexa: nil,
            accessibility: nil,
            audiblesigns_available: nil,
            visualsigns_available: nil,
            id_groupoflines: nil,
            shortname_groupoflines: shortGroupName,
            notice_title: nil,
            notice_text: nil,
            valid_fromdate: nil,
            valid_todate: nil,
            status: nil,
            privatecode: privateCode
        )
    }
    
    // Création à partir d'ImportedLine
    static func fromImportedLine(_ line: ImportedLine) -> TransportLineModel {
        return TransportLineModel(
            id: line.id_line,
            name: line.name_line.isEmpty ? line.shortname_line : line.name_line,
            shortName: line.shortname_line,
            privateCode: line.privatecode,
            transportMode: line.transportmode,
            transportSubmode: line.transportsubmode,
            operatorId: line.operatorref,
            operatorName: line.operatorname,
            color: line.colourweb_hexa ?? "007AFF",
            textColor: line.textcolourweb_hexa ?? "FFFFFF",
            shortGroupName: line.shortname_groupoflines
        )
    }
}
