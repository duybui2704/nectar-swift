import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Trang chủ", systemImage: "house.fill") }

            NavigationStack {
                HistoryView()
            }
            .tabItem { Label("Lịch sử", systemImage: "clock.arrow.circlepath") }

            CardsView()
                .tabItem { Label("Thẻ", systemImage: "creditcard.fill") }

            ProfileView()
                .tabItem { Label("Tài khoản", systemImage: "person.crop.circle") }
        }
        .tint(BankColors.brand)
    }
}
