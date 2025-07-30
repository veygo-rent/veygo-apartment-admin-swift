//
//  TaxView.swift
//  veygo-apartment-admin-swift
//
//  Created by Shenghong Zhou on 7/10/25.
//

import SwiftUI

struct TaxView: View {
    
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var alertTitle: String = ""
    @State private var clearUserTriggered: Bool = false
    
    @EnvironmentObject private var session: AdminSession
    
    @Binding var taxes: [Tax]
    @State private var searchText: String = ""
    
    @State private var seletedTax: Tax.ID? = nil
    
    @State private var showAddTaxView: Bool = false
    
    @State private var newTaxName: String = ""
    @State private var newTaxRate: String = ""
    
    private var filteredTaxes: [Tax] {
        if searchText.isEmpty { return taxes }
        return taxes.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationSplitView {
            List(filteredTaxes, selection: $seletedTax) { tax in
                VStack(alignment: .leading, spacing: 2) {
                    Text(tax.name)
                        .font(.headline)
                        .foregroundColor(Color("TextBlackPrimary"))
                }
                .padding(12)
            }
            .searchable(text: $searchText, prompt: "Search taxes")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        Task {
                            await ApiCallActor.shared.appendApi { token, userId in
                                await refreshTaxesAsync(token, userId)
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddTaxView.toggle()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        } detail: {
            ZStack {
                Color("MainBG").ignoresSafeArea()
                if let taxID = seletedTax, let tax = taxes.getItemBy(id: taxID) {
                    List {
                        Text("\(tax.name)")
                            .foregroundColor(Color("TextBlackPrimary"))
                            .font(.largeTitle)
                            .fontWeight(.thin)
                            .padding(.vertical, 10)
                            .listRowBackground(Color("CardBG"))
                        HStack (spacing: 0) {
                            Text("Multiplier: ")
                                .fontWeight(.semibold)
                                .foregroundColor(Color("TextBlackPrimary"))
                            Spacer()
                            Text("\(String(format: "%.2f", tax.multiplier * 100))%")
                                .foregroundColor(Color("TextBlackPrimary"))
                        }
                        .listRowBackground(Color("CardBG"))
                        HStack (spacing: 0) {
                            Text("Is effective: ")
                                .fontWeight(.semibold)
                                .foregroundColor(Color("TextBlackPrimary"))
                            Spacer()
                            Text("\(tax.isEffective ? "Yes" : "No")")
                                .foregroundColor(Color("TextBlackPrimary"))
                        }
                        .listRowBackground(Color("CardBG"))
                        PrimaryButton(text: "Make effective / Ineffective") {
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
                await ApiCallActor.shared.appendApi { token, userId in
                    await refreshTaxesAsync(token, userId)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color("MainBG"), ignoresSafeAreaEdges: .all)
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK") {
                if clearUserTriggered {
                    session.user = nil
                }
            }
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showAddTaxView) {
            NavigationStack {
                VStack (spacing: 28) {
                    TextInputField(placeholder: "Tax Name", text: $newTaxName)
                    TextInputField(placeholder: "Tax Rate", text: $newTaxRate, endingString: "%")
                }
                .frame(minWidth: 200, maxWidth: 320)
                .navigationTitle("New Tax / Surcharge")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button {
                            newTaxName = ""
                            newTaxRate = ""
                            showAddTaxView = false
                        } label: {
                            Image(systemName: "xmark")
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button {
                            showAddTaxView = false
                            // Save action here
                            // Ends here
                            Task {
                                await ApiCallActor.shared.appendApi { token, userId in
                                    await refreshTaxesAsync(token, userId)
                                }
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
    
    @ApiCallActor func refreshTaxesAsync (_ token: String, _ userId: Int) async -> ApiTaskResponse {
        do {
            if !token.isEmpty && userId > 0 {
                let request = veygoCurlRequest(url: "/api/v1/apartment/get-taxes", method: "GET", headers: ["auth": "\(token)$\(userId)"])
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    await MainActor.run {
                        alertTitle = "Server Error"
                        alertMessage = "Invalid protocol"
                        showAlert = true
                    }
                    return .doNothing
                }
                
                guard httpResponse.value(forHTTPHeaderField: "Content-Type") == "application/json" else {
                    await MainActor.run {
                        alertTitle = "Server Error"
                        alertMessage = "Invalid content"
                        showAlert = true
                    }
                    return .doNothing
                }
                
                switch httpResponse.statusCode {
                case 200:
                    nonisolated struct FetchSuccessBody: Decodable {
                        let taxes: [Tax]
                    }
                    
                    let token = extractToken(from: response) ?? ""
                    guard let decodedBody = try? VeygoJsonStandard.shared.decoder.decode(FetchSuccessBody.self, from: data) else {
                        await MainActor.run {
                            alertTitle = "Server Error"
                            alertMessage = "Invalid content"
                            showAlert = true
                        }
                        return .doNothing
                    }
                    await MainActor.run {
                        self.taxes = decodedBody.taxes
                    }
                    return .renewSuccessful(token: token)
                case 401:
                    await MainActor.run {
                        alertTitle = "Session Expired"
                        alertMessage = "Token expired, please login again"
                        showAlert = true
                        clearUserTriggered = true
                    }
                    return .clearUser
                case 403:
                    let token = extractToken(from: response) ?? ""
                    await MainActor.run {
                        alertTitle = "Access Denied"
                        alertMessage = "No admin access, please login as an admin"
                        showAlert = true
                    }
                    return .renewSuccessful(token: token)
                case 405:
                    await MainActor.run {
                        alertTitle = "Internal Error"
                        alertMessage = "Method not allowed, please contact the developer dev@veygo.rent"
                        showAlert = true
                        clearUserTriggered = true
                    }
                    return .clearUser
                default:
                    await MainActor.run {
                        alertTitle = "Application Error"
                        alertMessage = "Unrecognized response, make sure you are running the latest version"
                        showAlert = true
                    }
                    return .doNothing
                }
            }
            return .doNothing
        } catch {
            await MainActor.run {
                alertTitle = "Internal Error"
                alertMessage = "\(error.localizedDescription)"
                showAlert = true
            }
            return .doNothing
        }
    }
}
