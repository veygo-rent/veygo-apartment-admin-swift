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
    
    @EnvironmentObject private var session: AdminSession
    @AppStorage("token") private var token: String = ""
    @AppStorage("user_id") private var userId: Int = 0
    
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
                            do {
                                try await refreshTaxes()
                            } catch {
                                alertMessage = "Error: \(error.localizedDescription)"
                                showAlert = true
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
                do {
                    try await refreshTaxes()
                } catch {
                    alertMessage = "Error: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color("MainBG"), ignoresSafeAreaEdges: .all)
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
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
                                do {
                                    try await refreshTaxes()
                                } catch {
                                    alertMessage = "Error: \(error.localizedDescription)"
                                    showAlert = true
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
    
    func refreshTaxes() async throws {
        let request = veygoCurlRequest(url: "/api/v1/apartment/get-taxes", method: "GET", headers: ["auth": "\(token)$\(userId)"])
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        guard httpResponse.value(forHTTPHeaderField: "Content-Type") == "application/json" else {
            print("Unexpected Content-Type")
            throw URLError(.cannotParseResponse)
        }
        
        if httpResponse.statusCode == 200 {
            self.token = extractToken(from: response)!
            let responseJSON = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            if let taxesData = responseJSON?["taxes"],
               let taxesJSONArray = try? JSONSerialization.data(withJSONObject: taxesData),
               let decodedTaxes = try? VeygoJsonStandard.shared.decoder.decode([Tax].self, from: taxesJSONArray) {
                DispatchQueue.main.async {
                    self.taxes = decodedTaxes
                }
            }
        } else {
            throw NSError(domain: "Server", code: httpResponse.statusCode, userInfo: nil)
        }
    }
}
