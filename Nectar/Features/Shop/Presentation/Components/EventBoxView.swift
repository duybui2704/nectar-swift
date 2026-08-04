//
//  EventBoxView.swift
//  Nectar
//
//  Created by admin on 3/8/26.
//

import SwiftUI

/// Event promo: banner cover + product rail từ `page_data` (tab đầu).
struct EventBoxView: View {
    let event: EventBox?
    var currencySymbol: String = "$"
    @HotReloadObserver private var _hr

    private var bannerURL: URL? {
        guard let raw = event?.bannerUrl.trimmingCharacters(in: .whitespacesAndNewlines),
              !raw.isEmpty else { return nil }
        return URL(string: raw)
    }

    private var cornerRadius: CGFloat { NectarMetrics.radius.md }

    private var products: [ShopProduct] {
        guard let pageData = event?.pageData else { return [] }
        return HomeDTOMapper.eventPageProducts(from: pageData)
    }

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
                    RemoteImageView(url: bannerURL, contentMode: .fill)
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
                Text(event?.name ?? "")
                    .font(NectarFonts.elmsSans(size: 22.scaled, weight: .bold))
                    .foregroundStyle(NectarColors.surface)
                    .shadow(color: .black.opacity(0.45), radius: 2, y: 1)
                    .lineLimit(2)

                if let description = event?.description, !description.isEmpty {
                    Text(description)
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
        .accessibilityLabel(event?.name ?? "Event")
    }
}
