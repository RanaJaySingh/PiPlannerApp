import Foundation

public final class MockBalanceService: @unchecked Sendable {
    private var fetchCount = 0
    public let openingBalance: Decimal = 100_000
    public let syncedBalance: Decimal = 150_000

    public init() {}

    public func reset() {
        fetchCount = 0
    }

    public func fetchBalance(on date: Date) -> Snapshot {
        fetchCount += 1
        let balance = fetchCount == 1 ? openingBalance : syncedBalance
        return Snapshot(balance: balance, date: date, source: .fetched)
    }

    public var hasFetchedOnce: Bool { fetchCount >= 1 }
    public var fetchCountValue: Int { fetchCount }
}
