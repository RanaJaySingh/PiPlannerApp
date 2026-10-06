import SwiftUI

struct TransferView: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var fromId: UUID?
    @State private var toId: UUID?
    @State private var amountText = "10000"
    @State private var error: String?
    @State private var narration = ""

    var body: some View {
        NavigationStack {
            Form {
                Picker("From", selection: $fromId) {
                    Text("Select").tag(Optional<UUID>.none)
                    ForEach(app.engine.goals) { g in
                        Text("\(g.name) (\(INRFormatting.string(g.saved)))").tag(Optional(g.id))
                    }
                }
                Picker("To", selection: $toId) {
                    Text("Select").tag(Optional<UUID>.none)
                    ForEach(app.engine.goals) { g in
                        Text(g.name).tag(Optional(g.id))
                    }
                }
                TextField("Amount", text: $amountText)
                    .keyboardType(.numberPad)
                if !narration.isEmpty {
                    Section("Grok / template") {
                        Text(narration)
                            .font(.subheadline)
                            .foregroundStyle(PaytmTheme.textSecondary)
                    }
                }
                if let error { Text(error).foregroundStyle(.red) }
            }
            .navigationTitle("Transfer")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Transfer") { performTransfer() }
                }
            }
            .task(id: "\(fromId?.uuidString ?? "")-\(toId?.uuidString ?? "")-\(amountText)") {
                await refreshNarration()
            }
        }
    }

    private func refreshNarration() async {
        guard let fromId, let toId,
              let from = app.engine.goals.first(where: { $0.id == fromId }),
              let to = app.engine.goals.first(where: { $0.id == toId }) else {
            narration = ""
            return
        }
        let amount = INRFormatting.parse(amountText) ?? 0
        await app.loadTransferNarration(from: from.name, to: to.name, amount: amount)
        narration = app.transferNarration
    }

    private func performTransfer() {
        guard let fromId, let toId else { return }
        let amount = INRFormatting.parse(amountText) ?? 0
        do {
            _ = try app.engine.transfer(from: fromId, to: toId, amount: amount)
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
    }
}
