import Foundation

enum INRFormatting {
    private static let formatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencySymbol = "₹"
        f.locale = Locale(identifier: "en_IN")
        f.maximumFractionDigits = 0
        f.minimumFractionDigits = 0
        return f
    }()

    static func string(_ value: Decimal) -> String {
        formatter.string(from: value as NSDecimalNumber) ?? "₹\(value)"
    }

    static func string(_ value: Int) -> String {
        string(Decimal(value))
    }

    static func parse(_ text: String) -> Decimal? {
        let cleaned = text
            .replacingOccurrences(of: "₹", with: "")
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespaces)
        guard !cleaned.isEmpty, let d = Decimal(string: cleaned) else { return nil }
        return d
    }
}
