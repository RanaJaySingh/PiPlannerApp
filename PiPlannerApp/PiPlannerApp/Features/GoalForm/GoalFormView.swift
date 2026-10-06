import SwiftUI

struct GoalFormView: View {
    @Environment(AppState.self) private var app
    @State private var name = "Car"
    @State private var targetText = "1000000"
    @State private var secondName = "Emergency"
    @State private var secondTarget = "200000"
    @State private var useTwoGoals = true
    @State private var carPercent: Double = 60
    @State private var error: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Goal form")
                    .font(.title2.bold())
                    .foregroundStyle(PaytmTheme.navy)
                Text("Fallback when chat is skipped. Percents must sum to 100%.")
                    .font(.subheadline)
                    .foregroundStyle(PaytmTheme.textSecondary)

                CardView {
                    VStack(alignment: .leading, spacing: 12) {
                        TextField("Goal name", text: $name)
                        TextField("Target ₹", text: $targetText)
                            .keyboardType(.numberPad)
                        Toggle("Add second goal", isOn: $useTwoGoals)
                            .tint(PaytmTheme.primaryBlue)
                        if useTwoGoals {
                            TextField("Second goal", text: $secondName)
                            TextField("Second target ₹", text: $secondTarget)
                                .keyboardType(.numberPad)
                            PercentEditorRow(title: "\(name) %", percent: $carPercent)
                            Text("\(secondName) gets \(Int(100 - carPercent))%")
                                .font(.caption)
                                .foregroundStyle(PaytmTheme.textSecondary)
                        } else {
                            Text("Single goal → 100% allocation (split screen skipped).")
                                .font(.caption)
                                .foregroundStyle(PaytmTheme.success)
                        }
                    }
                }

                if let error {
                    Text(error).foregroundStyle(.red).font(.caption)
                }

                PrimaryButton(title: "Save goals & continue") {
                    save()
                }
            }
            .padding(24)
        }
        .background(PaytmTheme.background.ignoresSafeArea())
        .navigationTitle("Goals form")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func save() {
        guard let t1 = INRFormatting.parse(targetText), t1 > 0 else {
            error = "Enter a valid target"
            return
        }
        let carDate = app.engine.calendar.date(from: DateComponents(year: 2028, month: 3, day: 1))!
        let emergencyDate = app.engine.calendar.date(from: DateComponents(year: 2030, month: 12, day: 31))!
        if useTwoGoals {
            guard let t2 = INRFormatting.parse(secondTarget), t2 > 0 else {
                error = "Enter a valid second target"
                return
            }
            let p1 = Decimal(carPercent)
            let p2 = Decimal(100 - carPercent)
            guard p1 + p2 == 100 else {
                error = "Percents must sum to 100"
                return
            }
            let goals = [
                Goal(name: name, target: t1, targetDate: carDate, standingPercent: p1),
                Goal(name: secondName, target: t2, targetDate: emergencyDate, standingPercent: p2)
            ]
            app.engine.replaceGoals(goals)
        } else {
            let goals = [Goal(name: name, target: t1, targetDate: carDate, standingPercent: 100)]
            app.engine.replaceGoals(goals)
        }
        error = nil
        app.setupPath.append(.inflation)
    }
}
