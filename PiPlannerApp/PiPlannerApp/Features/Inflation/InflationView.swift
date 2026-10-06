import SwiftUI

struct InflationView: View {
    @Environment(AppState.self) private var app
    @State private var ratePercent: Double = 7
    @State private var error: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Inflation estimate")
                .font(.title2.bold())
                .foregroundStyle(PaytmTheme.navy)

            CardView {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Annual inflation")
                        Spacer()
                        Text("\(Int(ratePercent))%")
                            .font(.title3.bold())
                            .foregroundStyle(PaytmTheme.primaryBlue)
                    }
                    Slider(value: $ratePercent, in: 0...15, step: 1)
                        .tint(PaytmTheme.primaryBlue)
                        .onChange(of: ratePercent) { _, newValue in
                            applyRate(newValue)
                        }

                    Text("Estimate, not a guarantee. Used only for required monthly savings.")
                        .font(.caption)
                        .foregroundStyle(PaytmTheme.textSecondary)

                    if let car = app.engine.goals.first(where: { $0.name == "Car" }) ?? app.engine.goals.first {
                        let adjusted = app.engine.adjustedTarget(for: car)
                        Text("\(car.name) adjusted target: \(INRFormatting.string(adjusted))")
                            .font(.headline)
                            .foregroundStyle(PaytmTheme.navy)
                    }
                    if !app.inflationText.isEmpty {
                        Text(app.inflationText)
                            .font(.caption)
                            .foregroundStyle(PaytmTheme.primaryBlue)
                    }
                }
            }

            if let error {
                Text(error).foregroundStyle(.red).font(.caption)
            }

            Spacer()
            PrimaryButton(title: "Confirm") {
                applyRate(ratePercent)
                continueAfterInflation()
            }
        }
        .padding(24)
        .background(PaytmTheme.background.ignoresSafeArea())
        .navigationTitle("Inflation")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            applyRate(ratePercent)
            Task { await app.loadInflationCopy() }
        }
    }

    private func applyRate(_ percent: Double) {
        let rate = Decimal(percent) / 100
        for goal in app.engine.goals {
            app.engine.updateGoal(id: goal.id, inflationRate: rate)
        }
    }

    private func continueAfterInflation() {
        if app.engine.shouldSkipSplitUI {
            do {
                _ = try app.engine.lockOpeningSplit()
                error = nil
            } catch {
                self.error = error.localizedDescription
            }
        } else {
            app.setupPath.append(.openingSplit)
        }
    }
}
