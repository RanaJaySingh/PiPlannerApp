import SwiftUI

struct PercentEditor: View {
    let label: String
    @Binding var percent: Double
    var amountHint: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(PaytmTheme.textPrimary)
                Spacer()
                Text("\(Int(percent.rounded()))%")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(PaytmTheme.navy)
            }
            Slider(value: $percent, in: 0...100, step: 1)
                .tint(PaytmTheme.primaryBlue)
            if !amountHint.isEmpty {
                Text(amountHint)
                    .font(.caption)
                    .foregroundStyle(PaytmTheme.textSecondary)
            }
        }
    }
}

struct PercentEditorRow: View {
    let title: String
    @Binding var percent: Double
    var onChange: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(PaytmTheme.textPrimary)
            Spacer()
            TextField("0", value: $percent, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 64)
                .onChange(of: percent) { _, _ in onChange?() }
            Text("%")
                .foregroundStyle(PaytmTheme.textSecondary)
        }
    }
}
