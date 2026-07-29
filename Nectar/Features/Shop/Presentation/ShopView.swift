import SwiftUI
import UIKit

struct ShopView: View {
    @StateObject private var viewModel = ShopViewModel()

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: NectarMetrics.spacing.lg) {
                ShopLocationHeader(locationText: viewModel.locationText)
                    .screenPadding()

                HomeBannerCarousel(banners: viewModel.banners)
                    .screenPadding()

                if viewModel.isLoadingHome {
                    ProgressView()
                        .tint(NectarColors.green)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }

                ProductHorizontalRail(
                    title: "Exclusive Offer",
                    products: viewModel.exclusiveOffers,
                    currencySymbol: viewModel.currencySymbol,
                    onSeeAll: {},
                    onAdd: { _ in }
                )

                ProductHorizontalRail(
                    title: "Best Selling",
                    products: viewModel.bestSelling,
                    currencySymbol: viewModel.currencySymbol,
                    onSeeAll: {},
                    onAdd: { _ in }
                )
            }
            .padding(.top, NectarMetrics.spacing.md)
            .padding(.bottom, 100)
        }
        .hidesTabBarOnScroll()
        .background(NectarColors.background.ignoresSafeArea())
        .task {
            await viewModel.loadHome()
        }
    }
}

// MARK: - Location header

/// Brand “Nectar” — rainbow chạy trái→phải bằng TimelineView (không dùng withAnimation trên UnitPoint).
struct ShopLocationHeader: View {
    let locationText: String

    /// Chu kỳ 1 vòng rainbow (giây).
    private let period: TimeInterval = 2.8

    /// Dải màu lặp 2 lần để loop mượt khi offset.
    private let rainbowBand: [Color] = [
        .red, .orange, .yellow, .green, .cyan, .blue, .purple, .pink,
        .red, .orange, .yellow, .green, .cyan, .blue, .purple, .pink,
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: NectarMetrics.spacing.xs) {
           nectarTitle
                .accessibilityLabel("Nectar Market")

            // HStack(spacing: 8) {
            //     Image(systemName: "location.fill")
            //         .font(.system(size: 14.scaled, weight: .semibold))
            //         .foregroundStyle(NectarColors.green)
            //     Text(locationText)
            //         .font(.system(size: 15.scaled, weight: .semibold, design: .rounded))
            //         .foregroundStyle(NectarColors.textPrimary)
            //         .lineLimit(1)
            // }
            // .accessibilityLabel("Location \(locationText)")
        }
    }

    /// Great Vibes (script) — bắt buộc có file trong bundle + UIAppFonts.
    private var titleFont: Font {
        NectarTypography.brandScript(size: 50.scaled)
    }

    @ViewBuilder
    private var nectarTitle: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: false)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let phase = CGFloat(t.truncatingRemainder(dividingBy: period) / period)

            Text("Nectar Market")
                .font(titleFont)
                .hidden()
                .overlay {
                    GeometryReader { geo in
                        LinearGradient(
                            colors: rainbowBand,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: geo.size.width * 2, height: geo.size.height)
                        .offset(x: -phase * geo.size.width)
                    }
                }
                .mask {
                    Text("Nectar Market")
                        .font(titleFont)
                }
                .shadow(color: Color.purple.opacity(0.22), radius: 8, x: 0, y: 2)
        }
    }
}
