import HealthKit
import SwiftUI
import MapKit

let store = HKHealthStore()

struct MapView: View {
    @State private var showInfo = false
    @State private var showPanel = false
    @State private var selectedPolyline: MKPolyline?
    
    var body: some View {
        ZStack {
            MapContainerView()
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
                        .background(Color.blue)
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
            MapInfoView(showInfo: $showInfo)
        }
        .sheet(isPresented: $showPanel) {
            SlideUpPanelView(showPanel: $showPanel, selectedPolyline: $selectedPolyline)
        }
    }
}



struct SlideUpPanelView: View {
    @Binding var showPanel: Bool
    @Binding var selectedPolyline: MKPolyline?
    
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
            Text("Panel Content")
                .font(.headline)
                .padding()
            
            Spacer()
            
            Button(action: {
                showPanel = false
                selectedPolyline = nil
            }) {
                Text("Dismiss")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(10)
            }
            .padding(.bottom, 16)
        }
        .padding(.horizontal)
        .frame(maxWidth: .infinity, maxHeight: .infinity) // Fill the available space
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
    @State private var selectedPolyline: MKPolyline?
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView(frame: .zero)
        mapView.delegate = context.coordinator
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePolylineTap(_:)))
        mapView.addGestureRecognizer(tapGesture)
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
                
                if let tappedPolyline = overlay as? MKPolyline, let selectedPolyline = parent.selectedPolyline {
                    // Change color for the tapped polyline
                    renderer.strokeColor = tappedPolyline.isEqual(selectedPolyline) ? UIColor.orange : UIColor.red
                } else {
                    renderer.strokeColor = UIColor.red
                }
                
                renderer.lineWidth = 5
                return renderer
            }
            return MKOverlayRenderer()
        }
        
        @objc func handlePolylineTap(_ gestureRecognizer: UITapGestureRecognizer) {
            let mapView = gestureRecognizer.view as! MKMapView
            let touchPoint = gestureRecognizer.location(in: mapView)
            let coordinates = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            
            var newSelectedPolyline: MKPolyline?
            
            // Find the polyline that was tapped
            for overlay in mapView.overlays {
                if let polyline = overlay as? MKPolyline {
                    if isCoordinateOnPolyline(coordinates, polyline: polyline) {
                        newSelectedPolyline = polyline
                        break
                    }
                }
            }
            
            // Update the color of the selected polyline and bring it to the front
            if let newPolyline = newSelectedPolyline {
                if let previousPolyline = parent.selectedPolyline, let renderer = mapView.renderer(for: previousPolyline) as? MKPolylineRenderer {
                    renderer.strokeColor = UIColor.red
                }
                parent.selectedPolyline = newPolyline
                
                // Remove and re-add the selected polyline to bring it to the front
                mapView.removeOverlay(newPolyline)
                mapView.addOverlay(newPolyline)
                
                if let renderer = mapView.renderer(for: newPolyline) as? MKPolylineRenderer {
                    renderer.strokeColor = UIColor.orange
                }
            }
        }
        
        
        func isCoordinateOnPolyline(_ coordinate: CLLocationCoordinate2D, polyline: MKPolyline) -> Bool {
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
