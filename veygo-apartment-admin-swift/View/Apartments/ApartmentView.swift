//
//  ApartmentView.swift
//  veygo-apartment-admin-swift
//
//  Created by Shenghong Zhou on 6/17/25.
//

import SwiftUI

public struct ApartmentView: View {
    
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    
    @EnvironmentObject private var session: AdminSession
    @AppStorage("token") private var token: String = ""
    @AppStorage("user_id") private var userId: Int = 0
    
    @Binding var apartments: [Apartment]
    @Binding var taxes: [Tax]
    @State private var searchText: String = ""
    
    @State private var seletedApartment: Apartment.ID? = nil
    
    @State private var showAddApartmentView: Bool = false
    
    @State private var newAptName: String = ""
    @State private var newAptEmail: String = ""
    @State private var newAptPhone: String = ""
    @State private var newAptAddress: String = ""
    @State private var acceptedSchoolEmailDomain: String = ""
    @State private var freeTierHours: String = ""
    @State private var silverTierHours: String = ""
    @State private var silverTierRate: String = ""
    @State private var goldTierHours: String = ""
    @State private var goldTierRate: String = ""
    @State private var platinumTierHours: String = ""
    @State private var platinumTierRate: String = ""
    @State private var durationRate: String = ""
    @State private var liabilityProtectionRate: String = ""
    @State private var pcdwProtectionRate: String = ""
    @State private var pcdwExtProtectionRate: String = ""
    @State private var rsaProtectionRate: String = ""
    @State private var paiProtectionRate: String = ""
    @State private var isOperating: Bool? = nil
    @State private var isPublic: Bool? = nil
    @State private var uniId: Apartment.ID? = nil
    @State private var aptTaxes: [Int?] = []
    
    private var filteredApartments: [Apartment] {
        if searchText.isEmpty {
            return apartments.filter { apt in
                apt.id != 1
            }
        }
        return apartments.filter {
            $0.id != 1 && (
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.address.localizedCaseInsensitiveContains(searchText)
            )
        }
    }
    
    private var universities: [Apartment] {
        return apartments.filter { apt in
            apt.uniId == 0 || apt.uniId == 1
        }
    }
    
