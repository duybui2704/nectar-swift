import SwiftUI

struct ShopView: View {
    @StateObject private var viewModel = ShopViewModel()
    @HotReloadObserver private var _hr

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                       Color(hex: 0xFFF9EC),
                       Color(hex: 0xF7F8F2),
                       Color(hex: 0xEEF7F1)
                   ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            ScrollView {
                LazyVStack(alignment: .leading, spacing: NectarMetrics.spacing.lg) {
                    ShopLocationHeader(
                        categories: viewModel.categories,
                        isCategoriesLoading: viewModel.showCategoriesSkeleton
                    )
                    .screenPadding()

                    HomeBannerCarousel(banners: viewModel.banners)
                        .screenPadding()
                        .skeleton(isLoading: viewModel.showBannersSkeleton) {
                            SkeletonLayout.banner()
                        }

                    ProductReelsRail(reels: viewModel.productReels)
                        .skeleton(isLoading: viewModel.showReelsSkeleton) {
                            SkeletonLayout.reelsRail()
                        }

                    ProductHorizontalRail(
                        title: "Recently Viewed",
                        products: viewModel.recentlyViewed,
                        currencySymbol: viewModel.currencySymbol,
                        onSeeAll: {},
                        onAdd: { _ in },
                        onAddFavourite: { _ in },
                        onRemoveFavourite: { _ in }
                    )
                    .skeleton(isLoading: viewModel.showRecentlyViewedSkeleton) {
                        SkeletonLayout.productRail(title: true, count: 3)
                    }

                    ProductHorizontalRail(
                        title: "Exclusive Offer",
                        products: viewModel.exclusiveOffers,
                        currencySymbol: viewModel.currencySymbol,
                        onSeeAll: {},
                        onAdd: { _ in },
                        onAddFavourite: { _ in },
                        onRemoveFavourite: { _ in }
                    )
                    .skeleton(isLoading: viewModel.showExclusiveSkeleton) {
                        SkeletonLayout.productRail(title: true, count: 3)
                    }

                    ProductHorizontalRail(
                        title: "Best Selling",
                        products: viewModel.bestSelling,
                        currencySymbol: viewModel.currencySymbol,
                        onSeeAll: {},
                        onAdd: { _ in },
                        onAddFavourite: { _ in },
                        onRemoveFavourite: { _ in }
                    )
                    .skeleton(isLoading: viewModel.showBestSellingSkeleton) {
                        SkeletonLayout.productRail(title: true, count: 3)
                    }

                    SellerSpotlight(sellerData: viewModel.sellers)
                        .skeleton(isLoading: viewModel.showSellersSkeleton) {
                            SkeletonLayout.sellerSpotlight()
                        }

                    SkeletonGate(isLoading: viewModel.showEventBoxSkeleton) {
                        if let event = viewModel.primaryEvent {
                            EventBoxView(
                                event: event,
                                products: viewModel.eventBoxProducts,
                                currencySymbol: viewModel.currencySymbol
                            ).padding(.bottom, 250)
                        }
                    } skeleton: {
                        SkeletonLayout.eventBanner()
                    }
                }
                .padding(.top, NectarMetrics.spacing.md)
            }
        }
        .task {
            await viewModel.loadHome()
        }
        .hotReload()
    }
}

// MARK: - Location header

/// Brand “Nectar Market” — rainbow TimelineView + Great Vibes + Search + Categories.
struct ShopLocationHeader: View {
    var categories: [CategoryTree] = []
    var isCategoriesLoading: Bool = false

    @HotReloadObserver private var _hr

    private let period: TimeInterval = 2.8

    private let rainbowBand: [Color] = [
        .red, .orange, .yellow, .green, .cyan, .blue, .purple, .pink,
        .red, .orange, .yellow, .green, .cyan, .blue, .purple, .pink,
    ]
    @State private var searchText: String = ""
    @FocusState private var searchFieldIsFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: NectarMetrics.spacing.sm) {
            nectarTitle
                .accessibilityLabel("Nectar Market")

            TextField("Search", text: $searchText, prompt: Text("Search products").foregroundStyle(.gray))
                .focused($searchFieldIsFocused)
                .padding(12)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .frame(maxWidth: .infinity)
                .frame(height: NectarMetrics.button.inputHeight)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(searchFieldIsFocused ? NectarColors.green : .secondary, lineWidth: 1.5)
                )
                .cornerRadius(8)

            CategoryList(categories: categories)
                .skeleton(isLoading: isCategoriesLoading) {
                    SkeletonLayout.categoryRail()
                }
        }
        .hotReload()
    }

    private var titleFont: Font {
        NectarTypography.brandScript(size: 50.scaled)
    }

    private var nectarTitle: some View {
        HStack {
            // ~12fps đủ cho shimmer; 30fps tốn CPU liên tục trên Home.
            TimelineView(.animation(minimumInterval: 1.0 / 12.0, paused: false)) { context in
                let t = context.date.timeIntervalSinceReferenceDate
                let phase = CGFloat(t.truncatingRemainder(dividingBy: period) / period)

                Text("Nectar Market")
                    .font(titleFont)
                    .hidden()
                    .overlay {
                        GeometryReader { geo in
                            LinearGradient(
                                colors: rainbowBand,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .frame(width: geo.size.width * 2, height: geo.size.height)
                            .offset(x: -phase * geo.size.width)
                        }
                    }
                    .mask {
                        Text("Nectar Market")
                            .font(titleFont)
                    }
                    .shadow(color: Color.purple.opacity(0.18), radius: 4, x: 0, y: 1)
            }
            Spacer()
            Image(systemName: "bell.fill")
                .font(.system(size: 24.scaled, weight: .semibold))
                .foregroundStyle(NectarColors.green)
        }
    }
}
