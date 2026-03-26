//
//  SettingView.swift
//  veygo-apartment-admin-swift
//
//  Created by Shenghong Zhou on 3/26/26.
//

import SwiftUI

enum SettingDestination: Hashable {
    case deleteAccount
    case privacyPolicy
    case memberAgreement
    case rentalAgreement
    case termsOfUse
}

struct SettingView: View {
    
    @EnvironmentObject private var session: AdminSession
    
    @Binding var path: [SettingDestination]

    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var alertTitle: String = ""

    var body: some View {
        NavigationStack (path: $path) {
            List {
                
                Section {
                    NavigationLink("Privacy Policy", value: SettingDestination.privacyPolicy)
                    NavigationLink("Member Agreement", value: SettingDestination.memberAgreement)
                    NavigationLink("Rental Agreement", value: SettingDestination.rentalAgreement)
                    NavigationLink("Terms of Use", value: SettingDestination.termsOfUse)
                } header: {
                    Text("Legal")
                        .fontWeight(.light)
                }
                .listRowBackground(Color("CardBG"))
                .foregroundStyle(Color("TextBlackSecondary"))
                .listSectionSeparator(.hidden)
                
                Section {
                    Button(role: .destructive) {
                        Task {
                            await ApiCallActor.shared.appendApi { token, userId in
                                await logoutRequestAsync(token, userId)
                            }
                        }
                    } label: {
                        Text("Log Out")
                            .foregroundStyle(Color("InvalidRed"))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                } header: {
                    Text("Account")
                        .fontWeight(.light)
                }
                .listRowBackground(Color("CardBG"))
                .foregroundStyle(Color("TextBlackSecondary"))
                .listSectionSeparator(.hidden)
                
                Section {
                    ShortTextLink(text: "Request deleting account") {
                        path.append(.deleteAccount)
                    }
                    .listRowBackground(Color.clear)
                }
                .listSectionSeparator(.hidden)
                .listSectionSpacing(0)
            }
            .listStyle(.automatic)
            .scrollIndicators(.hidden)
            .scrollContentBackground(.hidden)
            .background(Color("MainBG"), ignoresSafeAreaEdges: .all)
            .navigationTitle("Settings")
            .navigationDestination(for: SettingDestination.self) { destination in
                switch destination {
                case .deleteAccount:
                    DeleteAccountView()
                case .memberAgreement:
                    TermsView(term: .membershipAgreement)
                case .rentalAgreement:
                    TermsView(term: .rentalAgreement)
                case .privacyPolicy:
                    TermsView(term: .privacyPolicy)
                case .termsOfUse:
                    TermsView(term: .termsOfUse)
                }
            }
            .alert(alertTitle, isPresented: $showAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }

    @ApiCallActor
    private func logoutRequestAsync(_ token: String, _ userId: Int) async -> ApiTaskResponse {
        do {
            guard !token.isEmpty, userId > 0 else {
                await MainActor.run {
                    session.user = nil
                }
                return .clearUser
            }

            let request = veygoCurlRequest(
                url: "/api/v1/user/token",
                method: .delete,
                headers: ["auth": "\(token)$\(userId)"]
            )

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                let body = ErrorResponse.WRONG_PROTOCOL
                await MainActor.run {
                    alertTitle = body.title
                    alertMessage = body.message
                    showAlert = true
                }
                return .doNothing
            }

            switch httpResponse.statusCode {
            case 200, 401:
                await MainActor.run {
                    session.user = nil
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
                    alertMessage = "\(body.message) (\(httpResponse.statusCode))"
                    showAlert = true
                }
                return .doNothing
            }
        } catch {
            let body = ErrorResponse.E_DEFAULT
            await MainActor.run {
                alertTitle = body.title
                alertMessage = body.message
                showAlert = true
            }
            return .doNothing
        }
    }
}

private struct DeleteAccountView: View {
    @EnvironmentObject private var session: AdminSession

    @State private var confirmedDeletion = false
    @State private var isSubmitting = false

    var body: some View {
        List {
            Section("Important") {
                Text("Deleting your account is permanent and cannot be reversed.")
                    .listRowBackground(Color("CardBG"))
                Toggle("I understand and want to continue", isOn: $confirmedDeletion)
                    .listRowBackground(Color("CardBG"))
            }

            Section {
                Button(role: .destructive) {
                    Task {
                        await MainActor.run {
                            isSubmitting = true
                        }
                        await ApiCallActor.shared.appendApi { token, userId in
                            await deleteAccountRequestAsync(token, userId)
                        }
                        await MainActor.run {
                            isSubmitting = false
                        }
                    }
                } label: {
                    Text(isSubmitting ? "Submitting..." : "Request Account Deletion")
                }
                .disabled(!confirmedDeletion || isSubmitting)
                .listRowBackground(Color("CardBG"))
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.mainBG)
        .navigationTitle("Delete Account")
    }

    @ApiCallActor
    private func deleteAccountRequestAsync(_ token: String, _ userId: Int) async -> ApiTaskResponse {
        do {
            guard !token.isEmpty, userId > 0 else {
                await MainActor.run {
                    session.user = nil
                }
                return .clearUser
            }

            let request = veygoCurlRequest(
                url: "/api/v1/user",
                method: .delete,
                headers: ["auth": "\(token)$\(userId)"]
            )

            let (_, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                return .doNothing
            }

            switch httpResponse.statusCode {
            case 200, 401:
                await MainActor.run {
                    session.user = nil
                }
                return .clearUser
            default:
                return .doNothing
            }
        } catch {
            return .doNothing
        }
    }
}
