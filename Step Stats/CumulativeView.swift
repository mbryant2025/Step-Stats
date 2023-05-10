import SwiftUI
import HealthKit


struct CumulativeView: View {
    @StateObject private var widgetDataStore = WidgetDataStore()
    
    private let buttonHeight: CGFloat = 80
    private let widgetSpacing: CGFloat = 8
    
    var body: some View {
        ScrollView {
            VStack(spacing: widgetSpacing) {
                WidgetView(widgets: widgetDataStore.widgets, buttonHeight: buttonHeight)
            }
            .padding()
        }
        .navigationBarTitle("Cumulative Stats")
        .onAppear {
            requestAuthorization()
            fetchCumulativeHealthData()
        }
    }
    
    //TO ADD WIDGET, ADD HERE (1/2)
    
    private func fetchCumulativeHealthData() {
        let healthDataTypes: [HKQuantityTypeIdentifier: String] = [
            .stepCount: "Steps",
            .distanceWalkingRunning: "Distance",
            .flightsClimbed: "Flights Climbed",
            .appleMoveTime: "Move Time",
            .appleStandTime: "Stand Time",
            .activeEnergyBurned: "Calories Burned",
            
        ]
    //------------------------------
        
        let dispatchGroup = DispatchGroup()
        
        for (quantityType, title) in healthDataTypes {
            dispatchGroup.enter()
            
            getCumulativeHealthData(for: quantityType) { result in
                DispatchQueue.main.async {
                    let formattedData: String
                    let numberFormatter = NumberFormatter()
                    numberFormatter.numberStyle = .decimal
                    numberFormatter.maximumFractionDigits = 2
                    
                    //AND HERE (2/2) IF APPLICABLE
                    switch quantityType {
                    case .distanceWalkingRunning:
                        formattedData = numberFormatter.string(from: NSNumber(value: result)) ?? ""
                    default:
                        formattedData = numberFormatter.string(from: NSNumber(value: Int(result))) ?? ""
                    }
                    
                    //----------------------------
                    
                    let widgetData = WidgetData(
                        title: title,
                        destination: AnyView(Text("iruhfciuerubn")),
                        symbolName: "",
                        hasData: true,
                        data: formattedData
                    )
                    
                    if let index = widgetDataStore.widgets.firstIndex(where: { $0.title == title }) {
                        widgetDataStore.widgets[index] = widgetData
                    } else {
                        widgetDataStore.widgets.append(widgetData)
                    }
                    
                    dispatchGroup.leave()
                }
            }
        }
    }
}


struct CumulativeView_Previews: PreviewProvider {
    static var previews: some View {
        CumulativeView()
    }
}
