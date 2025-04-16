//
//  Direction.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 16/04/2025.
//

import Foundation

func getDirection(departure: Departure?, favorite: TransportFavorite) -> String? {
    if departure != nil {
        return departure?.destination
    }
    
    // Otherwise try to get from line data - utilisons les infos stockées dans le favori
    if let lineId = favorite.lineId {
        // Si nous avons des informations dans le favori
        if let lineName = favorite.lineName {
            return lineName
        }
    }
    
    return nil
}
