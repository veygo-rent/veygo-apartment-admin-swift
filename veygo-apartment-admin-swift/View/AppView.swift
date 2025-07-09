//
//  AppView.swift
//  veygo-apartment-admin-swift
//
//  Created by Shenghong Zhou on 6/17/25.
//

import SwiftUI

private enum RootDestination: String, Identifiable, Hashable {
    case overview, apartments, vehicles, renters, setting, taxes, toll_companies, reports
    var id: String { self.rawValue }
}

struct AppView: View {
    @EnvironmentObject var session: AdminSession
    @State private var selected: RootDestination = .overview
    
    var body: some View {
        if session.user == nil {
            Text("Bad Credentials")
        } else {
            TabView (selection: $selected) {
                TabSection("Summary") {
                    Tab("Overview", systemImage: "chart.pie", value: RootDestination.overview) {
                        ZStack {
                            Color("MainBG").ignoresSafeArea()
                            OverviewView()
                        }
                    }
                }
                
                if session.user!.employeeTier == .admin {
                    TabSection("Administration") {
                        Tab("Taxes", systemImage: "percent", value: RootDestination.taxes) {
                            Text("Taxes")
                        }
                        
                        Tab("Toll Companies", systemImage: "car.front.waves.down", value: RootDestination.toll_companies) {
                            Text("Toll Companies")
                        }
                        
                        Tab("RootDestination", systemImage: "building.2", value: RootDestination.apartments) {
                            ApartmentView()
                        }
                        
                        Tab("Reports", systemImage: "chart.line.text.clipboard", value: RootDestination.reports) {
                            Text("Reports")
                        }
                    }
                }
                
                TabSection("Rentals") {
                    Tab("Renters", systemImage: "person", value: RootDestination.renters) {
                        ZStack {
                            Color("MainBG").ignoresSafeArea()
                            RenterView()
                        }
                    }
                    
                    Tab("Vehicles", systemImage: "car.rear", value: RootDestination.vehicles) {
                        VehicleView()
                    }
                }
                
                TabSection("Settings") {
                    Tab("Setting", systemImage: "gearshape", value: RootDestination.setting) {
                        ZStack {
                            Color("MainBG").ignoresSafeArea()
                            SettingView()
                        }
                    }
                }
            }
            .tabViewStyle(.sidebarAdaptable)
        }
    }
}

#Preview {
    AppView()
}
