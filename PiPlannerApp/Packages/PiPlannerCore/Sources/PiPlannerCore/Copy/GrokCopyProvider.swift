import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public final class GrokCopyProvider: CopyProvider, @unchecked Sendable {
    private let fallback: TemplateCopyProvider
    private let endpoint: URL?
    private let apiKey: String?
    private let session: URLSession
    private let timeout: TimeInterval

    public init(
        endpoint: URL? = GrokCopyProvider.resolveEndpoint(),
        apiKey: String? = GrokCopyProvider.resolveAPIKey(),
        timeout: TimeInterval = 2.5,
        fallback: TemplateCopyProvider = TemplateCopyProvider()
    ) {
        self.endpoint = endpoint
        self.apiKey = apiKey
        self.timeout = timeout
        self.fallback = fallback
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = timeout
        config.timeoutIntervalForResource = timeout
        self.session = URLSession(configuration: config)
    }

    public var isConfigured: Bool {
        endpoint != nil && !(apiKey ?? "").isEmpty
    }

    public func text(for key: CopyKey) -> String {
        fallback.text(for: key)
    }

    public func proposal(context: CopyContext) async -> String {
        if let text = await generate(kind: "proposal", context: context) { return text }
        return await fallback.proposal(context: context)
    }

    public func inflationSentence(context: CopyContext) async -> String {
        if let text = await generate(kind: "inflation", context: context) { return text }
        return await fallback.inflationSentence(context: context)
    }

    public func syncNarration(context: CopyContext) async -> String {
        if let text = await generate(kind: "sync", context: context) { return text }
        return await fallback.syncNarration(context: context)
    }

    public func transferNarration(context: CopyContext) async -> String {
        if let text = await generate(kind: "transfer", context: context) { return text }
        return await fallback.transferNarration(context: context)
    }

    public func askAnswer(question: String, context: CopyContext) async -> String {
        if let text = await generate(kind: "ask", context: context, question: question) { return text }
        return await fallback.askAnswer(question: question, context: context)
    }

    private func generate(kind: String, context: CopyContext, question: String? = nil) async -> String? {
        guard isConfigured, let endpoint else { return nil }
        var payload: [String: Any] = [
            "kind": kind,
            "goalNames": context.goalNames,
            "percents": context.percents.map { NSDecimalNumber(decimal: $0).stringValue },
            "amounts": context.amounts.map { NSDecimalNumber(decimal: $0).stringValue },
            "dates": context.dates,
            "inflationRates": context.inflationRates.map { NSDecimalNumber(decimal: $0).stringValue },
            "status": context.status
        ]
        if let question { payload["question"] = question }

        guard let body = try? JSONSerialization.data(withJSONObject: payload) else { return nil }
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let apiKey {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = body
        request.timeoutInterval = timeout

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                return nil
            }
            if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let text = obj["text"] as? String, !text.isEmpty {
                return text
            }
            if let text = String(data: data, encoding: .utf8), !text.isEmpty {
                return text
            }
            return nil
        } catch {
            return nil
        }
    }

    public static func resolveEndpoint() -> URL? {
        if let env = ProcessInfo.processInfo.environment["GROK_ENDPOINT"], let url = URL(string: env) {
            return url
        }
        #if canImport(UIKit) || canImport(AppKit)
        if let plist = Bundle.main.object(forInfoDictionaryKey: "GROK_ENDPOINT") as? String,
           let url = URL(string: plist) {
            return url
        }
        #endif
        return nil
    }

    public static func resolveAPIKey() -> String? {
        if let env = ProcessInfo.processInfo.environment["GROK_API_KEY"], !env.isEmpty {
            return env
        }
        #if canImport(UIKit) || canImport(AppKit)
        if let plist = Bundle.main.object(forInfoDictionaryKey: "GROK_API_KEY") as? String, !plist.isEmpty {
            return plist
        }
        #endif
        return nil
    }
}
