//
//  AppView.swift
//  veygo-apartment-admin-swift
//
//  Created by Shenghong Zhou on 6/17/25.
//

import SwiftUI

private enum RootDestination: String, Identifiable, Hashable {
    case overview
    case apartments
    case vehicles
    case renters
    case reports
    case agreements
    case taxes
    case tollCompanies
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .overview:
            return "Overview"
        case .apartments:
            return "Apartments"
        case .vehicles:
            return "Vehicles"
        case .renters:
            return "Renters"
        case .reports:
            return "Reports"
        case .agreements:
            return "Agreements"
        case .taxes:
            return "Taxes"
        case .tollCompanies:
            return "Toll Companies"
        case .settings:
            return "Settings"
        }
    }

    var symbol: String {
        switch self {
        case .overview:
            return "rectangle.grid.2x2"
        case .apartments:
            return "building.2"
        case .vehicles:
            return "car.2"
        case .renters:
            return "person.3"
        case .reports:
            return "chart.bar.doc.horizontal"
        case .agreements:
            return "doc.text"
        case .taxes:
            return "percent"
        case .tollCompanies:
            return "road.lanes"
        case .settings:
            return "gear"
        }
    }
}

struct AppView: View {
    @EnvironmentObject private var session: AdminSession
    @State private var selected: RootDestination? = .overview

    var body: some View {
        if let user = session.user {
            NavigationSplitView {
                sidebar(user: user)
            } detail: {
                detailContent
            }
            .navigationSplitViewStyle(.balanced)
        } else {
            ContentUnavailableView(
                "Bad credentials",
                systemImage: "exclamationmark.triangle",
                description: Text("Please sign in again to access the admin panel.")
            )
            .padding()
        }
    }

    @ViewBuilder
    private func sidebar(user: PublishRenter) -> some View {
        List(selection: $selected) {
            Section("Workspace") {
                destinationRow(.overview)
                destinationRow(.reports)
            }

            Section("Operations") {
                destinationRow(.apartments)
                destinationRow(.vehicles)
                destinationRow(.renters)
                destinationRow(.agreements)
            }

            Section("Configuration") {
                destinationRow(.taxes)
                destinationRow(.tollCompanies)
                destinationRow(.settings)
            }
        }
        .navigationTitle("Admin")
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(user.name)
                        .font(.footnote.weight(.semibold))
                    Text(user.studentEmail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(32)
            }
        }
    }

    private func destinationRow(_ destination: RootDestination) -> some View {
        NavigationLink(value: destination) {
            Label(destination.title, systemImage: destination.symbol)
        }
    }

    @ViewBuilder
    private var detailContent: some View {
        NavigationStack {
            if let selected {
                PlaceholderDetailView(destination: selected)
            } else {
                ContentUnavailableView(
                    "Select a section",
                    systemImage: "sidebar.left",
                    description: Text("Choose an item from the sidebar.")
                )
            }
        }
    }
}

private struct PlaceholderDetailView: View {
    let destination: RootDestination

    var body: some View {
        List {
            Section {
                Label(destination.title, systemImage: destination.symbol)
                    .font(.title3.weight(.semibold))
            }

            Section("Next Step") {
                Text("Replace this placeholder with your \(destination.title.lowercased()) screen.")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(destination.title)
    }
}
