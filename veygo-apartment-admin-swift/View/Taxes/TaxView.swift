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
    
    @Binding var taxes: [TaxViewModel]
    @State private var searchText: String = ""
    
    @State private var selectedTax: Tax.ID?
    @State private var selectedTaxObj: TaxViewModel?
    
    @State private var showAddTaxView: Bool = false
    
    @State private var newTaxName: String = ""
    @State private var newTaxRate: String = ""
    
    @State private var deleteData: Bool = false
    
    private var filteredTaxes: [TaxViewModel] {
        if searchText.isEmpty { return taxes }
        return taxes.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationSplitView {
            List(filteredTaxes, selection: $selectedTax) { tax in
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
                            await refreshTaxes()
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
            .task(id: selectedTax) {
                if let taxId = selectedTax,
                   let tax = taxes.getItemBy(id: taxId) {
                    await MainActor.run {
                        selectedTaxObj = tax
                    }
                }
            }
        } detail: {
            ZStack {
                Color("MainBG").ignoresSafeArea()
                if let tax = selectedTaxObj {
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
                await refreshTaxes()
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color("MainBG"), ignoresSafeAreaEdges: .all)
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Alert"), message: Text(alertMessage), dismissButton: .default(Text("OK")){
                if deleteData {
                    session.user = nil
                    userId = 0
                    token = ""
                }
            })
        }
        .sheet(isPresented: $showAddTaxView) {
            NavigationStack {
                VStack (spacing: 28) {
                    TextInputField(placeholder: "Tax Name", text: $newTaxName)
                    TextInputField(placeholder: "Tax Rate", text: $newTaxRate, endingString: "%")
                }
                .frame(minWidth: 200, maxWidth: 320)
                .navigationTitle("New Tax")
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
                                await refreshTaxes()
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
    
    @BackgroundActor func refreshTaxes() {
        Task {
            let token = await token
            let userId = await userId
            let request = veygoCurlRequest(url: "/api/v1/apartment/get-taxes", method: "GET", headers: ["auth": "\(token)$\(userId)"])
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

                    let responseJSON = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                    let taxesData = responseJSON?["taxes"]
                    let taxesJSONArray = taxesData.flatMap { try? JSONSerialization.data(withJSONObject: $0) }
                    let decodedTaxes = taxesJSONArray.flatMap { try? VeygoJsonStandard.shared.decoder.decode([Tax].self, from: $0) }

                    await MainActor.run {
                        self.token = newToken
                        guard let decodedTaxes else {
                            self.alertMessage = "Failed to parse taxes."
                            self.showAlert = true
                            return
                        }
                        self.deleteData = false
                        self.taxes = decodedTaxes.map(TaxViewModel.init)
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
