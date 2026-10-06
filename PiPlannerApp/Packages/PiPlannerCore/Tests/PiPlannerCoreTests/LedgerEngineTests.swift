import XCTest
@testable import PiPlannerCore

final class LedgerEngineTests: XCTestCase {
    var engine: LedgerEngine!

    override func setUp() {
        super.setUp()
        engine = LedgerEngine()
    }

    // MARK: - Opening 60/40

    func testOpeningSplit_60_40() throws {
        try runConsentOnSetup()
        let opening = try XCTUnwrap(engine.history.first { $0.kind == .opening })
        XCTAssertTrue(opening.saved)
        XCTAssertEqual(opening.amount, 100_000)
        let carSlice = try XCTUnwrap(opening.slices.first { $0.goalName == "Car" })
        let emSlice = try XCTUnwrap(opening.slices.first { $0.goalName == "Emergency" })
        XCTAssertEqual(carSlice.percent, 60)
        XCTAssertEqual(emSlice.percent, 40)
        XCTAssertEqual(carSlice.amount, 60_000)
        XCTAssertEqual(emSlice.amount, 40_000)
        XCTAssertEqual(engine.goals.first { $0.name == "Car" }?.saved, 60_000)
        XCTAssertEqual(engine.goals.first { $0.name == "Emergency" }?.saved, 40_000)
    }

    func testInflationAdjusted_andRequiredPerMonth() throws {
        try runConsentOnSetup()
        let car = try XCTUnwrap(engine.goals.first { $0.name == "Car" })
        let today = LedgerEngine.demoToday
        let targetDate = engine.calendar.date(from: DateComponents(year: 2028, month: 3, day: 1))!
        let months = InflationMath.monthsRemaining(from: today, to: targetDate, calendar: engine.calendar)
        XCTAssertEqual(months, 24)
        XCTAssertEqual(engine.adjustedTarget(for: car), Decimal(1_144_900))
        XCTAssertEqual(engine.requiredPerMonth(for: car), Decimal(45_204))
    }

    // MARK: - Sync +50,000

    func testSync_delta50000_oneTimeOverride() throws {
        try runConsentOnSetup()
        let entry = try engine.sync()
        XCTAssertEqual(entry.amount, 50_000)
        XCTAssertFalse(entry.saved)
        XCTAssertEqual(engine.lastSnapshot?.balance, 150_000)

        _ = try engine.overrideCreditSplit(
            entryId: entry.id,
            allocations: [
                (goalId: engine.goals.first { $0.name == "Car" }!.id, name: "Car", percent: 50, target: nil, targetDate: nil),
                (goalId: engine.goals.first { $0.name == "Emergency" }!.id, name: "Emergency", percent: 30, target: nil, targetDate: nil),
                (goalId: nil, name: "Vacation", percent: 20, target: 50_000, targetDate: nil)
            ]
        )
        let saved = try engine.saveHistoryEntry(id: entry.id)
        XCTAssertTrue(saved.saved)
        XCTAssertTrue(saved.overrideUsed)

        XCTAssertEqual(engine.goals.first { $0.name == "Car" }?.saved, 60_000 + 25_000)
        XCTAssertEqual(engine.goals.first { $0.name == "Emergency" }?.saved, 40_000 + 15_000)
        XCTAssertEqual(engine.goals.first { $0.name == "Vacation" }?.saved, 10_000)

        let opening = try XCTUnwrap(engine.history.first { $0.kind == .opening })
        XCTAssertEqual(opening.slices.first { $0.goalName == "Car" }?.percent, 60)

        XCTAssertThrowsError(try engine.overrideCreditSplit(
            entryId: entry.id,
            allocations: [
                (goalId: engine.goals.first { $0.name == "Car" }!.id, name: "Car", percent: 100, target: nil, targetDate: nil)
            ]
        ))
    }

    // MARK: - One-goal 100%

