import SwiftUI

struct DeleteGoalView: View {
    let goal: Goal
    @Binding var percents: [UUID: Double]
    let onConfirm: () -> Void
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss

    private var sum: Double { percents.values.reduce(0, +) }

    var body: some View {
        NavigationStack {
            Form {
                Text("Redistribute \(INRFormatting.string(goal.saved)) from \(goal.name)")
                ForEach(app.engine.goals.filter { $0.id != goal.id }) { g in
                    PercentEditorRow(
                        title: g.name,
                        percent: Binding(
                            get: { percents[g.id] ?? 0 },
                            set: { percents[g.id] = $0 }
                        )
                    )
                }
                Text("Total \(Int(sum))%")
                    .foregroundStyle(abs(sum - 100) < 0.01 ? PaytmTheme.success : .red)
            }
            .navigationTitle("Delete \(goal.name)")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Confirm") {
                        onConfirm()
                        dismiss()
                    }
                    .disabled(abs(sum - 100) > 0.01 && goal.saved > 0)
                }
            }
        }
    }
}
