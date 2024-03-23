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

struct MainView: View {
    @State private var showInfo = false
    @State private var showPanel = false
    @State private var selectedWorkoutPolyline: WorkoutStoreMKPolyline?
    @State private var mapType: MKMapType = .standard
    @State private var polylines: [WorkoutStoreMKPolyline] = []
    @State private var showAlert = false
    @State private var pauseRendering = false
    @State private var warnNeedsOneWorkoutOn = false
    @State private var isLoading = true

    @State private var showSettings = false
    @State private var selectedUnits = UnitManager.shared.unitType == .mi ? 0 : 1
    
    // Shared in order to persist sorting between opening the sheet
    @State private var sortAscending = false
    @State private var sortCriteria = SortCriteria.date

    // If we should display each of the three workout types
    @State private var showWalking = true
    @State private var showRunning = true
    @State private var showCycling = true

    @State private var needsPolylineUpdate = false

    private let topBarSize = 100.0
    
    var body: some View {

            ZStack {

                MapContainerView(
                    selectedPolyline: $selectedWorkoutPolyline,
                    polylines: $polylines,
                    showAlert: $showAlert,
                    isLoading: $isLoading,
                    mapType: $mapType,
                    needsPolylineUpdate: $needsPolylineUpdate,
                    showWalking: $showWalking,
                    showRunning: $showRunning,
                    showCycling: $showCycling,
                    pauseRendering: $pauseRendering
                )
                .ignoresSafeArea()

                VStack {
                    // Top black bar with buttons
                    ZStack {

                        HStack {
                            // Some content to fill the space
                            Spacer()
                        }
                        .padding(.top, topBarSize)
                        .overlay(
                            Color(UIColor.systemBackground).opacity(0.7)
                                .frame(maxWidth: .infinity, maxHeight: 250)
                                .edgesIgnoringSafeArea(.top)
                                .position(CGPoint(x: UIScreen.main.bounds.width / 2, y: 0))
                        )

                        HStack {
                        
                        Button(action: {
                            showSettings = true
                        }) {
                            Image(systemName: "gearshape")
                                .font(.system(size: 20))
                                .padding(8)
                        }
                        .padding(10)

                        Spacer()

                        Button(action: {
                            showInfo = true
                        }) {
                            Image(systemName: "ellipsis.circle")
                                .font(.system(size: 20))
                                .padding(8)
                        }
                        .padding(10)

                    }
                    .padding(.top, -topBarSize/2)

                    }
                     


                    Spacer()
                }
                
                
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



            if isLoading {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.black.opacity(0.7))
                        .frame(width: 300, height: 200)
                        .overlay(
                            VStack {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(2)
                                    .padding(.top, 16)
                                Text("Plotting Workouts...")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.top, 24)
                            }
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }
        }
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

        .sheet(isPresented: $showSettings) {
            SettingsView(
                showSettings: $showSettings,
                selectedUnits: $selectedUnits,
                mapType: $mapType,
                showWalking: $showWalking,
                showRunning: $showRunning,
                showCycling: $showCycling,
                needsPolylineUpdate: $needsPolylineUpdate,
                warnNeedsOneWorkoutOn: $warnNeedsOneWorkoutOn,
                pauseRendering: $pauseRendering
            )
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("No Workouts Found"),
                  message: Text("This mapper plots workout routes tracked with an Apple Watch. This includes outdoor walking, running, and cycling."),
                  dismissButton: .default(Text("OK")) {
                    pauseRendering = true
                  })
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
        dateFormatter.dateFormat = UnitManager.shared.unitType == .mi ? "M/d/yy" : "d/M/yy"
        
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
            .navigationTitle("Workouts")
            .navigationBarItems(trailing: Button("Done") {
                showInfo = false
            })
        }
    }
}

struct SettingsView: View {
    @Binding var showSettings: Bool
    @Binding var selectedUnits: Int
    @Binding var mapType: MKMapType
    @Binding var showWalking: Bool
    @Binding var showRunning: Bool
    @Binding var showCycling: Bool
    @Binding var needsPolylineUpdate: Bool
    @Binding var warnNeedsOneWorkoutOn: Bool
    @Binding var pauseRendering: Bool

    // Temp variables to store the current state of the toggles before updating the shared state
    // Initialized to the current state of the shared state
    // Uses init
    @State private var tempShowWalking: Bool
    @State private var tempShowRunning: Bool
    @State private var tempShowCycling: Bool

