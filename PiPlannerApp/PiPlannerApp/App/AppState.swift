import Foundation
import Observation

enum SetupRoute: Hashable {
    case accounts
    case consent
    case updateBalance
    case upiPin
    case manualAmount
    case goalChat
    case goalForm
    case inflation
    case openingSplit
}

enum MainTab: Hashable {
    case goals
    case history
    case ask
    case settings
}

@Observable
final class AppState {
    var engine: LedgerEngine
    var copyProvider: any CopyProvider
    var setupPath: [SetupRoute] = []
    var selectedTab: MainTab = .goals
    var showInflationSheet = false
    var activeHistoryEntryId: UUID?
    var historyPresentation = HistoryPresentation()
    var syncNarration: String = ""
    var proposalText: String = ""
    var inflationText: String = ""
    var transferNarration: String = ""
    var askAnswer: String = ""
    var toast: String?
    var openingCaptured = false

    init(
        engine: LedgerEngine = LedgerEngine(),
        copyProvider: (any CopyProvider)? = nil
    ) {
        self.engine = engine
        let grok = GrokCopyProvider()
        self.copyProvider = copyProvider ?? (grok.isConfigured ? grok : TemplateCopyProvider())
    }

    var isLocked: Bool { engine.isSetupComplete }

    func openNewHistoryEntry(_ id: UUID) {
        activeHistoryEntryId = id
        historyPresentation.presentNewEntry(id)
        selectedTab = .history
    }

    func resetDemo() {
        engine.resetDemo()
        setupPath = []
        selectedTab = .goals
        showInflationSheet = false
        activeHistoryEntryId = nil
        historyPresentation.reset()
        syncNarration = ""
        proposalText = ""
        inflationText = ""
        transferNarration = ""
        askAnswer = ""
        toast = nil
        openingCaptured = false
    }

    func greeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        let part: String
        switch hour {
        case 5..<12: part = "morning"
        case 12..<17: part = "afternoon"
        default: part = "evening"
        }
        return "Good \(part), Rahul"
    }

    func copyContext() -> CopyContext {
        CopyContext(
            goalNames: engine.goals.map(\.name),
            percents: engine.goals.map(\.standingPercent),
            amounts: engine.goals.map { engine.adjustedTarget(for: $0) } + engine.goals.map { engine.requiredPerMonth(for: $0) },
            dates: engine.goals.map { Self.dateString($0.targetDate) },
            inflationRates: engine.goals.map(\.inflationRate),
            status: syncNarration
        )
    }

    private static func dateString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM yyyy"
        f.locale = Locale(identifier: "en_IN")
        return f.string(from: date)
    }

    @MainActor
    func loadProposal() async {
        let template = TemplateCopyProvider()
        let ctx = CopyContext(
            goalNames: engine.goals.map(\.name),
            percents: engine.goals.map(\.standingPercent)
        )
        proposalText = await template.proposal(context: ctx)
        let upgraded = await copyProvider.proposal(context: ctx)
        if upgraded != proposalText {
            proposalText = upgraded
        }
    }

    @MainActor
    func loadInflationCopy() async {
        guard let car = engine.goals.first(where: { $0.name == "Car" }) ?? engine.goals.first else { return }
        let ctx = CopyContext(
            goalNames: [car.name],
            amounts: [engine.adjustedTarget(for: car)],
            inflationRates: [car.inflationRate]
        )
        let template = TemplateCopyProvider()
        inflationText = await template.inflationSentence(context: ctx)
        let upgraded = await copyProvider.inflationSentence(context: ctx)
        if upgraded != inflationText {
            inflationText = upgraded
        }
    }

    @MainActor
    func loadSyncNarration(amount: Decimal) async {
        let ctx = CopyContext(amounts: [amount])
        let template = TemplateCopyProvider()
        syncNarration = await template.syncNarration(context: ctx)
        let upgraded = await copyProvider.syncNarration(context: ctx)
        if upgraded != syncNarration {
            syncNarration = upgraded
        }
    }

    @MainActor
    func loadTransferNarration(from: String, to: String, amount: Decimal) async {
        let ctx = CopyContext(goalNames: [from, to], amounts: [amount])
        let template = TemplateCopyProvider()
        transferNarration = await template.transferNarration(context: ctx)
        let upgraded = await copyProvider.transferNarration(context: ctx)
        if upgraded != transferNarration {
            transferNarration = upgraded
        }
    }

    @MainActor
    func answerAsk(_ question: String) async {
        guard let car = engine.goals.first(where: { $0.name == "Car" }) ?? engine.goals.first else {
            askAnswer = "Set up goals first to get engine-backed answers."
            return
        }
        let ctx = CopyContext(
            goalNames: engine.goals.map(\.name),
            percents: engine.goals.map(\.standingPercent),
            amounts: [engine.adjustedTarget(for: car), engine.requiredPerMonth(for: car)],
            inflationRates: engine.goals.map(\.inflationRate),
            status: "Dedicated balance \(INRFormatting.string(engine.dedicatedBalance))"
        )
        let template = TemplateCopyProvider()
        askAnswer = await template.askAnswer(question: question, context: ctx)
        let upgraded = await copyProvider.askAnswer(question: question, context: ctx)
        if upgraded != askAnswer {
            askAnswer = upgraded
        }
    }
}
