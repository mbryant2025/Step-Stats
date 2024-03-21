//
//  ContentView.swift
//  Step Stats
//
//  Created by Michael Bryant on 5/9/23.
//

import SwiftUI

struct MainView: View {
    
    @State private var showSettings = false
    @State private var selectedUnits = 0
    
    var body: some View {
       NavigationView {
            GeometryReader { geometry in
                ScrollView {
                    VStack {
                        Spacer(minLength: geometry.size.height / 3.0)
                        NavigationLink(destination: MapView()) {
                            HStack {
                                Text("Map Workouts")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color("ButtonColor1"))
                                .cornerRadius(10)
                            }
                        }
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationBarTitle("")
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
