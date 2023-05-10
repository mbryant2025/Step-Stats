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
    
    //TO ADD WIDGET, ADD HERE (1/3)
    
    private func fetchCumulativeHealthData() {
        let healthDataTypes: [HKQuantityTypeIdentifier: String] = [
            .stepCount: "Steps",
            .distanceWalkingRunning: "Distance",
            .flightsClimbed: "Flights Climbed",
        ]
    //------------------------------
        
        let dispatchGroup = DispatchGroup()
        
        //For data gathered from the phone, we have to iterate through each Identifier
        for (quantityType, title) in healthDataTypes {
            dispatchGroup.enter()
            
            getCumulativeHealthDataPhone(for: quantityType) { result in
                DispatchQueue.main.async {
                    let formattedData: String
                    let numberFormatter = NumberFormatter()
                    numberFormatter.numberStyle = .decimal
                    numberFormatter.maximumFractionDigits = 2
                    
                    //AND HERE (2/3) IF APPLICABLE
                    switch quantityType {
                        case .distanceWalkingRunning:
                            formattedData = numberFormatter.string(from: NSNumber(value: result)) ?? ""
                        default:
                            formattedData = numberFormatter.string(from: NSNumber(value: Int(result))) ?? ""
                    }
                    
                    //----------------------------
                    //FOR (3/3), SEE GetHealthData.swift TO ENSURE UNITS ARE PROPERLY HANDLED
                    
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
            
            getAllCumulativeHealthDataWatch { results in
                for (title, value) in results {
                    
                    dispatchGroup.enter()
                    
                    DispatchQueue.main.async {
                        
                        let widgetData = WidgetData(
                            title: title,
                            destination: AnyView(Text("iruhfciuerubn")),
                            symbolName: "",
                            hasData: true,
                            data: value
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
}


struct CumulativeView_Previews: PreviewProvider {
    static var previews: some View {
        CumulativeView()
    }
}
