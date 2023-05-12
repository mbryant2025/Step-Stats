////
////  TestPlot.swift
////  Step Stats
////
////  Created by Michael Bryant on 5/11/23.
////
//
//import SwiftUI
//import MapKit
//
//struct ContentView2: View {
//    @State private var mapPoints: [CLLocationCoordinate2D] = []
//
//    var body: some View {
//        VStack {
//            MapViewTest(mapPoints: mapPoints)
//                .frame(height: 400)
//                .padding()
//
//            Button("Plot Points") {
//                fetchPoints()
//            }
//        }
//    }
//
//    func fetchPoints() {
//        // Simulated points for demonstration
//        let points = [
//            CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
//            CLLocationCoordinate2D(latitude: 37.7739, longitude: -122.4127),
//            CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4313),
//            CLLocationCoordinate2D(latitude: 37.7758, longitude: -122.4318)
//        ]
//
//        DispatchQueue.main.async {
//            self.mapPoints = points
//        }
//    }
//}
//
//struct MapViewTest: UIViewRepresentable {
//    let mapPoints: [CLLocationCoordinate2D]
//
//    func makeUIView(context: Context) -> MKMapView {
//        let mapView = MKMapView()
//        mapView.delegate = context.coordinator
//        return mapView
//    }
//
//    func updateUIView(_ mapView: MKMapView, context: Context) {
//        mapView.removeOverlays(mapView.overlays)
//
//        if !mapPoints.isEmpty {
//            print("HERE2")
//            print(mapPoints)
//            let polyline = MKPolyline(coordinates: mapPoints, count: mapPoints.count)
//            mapView.addOverlay(polyline)
//
//            let region = MKCoordinateRegion(polyline.boundingMapRect)
//            mapView.setRegion(region, animated: true)
//        }
//    }
//
//    func makeCoordinator() -> Coordinator {
//        Coordinator()
//    }
//
//    class Coordinator: NSObject, MKMapViewDelegate {
//        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
//            if let polyline = overlay as? MKPolyline {
//                let renderer = MKPolylineRenderer(polyline: polyline)
//                renderer.strokeColor = UIColor.blue.withAlphaComponent(0.7)
//                renderer.lineWidth = 5
//                renderer.lineJoin = .round
//                renderer.lineCap = .round
//                return renderer
//            }
//
//            return MKOverlayRenderer(overlay: overlay)
//        }
//    }
//
//}
//
//struct ContentView2_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView2()
//    }
//}
