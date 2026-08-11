import SwiftUI
import UIKit
import ImageIO

/// Remote image với URLCache + decode downsample (tránh full-res decode storm trên Home rails).
struct RemoteImageView: View {
    let url: URL?
    var contentMode: ContentMode = .fill
    /// Tắt trên card nhỏ / rail — tránh hàng chục `ProgressView` spin cùng lúc.
    var showsLoadingIndicator: Bool = true
    /// Max cạnh dài (px) khi decode — Home cards ~300–600; gallery có thể tăng.
    var maxPixelSize: CGFloat = 512

    @State private var image: UIImage?
    @State private var failed = false

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else if failed || url == nil {
                placeholder
            } else {
                placeholder
                    .overlay {
                        if showsLoadingIndicator {
                            ProgressView().tint(NectarColors.green)
                        }
                    }
            }
        }
        .transaction { $0.animation = nil }
        .task(id: url?.absoluteString) {
            await load()
        }
    }

    private var placeholder: some View {
        ZStack {
            NectarColors.brandSoft
            Image(systemName: "photo")
                .font(.system(size: 28))
                .foregroundStyle(NectarColors.green.opacity(0.55))
        }
    }

    private func load() async {
        image = nil
        failed = false
        guard let url else {
            failed = true
            return
        }
        let decoded = await RemoteImageDecoder.shared.image(for: url, maxPixelSize: maxPixelSize)
        guard !Task.isCancelled else { return }
        if let decoded {
            image = decoded
        } else {
            failed = true
        }
    }
}

// MARK: - Bootstrap

enum ImageCacheBootstrap {
    /// Gọi 1 lần khi launch — tăng URLCache cho download / URLSession.
    static func configure() {
        let memory = 64 * 1024 * 1024
        let disk = 256 * 1024 * 1024
        URLCache.shared = URLCache(
            memoryCapacity: memory,
            diskCapacity: disk,
            directory: nil
        )
    }
}

// MARK: - Decoder (downsample + memory cache)

/// Thread-safe downsample loader — NSCache + URLCache, decode off main.
final class RemoteImageDecoder: @unchecked Sendable {
    static let shared = RemoteImageDecoder()

    private let memory = NSCache<NSString, UIImage>()
    private let lock = NSLock()

    private init() {
        memory.countLimit = 120
        memory.totalCostLimit = 48 * 1024 * 1024
    }

    func image(for url: URL, maxPixelSize: CGFloat) async -> UIImage? {
        let key = "\(url.absoluteString)#\(Int(maxPixelSize))" as NSString

        let cached = lock.withLock {
            memory.object(forKey: key)
        }
        if let cached { return cached }

        let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 30)

        do {
            let data: Data
            if let cachedResponse = URLCache.shared.cachedResponse(for: request) {
                data = cachedResponse.data
            } else {
                let (bytes, response) = try await URLSession.shared.data(for: request)
                if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                    return nil
                }
                URLCache.shared.storeCachedResponse(
                    CachedURLResponse(response: response, data: bytes),
                    for: request
                )
                data = bytes
            }

            let pixelSize = maxPixelSize
            let downsampled = await Task.detached(priority: .userInitiated) {
                Self.downsample(data: data, maxPixelSize: pixelSize)
            }.value

            guard let downsampled else { return nil }

            let cost = Int(
                downsampled.size.width * downsampled.size.height
                    * downsampled.scale * downsampled.scale * 4
            )
         
            lock.withLock {
                memory.setObject(downsampled, forKey: key, cost: max(cost, 1))
            }
            return downsampled
        } catch {
            return nil
        }
    }

    private static func downsample(data: Data, maxPixelSize: CGFloat) -> UIImage? {
        let cfData = data as CFData
        let sourceOptions: [CFString: Any] = [kCGImageSourceShouldCache: false]
        guard let source = CGImageSourceCreateWithData(cfData, sourceOptions as CFDictionary) else {
            return UIImage(data: data)
        }

        let thumbnailOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: max(maxPixelSize, 64),
        ]

        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbnailOptions as CFDictionary) else {
            return UIImage(data: data)
        }
        return UIImage(cgImage: cgImage)
    }
}
