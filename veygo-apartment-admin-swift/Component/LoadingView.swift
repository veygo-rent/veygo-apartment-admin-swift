//
//  LoadingView.swift
//  veygo-apartment-admin-swift
//
//  Created by Shenghong Zhou on 3/26/26.
//

import SwiftUI

struct LoadingView: View {
    @State private var startPoint: UnitPoint = .init(x: -1.8, y: -1.2)
    @State private var endPoint: UnitPoint = .init(x: 0, y: -0.2)
    
    private var gradientColor = [
        Color.init(uiColor: .systemGray5),
        Color.init(uiColor: .systemGray6),
        Color.init(uiColor: .systemGray5),
    ]
    
    var body: some View {
        GeometryReader { geometry in
            LinearGradient(colors: gradientColor, startPoint: startPoint, endPoint: endPoint)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
                .onAppear {
                    withAnimation(.easeOut(duration: 1.0).repeatForever(autoreverses: false)) {
                        startPoint = .init(x: 1, y: 1)
                        endPoint = .init(x: 2.2, y: 2.2)
                    }
                }
        }
        .clipped()
        .allowsHitTesting(false)
    }
}
