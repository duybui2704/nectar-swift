import SwiftUI

struct ShopView: View {
    @StateObject private var viewModel = ShopViewModel()
    @HotReloadObserver private var _hr

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: NectarMetrics.spacing.lg) {
                ShopLocationHeader(
                    locationText: viewModel.locationText,
                    categories: viewModel.categories
                )
                .screenPadding()

                HomeBannerCarousel(banners: viewModel.banners)
                    .screenPadding()

                if viewModel.isLoadingHome {
                    ProgressView()
                        .tint(NectarColors.green)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }

                ProductHorizontalRail(
                    title: "Exclusive Offer",
                    products: viewModel.exclusiveOffers,
                    currencySymbol: viewModel.currencySymbol,
                    onSeeAll: {},
                    onAdd: { _ in }
                )

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
        .hotReload()
    }
}

// MARK: - Location header

/// Brand “Nectar Market” — rainbow TimelineView + Great Vibes + Search + Categories.
struct ShopLocationHeader: View {
    let locationText: String
    var categories: [CategoryTree] = []

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
        }
        .hotReload()
    }

    private var titleFont: Font {
        NectarTypography.brandScript(size: 50.scaled)
    }

    private var nectarTitle: some View {
        HStack {
            TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: false)) { context in
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
                    .shadow(color: Color.purple.opacity(0.22), radius: 8, x: 0, y: 2)
            }
            Spacer()
            Image(systemName: "bell.fill")
                .font(.system(size: 24.scaled, weight: .semibold))
                .foregroundStyle(NectarColors.green)
        }
    }
}
