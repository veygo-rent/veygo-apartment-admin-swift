//
//  RenterView.swift
//  veygo-apartment-admin-swift
//
//  Created by Shenghong Zhou on 6/17/25.
//

import SwiftUI

public struct RenterView: View {
    
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    
    @EnvironmentObject var session: AdminSession
    @AppStorage("token") var token: String = ""
    @AppStorage("user_id") var userId: Int = 0
    
    @State private var renters: [PublishRenter] = []
    
    @State private var seletedRenter: PublishRenter.ID? = nil
    
    public var body: some View {
        
        NavigationSplitView {
            List(renters, selection: $seletedRenter) { renter in
                Text(renter.name)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        refreshRenters()
                    } label: {
                        Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
                    }
                    
                }
            }
        } detail: {
            ZStack {
                Color("MainBG").ignoresSafeArea()
                if let renterID = seletedRenter, let renter = renters.getRenterDetail(for: renterID) {
                    VStack (alignment: .leading, spacing: 20) {
                        Text("\(renter.name)")
                            .foregroundColor(Color("TextBlackPrimary"))
                            .font(.largeTitle)
                        RenterAttributeView(renter: renter, attribute: .email)
                        RenterAttributeView(renter: renter, attribute: .phone)
                    }
                    .padding(.horizontal, 36)
                    .padding(.vertical, 20)
                    .background(Color("TextFieldBg").cornerRadius(16))
                }
            }
        }
        .onAppear {
            refreshRenters()
        }
    }
    
    func refreshRenters() {
        let request = veygoCurlRequest(url: "/api/v1/user/get-users", method: "GET", headers: ["auth": "\(token)$\(userId)"])
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    alertMessage = "Network error: \(error.localizedDescription)"
                    showAlert = true
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, let data = data else {
                DispatchQueue.main.async {
                    alertMessage = "Invalid server response."
                    showAlert = true
                }
                return
            }
            
            if httpResponse.statusCode == 200 {
                let responseJSON = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                if let renterData = responseJSON?["renters"],
                   let renterJSONArray = try? JSONSerialization.data(withJSONObject: renterData),
                   let decodedUser = try? VeygoJsonStandard.shared.decoder.decode([PublishRenter].self, from: renterJSONArray) {
                    // Update AppStorage
                    self.token = extractToken(from: response)!
                    renters = decodedUser
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
    
    enum RenterAttributes: String, Equatable {
        case email = "Email"
        case phone = "Phone"
    }
    
    struct RenterAttributeView: View {
        let renter: PublishRenter
        let attribute: RenterAttributes
        var body: some View {
            HStack {
                Text("\(attribute.rawValue):")
                    .foregroundColor(Color("TextBlackPrimary"))
                switch attribute {
                case .email:
                    Text("\(renter.studentEmail)")
                        .foregroundColor(Color("TextBlackSecondary"))
                    if let _emailVerifiedAt = renter.studentEmailExpiration {
                        Text("Verified")
                    } else {
                        Text("Not Verified")
                            .foregroundColor(Color("InvalidRed"))
                    }
                case .phone:
                    Text("\(renter.phone)")
                        .foregroundColor(Color("TextBlackSecondary"))
                    if renter.phoneIsVerified {
                        Text("Verified")
                    } else {
                        Text("Not Verified")
                            .foregroundColor(Color("InvalidRed"))
                    }
                }
            }.font(.title3)
        }
    }
}

struct RenterCardView: View {
    var body: some View {
        Text("RenterCardView")
    }
}
