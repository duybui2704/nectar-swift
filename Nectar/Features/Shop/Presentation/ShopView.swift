import SwiftUI

struct ShopView: View {
    @StateObject private var viewModel = ShopViewModel()

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: NectarMetrics.spacing.lg) {
                locationHeader
                    .screenPadding()

                HomeBannerCarousel(banners: viewModel.banners)
                    .screenPadding()

                if viewModel.isLoadingHome {
                    ProgressView()
                        .tint(NectarColors.green)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }

                // today-big-deals → Exclusive Offer
                ProductHorizontalRail(
                    title: "Exclusive Offer",
                    products: viewModel.exclusiveOffers,
                    currencySymbol: viewModel.currencySymbol,
                    onSeeAll: {},
                    onAdd: { _ in }
                )

                // recommendation/products → Best Selling
                ProductHorizontalRail(
                    title: "Best Selling",
                    products: viewModel.bestSelling,
                    currencySymbol: viewModel.currencySymbol,
                    onSeeAll: {},
                    onAdd: { _ in }
                )
            }
            .padding(.top, NectarMetrics.spacing.md)
            .padding(.bottom, 100)
        }
        .hidesTabBarOnScroll()
        .background(NectarColors.background.ignoresSafeArea())
        .task {
            await viewModel.loadHome()
        }
    }

    private var locationHeader: some View {
        HStack(spacing: 8) {
            Image(systemName: "location.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(NectarColors.green)
            Text(viewModel.locationText)
                .font(.system(size: 16.scaled, weight: .semibold))
                .foregroundStyle(NectarColors.textPrimary)
                .lineLimit(1)
        }
    }
}
