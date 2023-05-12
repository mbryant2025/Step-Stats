import HealthKit
import SwiftUI
import MapKit

let store = HKHealthStore()

struct MapView: View {
    
    @State private var showInfo = false
    
    var body: some View {
        MapContainerView()
        .navigationTitle("Workout Mapper")
        .navigationBarItems(trailing:
            Button(action: {
                showInfo = true
            }) {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 18))
            }
        )
        .sheet(isPresented: $showInfo) {
            MapInfoView(showInfo: $showInfo)
        }
    }
}

struct MapInfoView: View {
    @Binding var showInfo: Bool
    
    var body: some View {
        NavigationView {
            Form {
                Text("TEST")
            }
            .navigationTitle("Mapper Info")
            .navigationBarItems(trailing: Button("Done") {
                showInfo = false
            })
        }
    }
}

struct MapContainerView: UIViewRepresentable {
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
        requestAuthorization()
        Task {
            readWorkouts { fetchedWorkouts in
                if let fetchedWorkouts = fetchedWorkouts {
                    workouts = fetchedWorkouts
                }
            }
        }
    }

    
    func plotWorkouts(on mapView: MKMapView) {
        for workout in workouts {
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
        var parent: MapContainerView
        
        init(_ parent: MapContainerView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if overlay is MKPolyline {
                let renderer = MKPolylineRenderer(overlay: overlay)
                renderer.strokeColor = UIColor.red
                renderer.lineWidth = 5
                return renderer
            }
            return MKOverlayRenderer()
        }
    }
}


struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView()
    }
}
