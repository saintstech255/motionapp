//
//  TrackPoint.swift
//  Motion
//
//  A single recorded GPS sample. Stored (JSON-encoded) inside ActivityRecord.
//

import Foundation
import CoreLocation

struct TrackPoint: Codable, Hashable {
    let latitude: Double
    let longitude: Double
    /// Altitude in meters.
    let altitude: Double
    /// Instantaneous speed in m/s.
    let speed: Double
    /// Cumulative distance in meters at this sample.
    let distance: Double
    /// Moving time in seconds at this sample (paused time excluded).
    let elapsed: TimeInterval

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
