import SwiftUI

struct HistoryView: View {
    @Environment(AppState.self) private var app

    var body: some View {
        @Bindable var state = app
        NavigationStack(path: Binding(
            get: { state.historyPresentation.path },
            set: { state.historyPresentation.path = $0 }
        )) {
            List {
                if app.engine.history.isEmpty {
                    Text("No history yet")
                        .foregroundStyle(PaytmTheme.textSecondary)
                }
                ForEach(app.engine.history) { entry in
                    NavigationLink(value: entry.id) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(title(for: entry))
                                    .font(.headline)
                                Text(entry.note.isEmpty ? entry.kind.rawValue : entry.note)
                                    .font(.caption)
                                    .foregroundStyle(PaytmTheme.textSecondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text(INRFormatting.string(entry.amount < 0 ? -entry.amount : entry.amount))
                                    .font(.subheadline.bold())
                                Text(entry.saved ? "Saved" : "Unsaved")
                                    .font(.caption2)
                                    .foregroundStyle(entry.saved ? PaytmTheme.textSecondary : PaytmTheme.primaryBlue)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("History")
            .navigationDestination(for: UUID.self) { entryId in
                HistoryEntryView(entryId: entryId)
            }
            .onAppear {
                state.historyPresentation.applyPendingToPath()
            }
            .onChange(of: state.historyPresentation.pendingOpenEntryID) { _, newID in
                if newID != nil {
                    state.historyPresentation.applyPendingToPath()
                }
            }
        }
    }

    private func title(for entry: HistoryEntry) -> String {
        switch entry.kind {
        case .opening: return "Opening split"
        case .credit: return "Sync credit"
        case .manualAdd: return "Added amount"
        case .transfer: return "Transfer"
        case .delete: return "Goal deleted"
        case .withdrawal: return "Withdrawal"
        }
    }
}
