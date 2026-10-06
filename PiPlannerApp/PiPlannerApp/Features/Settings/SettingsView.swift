import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var app
    @State private var confirmReset = false

    var body: some View {
        NavigationStack {
            List {
                Section("Demo") {
                    Text("Mock Rahul · no login · no real bank")
                        .font(.subheadline)
                        .foregroundStyle(PaytmTheme.textSecondary)
                    Button("Reset demo", role: .destructive) {
                        confirmReset = true
                    }
                }
                Section("About") {
                    LabeledContent("Bundle", value: "com.rana.piplanner.app")
                    LabeledContent("Display name", value: "PiPlanner")
                    LabeledContent("Grok", value: (app.copyProvider is GrokCopyProvider) ? "Configured (optional)" : "Templates (default)")
                }
            }
            .navigationTitle("Settings")
            .confirmationDialog("Reset demo and return to Welcome?", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Reset demo", role: .destructive) { app.resetDemo() }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
}
