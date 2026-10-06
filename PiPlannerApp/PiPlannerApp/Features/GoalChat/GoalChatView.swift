import SwiftUI

struct GoalChatView: View {
    @Environment(AppState.self) private var app
    @State private var input = "Car ₹10 lakh by Mar 2028 + Emergency"
    @State private var messages: [ChatBubble] = [
        ChatBubble(isUser: false, text: "Tell me your savings goals. Try: Car ₹10 lakh by Mar 2028 + Emergency")
    ]
    @State private var proposed = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(messages) { bubble in
                        HStack {
                            if bubble.isUser { Spacer(minLength: 40) }
                            Text(bubble.text)
                                .padding(12)
                                .background(bubble.isUser ? PaytmTheme.primaryBlue.opacity(0.15) : PaytmTheme.card)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            if !bubble.isUser { Spacer(minLength: 40) }
                        }
                    }
                    if proposed {
                        CardView {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Proposed split")
                                    .font(.caption)
                                    .foregroundStyle(PaytmTheme.textSecondary)
                                ForEach(app.engine.goals) { g in
                                    Text("\(g.name) — \(g.standingPercent)% · target \(INRFormatting.string(g.target))")
                                        .font(.subheadline)
                                }
                                if !app.proposalText.isEmpty {
                                    Text(app.proposalText)
                                        .font(.caption)
                                        .foregroundStyle(PaytmTheme.primaryBlue)
                                        .padding(.top, 4)
                                }
                            }
                        }
                    }
                }
                .padding(16)
            }

            HStack {
                TextField("Your goals", text: $input)
                    .textFieldStyle(.roundedBorder)
                Button("Send") { submit() }
                    .font(.headline)
                    .foregroundStyle(PaytmTheme.navy)
            }
            .padding()

            Button("Use form instead") {
                app.setupPath.append(.goalForm)
            }
            .font(.subheadline)
            .foregroundStyle(PaytmTheme.primaryBlue)
            .padding(.bottom, 8)

            PrimaryButton(title: "Continue", enabled: !app.engine.goals.isEmpty) {
                app.setupPath.append(.inflation)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .background(PaytmTheme.background.ignoresSafeArea())
        .navigationTitle("Goal chat")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func submit() {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        messages.append(ChatBubble(isUser: true, text: text))
        let lower = text.lowercased()
        if lower.contains("only") || (lower.contains("car") && !lower.contains("emergency") && !lower.contains("+")) {
            app.engine.replaceGoals(app.engine.proposeSingleGoal())
            messages.append(ChatBubble(isUser: false, text: "One goal — Car at 100%. Split screen will be skipped."))
        } else {
            app.engine.replaceGoals(app.engine.proposeDefaultGoals())
            messages.append(ChatBubble(isUser: false, text: "Got it — Car 60% / Emergency 40%. Adjust on the next screens if needed."))
        }
        proposed = true
        Task { await app.loadProposal() }
    }
}

private struct ChatBubble: Identifiable {
    let id = UUID()
    let isUser: Bool
    let text: String
}
