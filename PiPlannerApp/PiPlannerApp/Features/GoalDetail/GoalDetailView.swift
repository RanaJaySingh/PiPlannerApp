import SwiftUI

struct GoalDetailView: View {
    @Environment(AppState.self) private var app
    let goalId: UUID

    private var goal: Goal? {
        app.engine.goals.first { $0.id == goalId }
    }

    var body: some View {
        Group {
            if let goal {
                List {
                    Section("Saved") {
                        Text(INRFormatting.string(goal.saved))
                            .font(.title2.bold())
                    }
                    Section("Target") {
                        LabeledContent("Nominal", value: INRFormatting.string(goal.target))
                        LabeledContent("Inflation-adjusted", value: INRFormatting.string(app.engine.adjustedTarget(for: goal)))
                        LabeledContent("Required / mo", value: INRFormatting.string(app.engine.requiredPerMonth(for: goal)))
                        LabeledContent("Months left", value: "\(app.engine.monthsRemaining(for: goal))")
                        LabeledContent("Standing %", value: "\(goal.standingPercent)%")
                    }
                    Section {
                        NavigationLink("Edit standing split") {
                            StandingSplitView()
                        }
                    }
                }
                .navigationTitle(goal.name)
            } else {
                Text("Goal not found")
                    .navigationTitle("Goal")
            }
        }
    }
}
