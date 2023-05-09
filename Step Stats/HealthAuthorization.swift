//
//  HealthAuthorization.swift
//  Step Stats
//
//  Created by Michael Bryant on 5/8/23.
//

import Foundation
import HealthKit

public func requestAuthorization() {
    let healthStore = HKHealthStore()
    let stepType = HKObjectType.quantityType(forIdentifier: .stepCount)!
    let distanceType = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!
    let flightsClimbedType = HKObjectType.quantityType(forIdentifier: .flightsClimbed)!
    
    healthStore.requestAuthorization(toShare: [], read: [stepType, distanceType, flightsClimbedType]) { (success, error) in
        if let error = error {
            print("Error requesting authorization for HK data: \(error.localizedDescription)")
        }
    }
}
