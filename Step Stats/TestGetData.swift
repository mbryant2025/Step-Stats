import SwiftUI
import HealthKit

struct TestGetData: View {
    @State private var totalStandHours: Double?
    private let healthStore = HKHealthStore()
    
    var body: some View {
        VStack {
            if let totalStandHours = totalStandHours {
                Text("Total Stand Hours: \(totalStandHours, specifier: "%.2f")")
                    .font(.title)
                    .padding()
            } else {
                Text("Fetching Stand Hours...")
                    .font(.title)
                    .padding()
            }
        }
        .onAppear {
            requestAuthorization()
            fetchTotalStandHours()
        }
    }
    
//    private func requestAuthorization() {
//        let readTypes: Set<HKObjectType> = [HKObjectType.activitySummaryType()]
//        healthStore.requestAuthorization(toShare: nil, read: readTypes) { (success, error) in
//            if let error = error {
//                print("Error requesting HealthKit authorization: \(error.localizedDescription)")
//            }
//        }
//    }
    
    private func fetchTotalStandHours() {
        let calendar = Calendar.current
        let now = Date()
        let oneYearAgo = calendar.date(byAdding: .year, value: -1, to: now)!
        let startOfDay = calendar.startOfDay(for: oneYearAgo)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        let query = HKActivitySummaryQuery(predicate: predicate) { (_, summaries, error) in
            if let error = error {
                print("Error fetching activity summaries: \(error.localizedDescription)")
                return
            }
            
            if let summaries = summaries {
                var totalStandHours: Double = 0.0
                for summary in summaries {
                    let standHours = summary.appleStandHours.doubleValue(for: .count())
                    totalStandHours += standHours
                }
                
                DispatchQueue.main.async {
                    self.totalStandHours = totalStandHours
                }
            }
        }
        
        healthStore.execute(query)
    }



}

struct TestGetData_Previews: PreviewProvider {
    static var previews: some View {
        TestGetData()
    }
}
