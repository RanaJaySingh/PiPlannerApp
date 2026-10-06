import SwiftUI

struct MainTabView: View {
    @Environment(AppState.self) private var app

    var body: some View {
        @Bindable var app = app
        TabView(selection: $app.selectedTab) {
            GoalsView()
                .tabItem { Label("Goals", systemImage: "flag.fill") }
                .tag(MainTab.goals)

            HistoryView()
                .tabItem { Label("History", systemImage: "clock.fill") }
                .tag(MainTab.history)

            AskView()
                .tabItem { Label("Ask", systemImage: "bubble.left.and.bubble.right.fill") }
                .tag(MainTab.ask)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(MainTab.settings)
        }
    }
}
