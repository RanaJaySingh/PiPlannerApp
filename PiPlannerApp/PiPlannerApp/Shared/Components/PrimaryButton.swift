import SwiftUI

struct PrimaryButton: View {
    let title: String
    var enabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(enabled ? PaytmTheme.primaryBlue : PaytmTheme.primaryBlue.opacity(0.4))
                .clipShape(RoundedRectangle(cornerRadius: PaytmTheme.corner))
        }
        .disabled(!enabled)
    }
}
