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
    
    @EnvironmentObject private var session: AdminSession
    @State private var selected: RootDestination = .overview
    
    @State private var apartments: [Apartment] = []
    @State private var renters: [PublishRenter] = []
    @State private var taxes: [Tax] = []
    @State private var tollCompanies: [TransponderCompany] = []
    
    var body: some View {
        if session.user == nil {
            Text("Bad Credentials")
        } else {
            TabView (selection: $selected) {
                if session.user!.emailIsValid() {
                    TabSection("Summary") {
                        Tab("Overview", systemImage: "chart.pie", value: RootDestination.overview) {
                            OverviewView()
                        }
                    }
                    
                    if session.user!.employeeTier == .admin {
                        TabSection("Administration") {
                            Tab("Taxes", systemImage: "percent", value: RootDestination.taxes) {
                                TaxView(taxes: $taxes)
                            }
                            
                            Tab("Toll Companies", systemImage: "car.front.waves.down", value: RootDestination.toll_companies) {
                                TollCompanyView(tollCompanies: $tollCompanies)
                            }
                            
                            Tab("Apartments", systemImage: "building.2", value: RootDestination.apartments) {
                                ApartmentView(apartments: $apartments)
                            }
                            
                            Tab("Reports", systemImage: "chart.line.text.clipboard", value: RootDestination.reports) {
                                Text("Reports")
                            }
                        }
                    }
                    
                    TabSection("Rentals") {
                        Tab("Renters", systemImage: "person", value: RootDestination.renters) {
                            RenterView(renters: $renters)
                        }
                        
                        Tab("Vehicles", systemImage: "car.rear", value: RootDestination.vehicles) {
                            VehicleView()
                        }
                    }
                }
                
                TabSection("Settings") {
                    Tab("Setting", systemImage: "gearshape", value: RootDestination.setting) {
                        SettingView()
                    }
                }
            }
            .tabViewStyle(.sidebarAdaptable)
            .scrollContentBackground(.hidden)
        }
    }
}

#Preview {
    AppView()
}
