//
//  FeedView.swift
//  Motion
//
//  Main feed: past activities sorted by date (newest first).
//

import SwiftUI
import SwiftData

struct FeedView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ActivityRecord.startDate, order: .reverse) private var records: [ActivityRecord]
    @EnvironmentObject private var auth: AuthService
    @StateObject private var vm = FeedViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                if records.isEmpty {
                    ContentUnavailableView {
                        Label("No activities yet", systemImage: "figure.run")
                    } description: {
                        Text("Head to the Record tab and start your first activity. It will show up here.")
                    }
                } else {
                    feed
                }
            }
            .navigationTitle("Hi, \(auth.currentUser?.firstName ?? "Athlete")")
            .navigationDestination(for: ActivityRecord.self) { record in
                ActivityDetailView(activity: record)
            }
        }
    }

    private var feed: some View {
        let items = vm.filtered(records)
        return ScrollView {
            LazyVStack(spacing: 14) {
                filterBar
                ForEach(items) { record in
                    NavigationLink(value: record) {
                        ActivityCard(activity: record)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            modelContext.delete(record)
                            try? modelContext.save()
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "All", isSelected: vm.filter == nil) { vm.filter = nil }
                ForEach(vm.availableTypes(in: records)) { type in
                    FilterChip(title: type.displayName, symbol: type.symbol, isSelected: vm.filter == type) {
                        vm.filter = type
                    }
                }
            }
        }
    }
}

struct ActivityCard: View {
    let activity: ActivityRecord
    @AppStorage("useImperial") private var useImperial = false

    var body: some View {
        let type = activity.type
        let dist = Fmt.distance(activity.distance, type: type, imperial: useImperial)
        let rate = Fmt.primaryRate(speed: activity.averageSpeed, type: type, imperial: useImperial)
        let coords = activity.thumbnailCoordinates

        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                ActivityIconBadge(type: type)
                VStack(alignment: .leading, spacing: 2) {
                    Text(activity.title)
                        .font(.headline)
                        .lineLimit(1)
                    Text(activity.startDate.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Theme.textSecondary)
            }

            HStack(alignment: .center, spacing: 16) {
                HStack(spacing: 22) {
                    if type != .gym {
                        CompactStat(label: "Distance", value: dist.value, unit: dist.unit)
                    }
                    CompactStat(label: "Time", value: Fmt.durationWords(activity.duration))
                    if type == .gym {
                        CompactStat(label: "Calories", value: String(format: "%.0f", activity.calories), unit: "kcal")
                    } else {
                        CompactStat(label: rate.label, value: rate.value, unit: rate.unit)
                    }
                }
                Spacer(minLength: 0)
                if coords.count > 1 {
                    RouteThumbnail(coordinates: coords, color: type.color)
                        .frame(width: 84, height: 84)
                }
            }
        }
        .cardStyle()
    }
}
