//
//  GetHealthData.swift
//  Step Stats
//
//  Created by Michael Bryant on 5/8/23.
//

import Foundation
import HealthKit
import MapKit

//CUMULATIVE DATA
//=====================================================================

//NOT FOR WATCH
public let healthDataTypes: [HKQuantityTypeIdentifier: String] = [
    .stepCount: "Steps",
    .distanceWalkingRunning: "Distance Walked/Ran",
    .flightsClimbed: "Flights Climbed",
]

public func getCumulativeHealthData(for dataType: HKQuantityTypeIdentifier, completion: @escaping (String) -> Void) {
        guard let quantityType = HKObjectType.quantityType(forIdentifier: dataType) else {
            print("\(dataType.rawValue) type is not available.")
            return
        }
        
        let now = Date()
        let predicate = HKQuery.predicateForSamples(withStart: nil, end: now, options: .strictEndDate)
        let query = HKStatisticsQuery(quantityType: quantityType, quantitySamplePredicate: predicate, options: .cumulativeSum) { (_, result, error) in
            guard let result = result, let sum = result.sumQuantity() else {
                return
            }
            
            DispatchQueue.main.async {
                
                var unitString: String
                var value: Double
                
    
                let unit: HKUnit
                switch dataType {
                    case .distanceWalkingRunning, .distanceCycling:
                        unit = .meterUnit(with: .kilo)
                        value = sum.doubleValue(for: unit)
                        if UnitManager.shared.unitType == .km {
                            unitString = "km"
                        }
                        else {
                            unitString = "mi"
                            value *= kmToMiles
                        }
                    default:
                        unit = .count()
                        value = sum.doubleValue(for: unit)
                        unitString = unit.unitString
                }
                
                if value == 0.0 {
                    return
                }
                
                var valueString: String
                
                
                if unitString == "count" {
                    //If unit is "count", no need for it
                    unitString = ""
                    //We also want to Int these values
                    let numberFormatter = NumberFormatter()
                    numberFormatter.numberStyle = .decimal
                    valueString = numberFormatter.string(from: NSNumber(value: Int(value))) ?? ""
                }
                else {
                    //Round to 2 digits after decimal otherwise
                    let roundedValue = (value * 100).rounded() / 100.0
                    let numberFormatter = NumberFormatter()
                    numberFormatter.numberStyle = .decimal
                    valueString = numberFormatter.string(from: NSNumber(value: roundedValue)) ?? ""
                }
                
                completion(valueString + " " + unitString)
            }
        }
        
        let healthStore = HKHealthStore()
        healthStore.execute(query)
    }

//FOR WATCH
//=======================

