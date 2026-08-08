import Foundation

/// Data layer Product Detail — fetch / map. Không cache dài hạn (mỗi lần mở PDP fetch lại).
@MainActor
final class ProductDetailRepository: ProductDetailProviding {
    static let shared = ProductDetailRepository()

    func loadCritical(productId: String) async -> ProductCriticalLoadResult {
        var snapshot = ProductDetailSnapshot()
        var productError: String?
        var productParseFailed = false

        await withTaskGroup(of: CriticalChunk.self) { group in
            group.addTask { await Self.productChunk(productId) }
            group.addTask { await Self.galleryChunk(productId) }
            group.addTask { await Self.variantChunk(productId) }
            group.addTask { await Self.bulkChunk(productId) }
            for await chunk in group {
                switch chunk {
                case .product(let product, let error, let parseFailed):
                    snapshot.product = product
                    productError = error
                    productParseFailed = parseFailed
                case .gallery(let items):
                    snapshot.gallery = items
                case .variants(let variants):
                    snapshot.variants = variants
                case .bulk(let hint):
                    snapshot.bulkPriceHint = hint
                }
            }
        }

        // Seed gallery từ ảnh product nếu gallery API trống.
        if snapshot.gallery.isEmpty, let imageURL = snapshot.product?.imageURL {
            snapshot.gallery = [
                ProductGalleryItem(id: "product-cover", imageURL: imageURL, isVideo: false),
            ]
        }

        return ProductCriticalLoadResult(
            snapshot: snapshot,
            productError: productError,
            productParseFailed: productParseFailed
        )
    }

    func loadSecondary(productId: String) async -> ProductDetailSnapshot {
        var snapshot = ProductDetailSnapshot()

        await withTaskGroup(of: SecondaryChunk.self) { group in
            group.addTask { await Self.relatedChunk(productId) }
            group.addTask { await Self.keywordChunk(productId) }
            group.addTask { await Self.boughtTogetherChunk(productId) }
            group.addTask { await Self.colorGuideChunk(productId) }

            for await chunk in group {
                switch chunk {
                case .related(let products):
                    snapshot.relatedProducts = products
                case .keyword(let products):
                    snapshot.recommendationProducts = products
                case .boughtTogether(let items):
                    snapshot.boughtTogether = items
                case .colorGuide:
                    break
                }
            }
        }

        return snapshot
    }

    // MARK: - Critical

    private enum CriticalChunk: Sendable {
        case product(ProductDetail?, error: String?, parseFailed: Bool)
        case gallery([ProductGalleryItem])
        case variants(ProductVariantState)
        case bulk(ProductBulkPriceHint?)
    }

    private enum SecondaryChunk: Sendable {
        case related([ShopProduct])
        case keyword([ShopProduct])
        case boughtTogether([BoughtTogetherItem])
        case colorGuide
    }

    private static func productChunk(_ id: String) async -> CriticalChunk {
        do {
            let data = try await PrintervalAPI.fetchProduct(id: id)
            let product = ProductDTOMapper.product(from: data, fallbackId: id)
            return .product(product, error: nil, parseFailed: product == nil)
        } catch {
            log("product", error)
            return .product(nil, error: friendlyError(error), parseFailed: false)
        }
    }

    private static func galleryChunk(_ id: String) async -> CriticalChunk {
        do {
            let data = try await PrintervalAPI.fetchProductGallery(id: id)
            return .gallery(ProductDTOMapper.gallery(from: data))
        } catch {
            log("gallery", error)
            return .gallery([])
        }
    }

    private static func variantChunk(_ id: String) async -> CriticalChunk {
        do {
            let data = try await PrintervalAPI.fetchProductVariant(id: id)
            return .variants(ProductDTOMapper.variants(from: data))
        } catch {
            log("variant", error)
            return .variants(.init())
        }
    }

    private static func bulkChunk(_ id: String) async -> CriticalChunk {
        do {
            let data = try await PrintervalAPI.fetchProductBulkPrice(id: id)
            return .bulk(ProductDTOMapper.bulkPriceHint(from: data))
        } catch {
            log("bulk-price", error)
            return .bulk(nil)
        }
    }

    private static func relatedChunk(_ id: String) async -> SecondaryChunk {
        do {
            let data = try await PrintervalAPI.fetchProductRelated(id: id)
            return .related(ProductDTOMapper.products(from: data))
        } catch {
            log("related", error)
            return .related([])
        }
    }

    private static func keywordChunk(_ id: String) async -> SecondaryChunk {
        do {
            let data = try await PrintervalAPI.fetchProductRecommendationKeyword(id: id)
            return .keyword(ProductDTOMapper.products(from: data))
        } catch {
            log("recommendation-keyword", error)
            return .keyword([])
        }
    }

    private static func boughtTogetherChunk(_ id: String) async -> SecondaryChunk {
        do {
            let data = try await PrintervalAPI.fetchBoughtTogether(productId: id)
            return .boughtTogether(ProductDTOMapper.boughtTogether(from: data))
        } catch {
            log("bought-together", error)
            return .boughtTogether([])
        }
    }

    private static func colorGuideChunk(_ id: String) async -> SecondaryChunk {
        do {
            _ = try await PrintervalAPI.fetchProductColorGuide(id: id)
        } catch {
            log("color-guide", error)
        }
        return .colorGuide
    }

    private static func friendlyError(_ error: Error) -> String {
        if let app = error as? AppError {
            switch app {
            case .network(let message):
                if message.contains("HTTP") { return "Server error. Please try again." }
                return "Network error. Check your connection."
            case .unauthorized:
                return "Session expired. Please sign in again."
            case .validation, .notFound, .unknown:
                return app.errorDescription ?? "Something went wrong. Please try again."
            }
        }
        return "Something went wrong. Please try again."
    }

    private static func log(_ name: String, _ error: Error) {
        NectarLog.log("ProductDetail \(name) failed: \(error)", title: "Product")
    }
}
