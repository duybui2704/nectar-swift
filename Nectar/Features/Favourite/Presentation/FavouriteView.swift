import SwiftUI

struct FavouriteView: View {
    @StateObject private var viewModel = FavouriteViewModel()

    private let columns = [
        GridItem(.flexible(), spacing: NectarMetrics.spacing.sm),
        GridItem(.flexible(), spacing: NectarMetrics.spacing.sm),
    ]

    var body: some View {
        ScrollView {
            content
                .screenPadding()
                .padding(.top, NectarMetrics.spacing.md)
                .padding(.bottom, 100)
        }
        .hidesTabBarOnScroll()
        .background(NectarColors.background.ignoresSafeArea())
        .navigationTitle("Favourite")
        .task {
            await viewModel.loadFavourites()
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.products.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
        } else if viewModel.products.isEmpty {
            EmptyStateView(
                title: "No favourites yet",
                message: "Tap the heart on a product to save it here."
            )
        } else {
            LazyVGrid(columns: columns, spacing: NectarMetrics.spacing.sm) {
                ForEach(viewModel.products) { product in
                    ProductCardView(
                        product: product,
                        currencySymbol: viewModel.currencySymbol,
                        expandsToFill: true
                    )
                }
            }
        }
    }
}
