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
let meterToMiles = meterToKm * kmToMiles

enum UnitType {
    case km
    case mi
}

class UnitManager {
    static let shared = UnitManager()
    
    var unitType: UnitType = .mi // Default to imperial
    
    private init() {}
}

public func FarenheitToCelcius(_ farenheit: Double) -> Double {
    return (farenheit - 32) * 5 / 9
}

public func CelciusToFarenheit(_ celcius: Double) -> Double {
    return celcius * 9 / 5 + 32
}

