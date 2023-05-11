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
    
    private func fetchCumulativeHealthData() {
        
        let dispatchGroup = DispatchGroup()
        
        //DATA HANDLED INDIVIDUALLY (ASYNC)
        
        for (quantityType, title) in healthDataTypes {
            dispatchGroup.enter()
            
            getCumulativeHealthData(for: quantityType) { result in
                DispatchQueue.main.async {
                    
                    
                    let widgetData = WidgetData( //TODO SET WIDGET DESTINATION
                        title: title,
                        destination: AnyView(Text("iruhfciuerubn")),
                        symbolName: "",
                        hasData: true,
                        data: result
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
        
        //APPLE WATCH SUMMARY DATA GIVEN TOGETHER -- HANDLED AS A GROUP AND ARE DUMPED
        
        getAllCumulativeHealthDataWatch { results in
            for (title, value) in results {
                
                dispatchGroup.enter()
                
                DispatchQueue.main.async {
                    
                    let widgetData = WidgetData( //TODO SET WIDGET DESTINATION
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
        
        //TODO COMBINE THESE TWO INTO ONE FUNCTION
        
        //ADD WORKOUT DATA, IF THERE IS ANY
        getAllCumulativeWorkoutData { results in
            for (title, value) in results {
                
                dispatchGroup.enter()
                
                DispatchQueue.main.async {
                    
                    let widgetData = WidgetData( //TODO SET WIDGET DESTINATION
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


struct CumulativeView_Previews: PreviewProvider {
    static var previews: some View {
        CumulativeView()
    }
}