    func testOneGoal_100Percent_skipsSplitNeed() throws {
        XCTAssertTrue(engine.setDedicatedAccount(id: engine.accounts[0].id))
        engine.setConsent(.allowed)
        _ = engine.fetchOpeningBalance()
        engine.replaceGoals(engine.proposeSingleGoal())
        XCTAssertTrue(engine.shouldSkipSplitUI)
        XCTAssertEqual(engine.goals[0].standingPercent, 100)
        _ = try engine.lockOpeningSplit()
        let opening = try XCTUnwrap(engine.history.first { $0.kind == .opening })
        XCTAssertEqual(opening.slices.count, 1)
        XCTAssertEqual(opening.slices[0].percent, 100)
        XCTAssertEqual(opening.slices[0].amount, 100_000)
        XCTAssertEqual(engine.goals[0].saved, 100_000)

        let credit = try engine.sync()
        XCTAssertEqual(credit.amount, 50_000)
        XCTAssertEqual(credit.slices.count, 1)
        XCTAssertEqual(credit.slices[0].percent, 100)
        XCTAssertEqual(credit.slices[0].amount, 50_000)
    }

    // MARK: - Open-once override

    func testOpenOnceOverride_thenLocked() throws {
        try runConsentOnSetup()
        let entry = try engine.sync()
        XCTAssertFalse(entry.overrideUsed)
        _ = try engine.overrideCreditSplit(
            entryId: entry.id,
            allocations: [
                (goalId: engine.goals[0].id, name: engine.goals[0].name, percent: 70, target: nil, targetDate: nil),
                (goalId: engine.goals[1].id, name: engine.goals[1].name, percent: 30, target: nil, targetDate: nil)
            ]
        )
        _ = try engine.saveHistoryEntry(id: entry.id)
        let locked = try XCTUnwrap(engine.historyEntry(id: entry.id))
        XCTAssertTrue(locked.saved)
        XCTAssertTrue(locked.overrideUsed)
        XCTAssertThrowsError(try engine.saveHistoryEntry(id: entry.id))
        XCTAssertThrowsError(try engine.overrideCreditSplit(
            entryId: entry.id,
            allocations: [
                (goalId: engine.goals[0].id, name: engine.goals[0].name, percent: 100, target: nil, targetDate: nil)
            ]
        ))
    }

    // MARK: - Consent paths (state level)

    func testConsentYes_autoFetch() throws {
        XCTAssertTrue(engine.setDedicatedAccount(id: engine.accounts[0].id))
        engine.setConsent(.allowed)
        let snap = engine.fetchOpeningBalance()
        XCTAssertEqual(snap.balance, 100_000)
        XCTAssertEqual(snap.source, .fetched)
        XCTAssertEqual(engine.consent, .allowed)
    }

    func testConsentNo_manualPath() throws {
        XCTAssertTrue(engine.setDedicatedAccount(id: engine.accounts[0].id))
        engine.setConsent(.denied)
        engine.setConsentOffPath(.manual)
        engine.setManualOpeningBalance(100_000)
        engine.replaceGoals(engine.proposeDefaultGoals())
        _ = try engine.lockOpeningSplit()

        engine.setConsentOffPath(.manual)
        XCTAssertThrowsError(try engine.sync())

        let entry = try engine.addAmount(50_000)
        XCTAssertEqual(entry.kind, .manualAdd)
        XCTAssertEqual(entry.amount, 50_000)
        XCTAssertFalse(entry.saved)
        XCTAssertEqual(engine.lastSnapshot?.balance, 150_000)
    }

