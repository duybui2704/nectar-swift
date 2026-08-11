import Foundation
import Combine

@MainActor
final class FavouriteViewModel: ObservableObject {
    @Published private(set) var isLoading = false
    @Published private(set) var favourites: [Favourite] = []

    private let favouriteProvider: FavouriteProviding

    @Published var country = "us"
    @Published var pageId = 1
    @Published var pageSize = 20

    var currencySymbol: String {
        LocalizationStore.shared.currentCurrency?.symbol ?? "$"
    }

    /// Map sang `ShopProduct` để tái dùng `ProductCardView`.
    var products: [ShopProduct] {
        favourites.map(\.asShopProduct)
    }

    init(favouriteProvider: FavouriteProviding? = nil) {
        self.favouriteProvider = favouriteProvider ?? FavouriteRepository.shared
    }

    func loadFavourites() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            favourites = try await favouriteProvider.fetchFavourites(
                country: country,
                pageId: pageId,
                pageSize: pageSize
            )
        } catch {
            print("❌ Fetch favourites error:", error)
        }
    }
}

private extension Favourite {
    var asShopProduct: ShopProduct {
        ShopProduct(
            id: String(product.id),
            name: product.name,
            unitLabel: product.note.isEmpty ? product.sku : product.note,
            price: product.price,
            imageURL: URL(string: product.imageURL),
            isFavorite: true
        )
    }
}
