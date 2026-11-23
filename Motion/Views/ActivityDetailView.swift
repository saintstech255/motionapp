//
//  ActivityDetailView.swift
//  Motion
//
//  Full route map, key statistics, interactive charts and per-unit splits.
//

import SwiftUI
import SwiftData
import MapKit
import Charts

private struct ChartSample: Identifiable {
    let id: Int
    let x: Double            // distance in km / mi
    let elevation: Double    // m / ft
    let speed: Double        // km/h / mph
}

private struct Split: Identifiable {
    let id: Int
    let duration: TimeInterval
    let distance: Double     // meters covered by this split
}

struct ActivityDetailView: View {
    let activity: ActivityRecord

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @AppStorage("useImperial") private var useImperial = false

    private enum ChartMetric: String, CaseIterable, Identifiable {
        case elevation = "Elevation"
        case speed = "Speed"
        var id: String { rawValue }
    }

    @State private var metric: ChartMetric = .elevation
    @State private var selectedX: Double?
    @State private var showDeleteConfirm = false

    private var type: ActivityType { activity.type }

    var body: some View {
        let track = activity.track
        let samples = Self.makeSamples(from: track, imperial: useImperial)

        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if track.count > 1 {
                    routeMap(track)
                } else {
                    indoorBanner
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(activity.title).font(.title2.bold())
                    Label(activity.startDate.formatted(date: .complete, time: .shortened), systemImage: type.symbol)
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                }
                .padding(.horizontal, 16)

                statsGrid
                    .padding(.horizontal, 16)

                if samples.count > 3 {
                    chartSection(samples)
                        .padding(.horizontal, 16)
                    splitsSection(track)
                        .padding(.horizontal, 16)
                }
            }
            .padding(.bottom, 30)
        }
        .background(Theme.background)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    ShareLink(item: shareText) { Label("Share", systemImage: "square.and.arrow.up") }
                    Button(role: .destructive) { showDeleteConfirm = true } label: {
                        Label("Delete Activity", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .confirmationDialog("Delete this activity?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                modelContext.delete(activity)
                try? modelContext.save()
                dismiss()
            }
        } message: {
            Text("This can't be undone.")
        }
    }

    // MARK: Map

    private func routeMap(_ track: [TrackPoint]) -> some View {
        let coords = track.map(\.coordinate)
        let region = coords.boundingRegion ?? MKCoordinateRegion()
        return Map(initialPosition: .region(region), interactionModes: [.pan, .zoom]) {
            MapPolyline(coordinates: coords)
                .stroke(type.color, lineWidth: 5)
            if let first = coords.first {
                Marker("Start", systemImage: "flag.fill", coordinate: first).tint(.green)
            }
            if let last = coords.last {
                Marker("Finish", systemImage: "flag.checkered", coordinate: last).tint(.red)
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .frame(height: 300)
    }

    private var indoorBanner: some View {
        ZStack {
            LinearGradient(colors: [type.color.opacity(0.45), Theme.background],
                           startPoint: .top, endPoint: .bottom)
            Image(systemName: type.symbol)
                .font(.system(size: 80, weight: .semibold))
                .foregroundStyle(type.color)
        }
        .frame(height: 180)
    }

    // MARK: Stats

    private var statsGrid: some View {
        let dist = Fmt.distance(activity.distance, type: type, imperial: useImperial)
        let avg = Fmt.primaryRate(speed: activity.averageSpeed, type: type, imperial: useImperial)
        return LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            if type != .gym {
                StatTile(title: "Distance", value: dist.value, unit: dist.unit, symbol: "point.topleft.down.to.point.bottomright.curvepath")
            }
            StatTile(title: "Duration", value: Fmt.clock(activity.duration), symbol: "timer")
            if type != .gym {
                StatTile(title: "Avg \(avg.label)", value: avg.value, unit: avg.unit, symbol: "speedometer")
                StatTile(title: "Max Speed",
                         value: Fmt.speed(activity.maxSpeed, imperial: useImperial),
                         unit: Fmt.speedUnit(imperial: useImperial),
                         symbol: "bolt.fill")
            }
            if type.usesGPS {
                StatTile(title: "Elevation Gain",
                         value: Fmt.elevation(activity.elevationGain, imperial: useImperial),
                         unit: Fmt.elevationUnit(imperial: useImperial),
                         symbol: "mountain.2.fill")
            }
            StatTile(title: "Calories", value: String(format: "%.0f", activity.calories), unit: "kcal", symbol: "flame.fill")
        }
    }

    // MARK: Chart

    private func chartSection(_ samples: [ChartSample]) -> some View {
        let isElevation = metric == .elevation
        let values = samples.map { isElevation ? $0.elevation : $0.speed }
        let lo = isElevation ? (values.min() ?? 0) - 5 : 0
        let hi = (values.max() ?? 1) + (isElevation ? 5 : (values.max() ?? 1) * 0.1)
        let color = isElevation ? Theme.electricBlue : type.color
        let unit = isElevation ? Fmt.elevationUnit(imperial: useImperial) : Fmt.speedUnit(imperial: useImperial)
        let distUnit = useImperial ? "mi" : "km"
        let selected = selectedX.flatMap { x in samples.min { abs($0.x - x) < abs($1.x - x) } }

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Analysis").font(.headline)
                Spacer()
                Picker("Metric", selection: $metric) {
                    ForEach(ChartMetric.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .frame(width: 190)
            }

            Group {
                if let selected {
                    let v = isElevation ? selected.elevation : selected.speed
                    Text("\(String(format: "%.1f", v)) \(unit)  ·  \(String(format: "%.2f", selected.x)) \(distUnit)")
                        .font(.subheadline.weight(.semibold).monospacedDigit())
                        .foregroundStyle(color)
                } else {
                    Text("Drag across the chart to inspect")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                }
            }

            Chart {
                ForEach(samples) { s in
                    AreaMark(x: .value("Distance", s.x),
                             y: .value(metric.rawValue, isElevation ? s.elevation : s.speed))
                        .foregroundStyle(LinearGradient(colors: [color.opacity(0.4), color.opacity(0.02)],
                                                        startPoint: .top, endPoint: .bottom))
                        .interpolationMethod(.catmullRom)
                    LineMark(x: .value("Distance", s.x),
                             y: .value(metric.rawValue, isElevation ? s.elevation : s.speed))
                        .foregroundStyle(color)
                        .interpolationMethod(.catmullRom)
                }
                if let selected {
                    RuleMark(x: .value("Selected", selected.x))
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
            .chartXSelection(value: $selectedX)
            .chartYScale(domain: lo...Swift.max(hi, lo + 1))
            .chartXAxisLabel(distUnit)
            .frame(height: 200)
        }
        .cardStyle()
    }

    // MARK: Splits

    private func splitsSection(_ track: [TrackPoint]) -> some View {
        let unit = useImperial ? Fmt.metersPerMile : 1000
        let splits = Self.makeSplits(from: track, unitMeters: unit)
        let fastest = splits.map(\.duration).min() ?? 1
        let slowest = splits.map(\.duration).max() ?? 1

        return Group {
            if !splits.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text(useImperial ? "Splits (per mile)" : "Splits (per km)").font(.headline)
                    ForEach(splits.prefix(60)) { split in
                        HStack(spacing: 12) {
                            Text("\(split.id)")
                                .font(.subheadline.weight(.bold).monospacedDigit())
                                .frame(width: 26, alignment: .leading)
                            GeometryReader { geo in
                                let range = Swift.max(slowest - fastest, 1)
                                let ratio = 1 - (split.duration - fastest) / range     // faster = longer bar
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(type.color.opacity(0.85))
                                    .frame(width: Swift.max(geo.size.width * (0.3 + 0.7 * ratio), 8))
                            }
                            .frame(height: 10)
                            Text(Fmt.clock(split.duration))
                                .font(.subheadline.monospacedDigit())
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardStyle()
            }
        }
    }

    // MARK: Helpers

    private var shareText: String {
        let d = Fmt.distanceText(activity.distance, type: type, imperial: useImperial)
        return "\(activity.title) on Motion: \(d) in \(Fmt.durationWords(activity.duration))."
    }

    private static func makeSamples(from track: [TrackPoint], imperial: Bool) -> [ChartSample] {
        guard track.count > 3 else { return [] }
        let step = Swift.max(1, track.count / 250)
        let picked = stride(from: 0, to: track.count, by: step).map { track[$0] }
        return picked.enumerated().map { index, p in
            // Light moving-average smoothing of speed.
            let lower = Swift.max(0, index - 2)
            let upper = Swift.min(picked.count - 1, index + 2)
            let window = picked[lower...upper].map(\.speed)
            let avgSpeed = window.reduce(0, +) / Double(window.count)
            return ChartSample(
                id: index,
                x: Fmt.longDistanceValue(p.distance, imperial: imperial),
                elevation: Fmt.elevationValue(p.altitude, imperial: imperial),
                speed: Fmt.speedValue(avgSpeed, imperial: imperial)
            )
        }
    }

    /// Interpolates the time at which each full km / mile mark was crossed.
    private static func makeSplits(from track: [TrackPoint], unitMeters: Double) -> [Split] {
        guard var previous = track.first else { return [] }
        var result: [Split] = []
        var nextMark = unitMeters
        var lastTime: TimeInterval = 0
        for point in track.dropFirst() {
            while point.distance >= nextMark {
                let span = point.distance - previous.distance
                let fraction = span > 0 ? (nextMark - previous.distance) / span : 1
                let time = previous.elapsed + (point.elapsed - previous.elapsed) * fraction
                result.append(Split(id: result.count + 1, duration: time - lastTime, distance: unitMeters))
                lastTime = time
                nextMark += unitMeters
            }
            previous = point
        }
        return result
    }
}
