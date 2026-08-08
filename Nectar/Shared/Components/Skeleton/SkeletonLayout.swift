import SwiftUI

/// Preset skeleton theo bố cục UI Nectar — gọi từ từng section.
enum SkeletonLayout {

    // MARK: - Banner (HomeBannerCarousel ≈ 140pt)

    static func banner(height: CGFloat = 140) -> some View {
        VStack(spacing: NectarMetrics.spacing.xs) {
            SkeletonBone.rect(
                height: height.scaled,
                cornerRadius: SkeletonStyle.cornerMedium
            )
            HStack(spacing: 6) {
                Capsule().fill(SkeletonStyle.base).frame(width: 18, height: 7)
                ForEach(0..<3, id: \.self) { _ in
                    Circle().fill(SkeletonStyle.base).frame(width: 7, height: 7)
                }
            }
            .skeletonShimmer()
        }
    }

    // MARK: - Section header

    static func sectionHeader() -> some View {
        HStack {
            SkeletonBone.rect(width: 140.scaled, height: 22.scaled, cornerRadius: 6)
            Spacer()
            SkeletonBone.rect(width: 52.scaled, height: 14.scaled, cornerRadius: 4)
        }
        .screenPadding()
    }

    // MARK: - Category rail (CategoryList)

    static func categoryRail(count: Int = 6) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(alignment: .top, spacing: NectarMetrics.spacing.sm) {
                ForEach(0..<count, id: \.self) { _ in
                    VStack(spacing: NectarMetrics.spacing.xxs) {
                        SkeletonBone.circle(size: 58.scaled)
                        SkeletonBone.rect(width: 56.scaled, height: 10.scaled)
                        SkeletonBone.rect(width: 40.scaled, height: 10.scaled)
                    }
                    .frame(width: 72.scaled)
                }
            }
            .padding(.vertical, 2)
        }
    }

    // MARK: - Product card (ProductCardView 173×230)

    static func productCard() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            SkeletonBone.rect(
                height: 100.scaled,
                cornerRadius: SkeletonStyle.cornerMedium
            )
            .padding(.top, NectarMetrics.spacing.sm)
            .padding(.horizontal, NectarMetrics.spacing.xs)

            VStack(alignment: .leading, spacing: 6) {
                SkeletonBone.line(height: 14.scaled, widthFactor: 0.9)
                SkeletonBone.line(height: 14.scaled, widthFactor: 0.55)
                SkeletonBone.line(height: 11.scaled, widthFactor: 0.4)
            }
            .padding(.horizontal, NectarMetrics.spacing.sm)
            .padding(.top, NectarMetrics.spacing.xs)

            Spacer(minLength: 8)

            HStack {
                SkeletonBone.rect(width: 48.scaled, height: 16.scaled)
                Spacer()
                SkeletonBone.rect(
                    width: 40.scaled,
                    height: 40.scaled,
                    cornerRadius: 14
                )
            }
            .padding(.horizontal, NectarMetrics.spacing.sm)
            .padding(.bottom, NectarMetrics.spacing.sm)
        }
        .frame(width: 173.scaled, height: 230.scaled)
        .background(NectarColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: SkeletonStyle.cornerLarge, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: SkeletonStyle.cornerLarge, style: .continuous)
                .strokeBorder(NectarColors.border.opacity(0.7), lineWidth: 1)
        )
    }

    // MARK: - Product horizontal rail

    static func productRail(title: Bool = true, count: Int = 3) -> some View {
        VStack(alignment: .leading, spacing: NectarMetrics.spacing.sm) {
            if title {
                sectionHeader()
            }
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: NectarMetrics.spacing.sm) {
                    ForEach(0..<count, id: \.self) { _ in
                        productCard()
                    }
                }
                .padding(.horizontal, NectarMetrics.layout.screenHorizontal)
            }
        }
    }

    // MARK: - Reels rail (118 × 16:9)

    static func reelsRail(title: Bool = true, count: Int = 4) -> some View {
        let cardW = 118.scaled
        let cardH = cardW * 16.0 / 9.0

        return VStack(alignment: .leading, spacing: NectarMetrics.spacing.sm) {
            if title {
                sectionHeader()
            }
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: NectarMetrics.spacing.sm) {
                    ForEach(0..<count, id: \.self) { _ in
                        SkeletonBone.rect(
                            width: cardW,
                            height: cardH,
                            cornerRadius: SkeletonStyle.cornerMedium
                        )
                    }
                }
                .padding(.horizontal, NectarMetrics.layout.screenHorizontal)
            }
        }
    }

    // MARK: - Seller spotlight (2-row grid)

    static func sellerSpotlight(count: Int = 8) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            SkeletonBone.rect(width: 160.scaled, height: 22.scaled)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHGrid(
                    rows: [
                        GridItem(.fixed(60.scaled), spacing: NectarMetrics.spacing.md),
                        GridItem(.fixed(60.scaled)),
                    ],
                    spacing: NectarMetrics.spacing.sm
                ) {
                    ForEach(0..<count, id: \.self) { _ in
                        SkeletonBone.rect(
                            width: 68.scaled,
                            height: 68.scaled,
                            cornerRadius: 34.scaled
                        )
                    }
                }
            }
        }
        .padding(NectarMetrics.padding.sm)
        .background(SkeletonStyle.surface.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: SkeletonStyle.cornerMedium, style: .continuous))
        .screenPadding()
    }

    // MARK: - Event box banner

    static func eventBanner(height: CGFloat = 160) -> some View {
        VStack(alignment: .leading, spacing: NectarMetrics.spacing.sm) {
            SkeletonBone.rect(
                height: height.scaled,
                cornerRadius: SkeletonStyle.cornerMedium
            )
            .screenPadding()
            productRail(title: true, count: 3)
        }
    }

    // MARK: - Generic text block (PDP / forms)

    static func textBlock(lines: Int = 3) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(0..<lines, id: \.self) { index in
                SkeletonBone.line(
                    height: index == 0 ? 18.scaled : 14.scaled,
                    widthFactor: index == lines - 1 ? 0.55 : (index == 0 ? 0.85 : 1)
                )
            }
        }
    }

    // MARK: - Circle + text row (list cell)

    static func avatarRow() -> some View {
        HStack(spacing: NectarMetrics.spacing.sm) {
            SkeletonBone.circle(size: 44.scaled)
            VStack(alignment: .leading, spacing: 8) {
                SkeletonBone.line(height: 14.scaled, widthFactor: 0.5)
                SkeletonBone.line(height: 12.scaled, widthFactor: 0.35)
            }
        }
    }
}
