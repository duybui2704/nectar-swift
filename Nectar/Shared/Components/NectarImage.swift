import SwiftUI
import UIKit
import ImageIO

// MARK: - Public view

/// Ảnh remote dùng chung toàn app.
///
/// - Placeholder xám tĩnh (không shimmer) — không giật khi scroll.
/// - Download/decode độc lập với vòng đời View: cell biến mất không abort request.
/// - Khi decode xong, mọi View đang subscribe đều được cập nhật (không phụ thuộc `.task`).
struct NectarImage: View {
    let url: URL?
    var kind: NectarImageKind = .card
    var contentMode: ContentMode = .fill
    var showsLoadingIndicator: Bool = false

    @State private var image: UIImage?
    @State private var subscriptionID: UInt64 = 0

    var body: some View {
        ZStack {
            if let shown = image ?? cached {
                Image(uiImage: shown)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else if url == nil {
                emptyPlaceholder
            } else {
                Rectangle()
                    .fill(SkeletonStyle.base)
                    .overlay {
                        if showsLoadingIndicator {
                            ProgressView().tint(NectarColors.green)
                        }
                    }
            }
        }
        .transaction { $0.animation = nil }
        .onAppear(perform: subscribe)
        .onDisappear(perform: unsubscribe)
        .onChange(of: url?.absoluteString) { _, _ in
            image = nil
            unsubscribe()
            subscribe()
        }
        .onChange(of: kind) { _, _ in
            image = nil
            unsubscribe()
            subscribe()
        }
    }

    private var cached: UIImage? {
        guard let url else { return nil }
        return NectarImageLoader.shared.cached(url: url, kind: kind)
    }

    private var emptyPlaceholder: some View {
        ZStack {
            SkeletonStyle.base
            Image(systemName: "photo")
                .font(.system(size: 22, weight: .regular))
                .foregroundStyle(NectarColors.textSecondary.opacity(0.45))
        }
    }

    private func subscribe() {
        guard let url else {
            image = nil
            return
        }
        if let cached {
            image = cached
            return
        }
        subscriptionID = NectarImageLoader.shared.subscribe(url: url, kind: kind) { loaded in
            image = loaded
        }
    }

    private func unsubscribe() {
        guard subscriptionID != 0, let url else {
            subscriptionID = 0
            return
        }
        NectarImageLoader.shared.unsubscribe(url: url, kind: kind, id: subscriptionID)
        subscriptionID = 0
    }
}

// MARK: - Size buckets

/// Gom maxPixelSize thành bucket — cùng URL tái dùng 1 bản decode (tiết kiệm RAM + tránh miss cache).
enum NectarImageKind: Hashable, Sendable {
    /// Avatar, bought-together, category (~64–80pt).
    case thumbnail
    /// Product card Home / rail (~173pt).
    case card
    /// Banner / event.
    case banner
    /// Product gallery.
    case hero

    var maxPixelSize: CGFloat {
        switch self {
        case .thumbnail: return 200
        case .card: return 360
        case .banner: return 800
        case .hero: return 900
        }
    }

    static func closest(to maxPixelSize: CGFloat) -> NectarImageKind {
        switch maxPixelSize {
        case ..<240: return .thumbnail
        case ..<500: return .card
        case ..<850: return .banner
        default: return .hero
        }
    }
}

// MARK: - Loader

/// Pipeline ảnh: memory cache + URLCache + in-flight coalesce + waiter trên MainActor.
@MainActor
final class NectarImageLoader {
    static let shared = NectarImageLoader()

    private let memory = NSCache<NSString, UIImage>()
    private var waiters: [String: [Waiter]] = [:]
    private var inflight: [String: Task<Void, Never>] = [:]
    private var nextWaiterID: UInt64 = 1

    private let session: URLSession
    private let decodeQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "nectar.image.decode"
        queue.maxConcurrentOperationCount = 3
        queue.qualityOfService = .utility
        return queue
    }()

    private struct Waiter {
        let id: UInt64
        let handler: (UIImage) -> Void
    }

