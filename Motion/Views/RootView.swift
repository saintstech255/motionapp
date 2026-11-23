//
//  RootView.swift
//  Motion
//

import SwiftUI

/// Switches between the auth flow and the main app based on session state.
struct RootView: View {
    @EnvironmentObject private var auth: AuthService

    var body: some View {
        Group {
            if auth.isAuthenticated {
                MainTabView()
                    .transition(.opacity)
            } else {
                AuthView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: auth.isAuthenticated)
    }
}
