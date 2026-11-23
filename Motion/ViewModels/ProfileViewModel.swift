//
//  ProfileViewModel.swift
//  Motion
//
//  Aggregated statistics. Driving is excluded from fitness distance totals.
//

import Foundation

struct DailyDistance: Identifiable {
    let date: Date
    let meters: Double
    var id: Date { date }
}

struct TypeCount: Identifiable {
    let type: ActivityType
    let count: Int
    var id: String { type.rawValue }
}

struct ActivityStats {
    var weekDistance = 0.0
    var weekDuration = 0.0
    var weekCount = 0
    var totalDistance = 0.0
    var totalDuration = 0.0
    var totalCount = 0
    var totalCalories = 0.0
    var totalElevation = 0.0
    var perType: [TypeCount] = []
    var daily: [DailyDistance] = []
}

final class ProfileViewModel: ObservableObject {
    @Published private(set) var stats = ActivityStats()

    func refresh(with records: [ActivityRecord]) {
        let calendar = Calendar.current
        let now = Date()
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start
            ?? calendar.startOfDay(for: now)

        var s = ActivityStats()
        for r in records {
            let fitnessDistance = r.type == .driving ? 0 : r.distance
            s.totalDistance += fitnessDistance
            s.totalDuration += r.duration
            s.totalCalories += r.calories
            s.totalElevation += r.elevationGain
            s.totalCount += 1
            if r.startDate >= weekStart {
                s.weekDistance += fitnessDistance
                s.weekDuration += r.duration
                s.weekCount += 1
            }
        }

        s.perType = ActivityType.allCases.compactMap { type in
            let count = records.filter { $0.type == type }.count
            return count > 0 ? TypeCount(type: type, count: count) : nil
        }

        let today = calendar.startOfDay(for: now)
        s.daily = (0..<7).map { offset in
            let day = calendar.date(byAdding: .day, value: offset - 6, to: today) ?? today
            let total = records
                .filter { calendar.isDate($0.startDate, inSameDayAs: day) && $0.type != .driving }
                .reduce(0.0) { $0 + $1.distance }
            return DailyDistance(date: day, meters: total)
        }
        stats = s
    }
}
