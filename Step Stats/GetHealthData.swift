//
//  GetHealthData.swift
//  Step Stats
//
//  Created by Michael Bryant on 5/8/23.
//

import Foundation
import HealthKit


public func getCumulativeHealthData(for dataType: HKQuantityTypeIdentifier, completion: @escaping (Double) -> Void) {
        guard let quantityType = HKObjectType.quantityType(forIdentifier: dataType) else {
            print("\(dataType.rawValue) type is not available.")
            return
        }
        
        let now = Date()
        let predicate = HKQuery.predicateForSamples(withStart: nil, end: now, options: .strictEndDate)
        let query = HKStatisticsQuery(quantityType: quantityType, quantitySamplePredicate: predicate, options: .cumulativeSum) { (_, result, error) in
            guard let result = result, let sum = result.sumQuantity() else {
                if let error = error {
                    print("Error retrieving \(dataType.rawValue): \(error.localizedDescription)")
                }
                return
            }
            
            DispatchQueue.main.async {
                let unit: HKUnit
                switch dataType {
                    case .stepCount:
                        unit = .count()
                    case .distanceWalkingRunning:
                        unit = .meterUnit(with: .kilo)
                    case .flightsClimbed:
                        unit = .count()
                    default:
                        return
                }
                
                let value = sum.doubleValue(for: unit)
                completion(value)
            }
        }
        
        let healthStore = HKHealthStore()
        healthStore.execute(query)
    }