public func getAllCumulativeHealthDataWatch(for completion: @escaping ([String: String]) -> Void) {
    
    let now = Date()
    let predicate = HKQuery.predicateForSamples(withStart: nil, end: now, options: .strictEndDate)
    let query = HKActivitySummaryQuery(predicate: predicate) { (_, summaries, error) in
        if error != nil {
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
                
                allResults["Energy Burned"]?.0 += summary.activeEnergyBurned.doubleValue(for: .kilocalorie()).rounded()
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

//make map of number to apple workout string

public func getWorkoutType(for workout: HKWorkout) -> String {
    let workoutType = workout.workoutActivityType
    return workoutTypeMap[Int(workoutType.rawValue)] ?? "Unknown"
}



public func getAllCumulativeWorkoutData(for completion: @escaping ([String: String]) -> Void) {
    let workoutType = HKObjectType.workoutType()
    let predicate = HKQuery.predicateForWorkouts(with: .greaterThanOrEqualTo, duration: 0)
    let query = HKSampleQuery(sampleType: workoutType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, results, error) in
        if let workouts = results as? [HKWorkout] {
            
            var workoutData: [String: Double] = [:]
            let distanceUnit = UnitManager.shared.unitType
            
            //loop through all workouts
            for workout in workouts {
                
                //for each workout, add the total time to the total time for that activity type
                let workoutTypeString = getWorkoutType(for: workout)
                
                let duration = workout.duration
                
                //keep track of the number of workouts for each activity
                if let currentCount = workoutData[workoutTypeString + " Workouts"] {
                    workoutData[workoutTypeString + " Workouts"] = currentCount + 1
                } else {
                    workoutData[workoutTypeString + " Workouts"] = 1
                }

                //keep track of the duration for each activity
                if let currentDuration = workoutData[workoutTypeString + " Time"] {
                    workoutData[workoutTypeString + " Time"] = currentDuration + duration
                } else {
                    workoutData[workoutTypeString + " Time"] = duration
                }

                //keep track of the total number of workouts
                if let currentCount = workoutData["Workouts"] {
                    workoutData["Workouts"] = currentCount + 1
                } else {
                    workoutData["Workouts"] = 1
                }

                //keep track of the total time
                if let currentDuration = workoutData["Workout Time"] {
                    workoutData["Workout Time"] = currentDuration + duration
                } else {
                    workoutData["Workout Time"] = duration
                }

                //keep track of the total distance with error checking if the workout has distance
                //for each kind of workout and total
                if let distance = workout.totalDistance?.doubleValue(for: HKUnit.meter()) {
                    var scaledDistance: Double = distance * meterToKm
                    if distanceUnit == .mi {
                        scaledDistance *= kmToMiles
                    }
                    
                    if let currentDistance = workoutData["Workout Distance"] {
                        workoutData["Workout Distance"] = currentDistance + scaledDistance
                    } else {
                        workoutData["Workout Distance"] = scaledDistance
                    }

                    if let currentDistance = workoutData[workoutTypeString + " Distance"] {
                        workoutData[workoutTypeString + " Distance"] = currentDistance + scaledDistance
                    } else {
                        workoutData[workoutTypeString + " Distance"] = scaledDistance
                    }
                }

            }

            // Create a number formatter
            let numberFormatter = NumberFormatter()
            numberFormatter.numberStyle = .decimal
            numberFormatter.maximumFractionDigits = 2

            // Convert the keys to strings and make a new dictionary
            var valueString: [String: String] = [:]
            for (key, value) in workoutData {
                // Convert to a string unless the value ends with "Workouts" where we first go to an int
                if key.hasSuffix("Workouts") {
                    valueString[key] = numberFormatter.string(from: NSNumber(value: Int(value)))
                } else if key.hasSuffix("Time") {
                    // Convert from seconds to hours
                    let hours = value / 60 / 60
                    let formattedHours = numberFormatter.string(from: NSNumber(value: hours)) ?? ""
                    valueString[key] = formattedHours + " hr"
                } else {
                    let formattedValue = numberFormatter.string(from: NSNumber(value: value)) ?? ""
                    valueString[key] = formattedValue + " " + (distanceUnit == .mi ? "mi" : "km")
                }
            }

            completion(valueString)
        } else {
            print("Failed to read workouts")
        }
    }
    let healthStore = HKHealthStore()
    healthStore.execute(query)
}

//WORKOUT ROUTES
//=====================================================================


func readWorkouts(completion: @escaping ([HKWorkout]?) -> Void) {
    let workoutType = HKObjectType.workoutType()
    
    let query = HKSampleQuery(sampleType: workoutType, predicate: nil, limit: HKObjectQueryNoLimit, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { (query, samplesOrNil, errorOrNil) in
        if let error = errorOrNil {
            print("Failed to read workouts: \(error.localizedDescription)")
            completion(nil)
            return
        }
        
        guard let samples = samplesOrNil as? [HKWorkout] else {
            print("Invalid workout samples")
            completion(nil)
            return
        }
        
        completion(samples)
    }
    
    store.execute(query)
}




func getWorkoutRoute(workout: HKWorkout) async -> [HKWorkoutRoute]? {
    let byWorkout = HKQuery.predicateForObjects(from: workout)

    let samples = try! await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKSample], Error>) in
        store.execute(HKAnchoredObjectQuery(type: HKSeriesType.workoutRoute(), predicate: byWorkout, anchor: nil, limit: HKObjectQueryNoLimit, resultsHandler: { (query, samples, deletedObjects, anchor, error) in
            if let hasError = error {
                continuation.resume(throwing: hasError)
                return
            }

            guard let samples = samples else {
                return
            }

            continuation.resume(returning: samples)
        }))
    }

    guard let workouts = samples as? [HKWorkoutRoute] else {
        return nil
    }

    return workouts
}

func getLocationDataForRoute(givenRoute: HKWorkoutRoute) async -> [CLLocation] {
    let locations = try! await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[CLLocation], Error>) in
        var allLocations: [CLLocation] = []

        // Create the route query.
        let query = HKWorkoutRouteQuery(route: givenRoute) { (query, locationsOrNil, done, errorOrNil) in

            if let error = errorOrNil {
                continuation.resume(throwing: error)
                return
            }

            guard let currentLocationBatch = locationsOrNil else {
                fatalError("*** Invalid State: This can only fail if there was an error. ***")
            }

            allLocations.append(contentsOf: currentLocationBatch)

            if done {
                continuation.resume(returning: allLocations)
            }
        }

        store.execute(query)
    }

    return locations
    
}

