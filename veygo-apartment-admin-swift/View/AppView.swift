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
            return "person.2"
        case .reports:
            return "waveform.path.ecg.text.clipboard"
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
    
    @State private var settingPath: [SettingDestination] = []
    @State private var selected: RootDestination? = nil
    
    @AppStorage("apns_token") var apns_token: String = ""
    
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var alertTitle: String = ""
    @State private var clearUserTriggered: Bool = false

    var body: some View {
        if let user = session.user {
            NavigationSplitView {
                sidebar(user: user)
            } detail: {
                detailContent
            }
            .navigationSplitViewStyle(.balanced)
            .onAppear {
                let center = UNUserNotificationCenter.current()
                center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                    if granted {
                        DispatchQueue.main.async {
                            UIApplication.shared.registerForRemoteNotifications()
                        }
                    }
                }
            }
            .alert(alertTitle, isPresented: $showAlert) {
                Button("OK") {
                    if clearUserTriggered {
                        session.user = nil
                    }
                }
            } message: {
                Text(alertMessage)
            }
            .onChange(of: apns_token) { oldValue, newValue in
                Task {
                    await ApiCallActor.shared.appendApi { token, userId in
                        await updateApnsTokenAsync(token, userId)
                    }
                }
            }
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
        .navigationBarTitleDisplayMode(.large)
    }

    private func destinationRow(_ destination: RootDestination) -> some View {
        NavigationLink(value: destination) {
            Label(destination.title, systemImage: destination.symbol)
        }
        .environment(\.symbolVariants, selected == destination ? .fill : .none)
    }

    @ViewBuilder
    private var detailContent: some View {
        if let selected {
            switch selected {
            case .settings:
                SettingView(path: $settingPath)
            default:
                PlaceholderDetailView(destination: selected)
            }
        } else {
            ContentUnavailableView(
                "Select a section",
                systemImage: "sidebar.left",
                description: Text("Choose an item from the sidebar.")
            )
            .scrollContentBackground(.hidden)
            .background(Color.mainBG)
        }
    }
    
    @ApiCallActor func updateApnsTokenAsync (_ token: String, _ userId: Int) async -> ApiTaskResponse {
        do {
            let apns_token = await apns_token
            let user = await MainActor.run { self.session.user }
            
            if !token.isEmpty && userId > 0, user != nil,
               !apns_token.isEmpty {
                let body: [String: String] = ["apns": apns_token]
                let jsonData: Data = try VeygoJsonStandard.shared.encoder.encode(body)
                let request = veygoCurlRequest(url: "/api/v1/admin/update-apns", method: .post, headers: ["auth": "\(token)$\(userId)"], body: jsonData)
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    await MainActor.run {
                        alertTitle = ErrorResponse.WRONG_PROTOCOL.title
                        alertMessage = ErrorResponse.WRONG_PROTOCOL.message
                        showAlert = true
                    }
                    return .doNothing
                }
                switch httpResponse.statusCode {
                case 200:
                    return .doNothing
                case 401:
                    if let decodedBody = try? VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: data) {
                        await MainActor.run {
                            alertTitle = decodedBody.title
                            alertMessage = decodedBody.message
                            showAlert = true
                            clearUserTriggered = true
                        }
                    } else {
                        let decodedBody = ErrorResponse.E401
                        await MainActor.run {
                            alertTitle = decodedBody.title
                            alertMessage = decodedBody.message
                            showAlert = true
                            clearUserTriggered = true
                        }
                    }
                    return .clearUser
                case 405:
                    if let decodedBody = try? VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: data) {
                        await MainActor.run {
                            alertTitle = decodedBody.title
                            alertMessage = decodedBody.message
                            showAlert = true
                        }
                    } else {
                        let decodedBody = ErrorResponse.E405
                        await MainActor.run {
                            alertTitle = decodedBody.title
                            alertMessage = decodedBody.message
                            showAlert = true
                        }
                    }
                    return .doNothing
                default:
                    let body = ErrorResponse.E_DEFAULT
                    await MainActor.run {
                        alertTitle = body.title
                        alertMessage = body.message
                        showAlert = true
                    }
                    return .doNothing
                }
            }
            return .doNothing
        } catch {
            await MainActor.run {
                alertTitle = "Internal Error"
                alertMessage = "\(error.localizedDescription)"
                showAlert = true
            }
            return .doNothing
        }
    }
}

private struct PlaceholderDetailView: View {
    let destination: RootDestination

    var body: some View {
        NavigationStack {
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
            .scrollContentBackground(.hidden)
            .background(Color.mainBG)
            .navigationTitle(destination.title)
        }
    }
}
