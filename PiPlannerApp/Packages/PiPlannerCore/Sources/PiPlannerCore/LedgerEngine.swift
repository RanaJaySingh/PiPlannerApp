import Foundation

public final class LedgerEngine: @unchecked Sendable {
    public private(set) var accounts: [Account]
    public private(set) var consent: ConsentMode?
    public private(set) var consentOffPath: ConsentOffBalancePath?
    public private(set) var goals: [Goal]
    public private(set) var history: [HistoryEntry]
    public private(set) var lastSnapshot: Snapshot?
    public private(set) var isSetupComplete: Bool
    public private(set) var pendingPercents: [UUID: Decimal]
    public private(set) var pinVerified: Bool

    public let clock: () -> Date
    public let balanceService: MockBalanceService
    public let calendar: Calendar

    public static var demoToday: Date {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Kolkata") ?? .current
        return cal.date(from: DateComponents(year: 2026, month: 10, day: 6))!
    }

    public init(
        clock: @escaping () -> Date = { LedgerEngine.demoToday },
        balanceService: MockBalanceService = MockBalanceService(),
        calendar: Calendar? = nil
    ) {
        self.clock = clock
        self.balanceService = balanceService
        var cal = calendar ?? Calendar(identifier: .gregorian)
        if calendar == nil {
            cal.timeZone = TimeZone(identifier: "Asia/Kolkata") ?? .current
        }
        self.calendar = cal
        self.accounts = Self.defaultAccounts()
        self.consent = nil
        self.consentOffPath = nil
        self.goals = []
        self.history = []
        self.lastSnapshot = nil
        self.isSetupComplete = false
        self.pendingPercents = [:]
        self.pinVerified = false
    }

    // MARK: - Reset

    public func resetDemo() {
        balanceService.reset()
        accounts = Self.defaultAccounts()
        consent = nil
        consentOffPath = nil
        goals = []
        history = []
        lastSnapshot = nil
        isSetupComplete = false
        pendingPercents = [:]
        pinVerified = false
    }

    // MARK: - Accounts

    public static func defaultAccounts() -> [Account] {
        [
            Account(
                id: UUID(uuidString: "AAAAAAAA-0001-0001-0001-000000000001")!,
                maskedLabel: "XXXX 4821",
                isDedicated: false,
                displayName: "Paytm Payments Bank",
                linkedInPaytm: true
            ),
            Account(
                id: UUID(uuidString: "AAAAAAAA-0001-0001-0001-000000000002")!,
                maskedLabel: "XXXX 7730",
                isDedicated: false,
                displayName: "HDFC Savings",
                linkedInPaytm: false
            ),
            Account(
                id: UUID(uuidString: "AAAAAAAA-0001-0001-0001-000000000003")!,
                maskedLabel: "XXXX 1194",
                isDedicated: false,
                displayName: "Paytm UPI Lite",
                linkedInPaytm: true
            )
        ]
    }

    @discardableResult
    public func setDedicatedAccount(id: UUID) -> Bool {
        guard accounts.contains(where: { $0.id == id }) else { return false }
        accounts = accounts.map { acc in
            var a = acc
            a.isDedicated = (a.id == id)
            return a
        }
        return true
    }

    public var dedicatedAccount: Account? {
        accounts.first(where: \.isDedicated)
    }

    public var hasExactlyOneDedicated: Bool {
        accounts.filter(\.isDedicated).count == 1
    }

    public var needsUPIPinForBalanceSync: Bool {
        dedicatedAccount?.linkedInPaytm == true
    }

    // MARK: - Consent & opening

    public func setConsent(_ mode: ConsentMode) {
        consent = mode
        if mode == .allowed {
            consentOffPath = nil
            pinVerified = false
        }
    }

    public func setConsentOffPath(_ path: ConsentOffBalancePath) {
        consentOffPath = path
        if path == .manual {
            pinVerified = false
        }
    }

    @discardableResult
    public func verifyUPIPin(_ pin: String) -> Bool {
        let digits = pin.filter(\.isNumber)
        guard digits.count >= 4 && digits.count <= 6 else { return false }
        pinVerified = true
        return true
    }

    @discardableResult
    public func fetchOpeningBalance() -> Snapshot {
        let snap = balanceService.fetchBalance(on: clock())
        lastSnapshot = snap
        return snap
    }

