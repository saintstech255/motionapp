//
//  ActivityRecord.swift
//  Motion
//
//  SwiftData model for a saved activity.
//

import Foundation
import SwiftData
import CoreLocation

@Model
final class ActivityRecord {
    var id: UUID
    var typeRaw: String
    var title: String
    var startDate: Date
    /// Moving time in seconds.
    var duration: TimeInterval
    /// Total distance in meters.
    var distance: Double
    /// Maximum speed in m/s.
    var maxSpeed: Double
    /// Total ascent in meters.
    var elevationGain: Double
    var calories: Double
    /// JSON-encoded `[TrackPoint]`.
    @Attribute(.externalStorage) var routeData: Data?

    init(id: UUID = UUID(),
         type: ActivityType,
         title: String,
         startDate: Date,
         duration: TimeInterval,
         distance: Double,
         maxSpeed: Double,
         elevationGain: Double,
         calories: Double,
         track: [TrackPoint]) {
        self.id = id
        self.typeRaw = type.rawValue
        self.title = title
        self.startDate = startDate
        self.duration = duration
        self.distance = distance
        self.maxSpeed = maxSpeed
        self.elevationGain = elevationGain
        self.calories = calories
        self.routeData = try? JSONEncoder().encode(track)
    }

    var type: ActivityType {
        ActivityType(rawValue: typeRaw) ?? .running
    }

    /// Decoded GPS samples (empty for indoor activities).
    var track: [TrackPoint] {
        guard let routeData else { return [] }
        return (try? JSONDecoder().decode([TrackPoint].self, from: routeData)) ?? []
    }

    var averageSpeed: Double {
        duration > 0 ? distance / duration : 0
    }

    /// A down-sampled route that is cheap to draw in list rows.
    var thumbnailCoordinates: [CLLocationCoordinate2D] {
        let points = track
        guard points.count > 1 else { return [] }
        let step = Swift.max(1, points.count / 120)
        var result = stride(from: 0, to: points.count, by: step).map { points[$0].coordinate }
        if let last = points.last { result.append(last.coordinate) }
        return result
    }
}
