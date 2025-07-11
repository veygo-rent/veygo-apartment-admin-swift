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
    @State private var searchText: String = ""
    
    @State private var seletedApartment: Apartment.ID? = nil
    
    @State private var showAddApartmentView: Bool = false
    
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
                        refreshApartments()
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
            refreshApartments()
        }
        .scrollContentBackground(.hidden)
        .background(Color("MainBG"), ignoresSafeAreaEdges: .all)
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .sheet(isPresented: $showAddApartmentView) {
            NavigationStack {
                VStack (spacing: 28) {
                    Text("Hello World")
                }
                .frame(minWidth: 200, maxWidth: 320)
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
                            refreshApartments()
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
    
    func refreshApartments() {
        let request = veygoCurlRequest(url: "/api/v1/apartment/get-all-apartments", method: "GET", headers: ["auth": "\(token)$\(userId)"])
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
                if let apartmentsData = responseJSON?["apartments"],
                   let apartmentsJSONArray = try? JSONSerialization.data(withJSONObject: apartmentsData),
                   let decodedApartments = try? VeygoJsonStandard.shared.decoder.decode([Apartment].self, from: apartmentsJSONArray) {
                    apartments = decodedApartments
                }
            } else if httpResponse.statusCode == 401 {
                DispatchQueue.main.async {
                    alertMessage = "Reverify login status failed"
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