    @discardableResult
    public func fetchOpeningBalanceViaConsentOffSync() throws -> Snapshot {
        guard consent == .denied else { throw LedgerError.invalidConsentPath }
        guard consentOffPath == .balanceSync else { throw LedgerError.invalidConsentPath }
        if needsUPIPinForBalanceSync && !pinVerified {
            throw LedgerError.pinRequired
        }
        return fetchOpeningBalance()
    }

    public func setManualOpeningBalance(_ amount: Decimal) {
        lastSnapshot = Snapshot(balance: amount, date: clock(), source: .typed)
    }

    public var openingBalance: Decimal {
        lastSnapshot?.balance ?? 0
    }

    // MARK: - Goals (setup)

    public func replaceGoals(_ newGoals: [Goal]) {
        var goalsToSet = newGoals
        if goalsToSet.count == 1 {
            goalsToSet[0].standingPercent = 100
        }
        goals = goalsToSet
        pendingPercents = Dictionary(uniqueKeysWithValues: goalsToSet.map { ($0.id, $0.standingPercent) })
    }

    public var shouldSkipSplitUI: Bool {
        goals.count == 1
    }

    public func proposeDefaultGoals() -> [Goal] {
        let carDate = calendar.date(from: DateComponents(year: 2028, month: 3, day: 1))!
        let emergencyDate = calendar.date(from: DateComponents(year: 2030, month: 12, day: 31))!
        return [
            Goal(
                id: UUID(uuidString: "BBBBBBBB-0001-0001-0001-000000000001")!,
                name: "Car",
                target: 1_000_000,
                targetDate: carDate,
                inflationRate: Decimal(string: "0.07")!,
                standingPercent: 60,
                saved: 0
            ),
            Goal(
                id: UUID(uuidString: "BBBBBBBB-0001-0001-0001-000000000002")!,
                name: "Emergency",
                target: 200_000,
                targetDate: emergencyDate,
                inflationRate: Decimal(string: "0.07")!,
                standingPercent: 40,
                saved: 0
            )
        ]
    }

    public func proposeSingleGoal() -> [Goal] {
        let carDate = calendar.date(from: DateComponents(year: 2028, month: 3, day: 1))!
        return [
            Goal(
                id: UUID(uuidString: "BBBBBBBB-0001-0001-0001-000000000001")!,
                name: "Car",
                target: 1_000_000,
                targetDate: carDate,
                inflationRate: Decimal(string: "0.07")!,
                standingPercent: 100,
                saved: 0
            )
        ]
    }

    public func percentsSumTo100(_ percents: [Decimal]) -> Bool {
        percents.reduce(Decimal(0), +) == 100
    }

    public func standingPercentsSumTo100() -> Bool {
        percentsSumTo100(goals.map(\.standingPercent))
    }

    public func updateStandingPercent(goalId: UUID, percent: Decimal) {
        guard let idx = goals.firstIndex(where: { $0.id == goalId }) else { return }
        goals[idx].standingPercent = percent
        pendingPercents[goalId] = percent
    }

    public func updateGoal(
        id: UUID,
        name: String? = nil,
        target: Decimal? = nil,
        targetDate: Date? = nil,
        inflationRate: Decimal? = nil,
        standingPercent: Decimal? = nil
    ) {
        guard let idx = goals.firstIndex(where: { $0.id == id }) else { return }
        if let name { goals[idx].name = name }
        if let target { goals[idx].target = target }
        if let targetDate { goals[idx].targetDate = targetDate }
        if let inflationRate { goals[idx].inflationRate = inflationRate }
        if let standingPercent {
            goals[idx].standingPercent = standingPercent
            pendingPercents[id] = standingPercent
        }
    }

    @discardableResult
    public func addGoal(_ goal: Goal) -> Goal {
        var g = goal
        if goals.isEmpty {
            g.standingPercent = 100
        }
        if pendingPercents[g.id] == nil {
            pendingPercents[g.id] = g.standingPercent
        }
        goals.append(g)
        if goals.count == 1 {
            goals[0].standingPercent = 100
            pendingPercents[goals[0].id] = 100
        }
        return g
    }

    // MARK: - Lock opening split

    @discardableResult
    public func lockOpeningSplit() throws -> HistoryEntry {
        if goals.count == 1 {
            goals[0].standingPercent = 100
            pendingPercents[goals[0].id] = 100
        }
        guard standingPercentsSumTo100() else {
            throw LedgerError.percentsMustSumTo100
        }
        guard let snap = lastSnapshot, snap.balance > 0 else {
            throw LedgerError.noOpeningBalance
        }
        let amount = snap.balance
        let slices = makeSlices(amount: amount, usingStanding: true)
        applySlicesToSaved(slices)
        let entry = HistoryEntry(
            kind: .opening,
            amount: amount,
            slices: slices,
            overrideUsed: false,
            saved: true,
            date: clock(),
            note: "Opening split"
        )
        history.insert(entry, at: 0)
        isSetupComplete = true
        return entry
    }

