import HealthKit
import SwiftUI
import MapKit
import Atomics

let store = HKHealthStore()
let sheetAnimationDelay = 0.4

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
    @State private var polylines: [WorkoutStoreMKPolyline] = []
    @State private var showAlert = false
    
    //shared in order to persist sorting between opening the sheet
    @State private var sortAscending = false
    @State private var sortCriteria = SortCriteria.date
    
    var body: some View {
        
        ZStack {
            MapContainerView(selectedPolyline: $selectedWorkoutPolyline, mapType: $mapType, polylines: $polylines, showAlert: $showAlert)
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
        .alert(isPresented: $showAlert) {
            Alert(title: Text("No Workouts Found"),
                  message: Text("This mapper plots workout routes tracked with an Apple Watch. This includes walking, running, and cycling."),
                  dismissButton: .default(Text("OK")))
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
            MapInfoView(
                showInfo: $showInfo,
                mapType: $mapType,
                polylines: $polylines,
                selectedPolyline: $selectedWorkoutPolyline,
                sortAscending: $sortAscending,
                sortCriteria: $sortCriteria
            )
        }
        .sheet(isPresented: $showPanel) {
            SlideUpPanelView(showPanel: $showPanel, selectedPolyline: $selectedWorkoutPolyline, showInfo: $showInfo)
        }
    }
}

struct SlideUpPanelView: View {
    @Binding var showPanel: Bool
    @Binding var selectedPolyline: WorkoutStoreMKPolyline?
    @Binding var showInfo: Bool
    
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
            if let selectedPoly = selectedPolyline {
                if let workout = selectedPoly.workout {
                    Text(convertWorkoutToString(workout: workout))
                        .font(.headline)
                        .padding()
                    
                    Button(action: {
                        showPanel = false
                        
                        // Removing and re-adding the line automatically re-zooms
                        let temp = selectedPolyline
                        selectedPolyline = nil
                        
                        //Small delay to allow for animation of sheets
                        DispatchQueue.main.asyncAfter(deadline: .now() + sheetAnimationDelay) {
                            selectedPolyline = temp
                        }
                    }) {
                        Text("Re-Zoom")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color("ButtonColor1"))
                            .cornerRadius(10)
                    }
                    .padding(.bottom, 16)
                }
            }
            else {
                
                Spacer()
                
                VStack(alignment: .center) {
                    HStack {
                        Text("The selected route is highlighted in")
                            .font(.headline)
                        Text("blue")
                            .font(.headline)
                            .foregroundColor(Color("RouteSelected"))
                    }
                    HStack {
                        Text("All other routes are shown in")
                            .font(.headline)
                        Text("purple")
                            .font(.headline)
                            .foregroundColor(Color("Route"))
                    }
                    .padding(.bottom)
                    
                    Text("Select a workout by tapping its route on the map or find it in the info pane: ")
                        .font(.headline)
                        .padding(.bottom)
                }
                .multilineTextAlignment(.center)
                
                Button(action: {
                    showPanel = false
                    //Small delay to allow for animation of sheets
                    DispatchQueue.main.asyncAfter(deadline: .now() + sheetAnimationDelay) {
                        showInfo = true
                    }
                }) {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 22))
                        .foregroundColor(Color("AccentColor"))
                }
                .padding(.bottom, 16)
            }
            
            Spacer()
            
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
}

enum SortCriteria {
    case date
    case distance
}

struct MapInfoView: View {
    @Binding var showInfo: Bool
    @Binding var mapType: MKMapType
    @Binding var polylines: [WorkoutStoreMKPolyline]
    @Binding var selectedPolyline: WorkoutStoreMKPolyline?
    @Binding var sortAscending: Bool
    @Binding var sortCriteria: SortCriteria
    
    private func formatDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M/d/yy"
        
