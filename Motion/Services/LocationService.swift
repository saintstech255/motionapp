//
//  LocationService.swift
//  Motion
//
//  Thin CoreLocation wrapper: "While Using" authorization, accuracy
//  management per activity type, and a Combine publisher of filtered fixes.
//

import CoreLocation
import Combine

final class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published private(set) var authorizationStatus: CLAuthorizationStatus
    @Published private(set) var lastLocation: CLLocation?

    /// Emits every accepted location fix while tracking.
    let locationPublisher = PassthroughSubject<CLLocation, Never>()

    private let manager: CLLocationManager
    private(set) var isTracking = false

    var isAuthorized: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }
    var isDenied: Bool {
        authorizationStatus == .denied || authorizationStatus == .restricted
    }
    var needsPermissionPrompt: Bool { authorizationStatus == .notDetermined }

    override init() {
        let m = CLLocationManager()
        manager = m
        authorizationStatus = m.authorizationStatus
        super.init()
        m.delegate = self
        m.pausesLocationUpdatesAutomatically = false
    }

    /// Requests "While Using the App" authorization.
    func requestAuthorization() {
        manager.requestWhenInUseAuthorization()
    }

    /// Starts standard high-accuracy updates tuned for the activity.
    func startTracking(for type: ActivityType) {
        guard isAuthorized, !isTracking else { return }
        manager.activityType = type.clActivityType
        switch type {
        case .driving:
            manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
            manager.distanceFilter = 10
        default:
            manager.desiredAccuracy = kCLLocationAccuracyBest
            manager.distanceFilter = 5
        }
        // Requires the "location" UIBackgroundModes entry in Info.plist.
        manager.allowsBackgroundLocationUpdates = true
        manager.showsBackgroundLocationIndicator = true
        manager.startUpdatingLocation()
        isTracking = true
    }

    func stopTracking() {
        guard isTracking else { return }
        manager.stopUpdatingLocation()
        manager.allowsBackgroundLocationUpdates = false
        manager.showsBackgroundLocationIndicator = false
        isTracking = false
    }

    // MARK: CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        for location in locations where location.horizontalAccuracy >= 0 && location.horizontalAccuracy <= 50 {
            lastLocation = location
            locationPublisher.send(location)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("LocationService error: \(error.localizedDescription)")
    }
}
