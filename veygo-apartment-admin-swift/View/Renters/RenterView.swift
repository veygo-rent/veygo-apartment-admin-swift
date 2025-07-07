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
        } detail: {
            Color.blue
        }
        .onAppear {
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
    }
}

struct RenterCardView: View {
    var body: some View {
        Text("RenterCardView")
    }
}
