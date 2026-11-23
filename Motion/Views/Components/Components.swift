//
//  Components.swift
//  Motion
//
//  Reusable UI building blocks.
//

import SwiftUI
import MapKit

// MARK: Button styles

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Theme.brandGradient, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    var tint: Color = .white

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Theme.cardElevated, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: Stat tiles

struct StatTile: View {
    let title: String
    let value: String
    var unit: String = ""
    var symbol: String?
    var tint: Color = Theme.brand

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                if let symbol {
                    Image(systemName: symbol)
                        .font(.caption)
                        .foregroundStyle(tint)
                }
                Text(title.uppercased())
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Theme.textSecondary)
            }
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(padding: 14)
    }
}

/// Small label/value pair used inside feed cards.
struct CompactStat: View {
    let label: String
    let value: String
    var unit: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .monospacedDigit()
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption2)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        }
    }
}

// MARK: Badges & chips

struct ActivityIconBadge: View {
    let type: ActivityType
    var size: CGFloat = 44

    var body: some View {
        Image(systemName: type.symbol)
            .font(.system(size: size * 0.45, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(type.color.gradient, in: Circle())
    }
}

struct FilterChip: View {
    let title: String
    var symbol: String?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let symbol { Image(systemName: symbol) }
                Text(title)
            }
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .foregroundStyle(isSelected ? .white : Theme.textSecondary)
            .background(isSelected ? Theme.brand : Theme.card, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: Route drawing

/// Draws a route as a normalised line (no map tiles) for compact thumbnails.
struct RouteShape: Shape {
    let coordinates: [CLLocationCoordinate2D]

    func path(in rect: CGRect) -> Path {
        guard coordinates.count > 1 else { return Path() }
        let lats = coordinates.map(\.latitude)
        let lons = coordinates.map(\.longitude)
        guard let minLat = lats.min(), let maxLat = lats.max(),
              let minLon = lons.min(), let maxLon = lons.max() else { return Path() }

        let lonScale = cos(((minLat + maxLat) / 2) * .pi / 180)
        let w = max((maxLon - minLon) * lonScale, 0.00001)
        let h = max(maxLat - minLat, 0.00001)
        let scale = min(rect.width / w, rect.height / h)
        let offsetX = (rect.width - w * scale) / 2
        let offsetY = (rect.height - h * scale) / 2

        var path = Path()
        for (index, c) in coordinates.enumerated() {
            let point = CGPoint(
                x: rect.minX + offsetX + (c.longitude - minLon) * lonScale * scale,
                y: rect.minY + offsetY + (maxLat - c.latitude) * scale
            )
            if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        return path
    }
}

struct RouteThumbnail: View {
    let coordinates: [CLLocationCoordinate2D]
    var color: Color = Theme.brand

    var body: some View {
        RouteShape(coordinates: coordinates)
            .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
            .padding(10)
            .background(Theme.cardElevated, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: Progress ring

struct ProgressRing: View {
    let progress: Double
    var lineWidth: CGFloat = 12

    var body: some View {
        ZStack {
            Circle().stroke(Theme.cardElevated, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(Theme.brandGradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.6), value: progress)
        }
    }
}
