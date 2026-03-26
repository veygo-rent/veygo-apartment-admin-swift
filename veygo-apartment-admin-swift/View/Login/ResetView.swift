//
//  ResetView.swift
//  veygo-apartment-admin-swift
//
//  Created by Shenghong Zhou on 3/26/26.
//

import SwiftUI

struct ResetView: View {
    private enum Field: Hashable {
        case email
        case code
        case newPassword
    }

    @FocusState private var focusedField: Field?

    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var alertTitle: String = ""
    @State private var toDismiss: Bool = false

    @Environment(\.dismiss) var dismiss

    let currentEmail: String
    @State private var email: String = ""
    @State private var code: String = ""
    @State private var newPassword: String = ""

    var body: some View {
        VStack(spacing: 20) {
            TextInputField(placeholder: "Email", text: $email)
                .focused($focusedField, equals: .email)
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.none)
                .onAppear {
                    email = currentEmail
                }

            HStack(spacing: 16) {
                TextInputField(placeholder: "OTP Code", text: $code)
                    .focused($focusedField, equals: .code)

                SecondaryButton(text: "Send") {
                    Task {
                        await ApiCallActor.shared.appendApi { token, userId in
                            await requestPasswordCode()
                        }
                    }
                }
                .frame(width: 92)
            }

            TextInputField(placeholder: "Password", text: $newPassword, isSecure: true)
                .focused($focusedField, equals: .newPassword)

            PrimaryButton(text: "Reset") {
                Task {
                    await ApiCallActor.shared.appendApi { token, userId in
                        await resetPasswordCode()
                    }
                }
            }
        }
        .padding(22)
        .frame(maxWidth: 520)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(
            Color("MainBG")
                .ignoresSafeArea()
                .onTapGesture {
                    focusedField = nil
                }
        )
        .navigationTitle("Reset Password")
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK") {
                if toDismiss {
                    dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
    }

    @ApiCallActor func requestPasswordCode() async -> ApiTaskResponse {
        do {
            let body = await ["email": email]
            let jsonData: Data = try VeygoJsonStandard.shared.encoder.encode(body)

            let request = veygoCurlRequest(url: "/api/v1/verification/request-password-token", method: .post, body: jsonData)

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

            guard httpResponse.value(forHTTPHeaderField: "Content-Type") == "application/json" else {
                let body = ErrorResponse.E_DEFAULT
                await MainActor.run {
                    alertTitle = body.title
                    alertMessage = body.message
                    showAlert = true
                }
                return .doNothing
            }

            switch httpResponse.statusCode {
            case 200:
                await MainActor.run {
                    alertTitle = "Request Sent"
                    alertMessage = "You should receive an email with an OTP to reset your password."
                    showAlert = true
                }
                return .doNothing
            case 500:
                if let decodedBody = try? VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: data) {
                    await MainActor.run {
                        alertTitle = decodedBody.title
                        alertMessage = decodedBody.message
                        showAlert = true
                    }
                } else {
                    let decodedBody = ErrorResponse.E500
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
        } catch let error as URLError {
            switch error.code {
            case .timedOut:
                let body = ErrorResponse.E_TIME_OUT
                await MainActor.run {
                    alertTitle = body.title
                    alertMessage = body.message
                    showAlert = true
                }
            case .notConnectedToInternet:
                let body = ErrorResponse.E_NO_INTERNET
                await MainActor.run {
                    alertTitle = body.title
                    alertMessage = body.message
                    showAlert = true
                }
            default:
                let body = ErrorResponse.E_DEFAULT
                await MainActor.run {
                    alertTitle = body.title
                    alertMessage = body.message
                    showAlert = true
                }
            }
            return .doNothing
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

    @ApiCallActor func resetPasswordCode() async -> ApiTaskResponse {
        do {
            let body = await [
                "email": email,
                "code": code,
                "new_password": newPassword
            ]
            let jsonData: Data = try VeygoJsonStandard.shared.encoder.encode(body)

            let request = veygoCurlRequest(url: "/api/v1/verification/reset-password", method: .post, body: jsonData)

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

            guard httpResponse.value(forHTTPHeaderField: "Content-Type") == "application/json" else {
                let body = ErrorResponse.E_DEFAULT
                await MainActor.run {
                    alertTitle = body.title
                    alertMessage = body.message
                    showAlert = true
                }
                return .doNothing
            }

            switch httpResponse.statusCode {
            case 200:
                await MainActor.run {
                    alertTitle = "Password Reset"
                    alertMessage = "Your password has been reset. You can now log in."
                    showAlert = true
                    toDismiss = true
                }
                return .doNothing
            case 406:
                if let decodedBody = try? VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: data) {
                    await MainActor.run {
                        alertTitle = decodedBody.title
                        alertMessage = decodedBody.message
                        showAlert = true
                    }
                } else {
                    let decodedBody = ErrorResponse.E406
                    await MainActor.run {
                        alertTitle = decodedBody.title
                        alertMessage = decodedBody.message
                        showAlert = true
                    }
                }
                return .doNothing
            case 500:
                if let decodedBody = try? VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: data) {
                    await MainActor.run {
                        alertTitle = decodedBody.title
                        alertMessage = decodedBody.message
                        showAlert = true
                    }
                } else {
                    let decodedBody = ErrorResponse.E500
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
        } catch let error as URLError {
            switch error.code {
            case .timedOut:
                let body = ErrorResponse.E_TIME_OUT
                await MainActor.run {
                    alertTitle = body.title
                    alertMessage = body.message
                    showAlert = true
                }
            case .notConnectedToInternet:
                let body = ErrorResponse.E_NO_INTERNET
                await MainActor.run {
                    alertTitle = body.title
                    alertMessage = body.message
                    showAlert = true
                }
            default:
                let body = ErrorResponse.E_DEFAULT
                await MainActor.run {
                    alertTitle = body.title
                    alertMessage = body.message
                    showAlert = true
                }
            }
            return .doNothing
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

#Preview {
    NavigationStack {
        ResetView(currentEmail: "admin@example.com")
    }
}
