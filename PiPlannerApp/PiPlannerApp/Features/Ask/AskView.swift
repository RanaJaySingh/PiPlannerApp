import SwiftUI

struct AskView: View {
    @Environment(AppState.self) private var app
    private let copy = TemplateCopyProvider()
    @State private var question = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Ask PiPlanner")
                        .font(.title2.bold())
                        .foregroundStyle(PaytmTheme.navy)
                    Text("Answers quote engine numbers only. Grok is optional — templates always work.")
                        .font(.caption)
                        .foregroundStyle(PaytmTheme.textSecondary)

                    Button(copy.text(for: .askStarterSplit)) {
                        question = copy.text(for: .askStarterSplit)
                        Task { await app.answerAsk(question) }
                    }
                    .buttonStyle(.bordered)
                    .tint(PaytmTheme.navy)

                    Button(copy.text(for: .askStarterInflation)) {
                        question = copy.text(for: .askStarterInflation)
                        Task { await app.answerAsk(question) }
                    }
                    .buttonStyle(.bordered)
                    .tint(PaytmTheme.navy)

                    Button(copy.text(for: .askStarterTransfer)) {
                        question = copy.text(for: .askStarterTransfer)
                        Task { await app.answerAsk(question) }
                    }
                    .buttonStyle(.bordered)
                    .tint(PaytmTheme.navy)

                    HStack {
                        TextField("Ask anything", text: $question)
                            .textFieldStyle(.roundedBorder)
                        Button("Ask") {
                            Task { await app.answerAsk(question) }
                        }
                        .font(.headline)
                        .foregroundStyle(PaytmTheme.primaryBlue)
                    }

                    if !app.askAnswer.isEmpty {
                        CardView {
                            Text(app.askAnswer)
                                .foregroundStyle(PaytmTheme.textPrimary)
                        }
                    }
                }
                .padding(24)
            }
            .background(PaytmTheme.background.ignoresSafeArea())
            .navigationTitle("Ask")
        }
    }
}