        return dateFormatter.string(from: date)
    }
    
    var sortedPolylines: [WorkoutStoreMKPolyline] {
        switch sortCriteria {
        case .date:
            if sortAscending {
                return polylines.sorted { $0.workout?.startDate ?? Date() < $1.workout?.startDate ?? Date() }
            } else {
                return polylines.sorted { $0.workout?.startDate ?? Date() > $1.workout?.startDate ?? Date() }
            }
        case .distance:
            if sortAscending {
                return polylines.sorted { $0.workout?.totalDistance?.doubleValue(for: HKUnit.meter()) ?? 0 < $1.workout?.totalDistance?.doubleValue(for: HKUnit.meter()) ?? 0 }
            } else {
                return polylines.sorted { $0.workout?.totalDistance?.doubleValue(for: HKUnit.meter()) ?? 0 > $1.workout?.totalDistance?.doubleValue(for: HKUnit.meter()) ?? 0 }
            }
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Map Type")) {
                    Picker("", selection: $mapType) {
                        Text("Standard").tag(MKMapType.standard)
                        Text("Satellite").tag(MKMapType.satellite)
                        Text("Hybrid").tag(MKMapType.hybrid)
                        Text("Muted").tag(MKMapType.mutedStandard)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("Workouts")) {
                    HStack {
                        Text("Sort by:")
                        Picker("", selection: $sortCriteria) {
                            Text("Date").tag(SortCriteria.date)
                            Text("Distance").tag(SortCriteria.distance)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    HStack {
                        Text("Sort order:")
                        Picker("", selection: $sortAscending) {
                            Text("Ascending").tag(true)
                            Text("Descending").tag(false)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    List(sortedPolylines, id: \.self) { polyline in
                        if let workout = polyline.workout {
                            Button(action: {
                                showInfo = false
                                //Change to nil first to force to update
                                selectedPolyline = nil
                                selectedPolyline = polyline
                                
                                print("New workout selected in info panel")
                            }) {
                                HStack {
                                    Text(formatDate(workout.startDate) + " " + getWorkoutType(for: workout))
                                        .foregroundColor(polyline == selectedPolyline ? Color("ButtonColor1") : Color("ButtonColor2")) // Highlight selected workout
                                    Spacer()
                                    if let distance = workout.totalDistance?.doubleValue(for: HKUnit.meter()) {
                                        if UnitManager.shared.unitType == .mi {
                                            Text("\(distance * meterToMiles, specifier: "%.2f") mi")
                                                .foregroundColor(.gray)
                                        } else {
                                            Text("\(distance * meterToKm, specifier: "%.2f") km")
                                                .foregroundColor(.gray)
                                        }
                                    } else {
                                        Text("Distance unavailable")
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                        }
                    }
                }
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
    @Binding var polylines: [WorkoutStoreMKPolyline]
    @Binding var showAlert: Bool
    
    @State private var workouts: [HKWorkout] = []
    @State private var hasDrawnPolylines = false
    
    //To prevent re-zooming after selecting an individual polyline
    private let shouldZoomToPolylines = ManagedAtomic<Bool>(true)
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView(frame: .zero)
        mapView.delegate = context.coordinator
        mapView.mapType = mapType
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePolylineTap(_:)))
        mapView.addGestureRecognizer(tapGesture)
        
        print(workouts.count)
        return mapView
    }
    
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        print("updating")
        
        if uiView.mapType != mapType {
            uiView.mapType = mapType
        }
        
        if workouts.isEmpty {
            fetchWorkouts()
            return
        }
        
        if !hasDrawnPolylines {
            plotWorkouts(on: uiView)
            setHasDrawnPolylines()
        }
        
        // Set all polylines to default color
        for polyline in polylines {
            if let renderer = uiView.renderer(for: polyline) as? MKPolylineRenderer {
                renderer.strokeColor = UIColor(Color("Route"))
            }
        }
        
        // Set selected line highlight
        if let selectedPolyline = selectedPolyline {
            if let renderer = uiView.renderer(for: selectedPolyline) as? MKPolylineRenderer {
                renderer.strokeColor = UIColor(Color("RouteSelected"))
            } else {
                print("Alt")
                // Create a new renderer and set it for the selected polyline
                let renderer = MKPolylineRenderer(overlay: selectedPolyline) //TODO unify this with the coordinator
                renderer.strokeColor = UIColor(Color("RouteSelected"))
                renderer.lineWidth = 6
                uiView.addOverlay(selectedPolyline)
                uiView.renderer(for: selectedPolyline)
                
            }
        }
        
        // Zoom to selected polyline if it exists
        if let selectedPolyline = selectedPolyline {
            zoomToWorkoutPolyline(mapView: uiView, workout: selectedPolyline)
        }
    }

    private func bringSelectedPolylineToFront(_ mapView: MKMapView) {
        if let selectedPolyline = selectedPolyline {
            mapView.removeOverlay(selectedPolyline)
            mapView.addOverlay(selectedPolyline)
        }
    }
    
    private func setHasDrawnPolylines() {
        DispatchQueue.main.async {
            hasDrawnPolylines = true
        }
    }
    
    func fetchWorkouts() {
        print("fetching workouts")
        requestAuthorization()
        Task {
            readWorkouts { fetchedWorkouts in
                if let fetchedWorkouts = fetchedWorkouts {
                    workouts = fetchedWorkouts
                    print(workouts.count)
                    if workouts.isEmpty {
                        showAlert = true
                    }
                }
            }
        }
    }
    
    
    func plotWorkouts(on mapView: MKMapView) {
        // Remove all existing polylines before adding new ones
        mapView.removeOverlays(mapView.overlays)
        
        let dispatchGroup = DispatchGroup()
        
        for workout in workouts {
            dispatchGroup.enter()
            
            Task {
                if let workoutRoutes = await getWorkoutRoute(workout: workout) {
                    for workoutRoute in workoutRoutes {
                        let locationData = await getLocationDataForRoute(givenRoute: workoutRoute)
                        let coordinates = locationData.map { $0.coordinate }
                        let polyline = WorkoutStoreMKPolyline(coordinates: coordinates, count: coordinates.count, workout: workout)
                        await mapView.addOverlay(polyline)
                        
                        // Append the polyline to the polylines array
                        polylines.append(polyline)
                    }
                }
                
                dispatchGroup.leave()
            }
            
        }
        if self.shouldZoomToPolylines.load(ordering: .relaxed) {
            dispatchGroup.notify(queue: .main) {
                zoomToWorkoutPolylines(mapView: mapView)
            }
            self.shouldZoomToPolylines.store(false, ordering: .relaxed)
        }
    }
    
    
    func zoomToWorkoutPolyline(mapView: MKMapView, workout: WorkoutStoreMKPolyline?) {
        guard let workout = workout else {
            print("Workout does not exist, cannot zoom")
            return
        }
        
        mapView.setVisibleMapRect(workout.boundingMapRect, edgePadding: UIEdgeInsets(top: 20, left: 20, bottom: 40, right: 20), animated: true)
    }
    
    func zoomToWorkoutPolylines(mapView: MKMapView) {
        print("Zooming to all")
        var boundingRect: MKMapRect?
        
        for polyline in polylines {
            if boundingRect == nil {
                boundingRect = polyline.boundingMapRect
            } else {
                boundingRect = boundingRect!.union(polyline.boundingMapRect)
            }
        }
        
        if let rect = boundingRect {
            mapView.setVisibleMapRect(rect, edgePadding: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20), animated: true)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapContainerView
        
        init(_ parent: MapContainerView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if overlay is WorkoutStoreMKPolyline {
                let renderer = MKPolylineRenderer(overlay: overlay)
                
                //Only handle not-selected lines because none are initialized as selected
                renderer.strokeColor = UIColor(Color("Route"))
                renderer.lineWidth = 6
                
                return renderer
            }
            
            return MKOverlayRenderer(overlay: overlay)
        }
        
        
        @objc func handlePolylineTap(_ gestureRecognizer: UITapGestureRecognizer) {
            let mapView = gestureRecognizer.view as! MKMapView
            let touchPoint = gestureRecognizer.location(in: mapView)
            let coordinates = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            
            var closestPolyline: WorkoutStoreMKPolyline?
            var closestDistance: CLLocationDistance = Double.infinity
            
            // Find the closest polyline that was tapped
            for overlay in mapView.overlays {
                if let polyline = overlay as? WorkoutStoreMKPolyline {
                    let distance = distanceToPolyline(coordinates, polyline: polyline)
                    if distance < closestDistance {
                        closestDistance = distance
                        closestPolyline = polyline
                    }
                }
            }
            
            // Update the selected polyline
            if let polyline = closestPolyline {
                handlePolylineSelection(polyline, mapView: mapView)
            }
        }

        func handlePolylineSelection(_ polyline: WorkoutStoreMKPolyline, mapView: MKMapView) {
            
            parent.selectedPolyline = polyline
            
            // Remove and re-add the selected polyline to bring it to the front
            mapView.removeOverlay(polyline)
            mapView.addOverlay(polyline)
        }
        
        
        func distanceToPolyline(_ coordinate: CLLocationCoordinate2D, polyline: WorkoutStoreMKPolyline) -> CLLocationDistance {
            var closestDistance: CLLocationDistance = Double.infinity
            
            let tolerance: CLLocationDistance = 15 // Tolerance in meters
            
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
                
                let distance = startToTapDistance + endToTapDistance - polylineDistance
                if distance < closestDistance && distance <= tolerance {
                    closestDistance = distance
                }
            }
            
            return closestDistance
        }
        
    }
}

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView()
    }
}
