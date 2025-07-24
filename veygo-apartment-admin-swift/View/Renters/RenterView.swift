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
    
    @EnvironmentObject private var session: AdminSession
    @AppStorage("token") private var token: String = ""
    @AppStorage("user_id") private var userId: Int = 0
    
    @MainActor @Binding var renters: [PublishRenter]
    @State private var searchText: String = ""
    
    @State private var doNotRentRecords: [DoNotRentList] = [DoNotRentList(id: 1, note: "Renter doing illegal activities with our vehicle. "), DoNotRentList(id: 2, note: "Renter intentionally running into a police vehicle. ")]
    
    @State private var deleteData: Bool = false
    
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
    @State private var seletedRenterObj: PublishRenter? = nil
    
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
                        Task {
                            await refreshRenters()
                        }
                    } label: {
                        Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
                    }
                }
            }
            .task(id: seletedRenter) { @BackgroundActor in
                if let renterID = await seletedRenter,
                   let renter = await renters.getItemBy(id: renterID) {
                    await MainActor.run {
                        seletedRenterObj = renter
                    }
                }
            }
        } detail: {
            ZStack {
                Color("MainBG").ignoresSafeArea()
                if let renter = seletedRenterObj {
                    RenterCardViewNew(doNotRentRecords: $doNotRentRecords, renter: renter)
                }
            }
        }
        .onAppear {
            Task {
                await refreshRenters()
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color("MainBG"), ignoresSafeAreaEdges: .all)
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Alert"), message: Text(alertMessage), dismissButton: .default(Text("OK")){
                if deleteData {
                    session.user = nil
                    token = ""
                    userId = 0
                }
            })
        }
    }
    
    @BackgroundActor func refreshRenters() async {
        let request = await veygoCurlRequest(url: "/api/v1/user/get-users", method: "GET", headers: ["auth": "\(token)$\(userId)"])
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                await MainActor.run {
                    deleteData = true
                    alertMessage = "Parsing HTTPURLResponse Error"
                    showAlert = true
                }
                return
            }
            guard httpResponse.value(forHTTPHeaderField: "Content-Type") == "application/json" else {
                await MainActor.run {
                    deleteData = true
                    alertMessage = "Wrong Content Type: \(httpResponse.value(forHTTPHeaderField: "Content-Type") ?? "N/A")"
                    showAlert = true
                }
                return
            }
            switch httpResponse.statusCode {
            case 200:
                let newToken = extractToken(from: response) ?? ""
                // Decode on BackgroundActor before switching to MainActor
                let responseJSON = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                let renterData = responseJSON?["renters"]
                let renterJSONArray = renterData.flatMap { try? JSONSerialization.data(withJSONObject: $0) }
                let decodedUser = renterJSONArray.flatMap { try? VeygoJsonStandard.shared.decoder.decode([PublishRenter].self, from: $0) }
                await MainActor.run {
                    self.token = newToken
                    guard let decodedUser else {
                        deleteData = true
                        alertMessage = "Failed to parse renters."
                        showAlert = true
                        return
                    }
                    deleteData = false
                    renters = decodedUser
                }
            case 401:
                await MainActor.run {
                    deleteData = true
                    alertMessage = "Session expired when refreshing renters. Please log in again."
                    showAlert = true
                }
            default:
                await MainActor.run {
                    deleteData = true
                    alertMessage = "Unexpected error (code: \(httpResponse.statusCode))."
                    showAlert = true
                }
            }
        } catch {
            await MainActor.run {
                deleteData = true
                alertMessage = "Network error: \(error.localizedDescription)"
                showAlert = true
            }
        }
    }
}

enum RenterAttributes: String, Equatable {
    case email = "Email"
    case phone = "Phone"
    case dob = "Date of Birth"
}

struct RenterCardViewNew: View {
    @Binding var doNotRentRecords: [DoNotRentList]
    @State private var validDNRRecords: [DoNotRentList] = []
    
