//
//  UnitManager.swift
//  Step Stats
//
//  Created by Michael Bryant on 5/8/23.
//

import Foundation

let kmToMiles = 0.62137119
let milesToKm = 1.609344
let meterToKm = 0.001

enum UnitType {
    case km
    case mi
}

class UnitManager {
    static let shared = UnitManager()
    
    var unitType: UnitType = .mi // Default to imperial
    
    private init() {}
}
