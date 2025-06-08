//
//  LegalText.swift
//  veygo-apartment-admin-swift
//
//  Created by Shenghong Zhou on 6/7/25.
//

import SwiftUI

struct LegalText: View {
    var fullText: String = "By continuing, you acknowledge and agree to Veygo’s legal terms, which we recommend reviewing"
    var highlightedText: String = "legal terms"

    var body: some View {
        Text(makeAttributedString())
            .font(.system(size: 11, weight: .regular, design: .default))
            .foregroundColor(Color("FootNote"))
    }

    private func makeAttributedString() -> AttributedString {
        var fullString = AttributedString(fullText)

        if let range = fullString.range(of: highlightedText) {
            fullString[range].foregroundColor = Color("TextLink")
            fullString[range].underlineStyle = .single
        }

        return fullString
    }
}

#Preview {
    LegalText()
}
