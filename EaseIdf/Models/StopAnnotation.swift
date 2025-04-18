//
//  StopAnnotation.swift
//  EaseIdf
//
//  Created by Samuel DELIENS on 18/04/2025.
//

import Foundation
import CoreLocation

struct StopAnnotation: Identifiable {
    let id: String
    let name: String
    let coordinate: CLLocationCoordinate2D
    var isSelected: Bool
}
