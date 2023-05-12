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
    let readTypes: Set<HKObjectType> = [
        HKObjectType.activitySummaryType(),
        HKObjectType.quantityType(forIdentifier: .stepCount)!,
        HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
        HKObjectType.quantityType(forIdentifier: .flightsClimbed)!,
        HKObjectType.workoutType(),
        HKSeriesType.workoutRoute()
    ]
    
    healthStore.requestAuthorization(toShare: nil, read: readTypes) { (success, error) in
        if let error = error {
            print("Error requesting HealthKit authorization: \(error.localizedDescription)")
        }
    }
}
