import SwiftUI

/// Product card theo design Nectar (border, ảnh, giá, nút + / heart).
struct ProductCardView: View {
    let product: ShopProduct
    var currencySymbol: String = "$"
    /// `true` khi dùng trong lưới (Favourite…) — card giãn theo cột thay vì width cố định của rail.
    var expandsToFill: Bool = false
    var onAdd: (() -> Void)?
    var onAddFavourite: ((ProductID) -> Void)?
    var onRemoveFavourite: ((ProductID) -> Void)?

    @State private var isFavourite: Bool

    private let cardWidth: CGFloat = 173

    init(
        product: ShopProduct,
        currencySymbol: String = "$",
        expandsToFill: Bool = false,
        onAdd: (() -> Void)? = nil,
        onAddFavourite: ((ProductID) -> Void)? = nil,
        onRemoveFavourite: ((ProductID) -> Void)? = nil
    ) {
        self.product = product
        self.currencySymbol = currencySymbol
        self.expandsToFill = expandsToFill
        self.onAdd = onAdd
        self.onAddFavourite = onAddFavourite
        self.onRemoveFavourite = onRemoveFavourite
        _isFavourite = State(initialValue: product.isFavorite)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                RemoteImageView(
                    url: product.imageURL,
                    contentMode: .fit,
                    showsLoadingIndicator: false,
                    maxPixelSize: 360
                )
                    .frame(height: 100.scaled)
                    .frame(maxWidth: .infinity)
                    .padding(.top, NectarMetrics.spacing.sm)
                    .padding(.horizontal, NectarMetrics.spacing.xs)

                Button {
                    toggleFavourite()
                } label: {
                    Image(systemName: isFavourite ? "heart.fill" : "heart")
                        .resizable()
                        .scaledToFit()
                        .frame(width: NectarMetrics.icon.sm, height: NectarMetrics.icon.sm)
                        .foregroundStyle(isFavourite ? NectarColors.brand : NectarColors.border)
                        .padding(12)
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity)

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
        .frame(height: 230.scaled)
        .frame(width: expandsToFill ? nil : cardWidth.scaled)
        .frame(maxWidth: expandsToFill ? .infinity : nil)
        .background(NectarColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: NectarMetrics.radius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: NectarMetrics.radius.lg, style: .continuous)
                .strokeBorder(NectarColors.border, lineWidth: 1)
        )
    }

    private func toggleFavourite() {
        let id = ProductID.string(product.id)
        if isFavourite {
            onRemoveFavourite?(id)
        } else {
            onAddFavourite?(id)
        }
        isFavourite.toggle()
    }
}
