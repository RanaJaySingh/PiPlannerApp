import SwiftUI

struct StandingSplitView: View {
    @Environment(AppState.self) private var app
    @State private var percents: [UUID: Double] = [:]
    @State private var message: String?

    private var sum: Double { percents.values.reduce(0, +) }

    var body: some View {
        Form {
            Section {
                Text("Standing % applies to the next credit only. Past History stays locked.")
                    .font(.caption)
                    .foregroundStyle(PaytmTheme.textSecondary)
            }
            Section("Standing split") {
                ForEach(app.engine.goals) { goal in
                    PercentEditorRow(
                        title: goal.name,
                        percent: Binding(
                            get: { percents[goal.id] ?? NSDecimalNumber(decimal: goal.standingPercent).doubleValue },
                            set: { percents[goal.id] = $0 }
                        )
                    )
                }
                Text("Total \(Int(sum))%")
                    .foregroundStyle(abs(sum - 100) < 0.01 ? PaytmTheme.success : .red)
            }
            if let message {
                Text(message).foregroundStyle(PaytmTheme.success)
            }
            Section {
                Button("Save standing split") { save() }
                    .disabled(abs(sum - 100) > 0.01)
            }
        }
        .navigationTitle("Standing split")
        .onAppear {
            for goal in app.engine.goals {
                percents[goal.id] = NSDecimalNumber(decimal: goal.standingPercent).doubleValue
            }
        }
    }

    private func save() {
        for goal in app.engine.goals {
            app.engine.updateStandingPercent(goalId: goal.id, percent: Decimal(percents[goal.id] ?? 0))
        }
        message = app.engine.standingPercentsSumTo100() ? "Saved. Next credit uses this split." : "Must sum to 100."
    }
}
