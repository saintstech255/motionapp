//
//  RecordingViewModel.swift
//  Motion
//
//  Drives live activity recording: timer, distance, pace/speed, elevation
//  and route building from CoreLocation fixes. Supports pause / resume.
//

import Foundation
import CoreLocation
import Combine
import UIKit

/// A finished workout waiting for the user to save or discard it.
struct WorkoutDraft: Identifiable {
    let id = UUID()
    let type: ActivityType
    let startDate: Date
    let duration: TimeInterval
    let distance: Double
    let maxSpeed: Double
    let elevationGain: Double
    let calories: Double
    let track: [TrackPoint]
}

final class RecordingViewModel: ObservableObject {
    enum State { case idle, recording, paused }

    static let poolLength: Double = 25   // meters per lap

    // MARK: Published state
    @Published var state: State = .idle
    @Published var selectedType: ActivityType = .running
    @Published private(set) var elapsed: TimeInterval = 0
    @Published private(set) var distance: Double = 0
    @Published private(set) var currentSpeed: Double = 0
    @Published private(set) var maxSpeed: Double = 0
    @Published private(set) var elevationGain: Double = 0
    @Published private(set) var route: [CLLocationCoordinate2D] = []
    @Published var draft: WorkoutDraft?

    let location: LocationService

    // MARK: Private
    private var points: [TrackPoint] = []
    private var cancellables = Set<AnyCancellable>()
    private var timer: AnyCancellable?
    private var accumulated: TimeInterval = 0
    private var segmentStart: Date?
    private var startDate: Date?
    private var lastLocation: CLLocation?
    private var smoothedAltitude: Double?
    private var referenceAltitude: Double?
    private var lastLapDate: Date?

    init(location: LocationService = LocationService()) {
        self.location = location
        location.locationPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loc in self?.handle(loc) }
            .store(in: &cancellables)
    }

    // MARK: Derived

    var averageSpeed: Double { elapsed > 0 ? distance / elapsed : 0 }
    var lapCount: Int { Int((distance / Self.poolLength).rounded()) }
    var liveCalories: Double { Self.calories(type: selectedType, duration: elapsed) }

    static func calories(type: ActivityType, duration: TimeInterval, weightKg: Double = 70) -> Double {
        type.met * weightKg * (duration / 3600)
    }

    // MARK: Controls

    func start() {
        guard state == .idle else { return }
        resetMetrics()
        startDate = Date()
        segmentStart = Date()
        lastLapDate = Date()
        state = .recording
        startTimer()
        if selectedType.usesGPS { location.startTracking(for: selectedType) }
        UIApplication.shared.isIdleTimerDisabled = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    func pause() {
        guard state == .recording else { return }
        accumulated = currentElapsed()
        segmentStart = nil
        elapsed = accumulated
        state = .paused
        timer?.cancel()
        lastLocation = nil          // don't count the gap while paused
        currentSpeed = 0
        location.stopTracking()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func resume() {
        guard state == .paused else { return }
        segmentStart = Date()
        lastLapDate = Date()
        state = .recording
        startTimer()
        if selectedType.usesGPS { location.startTracking(for: selectedType) }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    /// Ends the session and publishes a `draft` for the save sheet.
    func finish() {
        guard state != .idle else { return }
        let total = currentElapsed()
        timer?.cancel()
        location.stopTracking()
        UIApplication.shared.isIdleTimerDisabled = false

        draft = WorkoutDraft(
            type: selectedType,
            startDate: startDate ?? Date(),
            duration: total,
            distance: distance,
            maxSpeed: maxSpeed,
            elevationGain: elevationGain,
            calories: Self.calories(type: selectedType, duration: total),
            track: points
        )
        resetMetrics()
        state = .idle
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    /// Swimming: register one pool length.
    func addLap() {
        guard state == .recording, selectedType == .swimming else { return }
        distance += Self.poolLength
        let now = Date()
        if let last = lastLapDate {
            let dt = now.timeIntervalSince(last)
            if dt > 0 {
                currentSpeed = Self.poolLength / dt
                maxSpeed = max(maxSpeed, currentSpeed)
            }
        }
        lastLapDate = now
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
    }

    func makeRecord(from draft: WorkoutDraft, title: String) -> ActivityRecord {
        let cleaned = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return ActivityRecord(
            type: draft.type,
            title: cleaned.isEmpty ? draft.type.defaultTitle(for: draft.startDate) : cleaned,
            startDate: draft.startDate,
            duration: draft.duration,
            distance: draft.distance,
            maxSpeed: draft.maxSpeed,
            elevationGain: draft.elevationGain,
            calories: draft.calories,
            track: draft.track
        )
    }

    // MARK: Timer

    private func currentElapsed() -> TimeInterval {
        accumulated + (segmentStart.map { Date().timeIntervalSince($0) } ?? 0)
    }

    private func startTimer() {
        timer?.cancel()
        timer = Timer.publish(every: 0.5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.elapsed = self.currentElapsed()
            }
    }

    private func resetMetrics() {
        timer?.cancel()
        accumulated = 0
        segmentStart = nil
        startDate = nil
        elapsed = 0
        distance = 0
        currentSpeed = 0
        maxSpeed = 0
        elevationGain = 0
        route = []
        points = []
        lastLocation = nil
        smoothedAltitude = nil
        referenceAltitude = nil
    }

    // MARK: Location handling

    private func handle(_ loc: CLLocation) {
        guard state == .recording, selectedType.usesGPS else { return }
        guard abs(loc.timestamp.timeIntervalSinceNow) < 15 else { return }   // stale fix

        if let last = lastLocation {
            let d = loc.distance(from: last)
            let dt = loc.timestamp.timeIntervalSince(last.timestamp)
            guard dt > 0 else { return }

            let implied = d / dt
            let limit: Double = selectedType == .driving ? 70 : 25           // m/s sanity cap
            guard implied <= limit else { return }                            // GPS jump

            let raw = loc.speed >= 0 ? loc.speed : implied
            if d < 2 && raw < 0.3 {                                           // standing still
                currentSpeed = 0
                return
            }
            distance += d
            currentSpeed = currentSpeed == 0 ? raw : currentSpeed * 0.6 + raw * 0.4
            maxSpeed = max(maxSpeed, currentSpeed)
        }
        lastLocation = loc
        updateElevation(with: loc)

        route.append(loc.coordinate)
        points.append(TrackPoint(
            latitude: loc.coordinate.latitude,
            longitude: loc.coordinate.longitude,
            altitude: loc.altitude,
            speed: currentSpeed,
            distance: distance,
            elapsed: currentElapsed()
        ))
    }

    /// Smoothed ascent calculation with a 1 m hysteresis to ignore GPS noise.
    private func updateElevation(with loc: CLLocation) {
        guard loc.verticalAccuracy >= 0, loc.verticalAccuracy <= 20 else { return }
        let smoothed = (smoothedAltitude ?? loc.altitude) * 0.7 + loc.altitude * 0.3
        smoothedAltitude = smoothed
        guard let ref = referenceAltitude else {
            referenceAltitude = smoothed
            return
        }
        let delta = smoothed - ref
        if abs(delta) >= 1 {
            if delta > 0 { elevationGain += delta }
            referenceAltitude = smoothed
        }
    }
}
