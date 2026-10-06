import Foundation

public struct HistoryPresentation: Equatable, Sendable {
    public var pendingOpenEntryID: UUID?
    public var path: [UUID]

    public init(pendingOpenEntryID: UUID? = nil, path: [UUID] = []) {
        self.pendingOpenEntryID = pendingOpenEntryID
        self.path = path
    }

    public mutating func presentNewEntry(_ id: UUID) {
        pendingOpenEntryID = id
        path = [id]
    }

    public mutating func applyPendingToPath() {
        if let id = pendingOpenEntryID {
            path = [id]
        }
    }

    public mutating func clearPending() {
        pendingOpenEntryID = nil
    }

    public mutating func reset() {
        pendingOpenEntryID = nil
        path = []
    }
}
