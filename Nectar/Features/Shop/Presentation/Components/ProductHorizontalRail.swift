import SwiftUI

/// Section: header + horizontal product rail.
struct ProductHorizontalRail: View {
    @EnvironmentObject private var router: AppRouter
    let title: String?
    let products: [ShopProduct]
    var currencySymbol: String = "$"
    var onSeeAll: (() -> Void)?
    var onAdd: ((ShopProduct) -> Void)?
    var onAddFavourite: ((ProductID) -> Void)?
    var onRemoveFavourite: ((ProductID) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: NectarMetrics.spacing.sm) {
            if let title, !title.isEmpty {
                HomeSectionHeader(title: title, onSeeAll: onSeeAll)
                    .screenPadding()
            }
            
            if !products.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: NectarMetrics.spacing.sm) {
                        ForEach(products) { product in
                            ProductCardView(
                                product: product,
                                currencySymbol: currencySymbol,
                                onAdd: { onAdd?(product) },
                                onAddFavourite: onAddFavourite,
                                onRemoveFavourite: onRemoveFavourite
                            )
                            .onTapGesture {
                                router.push(.productDetail(id: product.id))
                            }
                        }
                    }
                    .padding(.horizontal, NectarMetrics.layout.screenHorizontal)
                }
            }
        }
    }
}
