//
//  SettingView.swift
//  veygo-apartment-admin-swift
//
//  Created by Shenghong Zhou on 6/17/25.
//

import SwiftUI

public struct SettingView: View {
    
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var alertTitle: String = ""
    @State private var clearUserTriggered: Bool = false
    
    @State private var path: [Destination] = []
    
    @EnvironmentObject private var session: AdminSession
    
    public var body: some View {
        NavigationStack(path: $path) {
            List {
                Section() {
                    NavigationLink("About", value: Destination.about)
                }
                .listRowBackground(Color("CardBG"))
                
                Section() {
                    NavigationLink("Account", value: Destination.account)
                }
                .listRowBackground(Color("CardBG"))
                
                Section() {
                    NavigationLink("Verify Phone Number", value: Destination.phone)
                    NavigationLink(session.user?.emailIsValid() ?? false ? "Verify Email" : "Verify Email to Continue", value: Destination.email)
                }
                .listRowBackground(Color("CardBG"))
                
                Section() {
                    NavigationLink("Legal Notice", value: Destination.legalNotice)
                    NavigationLink("License", value: Destination.license)
                }
                .listRowBackground(Color("CardBG"))
                
                // Stand‑alone “Log Out” action
                Button(role: .destructive) {
                    Task {
                        await ApiCallActor.shared.appendApi { token, userId in
                            await logoutRequestAsync(token, userId)
                        }
                    }
                } label: {
                    Text("Log Out")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .listRowBackground(Color("CardBG"))
            }
            .navigationDestination(for: Destination.self) { dest in
                switch dest {
                case .about:        AboutView()
                case .account:      AccountView()
                case .phone:        PhoneVerificationView()
                case .email:        EmailVerificationView()
                case .legalNotice:  LegalNoticeView()
                case .license:      LicenseView()
                }
            }
            .navigationTitle("Settings")
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
        .scrollContentBackground(.hidden)
        .background(Color("MainBG"), ignoresSafeAreaEdges: .all)
    }
    @ApiCallActor func logoutRequestAsync (_ token: String, _ userId: Int) async -> ApiTaskResponse {
        do {
            if !token.isEmpty && userId > 0 {
                let request = veygoCurlRequest(url: "/api/v1/user/remove-token", method: "GET", headers: ["auth": "\(token)$\(userId)"])
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
                    await MainActor.run {
                        session.user = nil
                    }
                    return .clearUser
                case 405:
                    await MainActor.run {
                        alertTitle = "Internal Error"
                        alertMessage = "Method not allowed, please contact the developer dev@veygo.rent"
                        showAlert = true
                    }
                    return .doNothing
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

// MARK: - Navigation support

private enum Destination: Hashable {
    case about, account
    case phone, email
    case legalNotice, license
}

// MARK: - Leaf views

private struct AboutView: View {
    var body: some View {
        ZStack {
            Color("MainBG").ignoresSafeArea()
            Text("About")
        }
        .navigationTitle("About")
    }
}

private struct AccountView: View {
    var body: some View {
        ZStack {
            Color("MainBG").ignoresSafeArea()
            Text("Account")
        }
        .navigationTitle("Account")
    }
}

private struct PhoneVerificationView: View {
    var body: some View {
        ZStack {
            Color("MainBG").ignoresSafeArea()
            Text("Phone Verification")
        }
        .navigationTitle("Phone")
    }
}

private struct EmailVerificationView: View {
    var body: some View {
        ZStack {
            Color("MainBG").ignoresSafeArea()
            Text("Email Verification")
        }
        .navigationTitle("Email")
    }
}

private struct LegalNoticeView: View {
    var body: some View {
        ZStack {
            Color("MainBG").ignoresSafeArea()
            Text("Legal Notice")
        }
        .navigationTitle("Legal Notice")
    }
}

private struct LicenseView: View {
    var body: some View {
        ZStack {
            Color("MainBG").ignoresSafeArea()
            Text("License")
        }
        .navigationTitle("License")
    }
}
