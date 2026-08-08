//
//  EventBoxView.swift
//  Nectar
//
//  Created by admin on 3/8/26.
//

import SwiftUI

/// Event promo: banner cover + product rail.
/// `products` parse **một lần** ở ViewModel — không JSON-decode trong `body` (gây giật khi scroll tới cuối).
struct EventBoxView: View {
    let event: EventBox
    var products: [ShopProduct] = []
    var currencySymbol: String = "$"
    @HotReloadObserver private var _hr

    private var cornerRadius: CGFloat { NectarMetrics.radius.md }

    var body: some View {
        VStack(alignment: .leading, spacing: NectarMetrics.spacing.md) {
            bannerCard
                .screenPadding()

            if !products.isEmpty {
                ProductHorizontalRail(
                    title: nil,
                    products: products,
                    currencySymbol: currencySymbol,
                    onSeeAll: {},
                    onAdd: { _ in }
                )
            }
        }
        .hotReload()
    }

    private var bannerCard: some View {
        ZStack(alignment: .bottomLeading) {
            Color.clear
                .overlay {
                    RemoteImageView(
                        url: event.bannerURL,
                        contentMode: .fill,
                        showsLoadingIndicator: false
                    )
                }
                .clipped()

            LinearGradient(
                colors: [
                    .black.opacity(0.1),
                    .black.opacity(0.35),
                    .black.opacity(0.75),
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: NectarMetrics.spacing.xxs) {
                Text(event.name)
                    .font(NectarFonts.elmsSans(size: 22.scaled, weight: .bold))
                    .foregroundStyle(NectarColors.surface)
                    .shadow(color: .black.opacity(0.45), radius: 2, y: 1)
                    .lineLimit(2)

                if !event.description.isEmpty {
                    Text(event.description)
                        .font(NectarFonts.elmsSans(size: 13.scaled, weight: .regular))
                        .foregroundStyle(NectarColors.surface.opacity(0.95))
                        .shadow(color: .black.opacity(0.35), radius: 1, y: 1)
                        .lineLimit(2)
                }
            }
            .padding(NectarMetrics.spacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 160.scaled)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(event.name)
    }
}
