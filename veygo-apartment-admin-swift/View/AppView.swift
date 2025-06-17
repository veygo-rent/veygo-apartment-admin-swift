//
//  AppView.swift
//  veygo-apartment-admin-swift
//
//  Created by Shenghong Zhou on 6/17/25.
//

import SwiftUI

enum Destination: String, Identifiable, Hashable {
    case overview, apartments, vehicles, renters, setting

    var id: String { self.rawValue }
}

struct AppView: View {
    @State private var selected: Destination = .overview
    @State private var searchText: String = ""
    
    var body: some View {
        TabView (selection: $selected) {
            Tab(value: .overview) {
                OverviewView()
            } label: {
                Label("Overview", systemImage: "chart.pie")
            }
            
            Tab(value: .apartments) {
                ApartmentView()
            } label: {
                Label("Apartments", systemImage: "house")
            }
            
            Tab(value: .vehicles) {
                VehicleView()
            } label: {
                Label("Vehicles", systemImage: "car.rear")
            }
            
            Tab(value: .renters) {
                RenterView()
            } label: {
                Label("Renters", systemImage: "person")
            }
            
            Tab(value: .setting) {
                SettingView()
            } label: {
                Label("Setting", systemImage: "gearshape")
            }

        }
        .tabViewStyle(.sidebarAdaptable)
    }
}
