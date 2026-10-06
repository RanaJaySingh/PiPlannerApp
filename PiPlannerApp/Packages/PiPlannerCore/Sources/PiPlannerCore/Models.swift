import Foundation

// MARK: - Account

public struct Account: Identifiable, Equatable, Sendable {
    public let id: UUID
    public var maskedLabel: String
    public var isDedicated: Bool
    public var displayName: String
    public var linkedInPaytm: Bool

    public init(
        id: UUID = UUID(),
        maskedLabel: String,
        isDedicated: Bool = false,
        displayName: String = "",
        linkedInPaytm: Bool = false
    ) {
        self.id = id
        self.maskedLabel = maskedLabel
        self.isDedicated = isDedicated
        self.displayName = displayName
        self.linkedInPaytm = linkedInPaytm
    }
}

// MARK: - Consent

public enum ConsentMode: String, Equatable, Sendable {
    case allowed
    case denied
}

public enum ConsentOffBalancePath: String, Equatable, Sendable {
    case manual
    case balanceSync
}

// MARK: - Goal

public struct Goal: Identifiable, Equatable, Sendable {
    public let id: UUID
    public var name: String
    public var target: Decimal
    public var targetDate: Date
    public var inflationRate: Decimal
    public var standingPercent: Decimal
    public var saved: Decimal

    public init(
        id: UUID = UUID(),
        name: String,
        target: Decimal,
        targetDate: Date,
        inflationRate: Decimal = Decimal(string: "0.07")!,
        standingPercent: Decimal,
        saved: Decimal = 0
    ) {
        self.id = id
        self.name = name
        self.target = target
        self.targetDate = targetDate
        self.inflationRate = inflationRate
        self.standingPercent = standingPercent
        self.saved = saved
    }
}

// MARK: - Snapshot

public struct Snapshot: Equatable, Sendable {
    public var balance: Decimal
    public var date: Date
    public var source: SnapshotSource

    public init(balance: Decimal, date: Date, source: SnapshotSource) {
        self.balance = balance
        self.date = date
        self.source = source
    }
}

public enum SnapshotSource: String, Equatable, Sendable {
    case fetched
    case typed
}

// MARK: - Slice

public struct Slice: Identifiable, Equatable, Sendable {
    public let id: UUID
    public var goalId: UUID
    public var goalName: String
    public var percent: Decimal
    public var amount: Decimal

    public init(
        id: UUID = UUID(),
        goalId: UUID,
        goalName: String,
        percent: Decimal,
        amount: Decimal
    ) {
        self.id = id
        self.goalId = goalId
        self.goalName = goalName
        self.percent = percent
        self.amount = amount
    }
}

// MARK: - History

public enum HistoryKind: String, Equatable, Sendable {
    case opening
    case credit
    case manualAdd
    case transfer
    case delete
    case withdrawal
}

public struct HistoryEntry: Identifiable, Equatable, Sendable {
    public let id: UUID
    public var kind: HistoryKind
    public var amount: Decimal
    public var slices: [Slice]
    public var overrideUsed: Bool
    public var saved: Bool
    public var date: Date
    public var note: String

    public init(
        id: UUID = UUID(),
        kind: HistoryKind,
        amount: Decimal,
        slices: [Slice],
        overrideUsed: Bool = false,
        saved: Bool = false,
        date: Date,
        note: String = ""
    ) {
        self.id = id
        self.kind = kind
        self.amount = amount
        self.slices = slices
        self.overrideUsed = overrideUsed
        self.saved = saved
        self.date = date
        self.note = note
    }

    public var isCreditKind: Bool {
        kind == .credit || kind == .manualAdd
    }
}
