import SwiftUI

struct AccountsView: View {
    @Environment(AppState.self) private var app

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Mark exactly one dedicated savings account.")
                    .font(.subheadline)
                    .foregroundStyle(PaytmTheme.textSecondary)

                ForEach(app.engine.accounts) { account in
                    Button {
                        _ = app.engine.setDedicatedAccount(id: account.id)
                    } label: {
                        CardView {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(account.displayName)
                                        .font(.headline)
                                        .foregroundStyle(PaytmTheme.textPrimary)
                                    Text(account.maskedLabel)
                                        .font(.subheadline.monospaced())
                                        .foregroundStyle(PaytmTheme.textSecondary)
                                    if account.linkedInPaytm {
                                        Text("Linked in Paytm")
                                            .font(.caption)
                                            .foregroundStyle(PaytmTheme.success)
                                    }
                                }
                                Spacer()
                                Image(systemName: account.isDedicated ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(account.isDedicated ? PaytmTheme.primaryBlue : PaytmTheme.textSecondary)
                                    .font(.title2)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .background(PaytmTheme.background.ignoresSafeArea())
        .navigationTitle("Accounts")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            PrimaryButton(title: "Continue", enabled: app.engine.hasExactlyOneDedicated) {
                app.setupPath.append(.consent)
            }
            .padding()
            .background(PaytmTheme.background)
        }
    }
}
