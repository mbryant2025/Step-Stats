import HealthKit
import SwiftUI
import MapKit

let store = HKHealthStore()

func requestPermission() async -> Bool {
    let write: Set<HKSampleType> = []
    let read: Set<HKObjectType> = [
        HKObjectType.workoutType(),
        HKSeriesType.workoutRoute(),
    ]
    
    do {
        try await store.requestAuthorization(toShare: write, read: read)
        return true
    } catch {
        print("Failed to request HealthKit authorization: \(error.localizedDescription)")
        return false
    }
}

struct MapView: UIViewRepresentable {
    @State private var workouts: [HKWorkout] = []
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView(frame: .zero)
        mapView.delegate = context.coordinator
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        if workouts.isEmpty {
            fetchWorkouts()
        } else {
            plotWorkouts(on: uiView)
        }
    }
    
    func fetchWorkouts() {
        Task {
            if await requestPermission() {
                readWorkouts { fetchedWorkouts in
                    if let fetchedWorkouts = fetchedWorkouts {
                        workouts = fetchedWorkouts
                    }
                }
            }
        }
    }




    
    func plotWorkouts(on mapView: MKMapView) {
        for workout in workouts {
            print("HERE")
            print(workout)
            Task {
                if let workoutRoutes = await getWorkoutRoute(workout: workout) {
                    for workoutRoute in workoutRoutes {
                        let locationData = await getLocationDataForRoute(givenRoute: workoutRoute)
                        let coordinates = locationData.map { $0.coordinate }
                        let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
                        DispatchQueue.main.async {
                            mapView.addOverlay(polyline)
                        }
                    }
                }
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView
        
        init(_ parent: MapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if overlay is MKPolyline {
                let renderer = MKPolylineRenderer(overlay: overlay)
                renderer.strokeColor = UIColor.blue
                renderer.lineWidth = 3
                return renderer
            }
            return MKOverlayRenderer()
        }
    }
}

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

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView()
    }
}
