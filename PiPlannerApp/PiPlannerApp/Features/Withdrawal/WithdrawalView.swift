import SwiftUI

struct WithdrawalView: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var goalId: UUID?
    @State private var amountText = "5000"
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                Text(TemplateCopyProvider().text(for: .withdrawTitle))
                    .font(.subheadline)
                    .foregroundStyle(PaytmTheme.textSecondary)
                Picker("From goal", selection: $goalId) {
                    Text("Select").tag(Optional<UUID>.none)
                    ForEach(app.engine.goals) { g in
                        Text("\(g.name) (\(INRFormatting.string(g.saved)))").tag(Optional(g.id))
                    }
                }
                TextField("Amount", text: $amountText)
                    .keyboardType(.numberPad)
                if let error { Text(error).foregroundStyle(.red) }
                Text("Mock only — no real bank debit.")
                    .font(.caption)
                    .foregroundStyle(PaytmTheme.textSecondary)
            }
            .navigationTitle("Withdraw")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Withdraw") {
                        guard let goalId else { return }
                        let amount = INRFormatting.parse(amountText) ?? 0
                        do {
                            _ = try app.engine.withdraw(from: goalId, amount: amount)
                            dismiss()
                        } catch {
                            self.error = error.localizedDescription
                        }
                    }
                }
            }
            .onAppear {
                if goalId == nil { goalId = app.engine.goals.first?.id }
            }
        }
    }
}
