import SwiftUI
import HealthKit

struct CumulativeView: View {
    @State private var stepCount: Int = 0
    @State private var totalDistance: Double = 0.0
    @State private var totalFlightsClimbed: Int = 0
    
    var body: some View {
        VStack {
            Text("Total Steps:")
                .font(.title)
            Text("\(stepCount)")
                .font(.largeTitle)
            Text("Total Distance:")
                .font(.title)
            Text(String(format: "%.2f", totalDistance))
                .font(.largeTitle)
            Text("Total Flights Climbed:")
                .font(.title)
            Text("\(totalFlightsClimbed)")
                .font(.largeTitle)
        }
        .onAppear {
            requestAuthorization()
            getCumulativeHealthData(for: .stepCount) { steps in
                self.stepCount = Int(steps)
            }
            getCumulativeHealthData(for: .distanceWalkingRunning) { distance in
                self.totalDistance = distance
            }
            getCumulativeHealthData(for: .flightsClimbed) { flightsClimbed in
                self.totalFlightsClimbed = Int(flightsClimbed)
            }
        }
    }
    
    
    struct CumulativeView_Previews: PreviewProvider {
        static var previews: some View {
            CumulativeView()
        }
    }
    
}
