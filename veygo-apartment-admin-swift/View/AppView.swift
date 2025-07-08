//
//  AppView.swift
//  veygo-apartment-admin-swift
//
//  Created by Shenghong Zhou on 6/17/25.
//

import SwiftUI

enum Destination: String, Identifiable, Hashable {
    case overview, apartments, vehicles, renters, setting, taxes, toll_companies, reports
    var id: String { self.rawValue }
}

struct AppView: View {
    @EnvironmentObject var session: AdminSession
    @State private var selected: Destination = .overview
    
    var body: some View {
        if session.user == nil {
            Text("Bad Credentials")
        } else {
            TabView (selection: $selected) {
                TabSection("Summary") {
                    Tab("Overview", systemImage: "chart.pie", value: Destination.overview) {
                        ZStack {
                            Color("MainBG").ignoresSafeArea()
                            OverviewView()
                        }
                    }
                }
                
                if session.user!.employeeTier == .admin {
                    TabSection("Administration") {
                        Tab("Taxes", systemImage: "percent", value: Destination.taxes) {
                            Text("Taxes")
                        }
                        
                        Tab("Toll Companies", systemImage: "car.front.waves.down", value: Destination.toll_companies) {
                            Text("Toll Companies")
                        }
                        
                        Tab("Apartments", systemImage: "building.2", value: Destination.apartments) {
                            ApartmentView()
                        }
                        
                        Tab("Reports", systemImage: "chart.line.text.clipboard", value: Destination.reports) {
                            Text("Reports")
                        }
                    }
                }
                
                TabSection("Vehicles") {
                    Tab("Vehicles", systemImage: "car.rear", value: Destination.vehicles) {
                        VehicleView()
                    }
                }
                
                TabSection("Trips") {
                    Tab("Renters", systemImage: "person", value: Destination.renters) {
                        ZStack {
                            Color("MainBG").ignoresSafeArea()
                            RenterView()
                        }
                    }
                }
                
                TabSection("Management") {
                    Tab("Setting", systemImage: "gearshape", value: Destination.setting) {
                        SettingView()
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
