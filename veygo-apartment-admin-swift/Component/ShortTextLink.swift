//
//  ShortTextLink.swift
//  veygo-apartment-admin-swift
//
//  Created by Shenghong Zhou on 6/7/25.
//

import SwiftUI

struct ShortTextLink: View {
    let text: String
    var action: () -> Void

    var body: some View {
        Button(action: {
            action()
        }) {
            Text(text)
                .font(.system(size: 14, weight: .regular, design: .default))
                .foregroundColor(Color("TextLink"))
                .underline()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    ShortTextLink(text: "Forgot Password?") {
        print("Forgot Password Pressed")
    }
}