    init(showSettings: Binding<Bool>, selectedUnits: Binding<Int>, mapType: Binding<MKMapType>, showWalking: Binding<Bool>, showRunning: Binding<Bool>, showCycling: Binding<Bool>, needsPolylineUpdate: Binding<Bool>, warnNeedsOneWorkoutOn: Binding<Bool>, pauseRendering: Binding<Bool>) {
        self._showSettings = showSettings
        self._selectedUnits = selectedUnits
        self._mapType = mapType
        self._showWalking = showWalking
        self._showRunning = showRunning
        self._showCycling = showCycling
        self._needsPolylineUpdate = needsPolylineUpdate
        self._warnNeedsOneWorkoutOn = warnNeedsOneWorkoutOn
        self._pauseRendering = pauseRendering

        self._tempShowWalking = State(initialValue: showWalking.wrappedValue)
        self._tempShowRunning = State(initialValue: showRunning.wrappedValue)
        self._tempShowCycling = State(initialValue: showCycling.wrappedValue)
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Map Type")) {
                    Picker("", selection: $mapType) {
                        Text("Standard").tag(MKMapType.standard)
                        Text("Satellite").tag(MKMapType.satellite)
                        Text("Hybrid").tag(MKMapType.hybrid)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                Section(header: Text("Units")) {
                    Picker("Units", selection: $selectedUnits) {
                        Text("Imperial").tag(0)
                        Text("Metric").tag(1)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: selectedUnits) { newValue in
                        // Update the unit type based on the selectedUnits value
                        UnitManager.shared.unitType = (newValue == 0) ? .mi : .km
                    }
                }
                Section(header: Text("Workout Types")) {
                    Toggle("Walking", isOn: $tempShowWalking)
                        .toggleStyle(SwitchToggleStyle(tint: Color("AccentColor")))
                    Toggle("Running", isOn: $tempShowRunning)
                        .toggleStyle(SwitchToggleStyle(tint: Color("AccentColor")))
                    Toggle("Cycling", isOn: $tempShowCycling)
                        .toggleStyle(SwitchToggleStyle(tint: Color("AccentColor")))
                }

            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Done") {
                showSettings = false
                // If any of them changed, nuke the workouts and reload them
                if tempShowWalking != showWalking || tempShowRunning != showRunning || tempShowCycling != showCycling {
                    showWalking = tempShowWalking
                    showRunning = tempShowRunning
                    showCycling = tempShowCycling
                    needsPolylineUpdate = true
                    pauseRendering = false
                }
            })
        }
    }
}

struct MapContainerView: UIViewRepresentable {
    @Binding var selectedPolyline: WorkoutStoreMKPolyline?
    @Binding var polylines: [WorkoutStoreMKPolyline]
    @Binding var showAlert: Bool
    @Binding var isLoading: Bool
    @Binding var mapType: MKMapType
    @Binding var needsPolylineUpdate: Bool
    @Binding var showWalking: Bool
    @Binding var showRunning: Bool
    @Binding var showCycling: Bool
    @Binding var pauseRendering: Bool

    @State var hasDrawnPolylines = false
    @State var workouts: [HKWorkout] = []

    // To prevent selecting a new polyline after less than 1 second
    private let polylineSelectionDelay = 1.0
    var lastPolylineSelectionTime = Date()
    
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
        
        if uiView.mapType != mapType {
            uiView.mapType = mapType
        }
        
        print(pauseRendering)
        
        if(pauseRendering) {
            return
        }

        // Check if we are rerendering
        if needsPolylineUpdate && !polylines.isEmpty {
            DispatchQueue.main.async {
                isLoading = true
                needsPolylineUpdate = false
                polylines.removeAll()
                selectedPolyline = nil
                // Nuke the workouts and reload them
                fetchWorkouts()
                hasDrawnPolylines = false
            }
            return
        }
        
        if workouts.isEmpty {
            print("No workouts found, fetching...")
            fetchWorkouts()
            return
        }
        
        if !hasDrawnPolylines {
            // Delay a bit to allow for the workouts to be fetched (important when updating the workout type)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                print("Plotting workouts...")
                plotWorkouts(on: uiView)
                hasDrawnPolylines = true
            }
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
                let renderer = MKPolylineRenderer(overlay: selectedPolyline)
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
    
    func fetchWorkouts() {
        print("fetching workouts")
        requestAuthorization()
        Task {
            readWorkouts()
            { fetchedWorkouts in
                if let fetchedWorkouts = fetchedWorkouts {
                    //print workout types for debugging
                    print("We are looking for \(showWalking), \(showRunning), \(showCycling) workouts.")
                    for workout in fetchedWorkouts {
                        print(getWorkoutType(for: workout))
                    }
                    // Use getWorkoutType to filter fetched workouts before setting workouts
                    workouts = fetchedWorkouts.filter { workout in
                        return showWalking && getWorkoutType(for: workout) == "Walking" ||
                            showRunning && getWorkoutType(for: workout) == "Running" ||
                            showCycling && getWorkoutType(for: workout) == "Cycling"
                    }
                    print(workouts.count)
                    showAlert = workouts.isEmpty
                }
            }
        }
    }
    
    
    func plotWorkouts(on mapView: MKMapView) {

        print(workouts.count)

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
                isLoading = false
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
                // Check that the polyline was tapped within the last 1 second
                if polyline != parent.selectedPolyline && Date().timeIntervalSince(parent.lastPolylineSelectionTime) > parent.polylineSelectionDelay {
                    parent.lastPolylineSelectionTime = Date()
                    handlePolylineSelection(polyline, mapView: mapView)
                }
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
            
            let tolerance: CLLocationDistance = 100000 // Tolerance in meters
            
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

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
