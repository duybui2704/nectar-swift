import Foundation
import Combine
import UIKit

@MainActor
final class ProductDetailViewModel: ObservableObject {
    let productId: String
    /// SKU truyền sẵn (deep link) — fallback nếu product response chưa có skuId.
    private let initialSkuId: String?

    @Published private(set) var phase: ProductDetailPhase = .idle
    @Published private(set) var isLoadingSecondary = false
    @Published private(set) var isLoadingShipping = false

    @Published private(set) var product: ProductDetail?
    /// SKU đã resolve sau product call (dùng cho shipping / cart).
    @Published private(set) var skuId: String?
    @Published private(set) var gallery: [ProductGalleryItem] = []
    @Published var variants = ProductVariantState()
    @Published private(set) var bulkPriceHint: ProductBulkPriceHint?
    @Published private(set) var relatedProducts: [ShopProduct] = []
    @Published private(set) var recommendationProducts: [ShopProduct] = []
    @Published var boughtTogether: [BoughtTogetherItem] = []
    @Published var shippingInfo: ShippingInfo?

    @Published var quantity = 1
    @Published var isFavorite = false
    @Published private(set) var sharePayload: ProductSharePayload?
    @Published private(set) var isPreparingShare = false

    private let repository: ProductDetailProviding
    private var loadTask: Task<Void, Never>?
    private var secondaryTask: Task<Void, Never>?
    private var shippingTask: Task<Void, Never>?
    private var shareTask: Task<Void, Never>?

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

    init(
        productId: String,
        skuId: String? = nil,
        repository: ProductDetailProviding
    ) {
        self.productId = productId
        self.initialSkuId = skuId
        self.repository = repository
    }

    convenience init(productId: String, skuId: String? = nil) {
        self.init(
            productId: productId,
            skuId: skuId,
            repository: ProductDetailRepository.shared
        )
    }

    /// Phase 1: await product + gallery + variant → first paint.
    /// Phase 2: khi đã có `skuId` → shipping-info.
    /// Phase 3: secondary rails (song song, không phụ thuộc shipping).
    func load(force: Bool = false) async {
        if !force, phase == .ready || phase == .loading { return }

        loadTask?.cancel()
        secondaryTask?.cancel()
        shippingTask?.cancel()

        phase = .loading
        clearSecondary()
        shippingInfo = nil
        skuId = nil

        let result = await repository.loadCritical(productId: productId)
        guard !Task.isCancelled else { return }

        applyCritical(result.snapshot)

        guard let product = result.snapshot.product else {
            phase = .failed(message: failureReason(from: result))
            return
        }

        // Resolve skuId: ưu tiên từ product response, fallback init/deep link.
        let resolved = Self.resolvedSkuId(
            fromProduct: product.skuId,
            initial: initialSkuId
        )
        skuId = resolved
        phase = .ready

        if let resolved {
            shippingTask = Task { [weak self] in
                guard let self else { return }
                await self.loadShipping(skuId: resolved)
            }
        } else {
            NectarLog.log(
                "Skip shipping-info: missing skuId for product \(productId)",
                title: "Product"
            )
        }

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
        shippingTask?.cancel()
        shareTask?.cancel()
    }

    /// Tải ảnh (nếu cần) rồi mở share sheet với ảnh + tên + giá.
    func prepareShare() {
        guard let product, !isPreparingShare else { return }
        shareTask?.cancel()
        isPreparingShare = true

        let imageURL = product.imageURL ?? gallery.first?.imageURL

        shareTask = Task { [weak self] in
            guard let self else { return }
            let image = await Self.resolveShareImage(url: imageURL)
            guard !Task.isCancelled else {
                isPreparingShare = false
                return
            }
            sharePayload = ProductSharePayload.make(
                product: product,
                price: footerPrice,
                image: image
            )
            isPreparingShare = false
        }
    }

    func clearSharePayload() {
        sharePayload = nil
    }

    func incrementQuantity() {
        quantity = min(quantity + 1, 99)
        refreshShippingIfNeeded()
    }

    func decrementQuantity() {
        quantity = max(quantity - 1, 1)
        refreshShippingIfNeeded()
    }

    func toggleBoughtTogether(_ id: String) {
        guard let index = boughtTogether.firstIndex(where: { $0.id == id }) else { return }
        boughtTogether[index].isSelected.toggle()
    }

    // MARK: - Private

    private func loadShipping(skuId: String) async {
        isLoadingShipping = true
        defer { isLoadingShipping = false }

        let info = await repository.loadShipping(
            productId: productId,
            skuId: skuId,
            qty: quantity
        )
        guard !Task.isCancelled else { return }
        shippingInfo = info
    }

    private func refreshShippingIfNeeded() {
        guard let skuId else { return }
        shippingTask?.cancel()
        shippingTask = Task { [weak self] in
            guard let self else { return }
            await self.loadShipping(skuId: skuId)
        }
    }

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
        if let hint = snapshot.bulkPriceHint {
            bulkPriceHint = hint
        }
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

    private static func resolvedSkuId(fromProduct: String?, initial: String?) -> String? {
        if let fromProduct, !fromProduct.isEmpty { return fromProduct }
        if let initial, !initial.isEmpty { return initial }
        return nil
    }

    private static func resolveShareImage(url: URL?) async -> UIImage? {
        guard let url else { return nil }

        if let cached = NectarImageLoader.shared.cached(url: url, kind: .hero)
            ?? NectarImageLoader.shared.cached(url: url, kind: .card)
            ?? NectarImageLoader.shared.cached(url: url, kind: .thumbnail) {
            return cached
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return UIImage(data: data)
        } catch {
            return nil
        }
    }
}
