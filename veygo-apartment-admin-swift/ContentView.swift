//
//  ContentView.swift
//  veygo-apartment-admin-swift
//
//  Created by Shenghong Zhou on 6/7/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var session: AdminSession
    @AppStorage("token") var token: String = ""
    @AppStorage("user_id") var userId: Int = 0

    var body: some View {
        ZStack {
            if session.user == nil {
                LoginView()
                    .transition(.move(edge: .leading))
            } else {
                AppView()
                    .transition(.move(edge: .trailing))
            }
        }
        .animation(.bouncy, value: session.user)
        .onChange(of: session.user) { old, new in
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}


#Preview {
    ContentView()
}