func convertWorkoutToString(workout: HKWorkout) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .medium
    dateFormatter.timeStyle = .short
    

    let date = dateFormatter.string(from: workout.startDate)
    let duration = String(format: "%.2f", workout.duration / 60.0) // Convert duration to minutes
    let distance = workout.totalDistance?.doubleValue(for: HKUnit.meter()) ?? 0.0 // Convert distance to meters
    let distanceUnits = distance * meterToKm * (UnitManager.shared.unitType == .km ? 1 : kmToMiles)
    let distanceUnitsString = String(format: "%.2f", distanceUnits) + " " + (UnitManager.shared.unitType == .km ? "km" : "mi")
    let temperature = getTemperatureFromMetadata(workout: workout)
    let pace = calculatePace(distance: workout.totalDistance, duration: workout.duration) // Calculate the pace
    let workoutType = getWorkoutType(for: workout) // Get the type of workout

    let workoutString = """
        Date: \(date)
        Workout Type: \(workoutType)
        Duration: \(duration) minutes
        Distance: \(distanceUnitsString)
        Temperature: \(temperature)
        Pace: \(pace) min/\(UnitManager.shared.unitType == .km ? "km" : "mi")
        """

    return workoutString
}

func getTemperatureFromMetadata(workout: HKWorkout) -> String {
    guard let metadata = workout.metadata else {
        return "Unknown Temperature"
    }

    if let temperatureQuantity = metadata[HKMetadataKeyWeatherTemperature] as? HKQuantity {
        let temperatureUnit = HKUnit.degreeFahrenheit()
        let temperatureValue = temperatureQuantity.doubleValue(for: temperatureUnit)
        //convert to celcius if the unit is km
        let temperatureCelsius = UnitManager.shared.unitType == .km ? FarenheitToCelcius(temperatureValue) : temperatureValue
        return String(format: "%.1f", temperatureCelsius) + " " + (UnitManager.shared.unitType == .km ? "°C" : "°F")
    }

    return "Unknown Temperature"
}

func calculatePace(distance: HKQuantity?, duration: TimeInterval) -> String {
    guard let distance = distance else {
        return "Unknown Pace"
    }

    let distanceInKilometers = distance.doubleValue(for: HKUnit.meterUnit(with: .kilo))
    let unitDistance = UnitManager.shared.unitType == .km ? distanceInKilometers : distanceInKilometers * kmToMiles
    let paceInSecondsPerDistance = duration / unitDistance

    let paceMinutes = Int(paceInSecondsPerDistance / 60)
    let paceSeconds = Int(paceInSecondsPerDistance.truncatingRemainder(dividingBy: 60))

    return String(format: "%02d:%02d", paceMinutes, paceSeconds)
}


public let workoutTypeMap: [Int: String] = [
    1: "American Football",
    2: "Archery",
    3: "Australian Football",
    4: "Badminton",
    5: "Baseball",
    6: "Basketball",
    7: "Bowling",
    8: "Boxing",
    9: "Climbing",
    10: "Cricket",
    11: "Cross Training",
    12: "Curling",
    13: "Cycling",
    14: "Dance",
    15: "Dance Inspired Training",
    16: "Elliptical",
    17: "Equestrian Sports",
    18: "Fencing",
    19: "Fishing",
    20: "Functional Strength Training",
    21: "Golf",
    22: "Gymnastics",
    23: "Handball",
    24: "Hiking",
    25: "Hockey",
    26: "Hunting",
    27: "Lacrosse",
    28: "Martial Arts",
    29: "Mind and Body",
    30: "Mixed Metabolic Cardio Training",
    31: "Paddle Sports",
    32: "Play",
    33: "Preparation and Recovery",
    34: "Racquetball",
    35: "Rowing",
    36: "Rugby",
    37: "Running",
    38: "Sailing",
    39: "Skating Sports",
    40: "Snow Sports",
    41: "Soccer",
    42: "Softball",
    43: "Squash",
    44: "Stair Climbing",
    45: "Surfing Sports",
    46: "Swimming",
    47: "Table Tennis",
    48: "Tennis",
    49: "Track and Field",
    50: "Traditional Strength Training",
    51: "Volleyball",
    52: "Walking",
    53: "Water Fitness",
    54: "Water Polo",
    55: "Water Sports",
    56: "Wrestling",
    57: "Yoga",
    58: "Barre"
]
