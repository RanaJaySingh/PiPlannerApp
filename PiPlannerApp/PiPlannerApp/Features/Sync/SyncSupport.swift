import SwiftUI

struct PostSetupUpdateBalanceSheet: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss
    var onManual: () -> Void
    var onNeedPin: () -> Void
    var onSynced: () -> Void
    @State private var error: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Update balance")
                .font(.title3.weight(.semibold))
            Text("Manually type an amount, or sync a mock balance.")
                .font(.subheadline)
                .foregroundStyle(PaytmTheme.textSecondary)

            if let error {
                Text(error).font(.caption).foregroundStyle(.red)
            }

            Spacer()

            PrimaryButton(title: "Enter amount manually") {
                onManual()
            }

            Button {
                app.engine.setConsentOffPath(.balanceSync)
                if app.engine.needsUPIPinForBalanceSync && !app.engine.pinVerified {
                    onNeedPin()
                } else {
                    do {
                        let entry = try app.engine.sync()
                        app.openNewHistoryEntry(entry.id)
                        onSynced()
                    } catch {
                        self.error = error.localizedDescription
                    }
                }
            } label: {
                Text("Balance sync")
                    .font(.headline)
                    .foregroundStyle(PaytmTheme.navy)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(PaytmTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: PaytmTheme.corner))
                    .overlay(
                        RoundedRectangle(cornerRadius: PaytmTheme.corner)
                            .stroke(PaytmTheme.primaryBlue.opacity(0.4), lineWidth: 1)
                    )
            }
        }
        .padding(24)
        .background(PaytmTheme.background.ignoresSafeArea())
        .navigationTitle("Update balance")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
        }
    }
}

struct PostSetupUPIPINSheet: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss
    var onDone: () -> Void
    @State private var pin = ""
    @State private var error: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Enter UPI PIN")
                .font(.title3.weight(.semibold))
            Text("Mock PIN — any 4–6 digits.")
                .font(.subheadline)
                .foregroundStyle(PaytmTheme.textSecondary)

            SecureField("••••", text: $pin)
                .keyboardType(.numberPad)
                .padding()
                .background(PaytmTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .font(.title2.monospacedDigit())

            if let error {
                Text(error).font(.caption).foregroundStyle(.red)
            }

            Spacer()

            PrimaryButton(title: "Verify & sync", enabled: pin.filter(\.isNumber).count >= 4) {
                app.engine.setConsentOffPath(.balanceSync)
                if app.engine.verifyUPIPin(pin) {
                    do {
                        let entry = try app.engine.sync()
                        app.openNewHistoryEntry(entry.id)
                        onDone()
                    } catch {
                        self.error = error.localizedDescription
                    }
                } else {
                    error = "Enter 4–6 digits"
                }
            }
        }
        .padding(24)
        .background(PaytmTheme.background.ignoresSafeArea())
        .navigationTitle("UPI PIN")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
        }
    }
}