    // MARK: - Sync / Add amount

    @discardableResult
    public func sync() throws -> HistoryEntry {
        guard consent == .allowed || (consent == .denied && consentOffPath == .balanceSync) else {
            throw LedgerError.syncRequiresConsent
        }
        guard isSetupComplete else { throw LedgerError.setupIncomplete }
        if consent == .denied, needsUPIPinForBalanceSync, !pinVerified {
            throw LedgerError.pinRequired
        }
        let previous = lastSnapshot?.balance ?? 0
        let snap = balanceService.fetchBalance(on: clock())
        lastSnapshot = snap
        let delta = snap.balance - previous
        guard delta > 0 else { throw LedgerError.noPositiveDelta }
        return createUnsavedCredit(amount: delta, kind: .credit, note: "Sync credit")
    }

    @discardableResult
    public func addAmount(_ amount: Decimal) throws -> HistoryEntry {
        guard amount > 0 else { throw LedgerError.invalidAmount }
        guard isSetupComplete else { throw LedgerError.setupIncomplete }
        let previous = lastSnapshot?.balance ?? 0
        lastSnapshot = Snapshot(balance: previous + amount, date: clock(), source: .typed)
        return createUnsavedCredit(amount: amount, kind: .manualAdd, note: "Manual add")
    }

    private func createUnsavedCredit(amount: Decimal, kind: HistoryKind, note: String) -> HistoryEntry {
        if goals.count == 1 {
            goals[0].standingPercent = 100
            pendingPercents[goals[0].id] = 100
        }
        let slices = makeSlices(amount: amount, usingStanding: true)
        let entry = HistoryEntry(
            kind: kind,
            amount: amount,
            slices: slices,
            overrideUsed: false,
            saved: false,
            date: clock(),
            note: note
        )
        history.insert(entry, at: 0)
        return entry
    }

    // MARK: - One-time override on unsaved credit

    @discardableResult
    public func overrideCreditSplit(
        entryId: UUID,
        allocations: [(goalId: UUID?, name: String, percent: Decimal, target: Decimal?, targetDate: Date?)]
    ) throws -> HistoryEntry {
        guard let idx = history.firstIndex(where: { $0.id == entryId }) else {
            throw LedgerError.entryNotFound
        }
        var entry = history[idx]
        guard entry.isCreditKind else { throw LedgerError.overrideNotAllowed }
        guard !entry.saved else { throw LedgerError.alreadySaved }
        guard !entry.overrideUsed else { throw LedgerError.overrideAlreadyUsed }
        let percents = allocations.map(\.percent)
        guard percentsSumTo100(percents) else { throw LedgerError.percentsMustSumTo100 }

        var slices: [Slice] = []
        for alloc in allocations {
            let goalId: UUID
            let goalName: String
            if let existingId = alloc.goalId, let g = goals.first(where: { $0.id == existingId }) {
                goalId = g.id
                goalName = alloc.name.isEmpty ? g.name : alloc.name
            } else {
                let defaultDate = calendar.date(from: DateComponents(year: 2028, month: 6, day: 1))!
                let newGoal = Goal(
                    name: alloc.name,
                    target: alloc.target ?? 100_000,
                    targetDate: alloc.targetDate ?? defaultDate,
                    inflationRate: Decimal(string: "0.07")!,
                    standingPercent: 0,
                    saved: 0
                )
                addGoal(newGoal)
                goalId = newGoal.id
                goalName = newGoal.name
            }
            let sliceAmount = (entry.amount * alloc.percent / 100).rounded(toPlaces: 2)
            slices.append(Slice(goalId: goalId, goalName: goalName, percent: alloc.percent, amount: sliceAmount))
        }
        if !slices.isEmpty {
            let sumExceptLast = slices.dropLast().map(\.amount).reduce(Decimal(0), +)
            slices[slices.count - 1].amount = entry.amount - sumExceptLast
        }

        entry.slices = slices
        entry.overrideUsed = true
        history[idx] = entry
        return entry
    }

    @discardableResult
    public func saveHistoryEntry(id: UUID) throws -> HistoryEntry {
        guard let idx = history.firstIndex(where: { $0.id == id }) else {
            throw LedgerError.entryNotFound
        }
        var entry = history[idx]
        guard !entry.saved else { throw LedgerError.alreadySaved }
        applySlicesToSaved(entry.slices)
        entry.saved = true
        history[idx] = entry
        return entry
    }