    private init() {
        memory.countLimit = 200
        memory.totalCostLimit = 64 * 1024 * 1024

        let config = URLSessionConfiguration.default
        config.urlCache = URLCache.shared
        config.requestCachePolicy = .returnCacheDataElseLoad
        config.timeoutIntervalForRequest = 20
        config.timeoutIntervalForResource = 40
        config.httpMaximumConnectionsPerHost = 6
        config.waitsForConnectivity = true
        config.httpAdditionalHeaders = ["Accept": "image/*"]
        session = URLSession(configuration: config)
    }

    func cached(url: URL, kind: NectarImageKind) -> UIImage? {
        memory.object(forKey: cacheKey(url, kind) as NSString)
    }

    /// Đăng ký nhận ảnh. Download không bị hủy khi unsubscribe.
    @discardableResult
    func subscribe(url: URL, kind: NectarImageKind, handler: @escaping (UIImage) -> Void) -> UInt64 {
        let key = cacheKey(url, kind)

        if let cached = memory.object(forKey: key as NSString) {
            handler(cached)
            return 0
        }

        let id = nextWaiterID
        nextWaiterID += 1
        waiters[key, default: []].append(Waiter(id: id, handler: handler))
        startIfNeeded(url: url, kind: kind, cacheKey: key)
        return id
    }

    func unsubscribe(url: URL, kind: NectarImageKind, id: UInt64) {
        guard id != 0 else { return }
        let key = cacheKey(url, kind)
        waiters[key]?.removeAll { $0.id == id }
        if waiters[key]?.isEmpty == true {
            waiters[key] = nil
        }
    }

    private func startIfNeeded(url: URL, kind: NectarImageKind, cacheKey: String) {
        guard inflight[cacheKey] == nil else { return }

        inflight[cacheKey] = Task.detached(priority: .utility) { [weak self, session, decodeQueue] in
            let loaded = await Self.fetchAndDecode(
                url: url,
                maxPixelSize: kind.maxPixelSize,
                session: session,
                decodeQueue: decodeQueue
            )
            await self?.deliver(cacheKey: cacheKey, image: loaded)
        }
    }

    private func deliver(cacheKey: String, image: UIImage?) {
        inflight[cacheKey] = nil
        guard let image else { return }

        let cost = Int(image.size.width * image.size.height * 4)
        memory.setObject(image, forKey: cacheKey as NSString, cost: max(cost, 1))

        let pending = waiters.removeValue(forKey: cacheKey) ?? []
        for waiter in pending {
            waiter.handler(image)
        }
    }

    private func cacheKey(_ url: URL, _ kind: NectarImageKind) -> String {
        "\(url.absoluteString)#\(kind.maxPixelSize)"
    }

    // MARK: Background fetch

    private nonisolated static func fetchAndDecode(
        url: URL,
        maxPixelSize: CGFloat,
        session: URLSession,
        decodeQueue: OperationQueue
    ) async -> UIImage? {
        guard let data = await fetchData(url: url, session: session) else { return nil }

        return await withCheckedContinuation { continuation in
            decodeQueue.addOperation {
                continuation.resume(returning: downsample(data: data, maxPixelSize: maxPixelSize))
            }
        }
    }

    private nonisolated static func fetchData(url: URL, session: URLSession) async -> Data? {
        var request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 20)
        request.setValue("image/*,*/*;q=0.8", forHTTPHeaderField: "Accept")

        if let cached = session.configuration.urlCache?.cachedResponse(for: request),
           isDecodableImageData(cached.data) {
            return cached.data
        }

