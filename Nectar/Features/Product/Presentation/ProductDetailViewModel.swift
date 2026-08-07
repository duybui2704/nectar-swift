import Foundation
import Combine

@MainActor
final class ProductDetailViewModel: ObservableObject {
    let productId: String

    @Published private(set) var phase: ProductDetailPhase = .idle
    @Published private(set) var isLoadingSecondary = false

    @Published private(set) var product: ProductDetail?
    @Published private(set) var gallery: [ProductGalleryItem] = []
    @Published var variants = ProductVariantState()
    @Published private(set) var bulkPriceHint: ProductBulkPriceHint?
    @Published private(set) var relatedProducts: [ShopProduct] = []
    @Published private(set) var recommendationProducts: [ShopProduct] = []
    @Published var boughtTogether: [BoughtTogetherItem] = []

    @Published var quantity = 1
    @Published var isFavorite = false

    private let repository: ProductDetailProviding
    private var loadTask: Task<Void, Never>?
    private var secondaryTask: Task<Void, Never>?

    var currencySymbol: String {
        product?.currencySymbol
            ?? LocalizationStore.shared.currentCurrency?.symbol
            ?? "$"
    }

    var footerPrice: String {
        variants.selectedStyle?.priceLabel
            ?? product?.displayPrice
            ?? "—"
    }

    var footerComparePrice: String? {
        product?.compareAtPrice
    }

    var boughtTogetherTotal: String {
        let selected = boughtTogether.filter(\.isSelected)
        guard !selected.isEmpty else { return footerPrice }
        let values = selected.compactMap { parsePrice($0.displayPrice) }
        if values.count == selected.count {
            let total = values.reduce(0, +)
            return String(format: "%@%.2f", currencySymbol, total)
        }
        return footerPrice
    }

    var failureMessage: String {
        if case .failed(let message) = phase { return message }
        return "Couldn’t load this product."
    }

    var showsCheckoutFooter: Bool {
        if case .ready = phase { return true }
        return false
    }

    init(productId: String, repository: ProductDetailProviding = ProductDetailRepository.shared) {
        self.productId = productId
        self.repository = repository
    }

    /// Phase 1: await product + gallery + variant → first paint.
    /// Phase 2: fire-and-forget secondary APIs.
    func load(force: Bool = false) async {
        if !force, phase == .ready || phase == .loading { return }

        loadTask?.cancel()
        secondaryTask?.cancel()

        phase = .loading
        clearSecondary()

        let result = await repository.loadCritical(productId: productId)
        guard !Task.isCancelled else { return }

        applyCritical(result.snapshot)

        guard let product = result.snapshot.product else {
            phase = .failed(message: failureReason(from: result))
            return
        }

        _ = product
        phase = .ready

        secondaryTask = Task { [weak self] in
            guard let self else { return }
            await self.loadSecondary()
        }
    }

    func retry() async {
        await load(force: true)
    }

    func cancelLoads() {
        loadTask?.cancel()
        secondaryTask?.cancel()
    }

    func incrementQuantity() {
        quantity = min(quantity + 1, 99)
    }

    func decrementQuantity() {
        quantity = max(quantity - 1, 1)
    }

    func toggleBoughtTogether(_ id: String) {
        guard let index = boughtTogether.firstIndex(where: { $0.id == id }) else { return }
        boughtTogether[index].isSelected.toggle()
    }

    // MARK: - Private

    private func loadSecondary() async {
        isLoadingSecondary = true
        defer { isLoadingSecondary = false }

        let secondary = await repository.loadSecondary(productId: productId)
        guard !Task.isCancelled else { return }
        applySecondary(secondary)
    }

    private func applyCritical(_ snapshot: ProductDetailSnapshot) {
        product = snapshot.product
        gallery = snapshot.gallery
        variants = snapshot.variants
    }

    private func applySecondary(_ snapshot: ProductDetailSnapshot) {
        if let hint = snapshot.bulkPriceHint {
            bulkPriceHint = hint
        }
        if !snapshot.relatedProducts.isEmpty {
            relatedProducts = snapshot.relatedProducts
        }
        if !snapshot.recommendationProducts.isEmpty {
            recommendationProducts = snapshot.recommendationProducts
        }
        if !snapshot.boughtTogether.isEmpty {
            boughtTogether = snapshot.boughtTogether
        }
    }

    private func clearSecondary() {
        bulkPriceHint = nil
        relatedProducts = []
        recommendationProducts = []
        boughtTogether = []
        quantity = 1
    }

    private func failureReason(from result: ProductCriticalLoadResult) -> String {
        if let productError = result.productError, !productError.isEmpty {
            return productError
        }
        if result.productParseFailed {
            return "This product isn’t available right now."
        }
        return "Couldn’t load this product."
    }

    private func parsePrice(_ text: String) -> Double? {
        let cleaned = text.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
        return Double(cleaned)
    }
}
