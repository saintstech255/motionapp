//
//  Coordinates.swift
//  Motion
//
//  Helpers for working with arrays of coordinates and map regions.
//

import MapKit

extension Array where Element == CLLocationCoordinate2D {
    /// A region that comfortably fits every coordinate (with padding).
    var boundingRegion: MKCoordinateRegion? {
        guard let first = self.first else { return nil }
        var minLat = first.latitude, maxLat = first.latitude
        var minLon = first.longitude, maxLon = first.longitude
        for c in self {
            minLat = Swift.min(minLat, c.latitude)
            maxLat = Swift.max(maxLat, c.latitude)
            minLon = Swift.min(minLon, c.longitude)
            maxLon = Swift.max(maxLon, c.longitude)
        }
        let center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2,
                                            longitude: (minLon + maxLon) / 2)
        let span = MKCoordinateSpan(latitudeDelta: Swift.max((maxLat - minLat) * 1.5, 0.004),
                                    longitudeDelta: Swift.max((maxLon - minLon) * 1.5, 0.004))
        return MKCoordinateRegion(center: center, span: span)
    }
}
