import Foundation

public struct TemplateCopyProvider: CopyProvider {
    public init() {}

    public func text(for key: CopyKey) -> String {
        switch key {
        case .welcomeTagline: return "Every Rupee Has a Plan."
        case .welcomeSubtitle: return "Every credit to savings gets a goal before it can be spent."
        case .welcomeCta: return "Set up savings"
        case .welcomeCaption: return "Powered by Grok · templates"
        case .accountsDedicated: return "Dedicated savings"
        case .accountsSpendingNote: return "everyday Paytm spend"
        case .consentAllow: return "Allow balance sync"
        case .consentManual: return "Enter amounts myself"
        case .goalsGreeting: return "Good evening, Rahul"
        case .openingLock: return "Lock this split"
        case .inflationLabel: return "Estimate, not a guarantee"
        case .askStarterSplit: return "What happens if I change the split?"
        case .askStarterInflation: return "Why is inflation 7%?"
        case .askStarterTransfer: return "Should I transfer from Emergency to Car?"
        case .withdrawTitle: return "Withdraw from a goal"
        }
    }

    public func proposal(context: CopyContext) async -> String {
        if context.goalNames.count >= 2, context.percents.count >= 2 {
            let a = context.goalNames[0]
            let b = context.goalNames[1]
            let pa = context.percents[0]
            let pb = context.percents[1]
            return "Based on your goals, I suggest \(a) \(pa)% and \(b) \(pb)%. You can edit before locking."
        }
        if context.goalNames.count == 1 {
            return "One goal — \(context.goalNames[0]) gets 100%. Split screen is skipped."
        }
        return "Here's a starting split for your goals. Adjust percentages so they add up to 100%."
    }

    public func inflationSentence(context: CopyContext) async -> String {
        let rate = context.inflationRates.first ?? Decimal(string: "0.07")!
        let pct = (rate * 100).rounded(toPlaces: 0)
        if let adjusted = context.amounts.first, let name = context.goalNames.first {
            return "At \(pct)% inflation, \(name)'s target becomes about \(Self.formatINR(adjusted)). Estimate, not a guarantee."
        }
        return "We apply a \(pct)% inflation estimate so your monthly target keeps pace with prices. Estimate, not a guarantee."
    }

    public func syncNarration(context: CopyContext) async -> String {
        if let amount = context.amounts.first {
            return "Naya paisa aaya: \(Self.formatINR(amount))"
        }
        return "Naya paisa aaya — allocate it to your goals."
    }

    public func transferNarration(context: CopyContext) async -> String {
        if context.goalNames.count >= 2, let amount = context.amounts.first {
            return "Moving \(Self.formatINR(amount)) from \(context.goalNames[0]) → \(context.goalNames[1]). Past History stays locked; only saved pools change."
        }
        return "Transfer moves saved rupees between goals. Standing % for the next credit is unchanged unless you edit Standing split."
    }

    public func askAnswer(question: String, context: CopyContext) async -> String {
        let q = question.lowercased()
        if q.contains("transfer") {
            return await transferNarration(context: context)
        }
        if q.contains("split") || q.contains("change") {
            let standing = zip(context.goalNames, context.percents)
                .map { "\($0.0) \($0.1)%" }
                .joined(separator: ", ")
            return "Changing the split updates standing percentages for the next credit only. Past History entries stay as saved. Current standing: \(standing). Percentages must sum to 100 before you lock or save."
        }
        if q.contains("inflation") || q.contains("7%") || q.contains("7 %") {
            let rate = context.inflationRates.first ?? Decimal(string: "0.07")!
            let pct = (rate * 100).rounded(toPlaces: 0)
            if let adjusted = context.amounts.first, let name = context.goalNames.first, let required = context.amounts.dropFirst().first {
                return "Inflation \(pct)% is an estimate, not a guarantee. For \(name), the inflation-adjusted target is \(Self.formatINR(adjusted)) and required savings are about \(Self.formatINR(required)) per month (from the ledger engine)."
            }
            return "The \(pct)% inflation rate is an estimate used only to pace monthly savings. All rupee figures come from the ledger engine, not from Grok."
        }
        if q.contains("withdraw") {
            return "Withdrawal reduces a goal's saved amount and the dedicated balance snapshot. It never touches real banks — mock only."
        }
        if !context.status.isEmpty {
            return context.status
        }
        let names = context.goalNames.joined(separator: ", ")
        return "PiPlanner allocates every credit to your goals (\(names)). Numbers always come from the savings engine."
    }

    private static func formatINR(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₹"
        formatter.locale = Locale(identifier: "en_IN")
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        return formatter.string(from: value as NSDecimalNumber) ?? "₹\(value)"
    }
}
