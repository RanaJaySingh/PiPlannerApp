import Foundation

public struct CopyContext: Sendable {
    public var goalNames: [String]
    public var percents: [Decimal]
    public var amounts: [Decimal]
    public var dates: [String]
    public var inflationRates: [Decimal]
    public var status: String

    public init(
        goalNames: [String] = [],
        percents: [Decimal] = [],
        amounts: [Decimal] = [],
        dates: [String] = [],
        inflationRates: [Decimal] = [],
        status: String = ""
    ) {
        self.goalNames = goalNames
        self.percents = percents
        self.amounts = amounts
        self.dates = dates
        self.inflationRates = inflationRates
        self.status = status
    }
}

public protocol CopyProvider: Sendable {
    func text(for key: CopyKey) -> String
    func proposal(context: CopyContext) async -> String
    func inflationSentence(context: CopyContext) async -> String
    func syncNarration(context: CopyContext) async -> String
    func transferNarration(context: CopyContext) async -> String
    func askAnswer(question: String, context: CopyContext) async -> String
}