    public var body: some View {
        NavigationSplitView {
            List(filteredApartments, selection: $seletedApartment) { apartment in
                VStack(alignment: .leading, spacing: 2) {
                    Text(apartment.name)
                        .font(.headline)
                        .foregroundColor(Color("TextBlackPrimary"))
                    Text(apartment.address)
                        .font(.subheadline)
                        .foregroundColor(Color("TextBlackSecondary"))
                }
                .padding(12)
            }
            .searchable(text: $searchText, prompt: "Search apartments")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        Task {
                            do {
                                try await refreshApartments()
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
                        showAddApartmentView.toggle()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        } detail: {
            ZStack {
                Color("MainBG").ignoresSafeArea()
                if let aptID = seletedApartment, let apt = apartments.getItemBy(id: aptID) {
                    List {
                        Text("\(apt.name)")
                            .foregroundColor(Color("TextBlackPrimary"))
                            .font(.largeTitle)
                            .fontWeight(.thin)
                            .padding(.vertical, 10)
                            .listRowBackground(Color("TextFieldBg"))
                        
                        HStack (spacing: 0) {
                            Text("Contact Email: ")
                                .fontWeight(.semibold)
                                .foregroundColor(Color("TextBlackPrimary"))
                            Spacer()
                            Text("\(apt.email)")
                                .foregroundColor(Color("TextBlackPrimary"))
                        }
                        .listRowBackground(Color("TextFieldBg"))
                        
                        HStack (spacing: 0) {
                            Text("Contact Phone: ")
                                .fontWeight(.semibold)
                                .foregroundColor(Color("TextBlackPrimary"))
                            Spacer()
                            Text("\(apt.phone)")
                                .foregroundColor(Color("TextBlackPrimary"))
                        }
                        .listRowBackground(Color("TextFieldBg"))
                        
                        HStack (spacing: 0) {
                            Text("Address: ")
                                .fontWeight(.semibold)
                                .foregroundColor(Color("TextBlackPrimary"))
                            Spacer()
                            Text("\(apt.address)")
                                .foregroundColor(Color("TextBlackPrimary"))
                        }
                        .listRowBackground(Color("TextFieldBg"))
                        
                        HStack (spacing: 0) {
                            Text("Domain: ")
                                .fontWeight(.semibold)
                                .foregroundColor(Color("TextBlackPrimary"))
                            Spacer()
                            Text("\(apt.acceptedSchoolEmailDomain)")
                                .foregroundColor(Color("TextBlackPrimary"))
                        }
                        .listRowBackground(Color("TextFieldBg"))
                        
                        PrimaryButton(text: "Make operating / non-operating") {
                            // do something
                        }
                        .listRowBackground(Color("TextFieldBg"))
                    }
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .onAppear {
            Task {
                do {
                    try await refreshApartments()
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
        .sheet(isPresented: $showAddApartmentView) {
            NavigationStack {
                ScrollView {
                    VStack(spacing: 28) {
                        TextInputField(placeholder: "New Apartment Name", text: $newAptName)
                        HStack {
                            TextInputField(placeholder: "Email", text: $newAptEmail)
                            TextInputField(placeholder: "Phone", text: $newAptPhone)
                        }
                        TextInputField(placeholder: "Address", text: $newAptAddress)
                        TextInputField(placeholder: "Accepted School Email Domain", text: $acceptedSchoolEmailDomain)
                        HStack {
                            TextInputField(placeholder: "Duration Rate", text: $durationRate)
                            TextInputField(placeholder: "Free Tier Hours", text: $freeTierHours)
                        }
                        HStack {
                            TextInputField(placeholder: "Silver Tier Hours", text: $silverTierHours)
                            TextInputField(placeholder: "Silver Tier Rate", text: $silverTierRate)
                        }
                        HStack {
                            TextInputField(placeholder: "Gold Tier Hours", text: $goldTierHours)
                            TextInputField(placeholder: "Gold Tier Rate", text: $goldTierRate)
                        }
                        HStack {
                            TextInputField(placeholder: "Platinum Tier Hours", text: $platinumTierHours)
                            TextInputField(placeholder: "Platinum Tier Rate", text: $platinumTierRate)
                        }
                        TextInputField(placeholder: "Liability Protection Rate", text: $liabilityProtectionRate)
                        TextInputField(placeholder: "PCDW Protection Rate", text: $pcdwProtectionRate)
                        TextInputField(placeholder: "PCDW Ext Protection Rate", text: $pcdwExtProtectionRate)
                        TextInputField(placeholder: "RSA Protection Rate", text: $rsaProtectionRate)
                        TextInputField(placeholder: "PAI Protection Rate", text: $paiProtectionRate)
                        VStack (alignment: .leading, spacing: 10) {
                            Text("Apartment Belongs To:")
                                .foregroundColor(Color("TextFieldWordColor").opacity(0.65))
                            ZStack {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color("TextFieldBg"))
                                Picker("Belongs To", selection: $uniId) {
                                    ForEach(universities) { uni in
                                        Text(uni.name).tag(uni.id)
                                            .foregroundColor(Color("TextFieldWordColor"))
                                    }
                                }
                                .pickerStyle(.wheel)
                            }
                            .frame(height: 120)
                        }
                    }
                }
                .frame(minWidth: 200, maxWidth: 420)
                .padding(.vertical)
                .navigationTitle("New Apartment")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button {
                            showAddApartmentView = false
                        } label: {
                            Image(systemName: "xmark")
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button {
                            showAddApartmentView = false
                            // Save action here
                            // Ends here
                            Task {
                                do {
                                    try await refreshApartments()
                                    uniId = universities.first?.id ?? 0
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
    
    func refreshApartments() async throws {
        let request = veygoCurlRequest(url: "/api/v1/apartment/get-all-apartments", method: "GET", headers: ["auth": "\(token)$\(userId)"])
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        if httpResponse.statusCode == 200 {
            self.token = extractToken(from: response)!
            let responseJSON = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            if let apartmentsData = responseJSON?["apartments"],
               let apartmentsJSONArray = try? JSONSerialization.data(withJSONObject: apartmentsData),
               let decodedApartments = try? VeygoJsonStandard.shared.decoder.decode([Apartment].self, from: apartmentsJSONArray) {
                DispatchQueue.main.async {
                    self.apartments = decodedApartments
                }
            }
        } else {
            throw NSError(domain: "Server", code: httpResponse.statusCode, userInfo: nil)
        }
    }
    
    func refreshTaxes() async throws {
        let request = veygoCurlRequest(url: "/api/v1/apartment/get-taxes", method: "GET", headers: ["auth": "\(token)$\(userId)"])
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
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
