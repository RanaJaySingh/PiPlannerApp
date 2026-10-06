import SwiftUI

struct ManualAmountView: View {
    @Environment(AppState.self) private var app
    @State private var text = "100000"
    @State private var error: String?
    var isPostSetupAdd: Bool = false
    var onDone: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(isPostSetupAdd ? "Add amount" : "Opening balance")
                .font(.title3.weight(.semibold))
            Text("Type amount in rupees (demo opening: 100000).")
                .font(.subheadline)
                .foregroundStyle(PaytmTheme.textSecondary)

            TextField("Amount", text: $text)
                .keyboardType(.numberPad)
                .padding()
                .background(PaytmTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .font(.title3.monospacedDigit())

            if let error {
                Text(error).font(.caption).foregroundStyle(.red)
            }

            Spacer()

            PrimaryButton(title: "Continue", enabled: INRFormatting.parse(text) != nil) {
                guard let amount = INRFormatting.parse(text), amount > 0 else {
                    error = "Enter a valid amount"
                    return
                }
                if isPostSetupAdd {
                    do {
                        let entry = try app.engine.addAmount(amount)
                        app.openNewHistoryEntry(entry.id)
                        onDone?()
                    } catch {
                        self.error = error.localizedDescription
                    }
                } else {
                    app.engine.setManualOpeningBalance(amount)
                    app.openingCaptured = true
                    app.setupPath.append(.goalChat)
                }
            }
        }
        .padding(24)
        .background(PaytmTheme.background.ignoresSafeArea())
        .navigationTitle(isPostSetupAdd ? "Add amount" : "Manual amount")
        .navigationBarTitleDisplayMode(.inline)
    }
}
