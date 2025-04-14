//
//  Coordinates.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 14/04/2025.
//

import Foundation
import CoreLocation

struct Coordinates: Codable {
    let latitude: Double
    let longitude: Double
    
    var locationCoordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
