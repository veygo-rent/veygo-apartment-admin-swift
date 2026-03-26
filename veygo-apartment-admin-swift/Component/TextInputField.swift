//
//  TextInputField.swift
//  veygo-apartment-swift
//
//  Created by 魔法玛丽大炮 on 5/19/25.
//
import SwiftUI

struct TextInputField: View {
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var textFont: Font = .body
    
    var body: some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: $text)
                    .font(textFont)
                    .kerning(2)
                    .padding(.vertical, 10)
                    .foregroundColor(Color("TextFieldWordColor"))
                    .padding(.leading, 16)
                    .background(Color("TextFieldBg"))
                    .cornerRadius(14)
            } else {
                TextField(placeholder, text: $text)
                    .font(textFont)
                    .kerning(1.5)
                    .padding(.vertical, 10)
                    .foregroundColor(Color("TextFieldWordColor"))
                    .padding(.leading, 16)
                    .background(Color("TextFieldBg"))
                    .cornerRadius(14)
            }
        }
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 16))
    }
}
