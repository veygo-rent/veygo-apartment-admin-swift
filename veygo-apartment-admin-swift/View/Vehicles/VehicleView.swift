//
//  VehicleView.swift
//  veygo-apartment-admin-swift
//
//  Created by Shenghong Zhou on 6/17/25.
//

import SwiftUI

struct VehicleView: View {
    
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var alertTitle: String = ""
    @State private var clearUserTriggered: Bool = false
    
    @EnvironmentObject private var session: AdminSession
    
    @Binding var vehicles: [PublishAdminVehicle]
    @State private var searchText: String = ""
    
    @State private var selectedVehicle: PublishAdminVehicle.ID? = nil
    
    @State private var showAddVehicleView: Bool = false
    @State private var isLoading: Bool = false
    
    @State private var newTaxName: String = ""
    @State private var newTaxRate: String = ""
    
    @AppStorage("smartcar_exchange_code") var smartcarExchangeCode: String = ""
    
    private var filteredVehicles: [PublishAdminVehicle] {
        if searchText.isEmpty { return vehicles }
        return vehicles.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.licenseNumber.localizedCaseInsensitiveContains(searchText) ||
            $0.vin.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationSplitView {
            List(filteredVehicles, selection: $selectedVehicle) { vehicle in
                VStack(alignment: .leading, spacing: 2) {
                    Text(vehicle.name)
                        .font(.headline)
                        .foregroundColor(Color("TextBlackPrimary"))
                    Text("\(vehicle.make) \(vehicle.model)")
                        .font(.subheadline)
                        .foregroundColor(Color("TextBlackSecondary"))
                    Text("\(vehicle.licenseState) \(vehicle.licenseNumber)")
                        .font(.subheadline)
                        .foregroundColor(Color("TextBlackSecondary"))
                    Text(vehicle.vin)
                        .font(.subheadline)
                        .foregroundColor(Color("TextBlackSecondary"))
                }
                .padding(12)
            }
            .searchable(text: $searchText, prompt: "Search vehicles")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        Task {
                            await ApiCallActor.shared.appendApi { token, userId in
                                await refreshVehicleAsync(token, userId)
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddVehicleView.toggle()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        } detail: {
            ZStack {
                Color("MainBG").ignoresSafeArea()
                if let vehicleID = selectedVehicle, let vehicle = vehicles.getItemBy(id: vehicleID) {
                    List {
                        Text("\(vehicle.make) \(vehicle.model)")
                            .foregroundColor(Color("TextBlackPrimary"))
                            .font(.largeTitle)
                            .fontWeight(.thin)
                            .padding(.vertical, 10)
                            .listRowBackground(Color("CardBG"))
                        HStack (spacing: 0) {
                            Text("VIN Number: ")
                                .fontWeight(.semibold)
                                .foregroundColor(Color("TextBlackPrimary"))
                            Spacer()
                            Text("\(vehicle.vin)")
                                .foregroundColor(Color("TextBlackPrimary"))
                        }
                        .listRowBackground(Color("CardBG"))
                        HStack (spacing: 0) {
                            Text("License Plate: ")
                                .fontWeight(.semibold)
                                .foregroundColor(Color("TextBlackPrimary"))
                            Spacer()
                            Text("\(vehicle.licenseState) \(vehicle.licenseNumber)")
                                .foregroundColor(Color("TextBlackPrimary"))
                        }
                        .listRowBackground(Color("CardBG"))
                        
                        VStack (spacing: 0) {
                            if vehicle.remoteMgmt == .smartcar {
                                if vehicle.remoteMgmtId.isEmpty {
                                    SecondaryButton(text: "Connect to smartcar") {
                                        // Find a presenter from the active UIWindowScene
                                        guard
                                            let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first,
                                            let presenter = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController?.topMostPresented()
                                        else { return }

                                        (AppDelegate.shared)?.beginSmartcarAuth(from: presenter)
                                    }
                                    .padding(.bottom, 16)
                                    .onChange(of: smartcarExchangeCode) { oldValue, newValue in
                                        if let vehicleID = selectedVehicle, !newValue.isEmpty {
                                            Task {
                                                await ApiCallActor.shared.appendApi { token, userId in
                                                    await setupSmartcarAsync(token, userId, vehicleID, newValue)
                                                }
                                            }
                                        }
                                    }
                                } else {
                                    HStack (spacing: 16) {
                                        SecondaryButton(text: "Lock w/ SmartCar") {
                                            // do something
                                            if let vehicleID = selectedVehicle {
                                                Task {
                                                    await ApiCallActor.shared.appendApi { token, userId in
                                                        await MainActor.run { isLoading = true }
                                                        let result = await lockingWithSmartcarAsync(token, userId, vehicleID, toLock: true)
                                                        await MainActor.run { isLoading = false }
                                                        return result
                                                    }
                                                }
                                            }
                                        }.buttonStyle(.borderless)
                                        DangerButton(text: "Unlock w/ SmartCar") {
                                            // do something
                                            if let vehicleID = selectedVehicle {
                                                Task {
                                                    await ApiCallActor.shared.appendApi { token, userId in
                                                        await MainActor.run { isLoading = true }
                                                        let result = await lockingWithSmartcarAsync(token, userId, vehicleID, toLock: false)
                                                        await MainActor.run { isLoading = false }
                                                        return result
                                                    }
                                                }
                                            }
                                        }.buttonStyle(.borderless)
                                    }
                                    .padding(.bottom, 16)
                                }
                            }
                            PrimaryButton(text: "Make available / Unavailable") {
                                // do something
                            }.buttonStyle(.borderless)
                        }
                        .listRowBackground(Color("CardBG"))
                    }
                    .scrollContentBackground(.hidden)
                }
                if isLoading {
                    ZStack {
                        Rectangle()
                            .fill(.ultraThinMaterial)
                            .ignoresSafeArea()
                        VStack(spacing: 12) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(1.4)
                            Text("Working…")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .padding(20)
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(radius: 8)
                    }
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.2), value: isLoading)
                }
            }
        }
        .onAppear {
            Task {
                await ApiCallActor.shared.appendApi { token, userId in
                    await refreshVehicleAsync(token, userId)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color("MainBG"), ignoresSafeAreaEdges: .all)
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK") {
                if clearUserTriggered {
                    session.user = nil
                }
            }
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showAddVehicleView) {
            NavigationStack {
                VStack (spacing: 28) {
                    TextInputField(placeholder: "Tax Name", text: $newTaxName)
                    TextInputField(placeholder: "Tax Rate", text: $newTaxRate, endingString: "%")
                }
                .frame(minWidth: 200, maxWidth: 320)
                .navigationTitle("New Tax / Surcharge")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button {
                            newTaxName = ""
                            newTaxRate = ""
                            showAddVehicleView = false
                        } label: {
                            Image(systemName: "xmark")
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button {
                            showAddVehicleView = false
                            // Save action here
                            // Ends here
                            Task {
                                await ApiCallActor.shared.appendApi { token, userId in
                                    await refreshVehicleAsync(token, userId)
                                }
                            }
                        } label: {
                            Image(systemName: "checkmark")
                        }
                        .buttonStyle(.glassProminent)
                    }
                }
            }
            .background(Color("MainBG"), ignoresSafeAreaEdges: .all)
        }
    }
    
    @ApiCallActor func refreshVehicleAsync (_ token: String, _ userId: Int) async -> ApiTaskResponse {
        do {
            let user = await MainActor.run { self.session.user }
            if !token.isEmpty && userId > 0, user != nil {
                let request = veygoCurlRequest(url: "/api/v1/vehicle/get", method: .get, headers: ["auth": "\(token)$\(userId)"])
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    await MainActor.run {
                        alertTitle = "Server Error"
                        alertMessage = "Invalid protocol"
                        showAlert = true
                    }
                    return .doNothing
                }
                
                guard httpResponse.value(forHTTPHeaderField: "Content-Type") == "application/json" else {
                    await MainActor.run {
                        alertTitle = "Server Error"
                        alertMessage = "Invalid content"
                        showAlert = true
                    }
                    return .doNothing
                }
                
                switch httpResponse.statusCode {
                case 200:
                    nonisolated struct FetchSuccessBody: Decodable {
                        let vehicles: [PublishAdminVehicle]
                    }
                    
                    let token = extractToken(from: response, for: "Getting vehicles") ?? ""
                    guard let decodedBody = try? VeygoJsonStandard.shared.decoder.decode(FetchSuccessBody.self, from: data) else {
                        await MainActor.run {
                            alertTitle = "Server Error"
                            alertMessage = "Invalid content"
                            showAlert = true
                        }
                        return .renewSuccessful(token: token)
                    }
                    await MainActor.run {
                        self.vehicles = decodedBody.vehicles
                    }
                    return .renewSuccessful(token: token)
                case 401:
                    await MainActor.run {
                        alertTitle = "Session Expired"
                        alertMessage = "Token expired, please login again"
                        showAlert = true
                        clearUserTriggered = true
                    }
                    return .clearUser
                case 403:
                    await MainActor.run {
                        alertTitle = "Access Denied"
                        alertMessage = "No admin access, please login as an admin"
                        showAlert = true
                        clearUserTriggered = true
                    }
                    return .clearUser
                case 405:
                    await MainActor.run {
                        alertTitle = "Internal Error"
                        alertMessage = "Method not allowed, please contact the developer dev@veygo.rent"
                        showAlert = true
                        clearUserTriggered = true
                    }
                    return .clearUser
                default:
                    await MainActor.run {
                        alertTitle = "Application Error"
                        alertMessage = "Unrecognized response, make sure you are running the latest version"
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
    
    @ApiCallActor func setupSmartcarAsync (_ token: String, _ userId: Int, _ vehicleId: Int, _ smartcarToken: String) async -> ApiTaskResponse {
        do {
            let user = await MainActor.run { self.session.user }
            if !token.isEmpty && userId > 0, user != nil {
                
                nonisolated struct Payload: Codable {
                    let vehicleId: Int
                    let smartcarToken: String
                }
                
                let jsonData = try VeygoJsonStandard.shared.encoder.encode(Payload.init(vehicleId: vehicleId, smartcarToken: smartcarToken))
                let request = veygoCurlRequest(url: "/api/v1/vehicle/set-sc-token", method: .post, headers: ["auth": "\(token)$\(userId)"], body: jsonData)
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    await MainActor.run {
                        alertTitle = "Server Error"
                        alertMessage = "Invalid protocol"
                        showAlert = true
                    }
                    return .doNothing
                }
                
                guard httpResponse.value(forHTTPHeaderField: "Content-Type") == "application/json" else {
                    await MainActor.run {
                        alertTitle = "Server Error"
                        alertMessage = "Invalid content"
                        showAlert = true
                    }
                    return .doNothing
                }
                
                switch httpResponse.statusCode {
                case 200:
                    nonisolated struct FetchSuccessBody: Decodable {
                        let updatedVehicle: PublishAdminVehicle
                    }
                    
                    let token = extractToken(from: response, for: "Setting up smartcar") ?? ""
                    guard let decodedBody = try? VeygoJsonStandard.shared.decoder.decode(FetchSuccessBody.self, from: data) else {
                        await MainActor.run {
                            alertTitle = "Server Error"
                            alertMessage = "Invalid content"
                            showAlert = true
                        }
                        return .renewSuccessful(token: token)
                    }
                    await MainActor.run {
                        // update vehicles
                        vehicles.updateItem(id: vehicleId, with: decodedBody.updatedVehicle)
                    }
                    return .renewSuccessful(token: token)
                case 400:
                    await MainActor.run {
                        alertTitle = "Bad Request"
                        alertMessage = "Invalid vehicle information"
                        showAlert = true
                    }
                    return .doNothing
                case 401:
                    await MainActor.run {
                        alertTitle = "Session Expired"
                        alertMessage = "Token expired, please login again"
                        showAlert = true
                        clearUserTriggered = true
                    }
                    return .clearUser
                case 403:
                    await MainActor.run {
                        alertTitle = "Access Denied"
                        alertMessage = "No admin access, please login as an admin"
                        showAlert = true
                        clearUserTriggered = true
                    }
                    return .clearUser
                case 405:
                    await MainActor.run {
                        alertTitle = "Internal Error"
                        alertMessage = "Method not allowed, please contact the developer dev@veygo.rent"
                        showAlert = true
                        clearUserTriggered = true
                    }
                    return .clearUser
                default:
                    await MainActor.run {
                        alertTitle = "Application Error"
                        alertMessage = "Unrecognized response, make sure you are running the latest version"
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
    
    @ApiCallActor func lockingWithSmartcarAsync (_ token: String, _ userId: Int, _ vehicleId: Int, toLock toLockInput: Bool) async -> ApiTaskResponse {
        do {
            let user = await MainActor.run { self.session.user }
            if !token.isEmpty && userId > 0, user != nil {
                
                nonisolated struct Payload: Codable {
                    let vehicleId: Int
                    let toLock: Bool
                }
                
                let jsonData = try VeygoJsonStandard.shared.encoder.encode(Payload.init(vehicleId: vehicleId, toLock: toLockInput))
                let request = veygoCurlRequest(url: "/api/v1/vehicle/lock-with-sc", method: .post, headers: ["auth": "\(token)$\(userId)"], body: jsonData)
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    await MainActor.run {
                        alertTitle = "Server Error"
                        alertMessage = "Invalid protocol"
                        showAlert = true
                    }
                    return .doNothing
                }
                
                guard httpResponse.value(forHTTPHeaderField: "Content-Type") == "application/json" else {
                    await MainActor.run {
                        alertTitle = "Server Error"
                        alertMessage = "Invalid content"
                        showAlert = true
                    }
                    return .doNothing
                }
                
                switch httpResponse.statusCode {
                case 200:
                    nonisolated struct FetchSuccessBody: Decodable {
                        let updatedVehicle: PublishAdminVehicle
                    }
                    
                    let token = extractToken(from: response, for: "Loacking the vehicle with smartcar") ?? ""
                    guard let decodedBody = try? VeygoJsonStandard.shared.decoder.decode(FetchSuccessBody.self, from: data) else {
                        await MainActor.run {
                            alertTitle = "Server Error"
                            alertMessage = "Invalid content"
                            showAlert = true
                        }
                        return .renewSuccessful(token: token)
                    }
                    await MainActor.run {
                        alertTitle = "Successful"
                        alertMessage = toLockInput ? "Vehicle is now locked" : "Vehicle is now unlocked"
                        showAlert = true
                        // update vehicles
                        vehicles.updateItem(id: vehicleId, with: decodedBody.updatedVehicle)
                    }
                    return .renewSuccessful(token: token)
                case 400:
                    await MainActor.run {
                        alertTitle = "Bad Request"
                        alertMessage = "Invalid vehicle information"
                        showAlert = true
                        clearUserTriggered = true
                    }
                    return .doNothing
                case 401:
                    await MainActor.run {
                        alertTitle = "Session Expired"
                        alertMessage = "Token expired, please login again"
                        showAlert = true
                        clearUserTriggered = true
                    }
                    return .clearUser
                case 403:
                    await MainActor.run {
                        alertTitle = "Access Denied"
                        alertMessage = "No admin access, please login as an admin"
                        showAlert = true
                        clearUserTriggered = true
                    }
                    return .clearUser
                case 405:
                    await MainActor.run {
                        alertTitle = "Internal Error"
                        alertMessage = "Method not allowed, please contact the developer dev@veygo.rent"
                        showAlert = true
                        clearUserTriggered = true
                    }
                    return .clearUser
                default:
                    await MainActor.run {
                        alertTitle = "Application Error"
                        alertMessage = "Unrecognized response, make sure you are running the latest version"
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
