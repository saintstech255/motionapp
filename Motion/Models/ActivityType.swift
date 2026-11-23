//
//  ActivityType.swift
//  Motion
//
//  Supported activity types and their presentation / physiology metadata.
//

import SwiftUI
import CoreLocation

enum ActivityType: String, CaseIterable, Identifiable, Codable {
    case running, cycling, walking, hiking, driving, swimming, gym

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .running: "Running"
        case .cycling: "Cycling"
        case .walking: "Walking"
        case .hiking: "Hiking"
        case .driving: "Driving"
        case .swimming: "Swimming"
        case .gym: "Gym Workout"
        }
    }

    /// SF Symbol name.
    var symbol: String {
        switch self {
        case .running: "figure.run"
        case .cycling: "bicycle"
        case .walking: "figure.walk"
        case .hiking: "figure.hiking"
        case .driving: "car.fill"
        case .swimming: "figure.pool.swim"
        case .gym: "dumbbell.fill"
        }
    }

    var color: Color {
        switch self {
        case .running: Color(hex: 0xFF5A1F)
        case .cycling: Color(hex: 0x2D7BFF)
        case .walking: Color(hex: 0x34C759)
        case .hiking: Color(hex: 0xC8A24A)
        case .driving: Color(hex: 0xA06BFF)
        case .swimming: Color(hex: 0x30D5F2)
        case .gym: Color(hex: 0xFF4F8B)
        }
    }

    /// Whether the activity is tracked with GPS. Swimming (pool) and gym are indoor.
    var usesGPS: Bool {
        switch self {
        case .swimming, .gym: false
        default: true
        }
    }

    /// Cycling and driving are shown as speed (km/h); everything else as pace.
    var prefersSpeed: Bool { self == .cycling || self == .driving }

    /// Activity hint so iOS can optimise location sampling.
    var clActivityType: CLActivityType {
        switch self {
        case .driving: .automotiveNavigation
        case .cycling: .otherNavigation
        default: .fitness
        }
    }

    /// Metabolic equivalent (MET) used for the calorie estimate.
    var met: Double {
        switch self {
        case .running: 9.8
        case .cycling: 7.5
        case .walking: 3.8
        case .hiking: 6.0
        case .driving: 1.3
        case .swimming: 6.0
        case .gym: 5.0
        }
    }

    private var noun: String {
        switch self {
        case .running: "Run"
        case .cycling: "Ride"
        case .walking: "Walk"
        case .hiking: "Hike"
        case .driving: "Drive"
        case .swimming: "Swim"
        case .gym: "Workout"
        }
    }

    /// e.g. "Morning Run"
    func defaultTitle(for date: Date = Date()) -> String {
        let hour = Calendar.current.component(.hour, from: date)
        let part: String
        switch hour {
        case 5..<12: part = "Morning"
        case 12..<17: part = "Afternoon"
        case 17..<21: part = "Evening"
        default: part = "Night"
        }
        return "\(part) \(noun)"
    }
}
