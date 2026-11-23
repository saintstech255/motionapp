//
//  ProfileView.swift
//  Motion
//
//  Mock user info + aggregated statistics and settings.
//

import SwiftUI
import SwiftData
import Charts

struct ProfileView: View {
    @Query(sort: \ActivityRecord.startDate, order: .reverse) private var records: [ActivityRecord]
    @EnvironmentObject private var auth: AuthService
    @StateObject private var vm = ProfileViewModel()

    @AppStorage("useImperial") private var useImperial = false
    @AppStorage("weeklyGoalKm") private var weeklyGoalKm = 20.0

    var body: some View {
        let stats = vm.stats
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    header
                    goalCard(stats)
                    weekTiles(stats)
                    weeklyChart(stats)
                    allTimeTiles(stats)
                    breakdown(stats)
                    settings
                    footer
                }
                .padding(16)
            }
            .background(Theme.background)
            .navigationTitle("Profile")
        }
        .onAppear { vm.refresh(with: records) }
        .onChange(of: records.count) { _, _ in vm.refresh(with: records) }
    }

    // MARK: Sections

    private var header: some View {
        HStack(spacing: 16) {
            Text(auth.currentUser?.initials ?? "M")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 72, height: 72)
                .background(Theme.brandGradient, in: Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text(auth.currentUser?.name ?? "Athlete").font(.title3.bold())
                Text(auth.currentUser?.email ?? "")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
                if let joined = auth.currentUser?.joinedAt {
                    Text("Member since \(joined.formatted(.dateTime.month(.abbreviated).year()))")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            Spacer()
        }
        .cardStyle()
    }

    private func goalCard(_ stats: ActivityStats) -> some View {
        let goalMeters = weeklyGoalKm * 1000
        let progress = goalMeters > 0 ? stats.weekDistance / goalMeters : 0
        let done = Fmt.longDistance(stats.weekDistance, imperial: useImperial)
        let goal = Fmt.longDistance(goalMeters, imperial: useImperial)

        return HStack(spacing: 20) {
            ZStack {
                ProgressRing(progress: progress)
                Text("\(Int(min(progress, 9.99) * 100))%")
                    .font(.system(.headline, design: .rounded).weight(.bold))
            }
            .frame(width: 88, height: 88)

            VStack(alignment: .leading, spacing: 4) {
                Text("WEEKLY GOAL")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Theme.textSecondary)
                Text("\(done.value) / \(goal.value) \(goal.unit)")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                Text(progress >= 1 ? "Goal reached — great work!" : "Keep moving, you've got this.")
                    .font(.footnote)
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
        }
        .cardStyle()
    }

    private func weekTiles(_ stats: ActivityStats) -> some View {
        let d = Fmt.longDistance(stats.weekDistance, imperial: useImperial)
        return VStack(alignment: .leading, spacing: 10) {
            sectionTitle("This Week")
            HStack(spacing: 12) {
                StatTile(title: "Distance", value: d.value, unit: d.unit)
                StatTile(title: "Activities", value: "\(stats.weekCount)")
            }
            StatTile(title: "Time", value: Fmt.durationWords(stats.weekDuration), symbol: "timer")
        }
    }

    private func weeklyChart(_ stats: ActivityStats) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Last 7 Days")
            Chart(stats.daily) { day in
                BarMark(
                    x: .value("Day", day.date, unit: .day),
                    y: .value("Distance", Fmt.longDistanceValue(day.meters, imperial: useImperial))
                )
                .foregroundStyle(Theme.brandGradient)
                .cornerRadius(6)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisValueLabel(format: .dateTime.weekday(.narrow))
                }
            }
            .chartYAxisLabel(useImperial ? "mi" : "km")
            .frame(height: 160)
        }
        .cardStyle()
    }

    private func allTimeTiles(_ stats: ActivityStats) -> some View {
        let d = Fmt.longDistance(stats.totalDistance, imperial: useImperial)
        return VStack(alignment: .leading, spacing: 10) {
            sectionTitle("All Time")
            HStack(spacing: 12) {
                StatTile(title: "Distance", value: d.value, unit: d.unit)
                StatTile(title: "Activities", value: "\(stats.totalCount)")
            }
            HStack(spacing: 12) {
                StatTile(title: "Time", value: Fmt.durationWords(stats.totalDuration), symbol: "timer")
                StatTile(title: "Calories", value: String(format: "%.0f", stats.totalCalories), unit: "kcal", symbol: "flame.fill")
            }
            Text("Distance totals exclude driving.")
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
        }
    }

    @ViewBuilder
    private func breakdown(_ stats: ActivityStats) -> some View {
        if !stats.perType.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                sectionTitle("By Activity")
                ForEach(stats.perType) { item in
                    HStack(spacing: 12) {
                        ActivityIconBadge(type: item.type, size: 34)
                        Text(item.type.displayName).font(.subheadline.weight(.medium))
                        Spacer()
                        Text("\(item.count)")
                            .font(.subheadline.weight(.bold).monospacedDigit())
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle()
        }
    }

    private var settings: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("Settings")
            Toggle("Use miles & feet", isOn: $useImperial)
                .tint(Theme.brand)
            Stepper(value: $weeklyGoalKm, in: 5...200, step: 5) {
                let goal = Fmt.longDistance(weeklyGoalKm * 1000, imperial: useImperial)
                Text("Weekly goal: \(goal.value) \(goal.unit)")
            }
            Button(role: .destructive) {
                auth.signOut()
            } label: {
                Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(SecondaryButtonStyle(tint: Theme.danger))
        }
        .cardStyle()
    }

    private var footer: some View {
        VStack(spacing: 2) {
            Text("Motion 1.0")
            Text("Developed by Kas-Kazini Inc.")
        }
        .font(.caption)
        .foregroundStyle(Theme.textSecondary.opacity(0.7))
        .padding(.top, 8)
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text).font(.headline)
    }
}