    // MARK: - Transfer

    @discardableResult
    public func transfer(from fromId: UUID, to toId: UUID, amount: Decimal) throws -> HistoryEntry {
        guard amount > 0 else { throw LedgerError.invalidAmount }
        guard let fromIdx = goals.firstIndex(where: { $0.id == fromId }),
              let toIdx = goals.firstIndex(where: { $0.id == toId }),
              fromId != toId else {
            throw LedgerError.goalNotFound
        }
        guard goals[fromIdx].saved >= amount else { throw LedgerError.insufficientSaved }

        goals[fromIdx].saved -= amount
        goals[toIdx].saved += amount

        let slices = [
            Slice(goalId: fromId, goalName: goals[fromIdx].name, percent: -100, amount: -amount),
            Slice(goalId: toId, goalName: goals[toIdx].name, percent: 100, amount: amount)
        ]
        let entry = HistoryEntry(
            kind: .transfer,
            amount: amount,
            slices: slices,
            overrideUsed: false,
            saved: true,
            date: clock(),
            note: "Transfer \(goals[fromIdx].name) → \(goals[toIdx].name)"
        )
        history.insert(entry, at: 0)
        return entry
    }

    // MARK: - Delete + redistribute

    public func defaultRedistribution(forDeletedGoalId deletedId: UUID) -> [(goalId: UUID, percent: Decimal)] {
        let remaining = goals.filter { $0.id != deletedId }
        guard !remaining.isEmpty else { return [] }
        let each = (Decimal(100) / Decimal(remaining.count)).rounded(toPlaces: 2)
        var result: [(UUID, Decimal)] = remaining.map { ($0.id, each) }
        if !result.isEmpty {
            let sumExceptLast = result.dropLast().map(\.1).reduce(Decimal(0), +)
            result[result.count - 1].1 = 100 - sumExceptLast
        }
        return result
    }

    @discardableResult
    public func deleteGoal(
        id: UUID,
        redistribution: [(goalId: UUID, percent: Decimal)]
    ) throws -> HistoryEntry {
        guard let idx = goals.firstIndex(where: { $0.id == id }) else {
            throw LedgerError.goalNotFound
        }
        let deleted = goals[idx]
        let amount = deleted.saved
        let percents = redistribution.map(\.percent)
        guard redistribution.isEmpty || percentsSumTo100(percents) else {
            throw LedgerError.percentsMustSumTo100
        }
        for r in redistribution {
            guard goals.contains(where: { $0.id == r.goalId && $0.id != id }) else {
                throw LedgerError.goalNotFound
            }
        }

        var slices: [Slice] = [
            Slice(goalId: deleted.id, goalName: deleted.name, percent: -100, amount: -amount)
        ]
        if amount > 0 && !redistribution.isEmpty {
            for (i, r) in redistribution.enumerated() {
                var sliceAmount = (amount * r.percent / 100).rounded(toPlaces: 2)
                if i == redistribution.count - 1 {
                    let prior = slices.dropFirst().map(\.amount).reduce(Decimal(0), +)
                    sliceAmount = amount - prior
                }
                if let gIdx = goals.firstIndex(where: { $0.id == r.goalId }) {
                    goals[gIdx].saved += sliceAmount
                    slices.append(Slice(
                        goalId: r.goalId,
                        goalName: goals[gIdx].name,
                        percent: r.percent,
                        amount: sliceAmount
                    ))
                }
            }
        }

        let deletedStanding = deleted.standingPercent
        goals.remove(at: idx)
        pendingPercents.removeValue(forKey: id)

        if !goals.isEmpty && deletedStanding > 0 {
            let each = (deletedStanding / Decimal(goals.count)).rounded(toPlaces: 2)
            for i in goals.indices {
                goals[i].standingPercent += each
                pendingPercents[goals[i].id] = goals[i].standingPercent
            }
            let sum = goals.map(\.standingPercent).reduce(Decimal(0), +)
            if sum != 100, let last = goals.indices.last {
                goals[last].standingPercent += (100 - sum)
                pendingPercents[goals[last].id] = goals[last].standingPercent
            }
        }
        if goals.count == 1 {
            goals[0].standingPercent = 100
            pendingPercents[goals[0].id] = 100
        }

        let entry = HistoryEntry(
            kind: .delete,
            amount: amount,
            slices: slices,
            overrideUsed: false,
            saved: true,
            date: clock(),
            note: "Deleted \(deleted.name)"
        )
        history.insert(entry, at: 0)
        return entry
    }

