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
                        Task { await loginUser() }
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
    
    @APIQueueActor
    func loginUser() {
        Task {
            let body: [String: String] = await ["email": email, "password": password]
            guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
                await MainActor.run {
                    alertMessage = "Failed to serialize request body."
                    showAlert = true
                }
                return
            }
            
            let request = veygoCurlRequest(url: "/api/v1/admin/login", method: "POST", body: jsonData)
            
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse else {
                    await MainActor.run {
                        alertMessage = "Invalid server response."
                        showAlert = true
                    }
                    return
                }
                guard httpResponse.value(forHTTPHeaderField: "Content-Type") == "application/json" else {
                    await MainActor.run {
                        alertMessage = "Wrong Content Type: \(httpResponse.value(forHTTPHeaderField: "Content-Type") ?? "N/A")"
                        showAlert = true
                    }
                    return
                }
                switch httpResponse.statusCode {
                case 200:
                    let newToken = extractToken(from: response) ?? ""
                    let responseJSON = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                    if let renterData = responseJSON?["admin"],
                       let renterJSON = try? JSONSerialization.data(withJSONObject: renterData) {
                        await MainActor.run {
                            if let decodedUser = try? VeygoJsonStandard.shared.decoder.decode(PublishRenter.self, from: renterJSON) {
                                self.session.user = decodedUser
                                self.token = newToken
                                self.userId = decodedUser.id
                            }
                        }
                    }
                case 401:
                    await MainActor.run {
                        alertMessage = "Email or password is incorrect"
                        showAlert = true
                    }
                default:
                    await MainActor.run {
                        alertMessage = "Unexpected error (code: \(httpResponse.statusCode))."
                        showAlert = true
                    }
                }
            } catch {
                await MainActor.run {
                    alertMessage = "Network error: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }
    
}

#Preview {
    LoginView()
}
