//
//  LoginView.swift
//  veygo-apartment-admin-swift
//
//  Created by Shenghong Zhou on 6/7/25.
//

import SwiftUI

enum SignupRoute: Hashable {
    case name
    case age
    case phone
    case email
    case password
}

struct LoginView: View {
    
    private enum Field: Hashable {
        case email
        case password
    }
    
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var alertTitle: String = ""
    @State private var clearUserTriggered: Bool = false
    
    @State private var email: String = ""
    @State private var password: String = ""
    
    @State private var path = NavigationPath()
    
    @State private var goToResetView = false
    
    @EnvironmentObject var session: AdminSession
    
    @FocusState private var focusedField: Field?
    
    var body: some View {
        NavigationStack(path: $path) {
            VStack {
                Spacer()

                Image("VeygoLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 250, height: 250)
                Text("Veygo Admin")
                    .font(.system(size: 36, weight: .semibold, design: .default))
                    .foregroundColor(Color("TextBlackSecondary"))

                TextInputField(placeholder: "Email", text: $email)
                    .onChange(of: email) { oldValue, newValue in
                        email = newValue.lowercased()
                    }
                    .focused($focusedField, equals: .email)
                Spacer().frame(height: 15)
                TextInputField(placeholder: "Password", text: $password, isSecure: true)
                    .focused($focusedField, equals: .password)
                Spacer().frame(height: 20)
                PrimaryButton(text: "Login") {
                    if email.isEmpty {
                        focusedField = .email
                    } else if password.isEmpty {
                        focusedField = .password
                    } else {
                        Task {
                            await ApiCallActor.shared.appendApi { token, userId in
                                await loginUserAsync()
                            }
                        }
                    }
                }

                Spacer().frame(height: 20)
                ShortTextLink(text: "Forgot Password?") {
                    goToResetView = true
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 10)

                Spacer()
                TextWithLink(fullText: "By using this App, you agree to its Terms of Use.", highlightedTexts: [
                    ("Terms of Use", { })
                ])
                TextWithLink(fullText: "By signing in, you agree to Veygo’s Privacy Policy and Membership Agreement.", highlightedTexts: [
                    ("Membership Agreement", { }),
                    ("Privacy Policy", { })
                ])
            }
            .padding(.horizontal, 400)
            .navigationDestination(isPresented: $goToResetView) {
                ResetView(currentEmail: email)
            }
            .background(Color("MainBG").ignoresSafeArea(.all))
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
    }
    
    @ApiCallActor func loginUserAsync() async -> ApiTaskResponse {
        do {
            let body = await ["email": email, "password": password]
            let jsonData: Data = try VeygoJsonStandard.shared.encoder.encode(body)
            
            let request = veygoCurlRequest(url: "/api/v1/admin/login", method: .post, body: jsonData)
            
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
                let token = extractToken(from: response, for: "Logging in") ?? ""
                guard let decodedBody = try? VeygoJsonStandard.shared.decoder.decode(PublishRenter.self, from: data) else {
                    await MainActor.run {
                        alertTitle = "Server Error"
                        alertMessage = "Invalid content"
                        showAlert = true
                    }
                    return .doNothing
                }
                await MainActor.run {
                    self.session.user = decodedBody
                }
                return .loginSuccessful(userId: decodedBody.id, token: token)
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
