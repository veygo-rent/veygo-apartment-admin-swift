//
//  PrimaryButton.swift
//  veygo-apartment-admin-swift
//
//  Created by Shenghong Zhou on 6/7/25.
//

import SwiftUI

struct PrimaryButton: View {
    // 接收按钮文本和点击事件
    let text: String
    var action: () -> Void

    var body: some View {
        Button(action: {
            action()
        }) {
            Text(text)
                .font(.system(size: 17, weight: .semibold, design: .default)) // 使用 SF Pro 字体
                .foregroundColor(Color("PrimaryButtonText")) // 使用 Assets 中的颜色
                .frame(maxWidth: .infinity)
                .frame(height: 45)
                .background(Color("PrimaryButtonBg"))
                .cornerRadius(16)
                .shadow(color: Color("ShadowPrimary").opacity(0.7), radius: 3, x: 2, y: 4)
        }
    }
}

#Preview {
    PrimaryButton(text: "Login") {
        print("Log In Button Pressed")
    }
}
