//
//  OverviewView.swift
//  veygo-apartment-admin-swift
//
//  Created by Shenghong Zhou on 6/17/25.
//

import SwiftUI
import SmartcarAuth

public struct OverviewView: View {
    
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var alertTitle: String = ""
    @State private var clearUserTriggered: Bool = false
    
    @AppStorage("apns_token") var apns_token: String = ""
    @EnvironmentObject var session: AdminSession
    
    public var body: some View {
        Button("Smartcar Test") {
            // Find a presenter from the active UIWindowScene
            guard
                let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first,
                let presenter = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController?.topMostPresented()
            else { return }

            (AppDelegate.shared)?.beginSmartcarAuth(from: presenter)
        }
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
        .onChange(of: apns_token) { oldValue, newValue in
            Task {
                await ApiCallActor.shared.appendApi { token, userId in
                    await updateApnsTokenAsync(token, userId)
                }
            }
        }
        .onOpenURL(perform: { url in
            print(url)
            if let appDelegate = AppDelegate.shared,
               let smartcar = appDelegate.smartcar {
                smartcar.handleCallback(callbackUrl: url)
            }
        })
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
                let (_, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    await MainActor.run {
                        alertTitle = "Server Error"
                        alertMessage = "Invalid protocol"
                        showAlert = true
                    }
                    return .doNothing
                }
                switch httpResponse.statusCode {
                case 200:
                    let token = extractToken(from: response, for: "Updating APNs token") ?? ""
                    return .renewSuccessful(token: token)
                case 401:
                    await MainActor.run {
                        alertTitle = "Session Expired"
                        alertMessage = "Token expired, please login again"
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
