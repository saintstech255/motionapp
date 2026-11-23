//
//  SaveWorkoutSheet.swift
//  Motion
//

import SwiftUI

/// Shown after finishing: name the workout, then save or discard it.
struct SaveWorkoutSheet: View {
    let draft: WorkoutDraft
    let onSave: (String) -> Void
    let onDiscard: () -> Void

    @State private var title: String
    @State private var confirmDiscard = false
    @AppStorage("useImperial") private var useImperial = false

    init(draft: WorkoutDraft, onSave: @escaping (String) -> Void, onDiscard: @escaping () -> Void) {
        self.draft = draft
        self.onSave = onSave
        self.onDiscard = onDiscard
        _title = State(initialValue: draft.type.defaultTitle(for: draft.startDate))
    }

    var body: some View {
        let dist = Fmt.distance(draft.distance, type: draft.type, imperial: useImperial)
        let avgSpeed = draft.duration > 0 ? draft.distance / draft.duration : 0
        let rate = Fmt.primaryRate(speed: avgSpeed, type: draft.type, imperial: useImperial)

        VStack(spacing: 20) {
            VStack(spacing: 10) {
                ActivityIconBadge(type: draft.type, size: 64)
                Text("Workout complete")
                    .font(.title2.bold())
            }
            .padding(.top, 28)

            TextField("Title", text: $title)
                .padding(14)
                .background(Theme.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                StatTile(title: "Duration", value: Fmt.clock(draft.duration), symbol: "timer")
                if draft.type == .gym {
                    StatTile(title: "Calories", value: String(format: "%.0f", draft.calories), unit: "kcal", symbol: "flame.fill")
                } else {
                    StatTile(title: "Distance", value: dist.value, unit: dist.unit, symbol: "point.topleft.down.to.point.bottomright.curvepath")
                    StatTile(title: "Avg \(rate.label)", value: rate.value, unit: rate.unit, symbol: "speedometer")
                    StatTile(title: "Calories", value: String(format: "%.0f", draft.calories), unit: "kcal", symbol: "flame.fill")
                }
            }

            Spacer()

            Button("Save Activity") { onSave(title) }
                .buttonStyle(PrimaryButtonStyle())
            Button("Discard") { confirmDiscard = true }
                .font(.headline)
                .foregroundStyle(Theme.danger)
                .padding(.bottom, 8)
        }
        .padding(.horizontal, 20)
        .background(Theme.background.ignoresSafeArea())
        .confirmationDialog("Discard this activity?", isPresented: $confirmDiscard, titleVisibility: .visible) {
            Button("Discard", role: .destructive, action: onDiscard)
            Button("Keep Editing", role: .cancel) {}
        }
        .presentationDetents([.large])
    }
}
