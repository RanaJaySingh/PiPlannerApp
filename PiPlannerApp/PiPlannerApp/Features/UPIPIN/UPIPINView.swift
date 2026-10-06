import SwiftUI

struct UPIPINView: View {
    @Environment(AppState.self) private var app
    @State private var pin = ""
    @State private var error: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Enter UPI PIN")
                .font(.title3.weight(.semibold))
            Text("Mock PIN — any 4–6 digits. No real payment.")
                .font(.subheadline)
                .foregroundStyle(PaytmTheme.textSecondary)

            SecureField("••••", text: $pin)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .padding()
                .background(PaytmTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .font(.title2.monospacedDigit())

            if let error {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Spacer()

            PrimaryButton(title: "Verify & continue", enabled: pin.filter(\.isNumber).count >= 4) {
                if app.engine.verifyUPIPin(pin) {
                    if app.engine.isSetupComplete {
                        do {
                            let entry = try app.engine.sync()
                            app.openNewHistoryEntry(entry.id)
                        } catch {
                            self.error = error.localizedDescription
                        }
                    } else {
                        do {
                            _ = try app.engine.fetchOpeningBalanceViaConsentOffSync()
                            app.openingCaptured = true
                            app.setupPath.append(.goalChat)
                        } catch {
                            self.error = error.localizedDescription
                        }
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
    }
}
