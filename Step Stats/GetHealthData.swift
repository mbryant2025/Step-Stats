//
//  GetHealthData.swift
//  Step Stats
//
//  Created by Michael Bryant on 5/8/23.
//

import Foundation
import HealthKit


public func getCumulativeHealthDataPhone(for dataType: HKQuantityTypeIdentifier, completion: @escaping (Double) -> Void) {
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
                    case .distanceWalkingRunning:
                        unit = .meterUnit(with: .kilo)
                    default:
                        unit = .count()
                }
                
                let value = sum.doubleValue(for: unit)
                completion(value)
            }
        }
        
        let healthStore = HKHealthStore()
        healthStore.execute(query)
    }


public func getAllCumulativeHealthDataWatch(for completion: @escaping ([String: String]) -> Void) {
    
    let now = Date()
    let predicate = HKQuery.predicateForSamples(withStart: nil, end: now, options: .strictEndDate)
    let query = HKActivitySummaryQuery(predicate: predicate) { (_, summaries, error) in
        if let error = error {
            print("Error fetching activity summaries: \(error.localizedDescription)")
            return
        }
        

        var allResults: [String: (Double, String)] = [
            "Stand Time": (0.0, "hr"),
            "Exercise Time": (0.0, "hr"),
            "Energy Burned": (0.0, "cal"),
        ]

        
        if let summaries = summaries {
            for summary in summaries {
                
                allResults["Stand Time"]?.0 += summary.appleStandHours.doubleValue(for: .count())
                
                allResults["Exercise Time"]?.0 += summary.appleExerciseTime.doubleValue(for: .minute()) / 60
                
                allResults["Energy Burned"]?.0 += summary.activeEnergyBurned
                    .doubleValue(for: .kilocalorie()).rounded()
            }
            
            DispatchQueue.main.async {
                var allResultsFormatted: [String: String] = [:]
                
                let numberFormatter = NumberFormatter()
                numberFormatter.numberStyle = .decimal

                for (key, (value, unit)) in allResults {
                    //Round to 2 digits after decimal
                    let roundedValue = (value * 100).rounded() / 100.0
                    
                    if roundedValue != 0 {
                        if let formattedValue = numberFormatter.string(from: NSNumber(value: roundedValue)) {
                            allResultsFormatted[key] = formattedValue + " " + unit
                        } else {
                            allResultsFormatted[key] = String(roundedValue) + " " + unit
                        }
                    }
                }

                
                completion(allResultsFormatted)
            }
        }
    }
    
    let healthStore = HKHealthStore()
    healthStore.execute(query)
}