    func testConsentNo_balanceSync_requiresPinWhenLinked() throws {
        XCTAssertTrue(engine.setDedicatedAccount(id: engine.accounts[0].id))
        XCTAssertTrue(engine.needsUPIPinForBalanceSync)
        engine.setConsent(.denied)
        engine.setConsentOffPath(.balanceSync)
        XCTAssertThrowsError(try engine.fetchOpeningBalanceViaConsentOffSync()) { err in
            XCTAssertEqual(err as? LedgerError, .pinRequired)
        }
        XCTAssertTrue(engine.verifyUPIPin("1234"))
        let snap = try engine.fetchOpeningBalanceViaConsentOffSync()
        XCTAssertEqual(snap.balance, 100_000)
        engine.replaceGoals(engine.proposeDefaultGoals())
        _ = try engine.lockOpeningSplit()
        let credit = try engine.sync()
        XCTAssertEqual(credit.amount, 50_000)
    }

    func testConsentNo_balanceSync_noPinWhenNotLinked() throws {
        XCTAssertTrue(engine.setDedicatedAccount(id: engine.accounts[1].id))
        XCTAssertFalse(engine.needsUPIPinForBalanceSync)
        engine.setConsent(.denied)
        engine.setConsentOffPath(.balanceSync)
        let snap = try engine.fetchOpeningBalanceViaConsentOffSync()
        XCTAssertEqual(snap.balance, 100_000)
    }

    func testExactlyOneDedicated() {
        XCTAssertFalse(engine.hasExactlyOneDedicated)
        XCTAssertTrue(engine.setDedicatedAccount(id: engine.accounts[1].id))
        XCTAssertTrue(engine.hasExactlyOneDedicated)
        XCTAssertEqual(engine.dedicatedAccount?.maskedLabel, "XXXX 7730")
        XCTAssertTrue(engine.setDedicatedAccount(id: engine.accounts[0].id))
        XCTAssertEqual(engine.accounts.filter(\.isDedicated).count, 1)
    }

    func testPercentsMustSumTo100_beforeLock() {
        XCTAssertTrue(engine.setDedicatedAccount(id: engine.accounts[0].id))
        engine.setConsent(.allowed)
        _ = engine.fetchOpeningBalance()
        var goals = engine.proposeDefaultGoals()
        goals[0].standingPercent = 70
        goals[1].standingPercent = 20
        engine.replaceGoals(goals)
        XCTAssertThrowsError(try engine.lockOpeningSplit()) { error in
            XCTAssertEqual(error as? LedgerError, .percentsMustSumTo100)
        }
    }

    func testResetDemo() throws {
        try runConsentOnSetup()
        _ = try engine.sync()
        engine.resetDemo()
        XCTAssertFalse(engine.isSetupComplete)
        XCTAssertNil(engine.consent)
        XCTAssertTrue(engine.goals.isEmpty)
        XCTAssertTrue(engine.history.isEmpty)
        XCTAssertNil(engine.lastSnapshot)
        XCTAssertFalse(engine.pinVerified)
    }

    // MARK: - Transfer

    func testTransfer_betweenGoals() throws {
        try runConsentOnSetup()
        let car = try XCTUnwrap(engine.goals.first { $0.name == "Car" })
        let em = try XCTUnwrap(engine.goals.first { $0.name == "Emergency" })
        let entry = try engine.transfer(from: car.id, to: em.id, amount: 10_000)
        XCTAssertEqual(entry.kind, .transfer)
        XCTAssertTrue(entry.saved)
        XCTAssertEqual(engine.goals.first { $0.name == "Car" }?.saved, 50_000)
        XCTAssertEqual(engine.goals.first { $0.name == "Emergency" }?.saved, 50_000)
        XCTAssertThrowsError(try engine.transfer(from: car.id, to: em.id, amount: 999_999))
    }

    // MARK: - Delete redistribution

    func testDelete_redistributesSavedAndStanding() throws {
        try runConsentOnSetup()
        let em = try XCTUnwrap(engine.goals.first { $0.name == "Emergency" })
        let car = try XCTUnwrap(engine.goals.first { $0.name == "Car" })
        let entry = try engine.deleteGoal(
            id: em.id,
            redistribution: [(goalId: car.id, percent: 100)]
        )
        XCTAssertEqual(entry.kind, .delete)
        XCTAssertEqual(entry.amount, 40_000)
        XCTAssertNil(engine.goals.first { $0.name == "Emergency" })
        XCTAssertEqual(engine.goals.count, 1)
        XCTAssertEqual(engine.goals[0].name, "Car")
        XCTAssertEqual(engine.goals[0].saved, 100_000)
        XCTAssertEqual(engine.goals[0].standingPercent, 100)
    }

