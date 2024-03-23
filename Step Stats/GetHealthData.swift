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

public func getWorkoutType(for workout: HKWorkout) -> String {
    let workoutType = workout.workoutActivityType
    return workoutTypeMap[Int(workoutType.rawValue)] ?? "Unknown"
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
