import SwiftUI

/// Sticky footer: price + ADD TO CART.
struct ProductDetailFooter: View {
    let price: String
    var compareAtPrice: String?
    var onAddToCart: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text(price)
                    .font(NectarFonts.elmsSans(size: 22.scaled, weight: .bold))
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
                        .font(NectarFonts.elmsSans(size: 14.scaled, weight: .bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .frame(height: 48.scaled)
                .background(NectarColors.danger)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, NectarMetrics.layout.screenHorizontal)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(
            NectarColors.surface
                .shadow(color: .black.opacity(0.06), radius: 8, y: -2)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}
