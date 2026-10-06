import SwiftUI

struct HistoryEntryView: View {
    @Environment(AppState.self) private var app
    let entryId: UUID

    @State private var editPercents: [EditRow] = []
    @State private var errorMessage: String?
    @State private var newGoalName = ""

    private var entry: HistoryEntry? {
        app.engine.historyEntry(id: entryId)
    }

    private var canEdit: Bool {
        guard let entry else { return false }
        return !entry.saved && entry.isCreditKind && !entry.overrideUsed
    }

    var body: some View {
        List {
            if let entry {
                Section("Amount") {
                    Text(INRFormatting.string(entry.amount))
                        .font(.title2.bold())
                    Text(entry.saved ? "Read-only (saved)" : "Editable once — then locked")
                        .font(.caption)
                        .foregroundStyle(PaytmTheme.textSecondary)
                }

                Section("Split") {
                    if canEdit || (!entry.saved && entry.overrideUsed) {
                        ForEach($editPercents) { $row in
                            HStack {
                                TextField("Goal", text: $row.name)
                                TextField("%", value: $row.percent, format: .number)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 56)
                                Text("%")
                            }
                        }
                        if canEdit {
                            HStack {
                                TextField("New goal name", text: $newGoalName)
                                Button("Add") { addGoalRow() }
                            }
                            Text("Total \(Int(editPercents.map(\.percent).reduce(0, +)))%")
                        }
                    } else {
                        ForEach(entry.slices) { slice in
                            HStack {
                                Text(slice.goalName)
                                Spacer()
                                Text("\(slice.percent)% · \(INRFormatting.string(slice.amount))")
                                    .foregroundStyle(PaytmTheme.textSecondary)
                            }
                        }
                    }
                }

                if canEdit {
                    Section {
                        Button("Apply one-time override") { applyOverride() }
                        Button("Save entry") { save() }
                    }
                } else if !entry.saved {
                    Section {
                        Button("Save entry") { save() }
                    }
                }

                if let errorMessage {
                    Text(errorMessage).foregroundStyle(.red)
                }
            } else {
                Text("Entry not found")
            }
        }
        .navigationTitle("History entry")
        .onAppear { loadRows() }
    }

    private func loadRows() {
        guard let entry else { return }
        editPercents = entry.slices.map {
            EditRow(id: $0.goalId, name: $0.goalName, percent: NSDecimalNumber(decimal: $0.percent).doubleValue, existing: true)
        }
    }

    private func addGoalRow() {
        let name = newGoalName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        editPercents.append(EditRow(id: UUID(), name: name, percent: 0, existing: false))
        newGoalName = ""
    }

    private func applyOverride() {
        let allocations: [(goalId: UUID?, name: String, percent: Decimal, target: Decimal?, targetDate: Date?)] =
            editPercents.map { row in
                (goalId: row.existing ? row.id : nil, name: row.name, percent: Decimal(row.percent), target: 50_000, targetDate: nil)
            }
        do {
            _ = try app.engine.overrideCreditSplit(entryId: entryId, allocations: allocations)
            loadRows()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func save() {
        if canEdit {
            let sum = editPercents.map(\.percent).reduce(0, +)
            if abs(sum - 100) < 0.01 {
                applyOverride()
            }
        }
        do {
            _ = try app.engine.saveHistoryEntry(id: entryId)
            app.activeHistoryEntryId = nil
            app.historyPresentation.clearPending()
            errorMessage = nil
            loadRows()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct EditRow: Identifiable {
    let id: UUID
    var name: String
    var percent: Double
    var existing: Bool
}
