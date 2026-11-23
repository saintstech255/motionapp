//
//  Formatting.swift
//  Motion
//
//  Unit-aware formatting helpers (metric / imperial) for distance, pace,
//  speed, elevation and durations.
//

import Foundation

enum Fmt {
    static let metersPerMile = 1609.344

    // MARK: Time

    /// "12:34" or "1:02:03"
    static func clock(_ interval: TimeInterval) -> String {
        let total = max(0, Int(interval.rounded()))
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        return h > 0
            ? String(format: "%d:%02d:%02d", h, m, s)
            : String(format: "%02d:%02d", m, s)
    }

    /// "1h 05m", "12m 30s", "45s"
    static func durationWords(_ interval: TimeInterval) -> String {
        let total = max(0, Int(interval.rounded()))
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 { return String(format: "%dh %02dm", h, m) }
        if m > 0 { return String(format: "%dm %02ds", m, s) }
        return "\(s)s"
    }

    // MARK: Distance

    /// Distance for a specific activity. Swimming uses meters / yards.
    static func distance(_ meters: Double, type: ActivityType, imperial: Bool) -> (value: String, unit: String) {
        if type == .swimming {
            return imperial
                ? (String(format: "%.0f", meters * 1.09361), "yd")
                : (String(format: "%.0f", meters), "m")
        }
        if type == .gym { return ("--", "") }
        let v = imperial ? meters / metersPerMile : meters / 1000
        return (String(format: "%.2f", v), imperial ? "mi" : "km")
    }

    static func distanceText(_ meters: Double, type: ActivityType, imperial: Bool) -> String {
        let d = distance(meters, type: type, imperial: imperial)
        return d.unit.isEmpty ? d.value : "\(d.value) \(d.unit)"
    }

    /// Long-range distance (always km / mi) used for totals and goals.
    static func longDistance(_ meters: Double, imperial: Bool) -> (value: String, unit: String) {
        let v = imperial ? meters / metersPerMile : meters / 1000
        return (String(format: v >= 100 ? "%.0f" : "%.1f", v), imperial ? "mi" : "km")
    }

    static func longDistanceValue(_ meters: Double, imperial: Bool) -> Double {
        imperial ? meters / metersPerMile : meters / 1000
    }

    // MARK: Speed & pace

    static func speedValue(_ metersPerSecond: Double, imperial: Bool) -> Double {
        imperial ? metersPerSecond * 2.23694 : metersPerSecond * 3.6
    }

    static func speed(_ metersPerSecond: Double, imperial: Bool) -> String {
        String(format: "%.1f", speedValue(metersPerSecond, imperial: imperial))
    }

    static func speedUnit(imperial: Bool) -> String { imperial ? "mph" : "km/h" }

    static func pace(speed: Double, type: ActivityType, imperial: Bool) -> String {
        guard speed > 0.2 else { return "--:--" }
        let secondsPerUnit: Double
        if type == .swimming {
            secondsPerUnit = 100 / speed                     // per 100 m
        } else {
            secondsPerUnit = (imperial ? metersPerMile : 1000) / speed
        }
        let s = Int(secondsPerUnit.rounded())
        guard s < 100 * 60 else { return "--:--" }
        return String(format: "%d:%02d", s / 60, s % 60)
    }

    static func paceUnit(type: ActivityType, imperial: Bool) -> String {
        if type == .swimming { return "/100m" }
        return imperial ? "/mi" : "/km"
    }

    /// Pace for running-like activities, speed for cycling / driving.
    static func primaryRate(speed: Double, type: ActivityType, imperial: Bool) -> (label: String, value: String, unit: String) {
        if type.prefersSpeed {
            return ("Speed", Fmt.speed(speed, imperial: imperial), speedUnit(imperial: imperial))
        }
        return ("Pace", pace(speed: speed, type: type, imperial: imperial), paceUnit(type: type, imperial: imperial))
    }

    // MARK: Elevation

    static func elevationValue(_ meters: Double, imperial: Bool) -> Double {
        imperial ? meters * 3.28084 : meters
    }

    static func elevation(_ meters: Double, imperial: Bool) -> String {
        String(format: "%.0f", elevationValue(meters, imperial: imperial))
    }

    static func elevationUnit(imperial: Bool) -> String { imperial ? "ft" : "m" }
}
