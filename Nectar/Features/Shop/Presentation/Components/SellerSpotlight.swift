import SwiftUI

/// Horizontal seller spotlight rail — cover + avatar, giống pattern Reels / Category.
struct SellerSpotlight: View {
    let sellerData: [Sellers]
    var title: String = "Seller Spotlight"
    var onSeeAll: (() -> Void)?
    var onSelect: ((Sellers) -> Void)?

    var body: some View {
        if !sellerData.isEmpty {
            VStack(alignment: .leading, spacing: NectarMetrics.spacing.sm) {
                HomeSectionHeader(title: title, onSeeAll: onSeeAll)
                    .screenPadding()

                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: NectarMetrics.spacing.sm) {
                        ForEach(sellerData) { seller in
                            Button {
                                onSelect?(seller)
                            } label: {
                                SellerSpotlightCard(seller: seller)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, NectarMetrics.layout.screenHorizontal)
                }
            }
        }
    }
}

// MARK: - Card

private struct SellerSpotlightCard: View {
    let seller: Sellers

    private var cardWidth: CGFloat { 156.scaled }
    private var cardHeight: CGFloat { 110.scaled }
    private var avatarSize: CGFloat { 36.scaled }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RemoteImageView(
                url: seller.backgroundURL ?? seller.avatarURL,
                contentMode: .fill,
                showsLoadingIndicator: false
            )

            LinearGradient(
                colors: [.clear, .black.opacity(0.7)],
                startPoint: .center,
                endPoint: .bottom
            )

            HStack(spacing: NectarMetrics.spacing.xxs) {
                RemoteImageView(
                    url: seller.avatarURL,
                    contentMode: .fill,
                    showsLoadingIndicator: false
                )
                .frame(width: avatarSize, height: avatarSize)
                .clipShape(Circle())
                .overlay {
                    Circle()
                        .strokeBorder(.white.opacity(0.85), lineWidth: 1.5)
                }

                Text(seller.name)
                    .font(NectarFonts.elmsSans(size: 12.scaled, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .padding(NectarMetrics.spacing.xxs)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: cardWidth, height: cardHeight)
        .clipShape(RoundedRectangle(cornerRadius: NectarMetrics.radius.md, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(seller.name)
    }
}
