import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            ShopView()
                .tabItem { Label("Shop", systemImage: "storefront") }

            ExploreView()
                .tabItem { Label("Explore", systemImage: "line.3.horizontal.decrease.circle") }

            CartView()
                .tabItem { Label("Cart", systemImage: "cart") }

            FavouriteView()
                .tabItem { Label("Favourite", systemImage: "heart") }

            ProfileView()
                .tabItem { Label("Account", systemImage: "person") }
        }
        .tint(NectarColors.green)
    }
}