    func testDelete_equalRedistributionDefaults() throws {
        try runConsentOnSetup()
        let vacationDate = engine.calendar.date(from: DateComponents(year: 2029, month: 6, day: 1))!
        _ = engine.addGoal(Goal(name: "Vacation", target: 50_000, targetDate: vacationDate, standingPercent: 0, saved: 0))
        let car = try XCTUnwrap(engine.goals.first { $0.name == "Car" })
        let vac = try XCTUnwrap(engine.goals.first { $0.name == "Vacation" })
        _ = try engine.transfer(from: car.id, to: vac.id, amount: 10_000)
        let defaults = engine.defaultRedistribution(forDeletedGoalId: vac.id)
        XCTAssertEqual(defaults.count, 2)
        let sum = defaults.map(\.percent).reduce(Decimal(0), +)
        XCTAssertEqual(sum, 100)
        _ = try engine.deleteGoal(id: vac.id, redistribution: defaults)
        XCTAssertNil(engine.goals.first { $0.name == "Vacation" })
        XCTAssertEqual(engine.goals.count, 2)
        let carSaved = try XCTUnwrap(engine.goals.first { $0.name == "Car" }?.saved)
        let emSaved = try XCTUnwrap(engine.goals.first { $0.name == "Emergency" }?.saved)
        XCTAssertEqual(carSaved + emSaved, 100_000)
    }

    // MARK: - Withdrawal

    func testWithdrawal_reducesSaved() throws {
        try runConsentOnSetup()
        let car = try XCTUnwrap(engine.goals.first { $0.name == "Car" })
        let entry = try engine.withdraw(from: car.id, amount: 5_000)
        XCTAssertEqual(entry.kind, .withdrawal)
        XCTAssertTrue(entry.saved)
        XCTAssertEqual(engine.goals.first { $0.name == "Car" }?.saved, 55_000)
        XCTAssertEqual(engine.lastSnapshot?.balance, 95_000)
        XCTAssertThrowsError(try engine.withdraw(from: car.id, amount: 999_999))
    }

    // MARK: - Template copy (Grok fallback)

    func testTemplateCopy_proposalAndTransfer() async {
        let copy = TemplateCopyProvider()
        let proposal = await copy.proposal(context: CopyContext(
            goalNames: ["Car", "Emergency"],
            percents: [60, 40]
        ))
        XCTAssertTrue(proposal.contains("Car"))
        XCTAssertTrue(proposal.contains("60"))
        let transfer = await copy.transferNarration(context: CopyContext(
            goalNames: ["Car", "Emergency"],
            amounts: [10_000]
        ))
        XCTAssertTrue(transfer.contains("Car") || transfer.lowercased().contains("moving"))
        XCTAssertEqual(copy.text(for: .welcomeCta), "Set up savings")
        let grok = GrokCopyProvider(endpoint: nil, apiKey: nil)
        XCTAssertFalse(grok.isConfigured)
    }

    // MARK: - Helpers

    private func runConsentOnSetup() throws {
        XCTAssertTrue(engine.setDedicatedAccount(id: engine.accounts[0].id))
        engine.setConsent(.allowed)
        let snap = engine.fetchOpeningBalance()
        XCTAssertEqual(snap.balance, 100_000)
        engine.replaceGoals(engine.proposeDefaultGoals())
        XCTAssertTrue(engine.standingPercentsSumTo100())
        _ = try engine.lockOpeningSplit()
        XCTAssertTrue(engine.isSetupComplete)
    }
}