        for attempt in 0..<2 {
            if attempt > 0 {
                try? await Task.sleep(nanoseconds: 350_000_000)
            }
            do {
                let (data, response) = try await session.data(for: request)
                if let http = response as? HTTPURLResponse {
                    if (400..<500).contains(http.statusCode) { return nil }
                    if !(200..<300).contains(http.statusCode) { continue }
                    // HTML/JSON lỗi CDN → ImageIO báo -50 (paramErr).
                    if let mime = http.mimeType?.lowercased(),
                       !mime.hasPrefix("image/"),
                       mime != "application/octet-stream",
                       mime != "binary/octet-stream" {
                        continue
                    }
                }
                if isDecodableImageData(data) { return data }
            } catch {
                continue
            }
        }
        return nil
    }

    /// Magic-byte check — tránh đưa HTML/JSON vào ImageIO.
    private nonisolated static func isDecodableImageData(_ data: Data) -> Bool {
        guard data.count > 16 else { return false }
        let b = [UInt8](data.prefix(12))
        // JPEG
        if b[0] == 0xFF, b[1] == 0xD8, b[2] == 0xFF { return true }
        // PNG
        if b[0] == 0x89, b[1] == 0x50, b[2] == 0x4E, b[3] == 0x47 { return true }
        // GIF
        if b[0] == 0x47, b[1] == 0x49, b[2] == 0x46 { return true }
        // WebP: RIFF....WEBP
        if b[0] == 0x52, b[1] == 0x49, b[2] == 0x46, b[3] == 0x46,
           b.count >= 12, b[8] == 0x57, b[9] == 0x45, b[10] == 0x42, b[11] == 0x50 {
            return true
        }
        // HEIC/HEIF: ....ftyp
        if b.count >= 8, b[4] == 0x66, b[5] == 0x74, b[6] == 0x79, b[7] == 0x70 { return true }
        // BMP
        if b[0] == 0x42, b[1] == 0x4D { return true }
        return false
    }

    /// Decode an toàn: thumbnail → full image → UIImage(data). Không log spam ImageIO -50.
    private nonisolated static func downsample(data: Data, maxPixelSize: CGFloat) -> UIImage? {
        guard isDecodableImageData(data) else { return nil }

        let pixelLimit = max(Int(maxPixelSize.rounded()), 64)
        let sourceOptions: [CFString: Any] = [kCGImageSourceShouldCache: false]
        guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions as CFDictionary) else {
            return UIImage(data: data)
        }

        let status = CGImageSourceGetStatus(source)
        guard status == .statusComplete || status == .statusIncomplete,
              CGImageSourceGetCount(source) > 0 else {
            return UIImage(data: data)
        }

        // 1) Thumbnail (nhanh, tiết kiệm RAM). Int — tránh CFNumber lỗi với CGFloat.
        let thumbOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: pixelLimit,
        ]
        if let thumb = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbOptions as CFDictionary) {
            return UIImage(cgImage: thumb, scale: 1, orientation: .up)
        }

        // 2) Fallback: full frame rồi scale (một số WebP/CMYK fail thumbnail → -50).
        let fullOptions: [CFString: Any] = [
            kCGImageSourceShouldCache: true,
            kCGImageSourceShouldCacheImmediately: true,
        ]
        if let full = CGImageSourceCreateImageAtIndex(source, 0, fullOptions as CFDictionary) {
            return scaled(full, maxPixelSize: pixelLimit)
        }

        // 3) Last resort
        return UIImage(data: data)
    }

    private nonisolated static func scaled(_ cgImage: CGImage, maxPixelSize: Int) -> UIImage {
        let w = cgImage.width
        let h = cgImage.height
        let longest = max(w, h)
        guard longest > maxPixelSize, longest > 0 else {
            return UIImage(cgImage: cgImage, scale: 1, orientation: .up)
        }
        let scale = CGFloat(maxPixelSize) / CGFloat(longest)
        let size = CGSize(width: CGFloat(w) * scale, height: CGFloat(h) * scale)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { _ in
            UIImage(cgImage: cgImage, scale: 1, orientation: .up)
                .draw(in: CGRect(origin: .zero, size: size))
        }
    }
}

// MARK: - Bootstrap

enum ImageCacheBootstrap {
    static func configure() {
        URLCache.shared = URLCache(
            memoryCapacity: 64 * 1024 * 1024,
            diskCapacity: 256 * 1024 * 1024,
            directory: nil
        )
        Task { @MainActor in
            _ = NectarImageLoader.shared
        }
    }
}
