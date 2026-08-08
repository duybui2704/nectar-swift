import SwiftUI
import Combine

/// Carousel banner — ScrollView paging (tránh TabView trong ScrollView dọc).
struct HomeBannerCarousel: View {
    let banners: [HomeBanner]
    @State private var page: Int? = 0

    private var cornerRadius: CGFloat { NectarMetrics.radius.md }

    var body: some View {
        VStack(spacing: NectarMetrics.spacing.xs) {
            GeometryReader { geo in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 0) {
                        ForEach(Array(banners.enumerated()), id: \.element.id) { index, banner in
                            bannerCard(banner)
                                // frame trước → clipShape sau: bắt buộc để radius ăn trên AsyncImage
                                .frame(width: geo.size.width, height: geo.size.height)
                                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                                .id(index)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.paging)
                .scrollPosition(id: $page)
            }
            .frame(height: 140.scaled)

            pageIndicator
        }
    }

    private func bannerCard(_ banner: HomeBanner) -> some View {
        ZStack(alignment: .leading) {
            // Overlay + clipped: chặn AsyncImage `.fill` tràn ra ngoài (clipShape một mình thường fail)
            Color.clear
                .overlay {
                    RemoteImageView(url: banner.imageURL, contentMode: .fill)
                }
                .clipped()

            LinearGradient(
                colors: [
                    Color.white.opacity(0.0),
                    Color.white.opacity(0.0),
                    Color.white.opacity(0.0),
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
        .compositingGroup()
    }

    private var pageIndicator: some View {
        let current = page ?? 0
        return HStack(spacing: 6) {
            ForEach(0..<banners.count, id: \.self) { index in
                Capsule()
                    .fill(index == current ? NectarColors.green : NectarColors.border)
                    .frame(width: index == current ? 18 : 7, height: 7)
                    .animation(.easeInOut(duration: 0.2), value: current)
            }
        }
    }
}
