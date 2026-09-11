import Foundation
import UIKit
import LinkPresentation

/// Nội dung share sản phẩm — preview sheet hiện ảnh + tên + giá.
struct ProductSharePayload: Identifiable {
    let id = UUID()
    let name: String
    let price: String
    let url: URL
    let image: UIImage?

    var activityItems: [Any] {
        var items: [Any] = [
            ProductShareItemSource(
                name: name,
                price: price,
                url: url,
                image: image
            )
        ]
        // Đính kèm ảnh riêng để Messages / AirDrop / Save nhận đúng hình sản phẩm.
        if let image {
            items.insert(image, at: 0)
        }
        return items
    }

    static func make(
        product: ProductDetail,
        price: String? = nil,
        image: UIImage? = nil
    ) -> ProductSharePayload {
        ProductSharePayload(
            name: product.name,
            price: price ?? product.displayPrice,
            url: product.shareURL,
            image: image
        )
    }
}

/// Cung cấp preview rich (ảnh / tên / giá) cho `UIActivityViewController`.
final class ProductShareItemSource: NSObject, UIActivityItemSource {
    private let name: String
    private let price: String
    private let url: URL
    private let image: UIImage?

    init(name: String, price: String, url: URL, image: UIImage?) {
        self.name = name
        self.price = price
        self.url = url
        self.image = image
    }

    private var shareText: String {
        "\(name)\n\(price)\n\(url.absoluteString)"
    }

    func activityViewControllerPlaceholderItem(
        _ activityViewController: UIActivityViewController
    ) -> Any {
        image ?? url
    }

    func activityViewController(
        _ activityViewController: UIActivityViewController,
        itemForActivityType activityType: UIActivity.ActivityType?
    ) -> Any? {
        // Copy / Messages / social: text gồm tên + giá + link.
        // Apps nhận ảnh: kèm image khi type phù hợp.
        if activityType == .saveToCameraRoll || activityType == .airDrop {
            return image ?? shareText
        }
        return shareText
    }

    func activityViewController(
        _ activityViewController: UIActivityViewController,
        subjectForActivityType activityType: UIActivity.ActivityType?
    ) -> String {
        "\(name) — \(price)"
    }

    func activityViewControllerLinkMetadata(
        _ activityViewController: UIActivityViewController
    ) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        metadata.originalURL = url
        metadata.url = url
        // Title = tên; price hiện ngay dưới dạng phụ đề trong preview.
        metadata.title = name
        if let image {
            let provider = NSItemProvider(object: image)
            metadata.imageProvider = provider
            metadata.iconProvider = provider
        }
        // `LPLinkMetadata` không có field price riêng — gắn giá vào title phụ qua subject
        // và để text body chứa giá. Một số app đọc title dạng "Name · $price".
        metadata.title = "\(name) · \(price)"
        return metadata
    }
}
