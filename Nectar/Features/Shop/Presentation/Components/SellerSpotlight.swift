import SwiftUI

/// Horizontal seller spotlight — 2-row grid.
struct SellerSpotlight: View {
    let sellerData: [Sellers]
    var title: String = "Artist Spotlight"
    var onSeeAll: (() -> Void)?
    var onSelect: ((Sellers) -> Void)?

    private var iconWidth: CGFloat { 68.scaled }
    /// Avatar + tên — phải khớp `GridItem` để tránh layout thrash khi scroll tới.
    private var rowHeight: CGFloat { iconWidth + 28.scaled }

    @HotReloadObserver private var _hr

    var body: some View {
        if !sellerData.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                Text(title)
                    .font(.system(size: NectarMetrics.font.title, weight: .semibold))
                    .foregroundColor(NectarColors.navy)

                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHGrid(
                        rows: [
                            GridItem(.fixed(rowHeight), spacing: NectarMetrics.spacing.md),
                            GridItem(.fixed(rowHeight)),
                        ],
                        spacing: NectarMetrics.spacing.sm
                    ) {
                        ForEach(sellerData) { seller in
                            Button {
                                onSelect?(seller)
                            } label: {
                                SellerSpotlightCard(seller: seller, iconW: iconWidth)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                // Chiều cao cố định 2 hàng → LazyVStack không đo lại khi ảnh load.
                .frame(height: rowHeight * 2 + NectarMetrics.spacing.md)
            }
            .padding(NectarMetrics.padding.sm)
            .background {
                LinearGradient(
                    colors: [
                        NectarColors.cardGold.opacity(0.4),
                        NectarColors.facebookBlue.opacity(0.4),
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .clipShape(RoundedRectangle(cornerRadius: NectarMetrics.radius.md))
            }
            .screenPadding()
            .hotReload()
        }
    }
}

// MARK: - Card

private struct SellerSpotlightCard: View {
    let seller: Sellers
    var iconW: CGFloat

    var body: some View {
        VStack(spacing: NectarMetrics.spacing.xxs) {
            RemoteImageView(
                url: seller.avatarURL,
                contentMode: .fill,
                showsLoadingIndicator: false
            )
            .frame(width: iconW, height: iconW)
            .clipShape(RoundedRectangle(cornerRadius: iconW / 2, style: .continuous))

            Text(seller.name)
                .font(.system(size: NectarMetrics.font.textSmall, weight: .regular))
                .foregroundColor(NectarColors.navy)
                .lineLimit(1)
                .frame(width: iconW)
        }
        .frame(width: iconW)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(seller.name)
    }
}
