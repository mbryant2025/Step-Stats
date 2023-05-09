import SwiftUI

struct MainView: View {
    @State private var widgets = [
        WidgetData(title: "Cumulative Stats", symbolName: "chart.bar.fill", destination: AnyView(CumulativeView())),
        WidgetData(title: "Records", symbolName: "list.bullet.rectangle", destination: AnyView(Text("Records View"))),
        WidgetData(title: "Workout Mapper", symbolName: "map.fill", destination: AnyView(Text("Workout Mapper View")))
    ]
    
    @State private var showSettings = false
    @State private var selectedUnits = 0
    
    private let buttonHeight: CGFloat = 100 // Set the desired button height here
    private let widgetSpacing: CGFloat = 10 // Set the desired spacing between widgets here
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: widgetSpacing) { // Use widgetSpacing for spacing between widgets
                    WidgetView(widgets: widgets, buttonHeight: buttonHeight)
                }
                .padding()
            }
            .navigationBarTitle("Step Stats")
            .navigationBarItems(trailing:
                Button(action: {
                    showSettings = true
                }) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 18))
                }
            )
            .sheet(isPresented: $showSettings) {
                SettingsView(showSettings: $showSettings, selectedUnits: $selectedUnits)
            }
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}

struct SettingsView: View {
    @Binding var showSettings: Bool
    @Binding var selectedUnits: Int
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Units")) {
                    Picker("Units", selection: $selectedUnits) {
                        Text("Metric").tag(0)
                        Text("Imperial").tag(1)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: selectedUnits) { newValue in
                        // Update the unit type based on the selectedUnits value
                        UnitManager.shared.unitType = (newValue == 0) ? .km : .mi
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Done") {
                showSettings = false
            })
        }
    }
}
