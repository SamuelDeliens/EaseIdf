//
//  LinesData.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 16/04/2025.
//

import Foundation

struct GroupDeparture {
    let id: UUID
    let transportFavorite: TransportFavorite
    let departures: [Departure]
}
