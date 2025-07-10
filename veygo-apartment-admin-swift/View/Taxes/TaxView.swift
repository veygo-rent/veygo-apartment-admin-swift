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
    
    @EnvironmentObject var session: AdminSession
    @AppStorage("token") var token: String = ""
    @AppStorage("user_id") var userId: Int = 0
    
    @State private var taxes: [Tax] = []
    @State private var searchText: String = ""
    
    @State private var seletedTax: Tax.ID? = nil
    
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
                        refreshTaxes()
                    } label: {
                        Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
                    }
                }
            }
        } detail: {
            ZStack {
                Color("MainBG").ignoresSafeArea()
                if let taxID = seletedTax, let tax = taxes.getItemBy(id: taxID) {
                    
                }
            }
        }
        .onAppear {
            refreshTaxes()
        }
        .scrollContentBackground(.hidden)
        .background(Color("MainBG"), ignoresSafeAreaEdges: .all)
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    func refreshTaxes() {
        let request = veygoCurlRequest(url: "/api/v1/apartment/get-taxes", method: "GET", headers: ["auth": "\(token)$\(userId)"])
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
                // Update AppStorage
                self.token = extractToken(from: response)!
                let responseJSON = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                if let taxesData = responseJSON?["taxes"],
                   let taxesJSONArray = try? JSONSerialization.data(withJSONObject: taxesData),
                   let decodedTaxes = try? VeygoJsonStandard.shared.decoder.decode([Tax].self, from: taxesJSONArray) {
                    taxes = decodedTaxes
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
    TaxView()
}
