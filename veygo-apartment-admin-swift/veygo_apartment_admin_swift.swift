//
//  veygo_apartment_admin_swiftApp.swift
//  veygo-apartment-admin-swift
//
//  Created by Shenghong Zhou on 6/7/25.
//

@preconcurrency import Stripe
import SwiftUI

@main
struct veygo_apartment_admin_swift: App {
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    @StateObject var session = AdminSession()
    
    @State private var didLoad = false
    
    init() {
        StripeAPI.defaultPublishableKey = "pk_live_51QzCjkL87NN9tQEdbASm7SXLCkcDPiwlEbBpOVQk5wZcjOPISrtTVFfK1SFKIlqyoksRIHusp5UcRYJLvZwkyK0a00kdPmuxhM"
    }
    var body: some Scene {
        WindowGroup {
            LaunchScreenView(didLoad: $didLoad) {
                ContentView()
                    .environmentObject(session)
                    .alert(isPresented: $showAlert) {
                        Alert(title: Text("Login Failed"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
                    }
            }
            .onAppear {
                Task {
                    await ApiCallActor.shared.appendApi { token, userId in
                        let result = await validateTokenAndFetchUser(token, userId)
                        await MainActor.run {
                            didLoad.toggle()
                        }
                        return result
                    }
                }
            }
        }
    }
    
    @ApiCallActor func validateTokenAndFetchUser (_ token: String, _ userId: Int) async -> ApiTaskResponse {
        do {
            if !token.isEmpty && userId > 0 {
                let request = veygoCurlRequest(url: "/api/v1/admin/retrieve", method: "GET", headers: ["auth": "\(token)$\(userId)"])
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    await MainActor.run {
                        alertMessage = "Server Error: Invalid protocol"
                        showAlert = true
                    }
                    return .doNothing
                }
                
                guard httpResponse.value(forHTTPHeaderField: "Content-Type") == "application/json" else {
                    await MainActor.run {
                        alertMessage = "Server Error: Invalid content"
                        showAlert = true
                    }
                    return .doNothing
                }
                
                switch httpResponse.statusCode {
                case 200:
                    nonisolated struct FetchSuccessBody: Decodable {
                        let admin: PublishRenter
                    }
                    
                    let token = extractToken(from: response) ?? ""
                    guard let decodedBody = try? VeygoJsonStandard.shared.decoder.decode(FetchSuccessBody.self, from: data) else {
                        await MainActor.run {
                            alertMessage = "Server Error: Invalid content"
                            showAlert = true
                        }
                        return .doNothing
                    }
                    await MainActor.run {
                        self.session.user = decodedBody.admin
                    }
                    return .renewSuccessful(token: token)
                case 401:
                    await MainActor.run {
                        alertMessage = "Token expired, please login again"
                        showAlert = true
                        session.user = nil
                    }
                    return .clearUser
                case 405:
                    await MainActor.run {
                        alertMessage = "Internal Error: Method not allowed, please contact the developer dev@veygo.rent"
                        showAlert = true
                        session.user = nil
                    }
                    return .clearUser
                default:
                    await MainActor.run {
                        alertMessage = "Unrecognized response, make sure you are running the latest version"
                        showAlert = true
                    }
                    return .doNothing
                }
            }
            return .doNothing
        } catch {
            await MainActor.run {
                alertMessage = "Internal Error: \(error.localizedDescription)"
                showAlert = true
            }
            return .doNothing
        }
    }
}
