import SwiftUI

struct SetupFlowView: View {
    @Environment(AppState.self) private var app

    var body: some View {
        @Bindable var app = app
        NavigationStack(path: $app.setupPath) {
            WelcomeView()
                .navigationDestination(for: SetupRoute.self) { route in
                    switch route {
                    case .accounts: AccountsView()
                    case .consent: ConsentView()
                    case .updateBalance: UpdateBalanceView()
                    case .upiPin: UPIPINView()
                    case .manualAmount: ManualAmountView()
                    case .goalChat: GoalChatView()
                    case .goalForm: GoalFormView()
                    case .inflation: InflationView()
                    case .openingSplit: OpeningSplitView()
                    }
                }
        }
    }
}
