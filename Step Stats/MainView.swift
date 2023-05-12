//
//  ContentView.swift
//  Step Stats
//
//  Created by Michael Bryant on 5/9/23.
//

import SwiftUI

struct MainView: View {
    @State private var widgets = [
        WidgetData(title: "Cumulative Stats", destination: AnyView(CumulativeView()), symbolName: "chart.bar.fill", hasData: false, data:""),
        WidgetData(title: "Records", destination: AnyView(CumulativeView()), symbolName: "list.bullet.rectangle", hasData: false, data:""),
        WidgetData(title: "Workout Mapper", destination: AnyView(MapView()), symbolName: "map.fill", hasData: false, data:""),
    ]
    
    @State private var showSettings = false
    @State private var selectedUnits = 0
    
    private let buttonHeight: CGFloat = 100
    private let widgetSpacing: CGFloat = 10
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: widgetSpacing) {
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
                        Text("Miles").tag(0)
                        Text("km").tag(1)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: selectedUnits) { newValue in
                        // Update the unit type based on the selectedUnits value
                        UnitManager.shared.unitType = (newValue == 0) ? .mi : .km
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