    // MARK: - Withdrawal

    @discardableResult
    public func withdraw(from goalId: UUID, amount: Decimal) throws -> HistoryEntry {
        guard amount > 0 else { throw LedgerError.invalidAmount }
        guard let idx = goals.firstIndex(where: { $0.id == goalId }) else {
            throw LedgerError.goalNotFound
        }
        guard goals[idx].saved >= amount else { throw LedgerError.insufficientSaved }

        goals[idx].saved -= amount
        if let snap = lastSnapshot {
            lastSnapshot = Snapshot(
                balance: max(0, snap.balance - amount),
                date: clock(),
                source: snap.source
            )
        }

        let slices = [
            Slice(goalId: goalId, goalName: goals[idx].name, percent: -100, amount: -amount)
        ]
        let entry = HistoryEntry(
            kind: .withdrawal,
            amount: amount,
            slices: slices,
            overrideUsed: false,
            saved: true,
            date: clock(),
            note: "Withdrawal from \(goals[idx].name)"
        )
        history.insert(entry, at: 0)
        return entry
    }

    // MARK: - Queries

    public func adjustedTarget(for goal: Goal) -> Decimal {
        InflationMath.inflationAdjustedTarget(
            target: goal.target,
            rate: goal.inflationRate,
            from: clock(),
            to: goal.targetDate,
            calendar: calendar
        )
    }

    public func requiredPerMonth(for goal: Goal) -> Decimal {
        InflationMath.requiredPerMonth(
            target: goal.target,
            rate: goal.inflationRate,
            saved: goal.saved,
            from: clock(),
            to: goal.targetDate,
            calendar: calendar
        )
    }

    public func monthsRemaining(for goal: Goal) -> Int {
        InflationMath.monthsRemaining(from: clock(), to: goal.targetDate, calendar: calendar)
    }

    public func historyEntry(id: UUID) -> HistoryEntry? {
        history.first { $0.id == id }
    }

    public var dedicatedBalance: Decimal {
        lastSnapshot?.balance ?? goals.map(\.saved).reduce(0, +)
    }

    // MARK: - Helpers

    private func makeSlices(amount: Decimal, usingStanding: Bool) -> [Slice] {
        var slices: [Slice] = []
        for (i, goal) in goals.enumerated() {
            let pct = usingStanding ? (pendingPercents[goal.id] ?? goal.standingPercent) : goal.standingPercent
            var sliceAmount = (amount * pct / 100).rounded(toPlaces: 2)
            if i == goals.count - 1 {
                let prior = slices.map(\.amount).reduce(Decimal(0), +)
                sliceAmount = amount - prior
            }
            slices.append(Slice(goalId: goal.id, goalName: goal.name, percent: pct, amount: sliceAmount))
        }
        return slices
    }

    private func applySlicesToSaved(_ slices: [Slice]) {
        for slice in slices where slice.amount > 0 {
            if let idx = goals.firstIndex(where: { $0.id == slice.goalId }) {
                goals[idx].saved += slice.amount
            }
        }
    }
}

public enum LedgerError: Error, Equatable, LocalizedError {
    case percentsMustSumTo100
    case noOpeningBalance
    case syncRequiresConsent
    case setupIncomplete
    case noPositiveDelta
    case invalidAmount
    case entryNotFound
    case overrideNotAllowed
    case alreadySaved
    case overrideAlreadyUsed
    case goalNotFound
    case insufficientSaved
    case pinRequired
    case invalidConsentPath

    public var errorDescription: String? {
        switch self {
        case .percentsMustSumTo100: return "Percentages must sum to 100"
        case .noOpeningBalance: return "No opening balance"
        case .syncRequiresConsent: return "Sync requires balance consent or consent-off sync path"
        case .setupIncomplete: return "Setup not complete"
        case .noPositiveDelta: return "No new credit to allocate"
        case .invalidAmount: return "Invalid amount"
        case .entryNotFound: return "History entry not found"
        case .overrideNotAllowed: return "Override not allowed for this entry"
        case .alreadySaved: return "Entry already saved"
        case .overrideAlreadyUsed: return "One-time override already used"
        case .goalNotFound: return "Goal not found"
        case .insufficientSaved: return "Insufficient saved amount"
        case .pinRequired: return "UPI PIN required before balance sync"
        case .invalidConsentPath: return "Invalid consent / balance path"
        }
    }
}
