//
//  TollCompanyView.swift
//  veygo-apartment-admin-swift
//
//  Created by Shenghong Zhou on 7/11/25.
//

import SwiftUI

struct TollCompanyView: View {
    
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    
    @EnvironmentObject private var session: AdminSession
    @AppStorage("token") private var token: String = ""
    @AppStorage("user_id") private var userId: Int = 0
    
    @Binding var tollCompanies: [TransponderCompany]
    @State private var searchText: String = ""
    
    @State private var seletedTollCompany: TransponderCompany.ID? = nil
    
    @State private var showAddTollCompanyView: Bool = false
    
    @State private var newTaxName: String = ""
    @State private var newTaxRate: String = ""
    
    @State private var deleteData: Bool = false
    
    private var filteredTollCompanies: [TransponderCompany] {
        if searchText.isEmpty { return tollCompanies }
        return tollCompanies.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationSplitView {
            List(filteredTollCompanies, selection: $seletedTollCompany) { tollCompany in
                VStack(alignment: .leading, spacing: 2) {
                    Text(tollCompany.name)
                        .font(.headline)
                        .foregroundColor(Color("TextBlackPrimary"))
                }
                .padding(12)
            }
            .searchable(text: $searchText, prompt: "Search toll companies")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        Task {
                            await refreshTollCompanies()
                        }
                    } label: {
                        Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddTollCompanyView.toggle()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        } detail: {
            ZStack {
                Color("MainBG").ignoresSafeArea()
                if let tcID = seletedTollCompany, let tc = tollCompanies.getItemBy(id: tcID) {
                    List {
                        Text("\(tc.name)")
                            .foregroundColor(Color("TextBlackPrimary"))
                            .font(.largeTitle)
                            .fontWeight(.thin)
                            .padding(.vertical, 10)
                            .listRowBackground(Color("CardBG"))
                        HStack (spacing: 0) {
                            Text("Custom Prefix: ")
                                .fontWeight(.semibold)
                                .foregroundColor(Color("TextBlackPrimary"))
                            Spacer()
                            Text("\(tc.customPrefixForTransactionName)")
                                .foregroundColor(Color("TextBlackPrimary"))
                        }
                        .listRowBackground(Color("CardBG"))
                        HStack (spacing: 0) {
                            Text("Transaction Name Field: ")
                                .fontWeight(.semibold)
                                .foregroundColor(Color("TextBlackPrimary"))
                            Spacer()
                            Text("\(tc.correspondingKeyForTransactionName)")
                                .foregroundColor(Color("TextBlackPrimary"))
                        }
                        .listRowBackground(Color("CardBG"))
                        HStack (spacing: 0) {
                            Text("Vehicle ID Field: ")
                                .fontWeight(.semibold)
                                .foregroundColor(Color("TextBlackPrimary"))
                            Spacer()
                            Text("\(tc.correspondingKeyForVehicleId)")
                                .foregroundColor(Color("TextBlackPrimary"))
                        }
                        .listRowBackground(Color("CardBG"))
                        HStack (spacing: 0) {
                            Text("Transaction Time Field: ")
                                .fontWeight(.semibold)
                                .foregroundColor(Color("TextBlackPrimary"))
                            Spacer()
                            Text("\(tc.correspondingKeyForTransactionTime)")
                                .foregroundColor(Color("TextBlackPrimary"))
                        }
                        .listRowBackground(Color("CardBG"))
                        HStack (spacing: 0) {
                            Text("Transaction Time Format: ")
                                .fontWeight(.semibold)
                                .foregroundColor(Color("TextBlackPrimary"))
                            Spacer()
                            Text("\(tc.timestampFormat)")
                                .foregroundColor(Color("TextBlackPrimary"))
                        }
                        .listRowBackground(Color("CardBG"))
                        HStack (spacing: 0) {
                            Text("Transaction Timezone: ")
                                .fontWeight(.semibold)
                                .foregroundColor(Color("TextBlackPrimary"))
                            Spacer()
                            Text("\(tc.timezone ?? "Default [UTC]")")
                                .foregroundColor(Color("TextBlackPrimary"))
                        }
                        .listRowBackground(Color("CardBG"))
                        HStack (spacing: 0) {
                            Text("Transaction Amount Field: ")
                                .fontWeight(.semibold)
                                .foregroundColor(Color("TextBlackPrimary"))
                            Spacer()
                            Text("\(tc.correspondingKeyForTransactionAmount)")
                                .foregroundColor(Color("TextBlackPrimary"))
                        }
                        .listRowBackground(Color("CardBG"))
                        PrimaryButton(text: "Upload Tolls") {
                            // do something
                        }
                        .listRowBackground(Color("CardBG"))
                    }
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .onAppear {
            Task {
                await refreshTollCompanies()
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
        .sheet(isPresented: $showAddTollCompanyView) {
            NavigationStack {
                VStack (spacing: 28) {
                    TextInputField(placeholder: "Tax Name", text: $newTaxName)
                    TextInputField(placeholder: "Tax Rate", text: $newTaxRate, endingString: "%")
                }
                .frame(minWidth: 200, maxWidth: 320)
                .navigationTitle("New Toll Company")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button {
                            newTaxName = ""
                            newTaxRate = ""
                            showAddTollCompanyView = false
                        } label: {
                            Image(systemName: "xmark")
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button {
                            showAddTollCompanyView = false
                            // Save action here
                            // Ends here
                            Task {
                                await refreshTollCompanies()
                            }
                        } label: {
                            Image(systemName: "checkmark")
                        }
                        .buttonStyle(.glassProminent)
                    }
                }
            }
            .background(Color("MainBG"), ignoresSafeAreaEdges: .all)
        }
    }
    
    @APIQueueActor func refreshTollCompanies() {
        Task {
            let token = await token
            let userId = await userId
            let request = veygoCurlRequest(url: "/api/v1/toll/get-company", method: "GET", headers: ["auth": "\(token)$\(userId)"])
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
                    if !newToken.isEmpty && newToken != token {
                        await MainActor.run {
                            self.token = newToken
                        }
                    }
                    let responseJSON = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                    if let tcsData = responseJSON?["transponder_companies"],
                       let tcsJSONArray = try? JSONSerialization.data(withJSONObject: tcsData) {
                        await MainActor.run {
                            if let decodedTCs = try? VeygoJsonStandard.shared.decoder.decode([TransponderCompany].self, from: tcsJSONArray) {
                                deleteData = false
                                tollCompanies = decodedTCs
                            }
                        }
                    }
                case 401:
                    await MainActor.run {
                        deleteData = true
                        alertMessage = "Session expired. Please log in again."
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
}

