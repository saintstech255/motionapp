//
//  RecordView.swift
//  Motion
//
//  Live recording screen: real-time map + polyline, metrics, and controls.
//

import SwiftUI
import SwiftData
import MapKit

struct RecordView: View {
    @ObservedObject var recorder: RecordingViewModel
    @ObservedObject var location: LocationService

    @Environment(\.modelContext) private var modelContext
    @AppStorage("useImperial") private var useImperial = false

    @State private var camera: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var showLocationAlert = false

    private var type: ActivityType { recorder.selectedType }

    var body: some View {
        ZStack(alignment: .bottom) {
            backdrop
                .ignoresSafeArea(edges: .top)
            controlPanel
        }
        .background(Theme.background)
        .onAppear {
            if location.needsPermissionPrompt { location.requestAuthorization() }
        }
        .alert("Location Access Needed", isPresented: $showLocationAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Motion needs location access to track your route and distance. Enable \"While Using the App\" in Settings.")
        }
        .sheet(item: $recorder.draft) { draft in
            SaveWorkoutSheet(
                draft: draft,
                onSave: { title in save(draft, title: title) },
                onDiscard: { recorder.draft = nil }
            )
            .interactiveDismissDisabled()
        }
    }

    // MARK: Backdrop (map or indoor artwork)

    @ViewBuilder
    private var backdrop: some View {
        if type.usesGPS {
            Map(position: $camera) {
                UserAnnotation()
                if recorder.route.count > 1 {
                    MapPolyline(coordinates: recorder.route)
                        .stroke(Theme.brand, lineWidth: 6)
                }
            }
            .mapStyle(.standard(pointsOfInterest: .excludingAll))
            .mapControls {
                MapUserLocationButton()
                MapCompass()
            }
        } else {
            ZStack {
                LinearGradient(colors: [type.color.opacity(0.4), Theme.background],
                               startPoint: .top, endPoint: .bottom)
                Image(systemName: type.symbol)
                    .font(.system(size: 130, weight: .semibold))
                    .foregroundStyle(type.color.opacity(0.28))
                    .offset(y: -70)
            }
        }
    }

    // MARK: Panel

    private var controlPanel: some View {
        VStack(spacing: 18) {
            if recorder.state == .idle { idlePanel } else { livePanel }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
        .animation(.easeInOut(duration: 0.25), value: recorder.state)
    }

    private var idlePanel: some View {
        VStack(spacing: 18) {
            if type.usesGPS && location.isDenied {
                Button { showLocationAlert = true } label: {
                    Label("Location is off — tap to enable", systemImage: "location.slash.fill")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Theme.danger)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(ActivityType.allCases) { t in
                        Button { recorder.selectedType = t } label: {
                            VStack(spacing: 6) {
                                Image(systemName: t.symbol).font(.title3)
                                Text(t.displayName).font(.caption2.weight(.semibold))
                            }
                            .frame(width: 78, height: 64)
                            .foregroundStyle(t == type ? .white : Theme.textSecondary)
                            .background(t == type ? t.color : Theme.card.opacity(0.8),
                                        in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Button(action: startTapped) {
                Text("START")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(width: 96, height: 96)
                    .background(Theme.brandGradient, in: Circle())
                    .shadow(color: Theme.brand.opacity(0.5), radius: 16, y: 6)
            }
            .buttonStyle(.plain)

            Text(type.usesGPS ? "GPS tracking" : (type == .swimming ? "Pool swim · tap to count laps" : "Timer & calories"))
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
        }
    }

    private var livePanel: some View {
        let dist = Fmt.distance(recorder.distance, type: type, imperial: useImperial)
        let rate = Fmt.primaryRate(speed: recorder.currentSpeed, type: type, imperial: useImperial)

        return VStack(spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: type.symbol)
                Text(recorder.state == .paused ? "PAUSED" : type.displayName.uppercased())
                    .font(.caption.weight(.heavy))
                    .tracking(2)
            }
            .foregroundStyle(recorder.state == .paused ? Theme.brandLight : type.color)

            Text(Fmt.clock(recorder.elapsed))
                .font(.system(size: 60, weight: .bold, design: .rounded))
                .monospacedDigit()

            HStack {
                if type == .gym {
                    MetricColumn(title: "Calories", value: String(format: "%.0f", recorder.liveCalories), unit: "kcal")
                } else {
                    MetricColumn(title: "Distance", value: dist.value, unit: dist.unit)
                    MetricColumn(title: rate.label, value: rate.value, unit: rate.unit)
                    if type == .swimming {
                        MetricColumn(title: "Laps", value: "\(recorder.lapCount)", unit: "")
                    } else {
                        MetricColumn(title: "Elev. Gain",
                                     value: Fmt.elevation(recorder.elevationGain, imperial: useImperial),
                                     unit: Fmt.elevationUnit(imperial: useImperial))
                    }
                }
            }

            if type == .swimming && recorder.state == .recording {
                Button { recorder.addLap() } label: {
                    Label("Add lap (\(Int(RecordingViewModel.poolLength)) m)", systemImage: "plus.circle.fill")
                }
                .buttonStyle(SecondaryButtonStyle(tint: type.color))
            }

            controls
        }
    }

    private var controls: some View {
        HStack(spacing: 28) {
            if recorder.state == .recording {
                circleButton(symbol: "pause.fill", label: "Pause", fill: AnyShapeStyle(Theme.brandGradient)) {
                    recorder.pause()
                }
            } else {
                circleButton(symbol: "play.fill", label: "Resume", fill: AnyShapeStyle(Theme.success)) {
                    recorder.resume()
                }
                circleButton(symbol: "stop.fill", label: "Finish", fill: AnyShapeStyle(Theme.danger)) {
                    recorder.finish()
                }
            }
        }
    }

    private func circleButton(symbol: String, label: String, fill: AnyShapeStyle, action: @escaping () -> Void) -> some View {
        VStack(spacing: 6) {
            Button(action: action) {
                Image(systemName: symbol)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 76, height: 76)
                    .background(fill, in: Circle())
            }
            .buttonStyle(.plain)
            Text(label).font(.caption.weight(.semibold)).foregroundStyle(Theme.textSecondary)
        }
    }

    // MARK: Actions

    private func startTapped() {
        if type.usesGPS {
            if location.isDenied { showLocationAlert = true; return }
            if location.needsPermissionPrompt { location.requestAuthorization(); return }
        }
        recorder.start()
    }

    private func save(_ draft: WorkoutDraft, title: String) {
        let record = recorder.makeRecord(from: draft, title: title)
        modelContext.insert(record)
        try? modelContext.save()
        recorder.draft = nil
    }
}

private struct MetricColumn: View {
    let title: String
    let value: String
    let unit: String

    var body: some View {
        VStack(spacing: 2) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
            Text(value)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .monospacedDigit()
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(unit.isEmpty ? " " : unit)
                .font(.caption2)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}
