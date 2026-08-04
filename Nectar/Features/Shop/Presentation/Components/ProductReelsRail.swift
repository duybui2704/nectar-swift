import SwiftUI

/// Horizontal Reels strip — **thumbnail only** (no AVPlayer trên Home).
/// Video chỉ load khi mở fullscreen → tiết kiệm CPU / RAM / mạng.
struct ProductReelsRail: View {
    let reels: [ProductReel]
    var title: String = "Reels"
    var onSeeAll: (() -> Void)?
    var onSelect: ((ProductReel) -> Void)?

    @State private var selectedReel: ProductReel?

    var body: some View {
        if !reels.isEmpty {
            VStack(alignment: .leading, spacing: NectarMetrics.spacing.sm) {
                HomeSectionHeader(title: title, onSeeAll: onSeeAll)
                    .screenPadding()

                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: NectarMetrics.spacing.sm) {
                        ForEach(reels) { reel in
                            Button {
                                selectedReel = reel
                                onSelect?(reel)
                            } label: {
                                ProductReelCardView(reel: reel)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, NectarMetrics.layout.screenHorizontal)
                }
            }
            .fullScreenCover(item: $selectedReel) { reel in
                ProductReelsFullscreenView(reels: reels, initialID: reel.id)
            }
        }
    }
}

// MARK: - Card (thumbnail)

struct ProductReelCardView: View {
    let reel: ProductReel

    private var cardWidth: CGFloat { 118.scaled }
    private var cardHeight: CGFloat { cardWidth * 16.0 / 9.0 }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RemoteImageView(
                url: reel.thumbnailURL,
                contentMode: .fill,
                showsLoadingIndicator: false
            )

            LinearGradient(
                colors: [.clear, .black.opacity(0.75)],
                startPoint: .center,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(reel.productName)
                    .font(NectarFonts.elmsSans(size: 12.scaled, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                if !reel.displayPrice.isEmpty {
                    Text(reel.displayPrice)
                        .font(NectarFonts.elmsSans(size: 11.scaled, weight: .medium))
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
            .padding(NectarMetrics.spacing.xxs)
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "play.rectangle.fill")
                .font(.system(size: 14.scaled, weight: .semibold))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.35), radius: 2, y: 1)
                .padding(8)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        }
        .frame(width: cardWidth, height: cardHeight)
        .clipShape(RoundedRectangle(cornerRadius: NectarMetrics.radius.md, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: NectarMetrics.radius.md, style: .continuous))
        .accessibilityLabel("\(reel.productName), \(reel.displayPrice)")
    }
}
