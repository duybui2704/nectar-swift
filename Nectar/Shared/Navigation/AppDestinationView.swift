import SwiftUI

/// Map `AppDestination` → View. Thêm màn thật ở đây khi feature sẵn sàng.
struct AppDestinationView: View {
    let destination: AppDestination

    var body: some View {
        switch destination {
        case .productDetail(let id):
            ProductDetailView(productId: id)

        case .category(let id, let name):
            PlaceholderFeatureView(
                title: name,
                message: "Category id \(id) — nối CategoryProductsView khi sẵn sàng."
            )

        case .search(let query):
            PlaceholderFeatureView(
                title: "Search",
                message: query.isEmpty
                    ? "Search results — nối SearchView khi sẵn sàng."
                    : "Results for “\(query)”."
            )

        case .orders:
            PlaceholderFeatureView(
                title: "My Orders",
                message: "Track past and current grocery orders."
            )

        case .deliveryAddress:
            PlaceholderFeatureView(
                title: "Delivery Address",
                message: "Manage where your orders are delivered."
            )

        case .changePassword:
            PlaceholderFeatureView(
                title: "Đổi mật khẩu",
                message: "Sẽ nối API change password / forgetPwd của PostPay."
            )

        case .pinSettings:
            PlaceholderFeatureView(
                title: "Mã PIN",
                message: "PIN / Smart OTP — bước bảo mật nâng cao sau core flow."
            )
        }
    }
}

/// Sheet content cho `AppSheet`.
struct AppSheetView: View {
    let sheet: AppSheet

    var body: some View {
        switch sheet {
        case .filters:
            PlaceholderFeatureView(
                title: "Filters",
                message: "Filter sheet — nối UI lọc sản phẩm khi sẵn sàng."
            )
        }
    }
}
