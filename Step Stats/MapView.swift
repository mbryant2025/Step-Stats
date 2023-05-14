import HealthKit
import SwiftUI
import MapKit

let store = HKHealthStore()

class WorkoutStoreMKPolyline: MKPolyline {
    var workout: HKWorkout?
    
    convenience init(coordinates coords: UnsafePointer<CLLocationCoordinate2D>, count: Int, workout: HKWorkout?) {
        self.init(coordinates: coords, count: count)
        self.workout = workout
    }
}


struct MapView: View {
    @State private var showInfo = false
    @State private var showPanel = false
    @State private var selectedWorkoutPolyline: WorkoutStoreMKPolyline?
    @State private var mapType: MKMapType = .standard
    
    var body: some View {
        ZStack {
            MapContainerView(selectedPolyline: $selectedWorkoutPolyline, mapType: $mapType)
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                Button(action: {
                    showPanel = true
                }) {
                    Text("Workout Info")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color("ButtonColor1"))
                        .cornerRadius(10)
                }
                .padding(.bottom, 16)
            }
        }
        .navigationBarItems(trailing:
            VStack {
                HStack {
                    Button(action: {
                        showInfo = true
                    }) {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 18))
                            .padding(8)
                    }
                    .padding(3)
                    
                }
            }
        )
        .overlay(
            Color(UIColor.systemBackground).opacity(0.8)
                .frame(maxWidth: .infinity, maxHeight: 100)
                .edgesIgnoringSafeArea(.top)
                .position(CGPoint(x: UIScreen.main.bounds.width / 2, y: 0))
        )
        .sheet(isPresented: $showInfo) {
            MapInfoView(showInfo: $showInfo, mapType: $mapType)
        }
        .sheet(isPresented: $showPanel) {
            SlideUpPanelView(showPanel: $showPanel, selectedPolyline: $selectedWorkoutPolyline)
        }
    }
}


struct SlideUpPanelView: View {
    @Binding var showPanel: Bool
    @Binding var selectedPolyline: WorkoutStoreMKPolyline?
    
    private let panelHeight: CGFloat = 300
    private let handleHeight: CGFloat = 30
    
    var body: some View {
        VStack(spacing: 0) {
            arrowIndicator
            content
        }
        
    }
    
    var arrowIndicator: some View {
        VStack(spacing: 0) {
            
            RoundedRectangle(cornerRadius: 3)
                .frame(width: 40, height: 6)
                .foregroundColor(.gray)
                .padding(.vertical, 4)
        }
        .frame(height: handleHeight)
        .background(Color.clear)
    }
    
    var content: some View {
        VStack {
            if let selectedPolyline = selectedPolyline {
                if let workout = selectedPolyline.workout {
                    Text(workout.description)
                        .font(.headline)
                        .padding()
                }
            }
            
            Spacer()
            
            Button(action: {
                openWorkoutInFitnessApp()
                showPanel = false
            }) {
                Text("Open in Fitness App")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color("ButtonColor1"))
                    .cornerRadius(10)
            }
            .padding(.bottom, 16)
            
            Button(action: {
                showPanel = false
            }) {
                Text("Dismiss")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color("ButtonColor2"))
                    .cornerRadius(10)
            }
            .padding(.bottom, 16)
        }
        .padding(.horizontal)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    

    func openWorkoutInFitnessApp() {
        guard let workout = selectedPolyline?.workout else {
            print("No selected workout available.")
            return
        }

        // Check if the Fitness app is installed
        guard let fitnessAppURL = URL(string: UIApplication.openSettingsURLString) else {
            print("Fitness app not installed.")
            return
        }

        // Check if the workout is saved to the HealthKit store
        guard let workoutUUIDString = Optional(workout.uuid.uuidString) else {
            print("Workout UUID is not available.")
            return
        }

        // Create the URL for opening the workout in the Fitness app
        let workoutURLString = "your-custom-scheme://workout/\(workoutUUIDString)"

        // Create the URL from the workout URL string
        guard let workoutURL = URL(string: workoutURLString) else {
            print("Failed to create workout URL.")
            return
        }

        // Open the workout in the Fitness app
        UIApplication.shared.open(workoutURL) { success in
            if success {
                print("Workout opened in Fitness app.")
            } else {
                print("Failed to open workout in Fitness app.")
            }
        }
    }










}



struct MapInfoView: View {
    @Binding var showInfo: Bool
    @Binding var mapType: MKMapType
    
