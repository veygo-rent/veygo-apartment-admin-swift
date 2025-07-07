//
//  TextInputField.swift
//  veygo-apartment-admin-swift
//
//  Created by Shenghong Zhou on 6/7/25.
//

import SwiftUI

struct TextInputField: View {
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color("TextFieldBg"))
                .stroke(Color("TextFieldFrame"), lineWidth: 2) // 边框颜色
                .frame(height: 42)
            
            if isSecure {
                SecureField(placeholder, text: $text)
                    .frame(height: 42)
                    .foregroundColor(Color("TextFieldWordColor"))
                    .padding(.leading, 16)
                    .kerning(2)
            } else {
                TextField(placeholder, text: $text)
                    .frame(height: 42)
                    .foregroundColor(Color("TextFieldWordColor"))
                    .padding(.leading, 16)
                    .kerning(1.5)
            }
        }
    }
}

#Preview {
    TextInputField(placeholder: "Email", text: .constant(""))
}
