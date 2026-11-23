//
//  FeedViewModel.swift
//  Motion
//

import Foundation

final class FeedViewModel: ObservableObject {
    /// `nil` means "All".
    @Published var filter: ActivityType?

    func filtered(_ records: [ActivityRecord]) -> [ActivityRecord] {
        guard let filter else { return records }
        return records.filter { $0.type == filter }
    }

    func availableTypes(in records: [ActivityRecord]) -> [ActivityType] {
        ActivityType.allCases.filter { type in records.contains { $0.type == type } }
    }
}
