import Foundation
import SwiftUI

enum DeepLinkRouter {
    enum Destination: Equatable {
        case transfer
        case history
        case offers
    }

    @MainActor
    static func handle(url: URL, session: AppSession) -> Destination? {
        guard url.scheme == "nectar" else { return nil }
        guard session.route == .main else { return nil }
        switch url.host {
        case "transfer": return .transfer
        case "history": return .history
        case "offers": return .offers
        default: return nil
        }
    }
}

/// Tab shell with deep-link routing support.
struct MainShellView: View {
    @EnvironmentObject private var session: AppSession
    @StateObject private var lockService = SessionLockService.shared
    @State private var selectedTab = 0
    @State private var showTransfer = false
    @HotReloadObserver private var _hr

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                DashboardView()
                    .tag(0)
                    .tabItem { Label("Trang chủ", systemImage: "house.fill") }

                NavigationStack { HistoryView() }
                    .tag(1)
                    .tabItem { Label("Lịch sử", systemImage: "clock.arrow.circlepath") }

                NavigationStack { OffersView() }
                    .tag(2)
                    .tabItem { Label("Ưu đãi", systemImage: "gift.fill") }

                CardsView()
                    .tag(3)
                    .tabItem { Label("Thẻ", systemImage: "creditcard.fill") }

                ProfileView()
                    .tag(4)
                    .tabItem { Label("Tài khoản", systemImage: "person.crop.circle") }
            }
            .tint(BankColors.brand)
            .onOpenURL { url in
                applyDeepLink(DeepLinkRouter.handle(url: url, session: session))
            }
            // .onAppear {
            //     lockService.startMonitoring()
            // }
            // .onDisappear {
            //     lockService.stopMonitoring()
            // }
            // .simultaneousGesture(TapGesture().onEnded { lockService.recordActivity() })

            // SessionLockOverlay(
            //     lockService: lockService,
            //     onUnlockBiometric: {
            //         await BiometricAuthService.shared.authenticate(reason: "Mở khóa phiên Nectar")
            //     },
            //     onUnlockPIN: { PINService.verify($0) },
            //     onForceLogout: { session.logout() }
            // )
        }
        .sheet(isPresented: $showTransfer) {
            NavigationStack {
                TransferView()
            }
        }
        .hotReload()
    }

    private func applyDeepLink(_ destination: DeepLinkRouter.Destination?) {
        guard let destination else { return }
        switch destination {
        case .transfer: showTransfer = true
        case .history: selectedTab = 1
        case .offers: selectedTab = 2
        }
    }
}
