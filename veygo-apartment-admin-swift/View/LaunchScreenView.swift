//
//  LaunchScreenView.swift
//  veygo-apartment-admin-swift
//
//  Created by Shenghong Zhou on 6/7/25.
//

import SwiftUI

struct LaunchScreenView<Destination: View>: View {
    @State private var isActive = false
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 1.0
    @Binding var didLoad: Bool
    
    let destination: () -> Destination
    
    var body: some View {
        VStack {
            Spacer()
            Image("VeygoLogo")  // logo name
                .resizable()
                .scaledToFit()
                .frame(width: 250, height: 250)
                .offset(y: -50)  // 上移50个单位
            Text("Veygo Apartment Admin")
                .font(.system(size: 36, weight: .semibold, design: .default))
                .foregroundColor(Color("TextBlackSecondary"))
                
            Spacer()
        }
        .scaleEffect(scale)  // 缩放效果
        .opacity(opacity)    // 透明度效果
        .animation(.easeInOut(duration: 2), value: scale)  // 动画效果
        .animation(.easeInOut(duration: 2), value: opacity)
        .frame(maxWidth: .infinity)
        .background(Color("MainBG"))
        .onChange(of: didLoad) {
            withAnimation(.easeInOut(duration: 2)) {
                scale = 1.2
                opacity = 0.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    isActive = true
                }
            }
        }
        .fullScreenCover(isPresented: $isActive) {
            destination()  // 进入登录页
                .interactiveDismissDisabled(true)
        }
    }
}

#Preview {
    LaunchScreenView(didLoad: .constant(true)){
        ContentView()
    }
}
