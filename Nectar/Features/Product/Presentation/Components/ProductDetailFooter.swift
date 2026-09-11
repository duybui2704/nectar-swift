import SwiftUI

/// Sticky footer: price + ADD TO CART.
struct ProductDetailFooter: View {
    let price: String
    var compareAtPrice: String?
    var onAddToCart: () -> Void

    var body: some View {
        HStack(spacing: NectarMetrics.s(16)) {
            VStack(alignment: .leading, spacing: 2) {
                Text(price)
                    .font(NectarFonts.elmsSans(size: NectarMetrics.s(22), weight: .bold))
                    .foregroundStyle(NectarColors.danger)
                if let compareAtPrice, !compareAtPrice.isEmpty {
                    Text(compareAtPrice)
                        .font(NectarFonts.elmsSans(size: 13.scaled, weight: .regular))
                        .foregroundStyle(NectarColors.textSecondary)
                        .strikethrough()
                }
            }

            Spacer(minLength: 8)

            Button(action: onAddToCart) {
                HStack(spacing: 8) {
                    Image(systemName: "cart.fill")
                    Text("ADD TO CART")
                        .font(NectarFonts.elmsSans(size: NectarMetrics.s(14), weight: .bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, NectarMetrics.s(20))
                .frame(height: NectarMetrics.s(48))
                .background(NectarColors.danger)
                .clipShape(RoundedRectangle(cornerRadius: NectarMetrics.radius.md, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, NectarMetrics.layout.screenHorizontal)
        .padding(.top, NectarMetrics.s(12))
        .padding(.bottom, NectarMetrics.s(8))
        .background(
            NectarColors.surface
                .shadow(color: .black.opacity(0.06), radius: 8, y: -2)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}
