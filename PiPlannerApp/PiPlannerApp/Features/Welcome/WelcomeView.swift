import SwiftUI

struct WelcomeView: View {
    @Environment(AppState.self) private var app

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "indianrupeesign.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(PaytmTheme.primaryBlue)
            Text("PiPlanner")
                .font(.largeTitle.bold())
                .foregroundStyle(PaytmTheme.navy)
            Text("Every Rupee Has a Plan.\nMock demo for Rahul — no login, no real bank.")
                .multilineTextAlignment(.center)
                .foregroundStyle(PaytmTheme.textSecondary)
                .padding(.horizontal)
            Spacer()
            PrimaryButton(title: "Set up savings") {
                app.setupPath.append(.accounts)
            }
            .padding(.horizontal, 24)
            Text("Powered by Grok · templates · full plan")
                .font(.caption)
                .foregroundStyle(PaytmTheme.textSecondary)
                .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PaytmTheme.background.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
    }
}
