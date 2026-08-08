import SwiftUI

/// Horizontal seller spotlight rail — cover + avatar, giống pattern Reels / Category.
struct SellerSpotlight: View {
    let sellerData: [Sellers]
    var title: String = "Artist Spotlight"
    var onSeeAll: (() -> Void)?
    var onSelect: ((Sellers) -> Void)?
    var iconWidth: CGFloat { 68.scaled }
    
    @HotReloadObserver private var _hr
  
    var body: some View {
        if !sellerData.isEmpty {
            VStack(alignment: .leading, spacing: NectarMetrics.spacing.sm) {
                VStack(alignment: .leading, spacing: 16) {
                    Text(title)
                        .font(.system(size: NectarMetrics.font.title, weight: .semibold))
                        .foregroundColor(NectarColors.navy)

                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHGrid(
                            rows: [
                                GridItem(.fixed(60.scaled), spacing: NectarMetrics.spacing.md),
                                GridItem(.fixed(60.scaled))
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
                }
                .padding(NectarMetrics.padding.sm)
            }
            .background {
                LinearGradient(
                    colors: [
                        NectarColors.cardGold.opacity(0.4),
                        NectarColors.facebookBlue.opacity(0.4)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .clipShape(
                    RoundedRectangle(cornerRadius: NectarMetrics.radius.md)
                )
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
        VStack(alignment: .center, spacing: NectarMetrics.spacing.xxs) {
            RemoteImageView(
                url: seller.avatarURL,
                contentMode: .fit,
                showsLoadingIndicator: false
            )
            .clipShape(RoundedRectangle(cornerRadius: iconW, style: .continuous))
            
            Text(seller.name)
                .font(.system(size: NectarMetrics.font.textNormal, weight: .regular))
                .foregroundColor(NectarColors.navy)
        }
        .frame(width: iconW, height: iconW)
        
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(seller.name)
    }
}
