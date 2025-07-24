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
                        loginUser()
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

    func loginUser() {
        let body: [String: String] = ["email": email, "password": password]
        let jsonData = try? JSONSerialization.data(withJSONObject: body)
        
        let request = veygoCurlRequest(url: "/api/v1/admin/login", method: "POST", body: jsonData)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    alertMessage = "Network error: \(error.localizedDescription)"
                    showAlert = true
                }
                return
            }

            guard let httpResponse = response as? HTTPURLResponse, let data = data,
            httpResponse.value(forHTTPHeaderField: "Content-Type") == "application/json" else {
                DispatchQueue.main.async {
                    alertMessage = "Invalid server response."
                    showAlert = true
                }
                return
            }

            if httpResponse.statusCode == 200 {
                // Update AppStorage
                self.token = extractToken(from: response)!
                let responseJSON = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                if let renterData = responseJSON?["admin"],
                   let renterJSON = try? JSONSerialization.data(withJSONObject: renterData) {
                    DispatchQueue.main.async {
                        if let decodedUser = try? VeygoJsonStandard.shared.decoder.decode(PublishRenter.self, from: renterJSON) {
                            self.userId = decodedUser.id
                            print("\nLogin successful: \(self.token) \(decodedUser.id)\n")
                            self.session.user = decodedUser
                        }
                    }
                }
            } else if httpResponse.statusCode == 401 {
                DispatchQueue.main.async {
                    alertMessage = "Email or password is incorrect"
                    showAlert = true
                }
            } else {
                DispatchQueue.main.async {
                    alertMessage = "Unexpected error (code: \(httpResponse.statusCode))."
                    showAlert = true
                }
            }
        }.resume()
    }

}

#Preview {
    LoginView()
}
