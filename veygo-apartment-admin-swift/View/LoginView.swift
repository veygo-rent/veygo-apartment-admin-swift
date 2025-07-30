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
    
    @State private var email: String = ""
    @State private var password: String = ""
    
    @State private var path = NavigationPath()
    
    @State private var goToResetView = false

    @State private var showAlert = false
    @State private var alertMessage = ""

    @AppStorage("token") var token: String = ""
    @AppStorage("user_id") var userId: Int = 0
    
    @EnvironmentObject var session: AdminSession
    
    var body: some View {
        NavigationStack(path: $path) {
            VStack {
                Spacer()

                Image("VeygoLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 250, height: 250)
                Text("Veygo Apartment Admin")
                    .font(.system(size: 36, weight: .semibold, design: .default))
                    .foregroundColor(Color("TextBlackSecondary"))

                TextInputField(placeholder: "Email", text: $email)
                    .onChange(of: email) { oldValue, newValue in
                        email = newValue.lowercased()
                    }
                Spacer().frame(height: 15)
                TextInputField(placeholder: "Password", text: $password, isSecure: true)
                Spacer().frame(height: 20)
                PrimaryButton(text: "Login") {
                    if email.isEmpty {
                        alertMessage = "Please enter your email"
                        showAlert = true
                    } else if password.isEmpty {
                        alertMessage = "Please enter your password"
                        showAlert = true
                    } else {
                        Task {
                            await ApiCallActor.shared.appendApi { token, userId in
                                await loginUserAsync()
                            }
                        }
                    }
                }
                .alert(isPresented: $showAlert) {
                    Alert(title: Text("Login Failed"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
                }

                Spacer().frame(height: 20)
                ShortTextLink(text: "Forgot Password?") {
                    goToResetView = true
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 10)

                Spacer()
            }
            .padding(.horizontal, 400)
            .navigationDestination(isPresented: $goToResetView) {
                Text("TODO: Reset Password")
            }
            LegalText()
        }
        .background(Color("MainBG").ignoresSafeArea(.all))
    }

    @ApiCallActor func loginUserAsync() async -> ApiTaskResponse {
        do {
            let body = await ["email": email, "password": password]
            let jsonData = try JSONSerialization.data(withJSONObject: body)
            
            let request = veygoCurlRequest(url: "/api/v1/admin/login", method: "POST", body: jsonData)
            
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
                nonisolated struct LoginSuccessBody: Decodable {
                    let admin: PublishRenter
                }
                
                let token = extractToken(from: response) ?? ""
                guard let decodedBody = try? VeygoJsonStandard.shared.decoder.decode(LoginSuccessBody.self, from: data) else {
                    await MainActor.run {
                        alertMessage = "Server Error: Invalid content"
                        showAlert = true
                    }
                    return .doNothing
                }
                await MainActor.run {
                    self.session.user = decodedBody.admin
                }
                return .loginSuccessful(userId: decodedBody.admin.id, token: token)
            case 401:
                await MainActor.run {
                    alertMessage = "Invalid email or password"
                    showAlert = true
                }
                return .doNothing
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
        } catch {
            await MainActor.run {
                alertMessage = "Internal Error: \(error.localizedDescription)"
                showAlert = true
            }
            return .doNothing
        }
    }
}

#Preview {
    LoginView()
}
