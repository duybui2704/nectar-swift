import SwiftUI

/// Product card theo design Nectar (border, ảnh, giá, nút +).
struct ProductCardView: View {
    let product: ShopProduct
    var currencySymbol: String = "$"
    var onAdd: (() -> Void)?

    private let cardWidth: CGFloat = 173

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            RemoteImageView(url: product.imageURL, contentMode: .fit, showsLoadingIndicator: false)
                .frame(height: 100.scaled)
                .frame(maxWidth: .infinity)
                .padding(.top, NectarMetrics.spacing.sm)
                .padding(.horizontal, NectarMetrics.spacing.xs)

            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(NectarFonts.elmsSans(size: 15.scaled, weight: .bold))
                    .foregroundStyle(NectarColors.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Text(product.unitLabel)
                    .font(NectarFonts.elmsSans(size: 12.scaled, weight: .regular))
                    .foregroundStyle(NectarColors.textSecondary)
                    .lineLimit(1)
            }
            .padding(.horizontal, NectarMetrics.spacing.sm)
            .padding(.top, NectarMetrics.spacing.xs)

            Spacer(minLength: 8)

            HStack {
                if let price = product.formattedPrice(symbol: currencySymbol) {
                    Text(price)
                        .font(NectarFonts.elmsSans(size: 16.scaled, weight: .bold))
                        .foregroundStyle(NectarColors.textPrimary)
                }

                Spacer(minLength: 4)

                Button {
                    onAdd?()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 40.scaled, height: 40.scaled)
                        .background(NectarColors.green)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, NectarMetrics.spacing.sm)
            .padding(.bottom, NectarMetrics.spacing.sm)
        }
        .frame(width: cardWidth.scaled, height: 230.scaled)
        .background(NectarColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: NectarMetrics.radius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: NectarMetrics.radius.lg, style: .continuous)
                .strokeBorder(NectarColors.border, lineWidth: 1)
        )
    }
}
