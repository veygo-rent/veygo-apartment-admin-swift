import SwiftUI

struct SecondaryButton: View {
    // 接收按钮文本和点击事件
    let text: String
    var action: () -> Void

    var body: some View {
        Button(action: {
            action()
        }) {
            Text(text)
                .font(.system(size: 17, weight: .semibold, design: .default))
                .foregroundColor(Color.secondaryButtonText)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(.glassProminent)
        .buttonBorderShape(.roundedRectangle(radius: 16))
        .tint(Color.secondaryButtonBg)
        .frame(height: 45)
    }
}

#Preview {
    SecondaryButton(text: "Create New Account") {
        print("Create Button Pressed")
    }
}



