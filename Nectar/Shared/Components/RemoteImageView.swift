import SwiftUI

/// Async image với URLCache hệ thống (disk + memory).
struct RemoteImageView: View {
    let url: URL?
    var contentMode: ContentMode = .fill
    /// Tắt trên card nhỏ / rail — tránh hàng chục `ProgressView` spin cùng lúc.
    var showsLoadingIndicator: Bool = true

    var body: some View {
        if let url {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    placeholder
                        .overlay {
                            if showsLoadingIndicator {
                                ProgressView().tint(NectarColors.green)
                            }
                        }
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: contentMode)
                case .failure:
                    placeholder
                @unknown default:
                    placeholder
                }
            }
        } else {
            placeholder
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
}

enum ImageCacheBootstrap {
    /// Gọi 1 lần khi launch — tăng URLCache cho AsyncImage / URLSession.
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