    let renter: PublishRenter
    var body: some View {
        List {
            Text("\(renter.name)")
                .foregroundColor(Color("TextBlackPrimary"))
                .font(.largeTitle)
                .fontWeight(.thin)
                .padding(.vertical, 10)
                .listRowBackground(Color("CardBG"))
            RenterAttributeView(renter: renter, attribute: .dob)
                .listRowBackground(Color("CardBG"))
            RenterAttributeView(renter: renter, attribute: .email)
                .listRowBackground(Color("CardBG"))
            RenterAttributeView(renter: renter, attribute: .phone)
                .listRowBackground(Color("CardBG"))
            if doNotRentRecords.count > 0 {
                Text("Do Not Rent Record(s):")
                    .fontWeight(.semibold)
                    .foregroundColor(Color("TextBlackPrimary"))
                    .listRowBackground(Color("CardBG"))
                ForEach(validDNRRecords) { record in
                    HStack {
                        Text("\(record.note)")
                            .foregroundColor(Color("TextBlackSecondary"))
                        Spacer()
                        ShortTextLink(text: "View Details") {
                            // Do something
                        }
                        ShortTextLink(text: "Delete") {
                            // Do something
                        }
                    }
                    .listRowBackground(Color("CardBG"))
                }
            }
            VStack (spacing: 0) {
                HStack (spacing: 16) {
                    SecondaryButton(text: "Verify DLN") {
                        // do something
                    }
                    SecondaryButton(text: "Verify Insurance") {
                        // do something
                    }
                    SecondaryButton(text: "Verify Lease") {
                        // do something
                    }
                }
                .padding(.bottom, 16)
                HStack (spacing: 16) {
                    DangerButton(text: "Edit Privilages") {
                        // do something
                    }
                    DangerButton(text: "Add to DNR") {
                        // do something
                    }
                }
            }
            .listRowBackground(Color("CardBG"))
        }
        .scrollContentBackground(.hidden)
        .task(id: doNotRentRecords) {
            await updateValidDNRRecords()
        }
    }
    
    @BackgroundActor private func updateValidDNRRecords() async {
        let formatter = VeygoDateStandard.shared.YYYYMMDDformator
        let filtered = await doNotRentRecords.compactMap { record in
            if let exp = record.exp {
                if let expDate = formatter.date(from: exp),
                   expDate > Date.now {
                    return record
                } else {
                    return nil
                }
            } else {
                return record
            }
        }
        await MainActor.run {
            validDNRRecords = filtered
        }
    }
}

struct RenterAttributeView: View {
    let renter: PublishRenter
    let attribute: RenterAttributes
    @State private var expirationString: String?
    @State private var expirationDate: Date?
    @State private var dobString: String?
    var body: some View {
        HStack (spacing: 0) {
            Text("\(attribute.rawValue): ")
                .fontWeight(.semibold)
                .foregroundColor(Color("TextBlackPrimary"))
            switch attribute {
            case .email:
                Text("\(renter.studentEmail)")
                    .foregroundColor(Color("TextBlackSecondary"))
                Spacer()
                if let expirationString = expirationString,
                   let expirationDate = expirationDate {
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
                Text(dobString ?? renter.dateOfBirth)
                    .foregroundColor(Color("TextBlackSecondary"))
            }
        }
        .font(.title3)
        .task { @BackgroundActor in
            if let expirationString = renter.studentEmailExpiration {
                let expirationDate = VeygoDateStandard.shared.YYYYMMDDformator.date(from: expirationString)
                await MainActor.run {
                    self.expirationString = expirationString
                    self.expirationDate = expirationDate
                }
            }
            let dobDate = VeygoDateStandard.shared.YYYYMMDDformator.date(from: renter.dateOfBirth)
            let dobString = dobDate.map { VeygoDateStandard.shared.standardDateFormator.string(from: $0) }
            if let dobString {
                await MainActor.run {
                    self.dobString = dobString
                }
            }
        }
    }
}

