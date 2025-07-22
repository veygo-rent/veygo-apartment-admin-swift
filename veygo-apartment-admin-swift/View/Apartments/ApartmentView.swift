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
    @State private var isOperating: Bool = true
    @State private var isPublic: Bool = true
    @State private var uniId: Apartment.ID? = nil
    @State private var aptTaxes: [Int?] = []
    @State private var aptTaxSearch: String = ""
    
    @State private var freeTierHoursDouble: Double = 0
    @State private var silverTierHoursDouble: Double = 0
    @State private var silverTierRateDouble: Double = 0
    @State private var goldTierHoursDouble: Double = 0
    @State private var goldTierRateDouble: Double = 0
    @State private var platinumTierHoursDouble: Double = 0
    @State private var platinumTierRateDouble: Double = 0
    @State private var durationRateDouble: Double = 0
    @State private var liabilityProtectionRateDouble: Double = 0
    @State private var pcdwProtectionRateDouble: Double = 0
    @State private var pcdwExtProtectionRateDouble: Double = 0
    @State private var rsaProtectionRateDouble: Double = 0
    @State private var paiProtectionRateDouble: Double = 0
    
    @State private var deleteData: Bool = false
    
    private var isFormValid: Bool {
        
        let emailValidator = EmailValidator(email: newAptEmail)
        
        return !newAptName.isEmpty &&
        emailValidator.isValidEmail &&
        !newAptPhone.isEmpty &&
        !newAptAddress.isEmpty &&
        !acceptedSchoolEmailDomain.isEmpty
        
    }
    
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
                            await refreshApartments()
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
                            .listRowBackground(Color("CardBG"))
                        
                        HStack (spacing: 0) {
                            Text("Contact Email: ")
                                .fontWeight(.semibold)
                                .foregroundColor(Color("TextBlackPrimary"))
                            Spacer()
                            Text("\(apt.email)")
                                .foregroundColor(Color("TextBlackPrimary"))
                        }
                        .listRowBackground(Color("CardBG"))
                        
                        HStack (spacing: 0) {
                            Text("Contact Phone: ")
                                .fontWeight(.semibold)
                                .foregroundColor(Color("TextBlackPrimary"))
                            Spacer()
                            Text("\(apt.phone)")
                                .foregroundColor(Color("TextBlackPrimary"))
                        }
                        .listRowBackground(Color("CardBG"))
                        
                        HStack (spacing: 0) {
                            Text("Address: ")
                                .fontWeight(.semibold)
                                .foregroundColor(Color("TextBlackPrimary"))
                            Spacer()
                            Text("\(apt.address)")
                                .foregroundColor(Color("TextBlackPrimary"))
                        }
                        .listRowBackground(Color("CardBG"))
                        
                        HStack (spacing: 0) {
                            Text("Domain: ")
                                .fontWeight(.semibold)
                                .foregroundColor(Color("TextBlackPrimary"))
                            Spacer()
                            Text("\(apt.acceptedSchoolEmailDomain)")
                                .foregroundColor(Color("TextBlackPrimary"))
                        }
                        .listRowBackground(Color("CardBG"))
                        
                        PrimaryButton(text: "Make operating / non-operating") {
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
                await refreshApartments()
                await refreshTaxes()
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color("MainBG"), ignoresSafeAreaEdges: .all)
        .sheet(isPresented: $showAddApartmentView) {
            NavigationStack {
                ScrollView {
                    VStack(spacing: 28) {
                        TextInputField(placeholder: "New Apartment Name", text: $newAptName)
                        HStack(spacing: 22) {
                            TextInputField(placeholder: "Email", text: $newAptEmail)
                                .onChange(of: newAptEmail) { oldValue, newValue in
                                    newAptEmail = newValue.lowercased()
                                }
                            TextInputField(placeholder: "Phone", text: $newAptPhone)
                        }
                        TextInputField(placeholder: "Address", text: $newAptAddress)
                        TextInputField(placeholder: "Accepted School Email Domain", text: $acceptedSchoolEmailDomain)
                            .onChange(of: acceptedSchoolEmailDomain) { oldValue, newValue in
                                acceptedSchoolEmailDomain = newValue.lowercased()
                            }
                        HStack(spacing: 22) {
                            TextInputField(placeholder: "Duration Rate", text: $durationRate)
                                .keyboardType(.decimalPad)
                                .onChange(of: durationRate) { oldValue, newValue in
                                    if let tempVar = Double(newValue){
                                        self.durationRateDouble = tempVar
                                    } else if newValue == "" {
                                        durationRateDouble = 0.0
                                    } else {
                                        durationRate = oldValue
                                    }
                                }
                            TextInputField(placeholder: "Free Tier Hours", text: $freeTierHours)
                                .keyboardType(.decimalPad)
                                .onChange(of: freeTierHours) { oldValue, newValue in
                                    if let tempVar = Double(newValue){
                                        self.freeTierHoursDouble = tempVar
                                    } else if newValue == "" {
                                        freeTierHoursDouble = 0.0
                                    } else {
                                        freeTierHours = oldValue
                                    }
                                }
                        }
                        HStack(spacing: 22) {
                            TextInputField(placeholder: "Silver Tier Hours", text: $silverTierHours)
                                .keyboardType(.decimalPad)
                                .onChange(of: silverTierHours) { oldValue, newValue in
                                    if let tempVar = Double(newValue){
                                        self.silverTierHoursDouble = tempVar
                                    } else if newValue == "" {
                                        silverTierHoursDouble = 0.0
                                    } else {
                                        silverTierHours = oldValue
                                    }
                                }
                            TextInputField(placeholder: "Silver Tier Rate", text: $silverTierRate)
                                .keyboardType(.decimalPad)
                                .onChange(of: silverTierRate) { oldValue, newValue in
                                    if let tempVar = Double(newValue){
                                        self.silverTierRateDouble = tempVar
                                    } else if newValue == "" {
                                        silverTierRateDouble = 0.0
                                    } else {
                                        silverTierRate = oldValue
                                    }
                                }
                        }
                        HStack(spacing: 22) {
                            TextInputField(placeholder: "Gold Tier Hours", text: $goldTierHours)
                                .keyboardType(.decimalPad)
                                .onChange(of: goldTierHours) { oldValue, newValue in
                                    if let tempVar = Double(newValue){
                                        self.goldTierHoursDouble = tempVar
                                    } else if newValue == "" {
                                        goldTierHoursDouble = 0.0
                                    } else {
                                        goldTierHours = oldValue
                                    }
                                }
                            TextInputField(placeholder: "Gold Tier Rate", text: $goldTierRate)
                                .keyboardType(.decimalPad)
                                .onChange(of: goldTierRate) { oldValue, newValue in
                                    if let tempVar = Double(newValue){
                                        self.goldTierRateDouble = tempVar
                                    } else if newValue == "" {
                                        goldTierRateDouble = 0.0
                                    } else {
                                        goldTierRate = oldValue
                                    }
                                }
                        }
                        HStack(spacing: 22) {
                            TextInputField(placeholder: "Platinum Tier Hours", text: $platinumTierHours)
                                .keyboardType(.decimalPad)
                                .onChange(of: platinumTierHours) { oldValue, newValue in
                                    if let tempVar = Double(newValue){
                                        self.platinumTierHoursDouble = tempVar
                                    } else if newValue == "" {
                                        platinumTierHoursDouble = 0.0
                                    } else {
                                        platinumTierHours = oldValue
                                    }
                                }
                            TextInputField(placeholder: "Platinum Tier Rate", text: $platinumTierRate)
                                .keyboardType(.decimalPad)
                                .onChange(of: platinumTierRate) { oldValue, newValue in
                                    if let tempVar = Double(newValue){
                                        self.platinumTierRateDouble = tempVar
                                    } else if newValue == "" {
                                        platinumTierRateDouble = 0.0
                                    } else {
                                        platinumTierRate = oldValue
                                    }
                                }
                        }
                        TextInputField(placeholder: "Liability Protection Rate", text: $liabilityProtectionRate)
                            .keyboardType(.decimalPad)
                            .onChange(of: liabilityProtectionRate) { oldValue, newValue in
                                if let tempVar = Double(newValue){
                                    self.liabilityProtectionRateDouble = tempVar
                                } else if newValue == "" {
                                    liabilityProtectionRateDouble = 0.0
                                } else {
                                    liabilityProtectionRate = oldValue
                                }
                            }
                        TextInputField(placeholder: "PCDW Protection Rate", text: $pcdwProtectionRate)
                            .keyboardType(.decimalPad)
                            .onChange(of: pcdwProtectionRate) { oldValue, newValue in
                                if let tempVar = Double(newValue){
                                    self.pcdwProtectionRateDouble = tempVar
                                } else if newValue == "" {
                                    pcdwProtectionRateDouble = 0.0
                                } else {
                                    pcdwProtectionRate = oldValue
                                }
                            }
                        TextInputField(placeholder: "PCDW Ext Protection Rate", text: $pcdwExtProtectionRate)
                            .keyboardType(.decimalPad)
                            .onChange(of: pcdwExtProtectionRate) { oldValue, newValue in
                                if let tempVar = Double(newValue){
                                    self.pcdwExtProtectionRateDouble = tempVar
                                } else if newValue == "" {
                                    pcdwExtProtectionRateDouble = 0.0
                                } else {
                                    pcdwExtProtectionRate = oldValue
                                }
                            }
                        TextInputField(placeholder: "RSA Protection Rate", text: $rsaProtectionRate)
                            .keyboardType(.decimalPad)
                            .onChange(of: rsaProtectionRate) { oldValue, newValue in
                                if let tempVar = Double(newValue){
                                    self.rsaProtectionRateDouble = tempVar
                                } else if newValue == "" {
                                    rsaProtectionRateDouble = 0.0
                                } else {
                                    rsaProtectionRate = oldValue
                                }
                            }
                        TextInputField(placeholder: "PAI Protection Rate", text: $paiProtectionRate)
                            .keyboardType(.decimalPad)
                            .onChange(of: paiProtectionRate) { oldValue, newValue in
                                if let tempVar = Double(newValue){
                                    self.paiProtectionRateDouble = tempVar
                                } else if newValue == "" {
                                    paiProtectionRateDouble = 0.0
                                } else {
                                    paiProtectionRate = oldValue
                                }
                            }
                        ListInputField(searchText: $aptTaxSearch, listOfOptions: $taxes, selectedOptions: $aptTaxes, placeholder: "Search Taxes...")
                        VStack (alignment: .leading, spacing: 10) {
                            Text("Apartment Belongs To:")
                                .foregroundColor(Color("TextFieldWordColor").opacity(0.65))
                            ZStack {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color("CardBG").opacity(0.45))
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
                        if isFormValid {
                            Button {
                                showAddApartmentView = false
                                // Save action here
                                Task {
                                    await addApartment()
                                    uniId = universities.first?.id ?? 0
                                }
                            } label: {
                                Image(systemName: "checkmark")
                            }
                            .buttonStyle(.glassProminent)
                        } else {
                            Button {
                                
                            } label: {
                                Image(systemName: "checkmark")
                            }
                            .buttonStyle(.glassProminent)
                            .tint(Color.gray.opacity(0.5))
                            .disabled(true)
                        }
                    }
                }
            }
            .background(Color("MainBG"), ignoresSafeAreaEdges: .all)
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Alert"), message: Text(alertMessage), dismissButton: .default(Text("OK")){
                if deleteData {
                    session.user = nil
                    APIQueueManager.shared.setAuth(userId: 0, token: "")
                }
            })
        }
    }
    
    func refreshApartments() async {
        await withCheckedContinuation { continuation in
            APIQueueManager.shared.enqueueAPICall { token, userId, completion in
                let request = veygoCurlRequest(url: "/api/v1/apartment/get-all-apartments", method: "GET", headers: ["auth": "\(token)$\(userId)"])
                Task {
                    do {
                        let (data, response) = try await URLSession.shared.data(for: request)
                        guard let httpResponse = response as? HTTPURLResponse else {
                            await MainActor.run {
                                deleteData = true
                                alertMessage = "Parsing HTTPURLResponse Error"
                                showAlert = true
                            }
                            completion(nil)
                            continuation.resume()
                            return
                        }
                        guard httpResponse.value(forHTTPHeaderField: "Content-Type") == "application/json" else {
                            await MainActor.run {
                                deleteData = true
                                alertMessage = "Wrong Content Type: \(httpResponse.value(forHTTPHeaderField: "Content-Type") ?? "N/A")"
                                showAlert = true
                            }
                            completion(nil)
                            continuation.resume()
                            return
                        }
                        switch httpResponse.statusCode {
                        case 200:
                            let newToken = extractToken(from: response) ?? ""
                            let responseJSON = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                            if let apartmentsData = responseJSON?["apartments"],
                               let apartmentsJSONArray = try? JSONSerialization.data(withJSONObject: apartmentsData),
                               let decodedApartments = try? VeygoJsonStandard.shared.decoder.decode([Apartment].self, from: apartmentsJSONArray) {
                                await MainActor.run {
                                    deleteData = false
                                    self.apartments = decodedApartments
                                }
                            }
                            completion(newToken)
                            continuation.resume()
                        case 401:
                            await MainActor.run {
                                deleteData = true
                                alertMessage = "Session expired. Please log in again."
                                showAlert = true
                            }
                            completion(nil)
                            continuation.resume()
                        default:
                            await MainActor.run {
                                deleteData = true
                                showAlert = true
                                alertMessage = "Wrong Status Code: \(httpResponse.statusCode)"
                            }
                            completion(nil)
                            continuation.resume()
                        }
                    } catch {
                        await MainActor.run {
                            deleteData = true
                            showAlert = true
                            alertMessage = "Something went wrong: \(error.localizedDescription)"
                        }
                        completion(nil)
                        continuation.resume()
                    }
                }
            }
        }
    }
    
    func refreshTaxes() async {
        await withCheckedContinuation { continuation in
            APIQueueManager.shared.enqueueAPICall { token, userId, completion in
                let request = veygoCurlRequest(url: "/api/v1/apartment/get-taxes", method: "GET", headers: ["auth": "\(token)$\(userId)"])
                Task {
                    do {
                        let (data, response) = try await URLSession.shared.data(for: request)
                        guard let httpResponse = response as? HTTPURLResponse else {
                            await MainActor.run {
                                deleteData = true
                                alertMessage = "Parsing HTTPURLResponse Error"
                                showAlert = true
                            }
                            completion(nil)
                            continuation.resume()
                            return
                        }
                        guard httpResponse.value(forHTTPHeaderField: "Content-Type") == "application/json" else {
                            await MainActor.run {
                                deleteData = true
                                alertMessage = "Wrong Content Type: \(httpResponse.value(forHTTPHeaderField: "Content-Type") ?? "N/A")"
                                showAlert = true
                            }
                            completion(nil)
                            continuation.resume()
                            return
                        }
                        switch httpResponse.statusCode {
                        case 200:
                            let newToken = extractToken(from: response) ?? ""
                            let responseJSON = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                            if let taxesData = responseJSON?["taxes"],
                               let taxesJSONArray = try? JSONSerialization.data(withJSONObject: taxesData),
                               let decodedTaxes = try? VeygoJsonStandard.shared.decoder.decode([Tax].self, from: taxesJSONArray) {
                                await MainActor.run {
                                    deleteData = false
                                    self.taxes = decodedTaxes
                                }
                            }
                            completion(newToken)
                            continuation.resume()
                        case 401:
                            await MainActor.run {
                                deleteData = true
                                alertMessage = "Session expired. Please log in again."
                                showAlert = true
                            }
                            completion(nil)
                            continuation.resume()
                        default:
                            await MainActor.run {
                                deleteData = true
                                showAlert = true
                                alertMessage = "Wrong Status Code: \(httpResponse.statusCode)"
                            }
                            completion(nil)
                            continuation.resume()
                        }
                    } catch {
                        await MainActor.run {
                            deleteData = true
                            showAlert = true
                            alertMessage = "Something went wrong: \(error.localizedDescription)"
                        }
                        completion(nil)
                        continuation.resume()
                    }
                }
            }
        }
    }
    
    func addApartment() async {
        let payload = ApartmentNew(
            name: newAptName,
            email: newAptEmail,
            phone: newAptPhone,
            address: newAptAddress,
            acceptedSchoolEmailDomain: acceptedSchoolEmailDomain,
            freeTierHours: freeTierHoursDouble,
            freeTierRate: 0.00,
            silverTierHours: silverTierHoursDouble,
            silverTierRate: silverTierRateDouble,
            goldTierHours: goldTierHoursDouble,
            goldTierRate: goldTierRateDouble,
            platinumTierHours: platinumTierHoursDouble,
            platinumTierRate: platinumTierRateDouble,
            durationRate: durationRateDouble,
            liabilityProtectionRate: liabilityProtectionRateDouble,
            pcdwProtectionRate: pcdwProtectionRateDouble,
            pcdwExtProtectionRate: pcdwExtProtectionRateDouble,
            rsaProtectionRate: rsaProtectionRateDouble,
            paiProtectionRate: paiProtectionRateDouble,
            isOperating: isOperating,
            isPublic: isPublic,
            uniId: uniId ?? 1,
            taxes: aptTaxes
        )
        do {
            let jsonData = try VeygoJsonStandard.shared.encoder.encode(payload)
            await withCheckedContinuation { continuation in
                APIQueueManager.shared.enqueueAPICall { token, userId, completion in
                    let request = veygoCurlRequest(url: "/api/v1/apartment/add-apartment", method: "POST", headers: ["auth": "\(token)$\(userId)"], body: jsonData)
                    Task {
                        do {
                            let (_, response) = try await URLSession.shared.data(for: request)
                            guard let httpResponse: HTTPURLResponse = response as? HTTPURLResponse else {
                                await MainActor.run {
                                    deleteData = true
                                    alertMessage = "Parsing HTTPURLResponse Error"
                                    showAlert = true
                                }
                                completion(nil)
                                continuation.resume()
                                return
                            }
                            guard httpResponse.value(forHTTPHeaderField: "Content-Type") == "application/json" else {
                                await MainActor.run {
                                    deleteData = true
                                    alertMessage = "Wrong Content Type: \(httpResponse.value(forHTTPHeaderField: "Content-Type") ?? "N/A")"
                                    showAlert = true
                                }
                                completion(nil)
                                continuation.resume()
                                return
                            }
                            switch httpResponse.statusCode {
                            case 406:
                                let newToken = extractToken(from: response) ?? ""
                                await MainActor.run {
                                    deleteData = false
                                    alertMessage = "Apartment exists"
                                    showAlert = true
                                }
                                completion(newToken)
                                continuation.resume()
                            case 201:
                                let newToken = extractToken(from: response) ?? ""
                                await MainActor.run {
                                    deleteData = false
                                    newAptName = ""
                                    newAptEmail = ""
                                    newAptPhone = ""
                                    newAptAddress = ""
                                    acceptedSchoolEmailDomain = ""
                                    freeTierHours = ""
                                    silverTierHours = ""
                                    silverTierRate = ""
                                    goldTierHours = ""
                                    goldTierRate = ""
                                    platinumTierHours = ""
                                    platinumTierRate = ""
                                    durationRate = ""
                                    liabilityProtectionRate = ""
                                    pcdwProtectionRate = ""
                                    pcdwExtProtectionRate = ""
                                    rsaProtectionRate = ""
                                    paiProtectionRate = ""
                                    isOperating = true
                                    isPublic = true
                                    aptTaxes = []
                                    aptTaxSearch = ""
                                    showAlert = true
                                    alertMessage = "Apartment added successfully"
                                }
                                await refreshApartments()
                                completion(newToken)
                                continuation.resume()
                            case 401:
                                await MainActor.run {
                                    deleteData = true
                                    alertMessage = "Session expired. Please log in again."
                                    showAlert = true
                                }
                                completion(nil)
                                continuation.resume()
                            default:
                                await MainActor.run {
                                    deleteData = true
                                    alertMessage = "Wrong Status Code: \(httpResponse.statusCode)"
                                    showAlert = true
                                }
                                completion(nil)
                                continuation.resume()
                            }
                        } catch {
                            await MainActor.run {
                                deleteData = true
                                alertMessage = "Something went wrong: \(error.localizedDescription)"
                                showAlert = true
                            }
                            completion(nil)
                            continuation.resume()
                        }
                    }
                }
            }
        } catch {
            await MainActor.run {
                deleteData = true
                alertMessage = "Something went wrong: \(error.localizedDescription)"
                showAlert = true
            }
            return
        }
    }
    
}

