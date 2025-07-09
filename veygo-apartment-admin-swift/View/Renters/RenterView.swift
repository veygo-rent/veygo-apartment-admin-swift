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
    @State private var searchText: String = ""
    
    // Computed list that respects the search query (searches name, email, and phone)
    private var filteredRenters: [PublishRenter] {
        if searchText.isEmpty { return renters }
        return renters.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.studentEmail.localizedCaseInsensitiveContains(searchText) ||
            $0.phone.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    @State private var seletedRenter: PublishRenter.ID? = nil
    
    public var body: some View {
        
        NavigationSplitView {
            List(filteredRenters, selection: $seletedRenter) { renter in
                VStack(alignment: .leading, spacing: 2) {
                    Text(renter.name)
                        .font(.headline)
                        .foregroundColor(Color("TextBlackPrimary"))
                    Text(renter.studentEmail)
                        .font(.subheadline)
                        .foregroundColor(Color("TextBlackSecondary"))
                    Text(renter.phone)
                        .font(.subheadline)
                        .foregroundColor(Color("TextBlackSecondary"))
                }
                .padding(12)
            }
            .searchable(text: $searchText, prompt: "Search renters")
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
                        RenterAttributeView(renter: renter, attribute: .dob)
                        RenterAttributeView(renter: renter, attribute: .email)
                        RenterAttributeView(renter: renter, attribute: .phone)
                        HStack (spacing: 20) {
                            SecondaryButton(text: "Verify DLN") {
                                // do something
                            }
                            SecondaryButton(text: "Verify Insurance") {
                                // do something
                            }
                        }
                        HStack (spacing: 20) {
                            SecondaryButton(text: "Verify Lease") {
                                // do something
                            }
                            DangerButton(text: "Add to DNR") {
                                // do something
                            }
                        }
                    }
                    .padding(.horizontal, 36)
                    .padding(.vertical, 48)
                    .background(Color("TextFieldBg").cornerRadius(16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color("TextFieldFrame"), lineWidth: 1)
                    )
                    .padding(.horizontal, 26)
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
}

enum RenterAttributes: String, Equatable {
    case email = "Email"
    case phone = "Phone"
    case dob = "Date of Birth"
}

struct RenterAttributeView: View {
    let renter: PublishRenter
    let attribute: RenterAttributes
    // Formatter to display dates like "Sep 26, 2001"
    private static let displayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        // Keep the date in UTC so the printed day matches the stored string
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
    var body: some View {
        HStack (spacing: 0) {
            Text("\(attribute.rawValue): ")
                .foregroundColor(Color("TextBlackPrimary"))
            switch attribute {
            case .email:
                Text("\(renter.studentEmail)")
                    .foregroundColor(Color("TextBlackSecondary"))
                Spacer()
                if let expirationString = renter.studentEmailExpiration,
                   let expirationDate = dateFromYYYYMMDD(expirationString) {
                    if expirationDate >= Date() {
                        Text("Expires at \(expirationString)")
                            .foregroundColor(Color("ValidGreen"))
                    } else {
                        Text("Expired")
                            .foregroundColor(Color("InvalidRed"))
                    }
                } else {
                    Text("Not Verified")
                        .foregroundColor(Color("InvalidRed"))
                }
            case .phone:
                Text("\(renter.phone)")
                    .foregroundColor(Color("TextBlackSecondary"))
                Spacer()
                if renter.phoneIsVerified {
                    Text("Verified")
                        .foregroundColor(Color("ValidGreen"))
                } else {
                    Text("Not Verified")
                        .foregroundColor(Color("InvalidRed"))
                }
            case .dob:
                if let dobDate = dateFromYYYYMMDD(renter.dateOfBirth) {
                    Text(Self.displayFormatter.string(from: dobDate))
                        .foregroundColor(Color("TextBlackSecondary"))
                } else {
                    Text(renter.dateOfBirth)        // Fallback to raw string if parsing fails
                        .foregroundColor(Color("TextBlackSecondary"))
                }
            }
        }.font(.title3)
    }
}

struct RenterCardView: View {
    var body: some View {
        Text("RenterCardView")
    }
}
