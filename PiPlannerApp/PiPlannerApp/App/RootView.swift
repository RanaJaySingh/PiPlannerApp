import SwiftUI

struct RootView: View {
    @Environment(AppState.self) private var app

    var body: some View {
        Group {
            if app.engine.isSetupComplete {
                MainTabView()
            } else {
                SetupFlowView()
            }
        }
        .tint(PaytmTheme.primaryBlue)
        .background(PaytmTheme.background.ignoresSafeArea())
    }
}
