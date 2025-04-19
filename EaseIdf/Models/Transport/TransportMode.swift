//
//  TransportMode.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 14/04/2025.
//

import Foundation

enum TransportMode: String, Codable, CaseIterable {
    case bus = "bus"
    case tram = "tram"
    case metro = "metro"
    case rail = "rail"
    case rer = "rer"
    case other = "other"
}
