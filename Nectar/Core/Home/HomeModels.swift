import Foundation

/// Banner home (API `home/get-banners`).
struct HomeBanner: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let subtitle: String
    let imageURL: URL?
}

/// Product card trên Home (recommendation / big-deals / …).
struct ShopProduct: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    /// VD: "7pcs, Priceg", "1kg, Priceg"
    let unitLabel: String
    let price: Double
    let imageURL: URL?

    func formattedPrice(symbol: String = "$") -> String {
        if price == floor(price) {
            return "\(symbol)\(Int(price))"
        }
        return String(format: "%@%.2f", symbol, price)
    }
}

enum HomeMockData {
    static let banners: [HomeBanner] = [
        HomeBanner(
            id: "mock-banner-1",
            title: "Fresh Vegetables",
            subtitle: "Get Up To 40% OFF",
            imageURL: URL(string: "https://images.unsplash.com/photo-1540420773420-3366772f4999?w=800")
        ),
        HomeBanner(
            id: "mock-banner-2",
            title: "Organic Fruits",
            subtitle: "Farm fresh daily",
            imageURL: URL(string: "https://images.unsplash.com/photo-1610832958506-aa56368176cf?w=800")
        ),
        HomeBanner(
            id: "mock-banner-3",
            title: "Healthy Deals",
            subtitle: "Save more this week",
            imageURL: URL(string: "https://images.unsplash.com/photo-1498837167922-ddd27525d352?w=800")
        ),
    ]

    static let exclusiveOffers: [ShopProduct] = [
        ShopProduct(
            id: "mock-p1",
            name: "Organic Bananas",
            unitLabel: "7pcs, Priceg",
            price: 4.99,
            imageURL: URL(string: "https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?w=400")
        ),
        ShopProduct(
            id: "mock-p2",
            name: "Red Apple",
            unitLabel: "1kg, Priceg",
            price: 4.99,
            imageURL: URL(string: "https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?w=400")
        ),
        ShopProduct(
            id: "mock-p3",
            name: "Avocado",
            unitLabel: "2pcs, Priceg",
            price: 3.49,
            imageURL: URL(string: "https://images.unsplash.com/photo-1523049673857-eb18f1d7b578?w=400")
        ),
    ]

    static let bestSelling: [ShopProduct] = [
        ShopProduct(
            id: "mock-p4",
            name: "Bell Pepper Red",
            unitLabel: "1kg, Priceg",
            price: 4.99,
            imageURL: URL(string: "https://images.unsplash.com/photo-1563565375-f3fdfdbefa83?w=400")
        ),
        ShopProduct(
            id: "mock-p5",
            name: "Ginger",
            unitLabel: "250gm, Priceg",
            price: 4.99,
            imageURL: URL(string: "https://images.unsplash.com/photo-1599940824399-b87987ceb72a?w=400")
        ),
        ShopProduct(
            id: "mock-p6",
            name: "Broccoli",
            unitLabel: "1kg, Priceg",
            price: 2.99,
            imageURL: URL(string: "https://images.unsplash.com/photo-1459411552884-841db9b3cb2d?w=400")
        ),
    ]
}
