import SwiftUI

/// Section: header + horizontal product rail.
struct ProductHorizontalRail: View {
    let title: String
    let products: [ShopProduct]
    var currencySymbol: String = "$"
    var onSeeAll: (() -> Void)?
    var onAdd: ((ShopProduct) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: NectarMetrics.spacing.sm) {
            HomeSectionHeader(title: title, onSeeAll: onSeeAll)
                .screenPadding()

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: NectarMetrics.spacing.sm) {
                    ForEach(products) { product in
                        ProductCardView(
                            product: product,
                            currencySymbol: currencySymbol,
                            onAdd: { onAdd?(product) }
                        )
                    }
                }
                .padding(.horizontal, NectarMetrics.layout.screenHorizontal)
            }
        }
    }
}
