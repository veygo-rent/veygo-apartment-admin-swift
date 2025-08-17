//
//  AppView.swift
//  veygo-apartment-admin-swift
//
//  Created by Shenghong Zhou on 6/17/25.
//

import SwiftUI

private enum RootDestination: String, Identifiable, Hashable {
    case overview, apartments, vehicles, renters, setting, taxes, tollCompanies, reports, agreements
    var id: String { self.rawValue }
}

struct AppView: View {
    
    @EnvironmentObject private var session: AdminSession
    @State private var selected: RootDestination = .overview
    
    @State private var apartments: [Apartment] = []
    @State private var renters: [PublishRenter] = []
    @State private var taxes: [Tax] = []
    @State private var tollCompanies: [TransponderCompany] = []
    @State private var aptTaxes: [Int?] = []
    @State private var vehicles: [PublishAdminVehicle] = []
    
    var body: some View {
        if session.user == nil {
            Text("Bad Credentials")
        } else {
            TabView (selection: $selected) {
                if session.user!.emailIsValid() {
                    TabSection("Summary") {
                        Tab(value: RootDestination.overview) {
                            OverviewView()
                        } label: {
                            Label("Overview", systemImage: "chart.pie")
                                .environment(\.symbolVariants, selected == .overview ? .fill : .none)
                        }
                    }
                    
                    if session.user!.employeeTier == .admin {
                        TabSection("Administration") {
                            Tab(value: RootDestination.taxes) {
                                TaxView(taxes: $taxes)
                            } label: {
                                Label("Taxes", systemImage: "percent")
                                    .environment(\.symbolVariants, selected == .taxes ? .fill : .none)
                            }
                            
                            Tab(value: RootDestination.tollCompanies) {
                                TollCompanyView(tollCompanies: $tollCompanies)
                            } label: {
                                Label("Toll Companies", systemImage: "car.front.waves.down")
                                    .environment(\.symbolVariants, selected == .tollCompanies ? .fill : .none)
                            }
                            
                            Tab(value: RootDestination.apartments) {
                                ApartmentView(apartments: $apartments, taxes: $taxes)
                            } label: {
                                Label("Apartments", systemImage: "building.2")
                                    .environment(\.symbolVariants, selected == .apartments ? .fill : .none)
                            }
                            
                            Tab(value: RootDestination.reports) {
                                Text("Reports")
                            } label: {
                                Label("Reports", systemImage: "chart.line.text.clipboard")
                                    .environment(\.symbolVariants, selected == .reports ? .fill : .none)
                            }
                        }
                    }
                    
                    TabSection("Rentals") {
                        Tab(value: RootDestination.renters) {
                            RenterView(renters: $renters)
                        } label: {
                            Label("Renters", systemImage: "person")
                                .environment(\.symbolVariants, selected == .renters ? .fill : .none)
                        }
                        
                        Tab(value: RootDestination.agreements) {
                            AgreementView()
                        } label: {
                            Label("Agreements", systemImage: "pencil.and.list.clipboard")
                                .environment(\.symbolVariants, selected == .agreements ? .fill : .none)
                        }

                        Tab(value: RootDestination.vehicles) {
                            VehicleView()
                        } label: {
                            Label("Vehicles", systemImage: "car.rear")
                                .environment(\.symbolVariants, selected == .vehicles ? .fill : .none)
                        }

                    }
                }
                
                TabSection("Settings") {
                    Tab(value: RootDestination.setting) {
                        SettingView()
                    } label: {
                        Label("Setting", systemImage: "gearshape")
                            .environment(\.symbolVariants, selected == .setting ? .fill : .none)
                    }
                }
            }
            .tabViewStyle(.sidebarAdaptable)
            .scrollContentBackground(.hidden)
        }
    }
}
