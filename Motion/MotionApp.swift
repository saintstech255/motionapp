//
//  MotionApp.swift
//  Motion
//
//  App entry point. Developed by Kas-Kazini Inc.
//

import SwiftUI
import SwiftData

@main
struct MotionApp: App {
    @StateObject private var auth = AuthService()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(auth)
                .preferredColorScheme(.dark)
                .tint(Theme.brand)
        }
        .modelContainer(for: ActivityRecord.self)
    }
}
