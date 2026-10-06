import SwiftUI

struct OpeningSplitView: View {
    @Environment(AppState.self) private var app
    @State private var percents: [UUID: Double] = [:]
    @State private var errorMessage: String?

    private var sum: Double {
        percents.values.reduce(0, +)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Opening split")
                .font(.title2.bold())
                .foregroundStyle(PaytmTheme.navy)
            Text("Opening balance \(INRFormatting.string(app.engine.openingBalance))")
                .foregroundStyle(PaytmTheme.textSecondary)

            ForEach(app.engine.goals) { goal in
                CardView {
                    PercentEditorRow(
                        title: goal.name,
                        percent: Binding(
                            get: { percents[goal.id] ?? NSDecimalNumber(decimal: goal.standingPercent).doubleValue },
                            set: { percents[goal.id] = $0 }
                        )
                    )
                    let pct = Decimal(percents[goal.id] ?? NSDecimalNumber(decimal: goal.standingPercent).doubleValue)
                    let amount = (app.engine.openingBalance * pct / 100).rounded(toPlaces: 0)
                    Text(INRFormatting.string(amount))
                        .font(.caption)
                        .foregroundStyle(PaytmTheme.textSecondary)
                }
            }

            Text("Total \(Int(sum))% — must be 100")
                .font(.subheadline.bold())
                .foregroundStyle(abs(sum - 100) < 0.01 ? PaytmTheme.success : .red)

            if let errorMessage {
                Text(errorMessage).foregroundStyle(.red).font(.caption)
            }

            Spacer()
            PrimaryButton(title: "Lock this split", enabled: abs(sum - 100) < 0.01) {
                lock()
            }
        }
        .padding(24)
        .background(PaytmTheme.background.ignoresSafeArea())
        .navigationTitle("Lock split")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            for goal in app.engine.goals {
                percents[goal.id] = NSDecimalNumber(decimal: goal.standingPercent).doubleValue
            }
        }
    }

    private func lock() {
        for goal in app.engine.goals {
            let p = Decimal(percents[goal.id] ?? 0)
            app.engine.updateStandingPercent(goalId: goal.id, percent: p)
        }
        do {
            _ = try app.engine.lockOpeningSplit()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
