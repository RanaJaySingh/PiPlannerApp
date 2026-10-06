import SwiftUI

struct CardView<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(PaytmTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: PaytmTheme.corner))
            .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }
}
