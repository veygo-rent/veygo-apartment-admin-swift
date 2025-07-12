//
//  ListInputField.swift
//  veygo-apartment-admin-swift
//
//  Created by Shenghong Zhou on 7/12/25.
//

import SwiftUI

struct ListInputField<Element: Identifiable & HasName>: View where Element.ID == Int {
    
    @Binding var searchText: String
    @Binding var listOfOptions: [Element]
    @Binding var selectedOptions: [Int?]
    
    let placeholder: String
    
    private var searchResults: [Element] {
        listOfOptions.filter { option in
            option.name.lowercased().contains(searchText.lowercased()) &&
            !selectedOptions.compactMap { $0 }.contains(option.id)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            TextInputField(placeholder: placeholder, text: $searchText)
            if !searchText.isEmpty {
                ForEach(searchResults) { option in
                    HStack {
                        Text(option.name)
                            .foregroundColor(Color("TextBlackPrimary"))
                            .padding(.leading, 16)
                        Spacer()
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.green)
                            .padding(.trailing, 16)
                    }
                    .onTapGesture {
                        selectedOptions.append(option.id)
                    }
                }
            }
            // Show selected options below search results
            if !selectedOptions.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Selected:")
                        .font(.caption)
                        .foregroundColor(.gray)
                    ForEach(selectedOptions.compactMap { $0 }, id: \.self) { id in
                        if let matched = listOfOptions.first(where: { $0.id == id }) {
                            HStack {
                                Text(matched.name)
                                    .foregroundColor(Color("TextBlackPrimary"))
                                    .padding(.leading, 16)
                                Spacer()
                                Button {
                                    if let index = selectedOptions.firstIndex(where: { $0 == id }) {
                                        selectedOptions.remove(at: index)
                                    }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                        .padding(.trailing, 16)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
    }
}

