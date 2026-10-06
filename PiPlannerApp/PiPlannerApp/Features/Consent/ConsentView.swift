import SwiftUI

struct ConsentView: View {
    @Environment(AppState.self) private var app

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Allow PiPlanner to sync your dedicated savings balance?")
                .font(.title3.weight(.semibold))
                .foregroundStyle(PaytmTheme.textPrimary)

            Text("Mock only — no real bank call. Yes fetches ₹1,00,000 opening. No lets you enter amounts yourself or sync with a mock UPI PIN when the account is linked in Paytm.")
                .font(.subheadline)
                .foregroundStyle(PaytmTheme.textSecondary)

            Spacer()

            PrimaryButton(title: "Allow balance sync") {
                app.engine.setConsent(.allowed)
                _ = app.engine.fetchOpeningBalance()
                app.openingCaptured = true
                app.setupPath.append(.goalChat)
            }

            Button {
                app.engine.setConsent(.denied)
                app.setupPath.append(.updateBalance)
            } label: {
                Text("Enter amounts myself")
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
        .navigationTitle("Consent")
        .navigationBarTitleDisplayMode(.inline)
    }
}
