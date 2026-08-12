import SwiftUI
import Combine

private enum ProductDetailScrollSpace {
    static let name = "product-detail-scroll"
}

/// Product Detail — critical APIs first, secondary rails load in background.
struct ProductDetailView: View {
    @StateObject private var viewModel: ProductDetailViewModel
    @EnvironmentObject private var router: AppRouter
    @State private var showReturnsSheet = false
    @State private var showStylePickerSheet = false

    private let galleryBaseHeight: CGFloat = 360

    init(productId: String) {
        _viewModel = StateObject(
            wrappedValue: ProductDetailViewModel(productId: productId)
        )
    }

    private var galleryMaxHeight: CGFloat { galleryBaseHeight.scaled }
    private var galleryMinHeight: CGFloat { galleryMaxHeight * 0.5 }

    var body: some View {
        ZStack(alignment: .top) {
            content
                   .frame(maxWidth: .infinity, maxHeight: .infinity)
            topChrome
                .zIndex(999)
                .padding(.top, NectarMetrics.s(36))
            if viewModel.showsCheckoutFooter {
                ProductDetailFooter(
                    price: viewModel.footerPrice,
                    compareAtPrice: viewModel.footerComparePrice,
                    onAddToCart: {}
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
        }
        .background(NectarColors.surface.ignoresSafeArea())
        .customBottomSheet(
            isPresented: $showReturnsSheet,
            height: .fraction(0.35),
            cornerRadius: NectarMetrics.radius.md,
            showGrabber: false
        ) {
            returnsSheet
        }
        .customBottomSheet(
            isPresented: $showStylePickerSheet,
            height: .fraction(0.5),
            cornerRadius: NectarMetrics.radius.md,
            showGrabber: false
        ) {
            stylePickerSheet
        }
        .ignoresSafeArea(edges: .top)
        .navigationBarHidden(true)
        .task(id: viewModel.productId) {
            await viewModel.load()
        }
        .onDisappear {
            viewModel.cancelLoads()
        }
    }

    private var topChrome: some View {
        HStack {
            chromeButton(systemName: "chevron.left", action: { router.pop() })
            Spacer()
            chromeButton(systemName: "square.and.arrow.up", action: {})
            chromeButton(
                systemName: viewModel.isFavorite ? "heart.fill" : "heart",
                action: { viewModel.isFavorite.toggle() }
            )
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .safeAreaPadding(.top)
    }

    private var returnsSheet: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Free Returns")
                .font(.system(size: NectarMetrics.font.title, weight: .bold))
                .foregroundColor(NectarColors.black)
            HStack {
                Image(systemName: "australsign.circle")
                    .font(.system(size: NectarMetrics.icon.md))
                    .foregroundColor(NectarColors.success)
                Text("Return this item for free")
                    .font(.system(size: NectarMetrics.font.textNormal, weight: .bold))
                    .foregroundColor(NectarColors.textPrimary)
            }

            Text("Free returns are available for the shipping address you chose. You can return the item for any reason within 30 days of purchase.")
                .font(.system(size: NectarMetrics.font.textNormal, weight: .regular))
                .foregroundColor(NectarColors.textPrimary)
            Button {
            } label: {
                Text("Read the full returns policy")
                    .font(.system(size: NectarMetrics.font.textNormal, weight: .medium))
                    .foregroundColor(NectarColors.white)
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, maxHeight: NectarMetrics.button.inputHeight, alignment: .center)
            .background(NectarColors.blueDark)
            .cornerRadius(NectarMetrics.radius.sm)
            .padding(.top, NectarMetrics.s(36))
            Spacer(minLength: 0)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var stylePickerSheet: some View {
        ProductStylePickerSheet(
            styles: viewModel.variants.styles,
            selectedStyleId: viewModel.variants.selectedStyleId,
            onSelect: { styleId in
                viewModel.variants.selectedStyleId = styleId
                showStylePickerSheet = false
            }
        )
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

    /// Gallery nằm trong ScrollView + GeometryReader: height/pin tính trong layout → follow ngón tay 1:1.
    private var readyState: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Spacer(minLength: 80)
                collapsingGallery

                contentSections

                Spacer(minLength: 96)
            }
        }
        .coordinateSpace(name: ProductDetailScrollSpace.name)
        .scrollIndicators(.hidden)
    }
    private var collapsingGallery: some View {
        GeometryReader { geo in
            let minY = geo.frame(in: .named(ProductDetailScrollSpace.name)).minY
            let collapseRange = max(galleryMaxHeight - galleryMinHeight, 1)
            let scrolled = max(0, -minY)

            // 1pt scroll ↔ 1pt co — đáy gallery luôn “dính” mép trên content cho tới khi chạm min.
            let height = max(galleryMinHeight, galleryMaxHeight - scrolled)
            let progress = min(1, scrolled / collapseRange)

            // Luôn neo gallery sát đỉnh viewport (kể cả lúc đang co).
            let pinnedY: CGFloat = minY < 0 ? -minY : 0

            gallery(
                items: viewModel.gallery,
                height: height,
                collapseProgress: progress
            )
            .frame(width: geo.size.width, height: height, alignment: .top)
            .shadow(color: Color.black.opacity(0.06 * Double(progress)), radius: 8, y: 4)
            .offset(y: pinnedY)
        }
        .frame(height: galleryMaxHeight)
        .zIndex(10)
    }

    @ViewBuilder
    private var contentSections: some View {
        if let product = viewModel.product {
            ProductInfoHeader(product: product, showReturnsSheet: $showReturnsSheet)
        }

        ProductVariantPickers(
            variants: $viewModel.variants,
            showStylePickerSheet: $showStylePickerSheet
        )

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
            gallery(
                items: [],
                height: galleryMaxHeight,
                collapseProgress: 0
            )
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

    // MARK: - Helpers

    private func gallery(
        items: [ProductGalleryItem],
        height: CGFloat,
        collapseProgress: CGFloat
    ) -> some View {
        let variantThumbURL = viewModel.variants.colors
            .first(where: { $0.id != viewModel.variants.selectedColorId })?
            .imageURL
            ?? items.dropFirst().first?.imageURL

        return ProductGalleryView(
            items: items,
            variantThumbURL: variantThumbURL,
            isFavorite: viewModel.isFavorite,
            height: height,
            collapseProgress: collapseProgress,
            onBack: { router.pop() },
            onShare: {},
            onToggleFavorite: { viewModel.isFavorite.toggle() }
        )
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
