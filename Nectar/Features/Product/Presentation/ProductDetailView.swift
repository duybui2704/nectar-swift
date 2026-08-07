import SwiftUI

/// Product Detail — critical APIs first, secondary rails load in background.
struct ProductDetailView: View {
    @StateObject private var viewModel: ProductDetailViewModel
    @EnvironmentObject private var router: AppRouter

    init(productId: String) {
        _viewModel = StateObject(wrappedValue: ProductDetailViewModel(productId: productId))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            if viewModel.showsCheckoutFooter {
                ProductDetailFooter(
                    price: viewModel.footerPrice,
                    compareAtPrice: viewModel.footerComparePrice,
                    onAddToCart: {}
                )
            }
        }
        .background(NectarColors.surface.ignoresSafeArea())
        .navigationBarHidden(true)
        .task(id: viewModel.productId) {
            await viewModel.load()
        }
        .onDisappear {
            viewModel.cancelLoads()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.phase {
        case .idle, .loading:
            loadingState
        case .failed:
            failedState
        case .ready:
            readyState
        }
    }

    // MARK: - Ready

    private var readyState: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                gallery(
                    items: viewModel.gallery,
                    showsActions: true
                )

                contentSections

                Spacer(minLength: 96)
            }
        }
        .scrollIndicators(.hidden)
    }

    @ViewBuilder
    private var contentSections: some View {
        if let product = viewModel.product {
            ProductInfoHeader(product: product)
        }

        ProductVariantPickers(variants: $viewModel.variants)

        ProductQuantityStepper(
            quantity: $viewModel.quantity,
            bulkHint: viewModel.bulkPriceHint?.summary,
            onDecrement: viewModel.decrementQuantity,
            onIncrement: viewModel.incrementQuantity
        )

        ProductTrustBadges()

        ProductAccordionRows(product: viewModel.product)
            .padding(.top, 8)

        if !viewModel.relatedProducts.isEmpty {
            ProductHorizontalRail(
                title: "The design is also available on",
                products: viewModel.relatedProducts,
                currencySymbol: viewModel.currencySymbol
            )
            .padding(.top, 20)
        }

        if !viewModel.recommendationProducts.isEmpty {
            ProductHorizontalRail(
                title: "You might love these",
                products: viewModel.recommendationProducts,
                currencySymbol: viewModel.currencySymbol
            )
            .padding(.top, 16)
        }

        if viewModel.isLoadingSecondary
            && viewModel.relatedProducts.isEmpty
            && viewModel.recommendationProducts.isEmpty
            && viewModel.boughtTogether.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
        }

        ProductBoughtTogetherSection(
            items: $viewModel.boughtTogether,
            totalLabel: viewModel.boughtTogetherTotal,
            onToggle: viewModel.toggleBoughtTogether,
            onAddAll: {}
        )
        .padding(.top, 8)
    }

    // MARK: - Loading

    private var loadingState: some View {
        VStack(spacing: 0) {
            gallery(items: [], showsActions: true)
                .redacted(reason: .placeholder)
                .overlay {
                    ProgressView()
                        .tint(NectarColors.danger)
                }

            VStack(alignment: .leading, spacing: 12) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(NectarColors.border.opacity(0.5))
                    .frame(height: 20)
                RoundedRectangle(cornerRadius: 6)
                    .fill(NectarColors.border.opacity(0.35))
                    .frame(height: 14)
                    .padding(.trailing, 80)
                RoundedRectangle(cornerRadius: 6)
                    .fill(NectarColors.border.opacity(0.35))
                    .frame(width: 160, height: 14)
            }
            .padding(.horizontal, NectarMetrics.layout.screenHorizontal)
            .padding(.top, 24)

            Spacer()
        }
    }

    // MARK: - Failed

    private var failedState: some View {
        VStack(spacing: 0) {
            topChromeOnly

            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundStyle(NectarColors.textSecondary)

                Text(viewModel.failureMessage)
                    .font(NectarTypography.body)
                    .foregroundStyle(NectarColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Button {
                    Task { await viewModel.retry() }
                } label: {
                    Text("Retry")
                        .font(NectarFonts.elmsSans(size: 15.scaled, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 12)
                        .background(NectarColors.danger)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
    }

    private var topChromeOnly: some View {
        HStack {
            chromeButton(systemName: "chevron.left") { router.pop() }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .safeAreaPadding(.top)
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    // MARK: - Gallery helper

    private func gallery(items: [ProductGalleryItem], showsActions: Bool) -> some View {
        ProductGalleryView(
            items: items,
            variantThumbURL: viewModel.variants.colors
                .first(where: { $0.id != viewModel.variants.selectedColorId })?
                .imageURL
                ?? items.dropFirst().first?.imageURL,
            isFavorite: viewModel.isFavorite,
            onBack: { router.pop() },
            onShare: {},
            onToggleFavorite: { viewModel.isFavorite.toggle() }
        )
        .opacity(showsActions ? 1 : 1)
    }

    private func chromeButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(NectarColors.textPrimary)
                .frame(width: 40, height: 40)
                .background(.ultraThinMaterial, in: Circle())
        }
        .buttonStyle(.plain)
    }
}
