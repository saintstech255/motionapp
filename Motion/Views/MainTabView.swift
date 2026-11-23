//
//  MainTabView.swift
//  Motion
//

import SwiftUI
import UIKit

struct MainTabView: View {
    enum Tab { case feed, record, profile }

    @State private var selection: Tab = .feed
    /// Lives here so an in-progress recording survives tab switches.
    @StateObject private var recorder = RecordingViewModel()

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 0.07, green: 0.07, blue: 0.08, alpha: 1)
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView(selection: $selection) {
            FeedView()
                .tabItem { Label("Feed", systemImage: "list.bullet.rectangle.portrait.fill") }
                .tag(Tab.feed)

            RecordView(recorder: recorder, location: recorder.location)
                .tabItem { Label("Record", systemImage: "record.circle.fill") }
                .tag(Tab.record)

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.crop.circle.fill") }
                .tag(Tab.profile)
        }
    }
}
