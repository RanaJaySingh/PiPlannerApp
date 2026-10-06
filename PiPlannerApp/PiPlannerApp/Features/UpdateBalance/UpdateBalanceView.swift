import SwiftUI

struct UpdateBalanceView: View {
    @Environment(AppState.self) private var app
    var isPostSetup: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(isPostSetup ? "Update balance" : "How do you want to set the opening balance?")
                .font(.title3.weight(.semibold))

            Text("Manually type an amount, or sync a mock balance\(app.engine.needsUPIPinForBalanceSync ? " (UPI PIN required — account linked in Paytm)" : "").")
                .font(.subheadline)
                .foregroundStyle(PaytmTheme.textSecondary)

            Spacer()

            PrimaryButton(title: "Enter amount manually") {
                app.engine.setConsentOffPath(.manual)
                navigateManual()
            }

            Button {
                app.engine.setConsentOffPath(.balanceSync)
                if app.engine.needsUPIPinForBalanceSync && !app.engine.pinVerified {
                    navigatePIN()
                } else {
                    performBalanceSync()
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
    }

    private func navigateManual() {
        app.setupPath.append(.manualAmount)
    }

    private func navigatePIN() {
        app.setupPath.append(.upiPin)
    }

    private func performBalanceSync() {
        if app.engine.isSetupComplete {
            do {
                let entry = try app.engine.sync()
                app.openNewHistoryEntry(entry.id)
            } catch {
                app.toast = error.localizedDescription
            }
        } else {
            do {
                _ = try app.engine.fetchOpeningBalanceViaConsentOffSync()
                app.openingCaptured = true
                app.setupPath.append(.goalChat)
            } catch {
                app.toast = error.localizedDescription
            }
        }
    }
}
