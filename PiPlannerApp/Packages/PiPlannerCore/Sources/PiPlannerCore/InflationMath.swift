import Foundation

public enum InflationMath {
    public static func monthsRemaining(from today: Date, to target: Date, calendar: Calendar = .current) -> Int {
        let fromYear = calendar.component(.year, from: today)
        let toYear = calendar.component(.year, from: target)
        return max(1, (toYear - fromYear) * 12)
    }

    public static func yearsRemaining(from today: Date, to target: Date, calendar: Calendar = .current) -> Decimal {
        let months = monthsRemaining(from: today, to: target, calendar: calendar)
        return Decimal(months) / Decimal(12)
    }

    public static func inflationAdjustedTarget(
        target: Decimal,
        rate: Decimal,
        from today: Date,
        to targetDate: Date,
        calendar: Calendar = .current
    ) -> Decimal {
        let years = yearsRemaining(from: today, to: targetDate, calendar: calendar)
        let yearsDouble = NSDecimalNumber(decimal: years).doubleValue
        let rateDouble = NSDecimalNumber(decimal: rate).doubleValue
        let factor = pow(1.0 + rateDouble, yearsDouble)
        let adjusted = NSDecimalNumber(decimal: target).doubleValue * factor
        return Decimal(adjusted).rounded(toPlaces: 0)
    }

    public static func requiredPerMonth(
        target: Decimal,
        rate: Decimal,
        saved: Decimal,
        from today: Date,
        to targetDate: Date,
        calendar: Calendar = .current
    ) -> Decimal {
        let months = monthsRemaining(from: today, to: targetDate, calendar: calendar)
        let adjusted = inflationAdjustedTarget(
            target: target,
            rate: rate,
            from: today,
            to: targetDate,
            calendar: calendar
        )
        let remaining = max(Decimal(0), adjusted - saved)
        let perMonth = remaining / Decimal(months)
        return perMonth.rounded(toPlaces: 0)
    }
}

public extension Decimal {
    func rounded(toPlaces places: Int, mode: NSDecimalNumber.RoundingMode = .plain) -> Decimal {
        var value = self
        var result = Decimal()
        NSDecimalRound(&result, &value, places, mode)
        return result
    }
}
