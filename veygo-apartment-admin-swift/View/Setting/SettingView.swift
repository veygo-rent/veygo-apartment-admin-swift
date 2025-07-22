//
//  SettingView.swift
//  veygo-apartment-admin-swift
//
//  Created by Shenghong Zhou on 6/17/25.
//

import SwiftUI

public struct SettingView: View {
    /// Navigation path for back‑tracking through nested setting pages.
    @State private var path: [Destination] = []
    
    @AppStorage("token") private var token: String = ""
    @AppStorage("user_id") private var userId: Int = 0
    
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
                        let request = await veygoCurlRequest(url: "/api/v1/user/remove-token", method: "GET", headers: ["auth": "\(token)$\(userId)"])
                        do {
                            let (_, response) = try await URLSession.shared.data(for: request)
                            guard let httpResponse = response as? HTTPURLResponse else {
                                print("Invalid server response.")
                                return
                            }
                            switch httpResponse.statusCode {
                            case 200:
                                await MainActor.run {
                                    token = ""
                                    userId = 0
                                    self.session.user = nil
                                }
                                print("🧼 Token cleared")
                            default:
                                print("Error logging out, status code: \(httpResponse.statusCode)")
                            }
                        } catch {
                            print("Logout failed with error: \(error.localizedDescription)")
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
        .scrollContentBackground(.hidden)
        .background(Color("MainBG"), ignoresSafeAreaEdges: .all)
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