    var body: some View {
        NavigationView {
            Form {
                Text("TEST")
                Picker("", selection: $mapType) {
                                        Text("Standard").tag(MKMapType.standard)
                                        Text("Satellite").tag(MKMapType.satellite)
                                        Text("Hybrid").tag(MKMapType.hybrid)
                                        Text("Muted").tag(MKMapType.mutedStandard)
                                    }
                                    .pickerStyle(SegmentedPickerStyle())
//                                    .frame(width: 150)
            }
            .navigationTitle("Mapper Info")
            .navigationBarItems(trailing: Button("Done") {
                showInfo = false
            })
            
        }
    }
}

struct MapContainerView: UIViewRepresentable {
    @Binding var selectedPolyline: WorkoutStoreMKPolyline?
    @Binding var mapType: MKMapType
    
    @State private var workouts: [HKWorkout] = []
    
    func makeUIView(context: Context) -> MKMapView {
            let mapView = MKMapView(frame: .zero)
            mapView.delegate = context.coordinator
            mapView.mapType = mapType
            let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePolylineTap(_:)))
            mapView.addGestureRecognizer(tapGesture)
            return mapView
        }
    
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
            if uiView.mapType != mapType {
                uiView.mapType = mapType
            }
            
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
                        let polyline = WorkoutStoreMKPolyline(coordinates: coordinates, count: coordinates.count, workout: workout)
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
            if overlay is WorkoutStoreMKPolyline {
                let renderer = MKPolylineRenderer(overlay: overlay)
                
                if let tappedPolyline = overlay as? WorkoutStoreMKPolyline, let selectedPolyline = parent.selectedPolyline {
                    // Change color for the tapped polyline
                    renderer.strokeColor = tappedPolyline.isEqual(selectedPolyline) ? UIColor(Color("RouteSelected")) : UIColor(Color("Route"))
                } else {
                    renderer.strokeColor = UIColor(Color("Route"))
                }
                
                renderer.lineWidth = 6
                return renderer
            }
            return MKOverlayRenderer()
        }
        
        @objc func handlePolylineTap(_ gestureRecognizer: UITapGestureRecognizer) {
            let mapView = gestureRecognizer.view as! MKMapView
            let touchPoint = gestureRecognizer.location(in: mapView)
            let coordinates = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            
            var newSelectedPolyline: WorkoutStoreMKPolyline?
            
            // Find the polyline that was tapped
            for overlay in mapView.overlays {
                if let polyline = overlay as? WorkoutStoreMKPolyline {
                    if isCoordinateOnPolyline(coordinates, polyline: polyline) {
                        newSelectedPolyline = polyline
                        break
                    }
                }
            }
            
            // Update the color of the selected polyline and bring it to the front
            if let newPolyline = newSelectedPolyline {
                if let previousPolyline = parent.selectedPolyline, let renderer = mapView.renderer(for: previousPolyline) as? MKPolylineRenderer {
                    renderer.strokeColor = UIColor(Color("Route"))
                }
                parent.selectedPolyline = newPolyline
                
                // Remove and re-add the selected polyline to bring it to the front
                mapView.removeOverlay(newPolyline)
                mapView.addOverlay(newPolyline)
                
                if let renderer = mapView.renderer(for: newPolyline) as? MKPolylineRenderer {
                    renderer.strokeColor = UIColor(Color("RouteSelected"))
                }
            }
        }
        
        
        func isCoordinateOnPolyline(_ coordinate: CLLocationCoordinate2D, polyline: WorkoutStoreMKPolyline) -> Bool {
            let tolerance: CLLocationDistance = 4 // Tolerance in meters
            
            for i in 0 ..< polyline.pointCount - 1 {
                let startMapPoint = polyline.points()[i]
                let endMapPoint = polyline.points()[i + 1]
                
                let startCoordinate = startMapPoint.coordinate
                let endCoordinate = endMapPoint.coordinate
                
                let startLocation = CLLocation(latitude: startCoordinate.latitude, longitude: startCoordinate.longitude)
                let endLocation = CLLocation(latitude: endCoordinate.latitude, longitude: endCoordinate.longitude)
                let polylineDistance = startLocation.distance(from: endLocation)
                
                let startToTapDistance = CLLocation(latitude: startCoordinate.latitude, longitude: startCoordinate.longitude).distance(from: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))
                let endToTapDistance = CLLocation(latitude: endCoordinate.latitude, longitude: endCoordinate.longitude).distance(from: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))
                
                if startToTapDistance + endToTapDistance - polylineDistance < tolerance {
                    return true
                }
            }
            
            return false
        }
    }
}


struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView()
    }
}
