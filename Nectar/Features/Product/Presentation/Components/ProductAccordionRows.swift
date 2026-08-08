import SwiftUI

struct ProductAccordionRows: View {
    let product: ProductDetail?

    var body: some View {
        VStack(spacing: 0) {
            row(icon: "info.circle", title: "Product Information")
            row(icon: "doc.text", title: "Policies", subtitle: "Returns & replacements")
            row(icon: "flag", title: "Having trouble?")
            row(
                icon: "star.bubble",
                title: reviewTitle,
                trailing: { ratingBadge }
            )
            row(
                icon: "person.crop.circle",
                title: "Designed and sold by",
                subtitle: product?.sellerName
            )
        }
        .padding(.top, 8)
    }

    private var reviewTitle: String {
        if let count = product?.reviewCount, count > 0 {
            return "\(count) Reviews"
        }
        return "Reviews"
    }

    @ViewBuilder
    private var ratingBadge: some View {
        if let rating = product?.rating {
            HStack(spacing: 4) {
                Text(String(format: "%.1f", rating))
                    .font(NectarFonts.elmsSans(size: 13.scaled, weight: .semibold))
                Image(systemName: "star.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(hex: 0xF5A623))
            }
            .foregroundStyle(NectarColors.textPrimary)
        }
    }

    private func row<Trailing: View>(
        icon: String,
        title: String,
        subtitle: String? = nil,
        @ViewBuilder trailing: () -> Trailing = { EmptyView() }
    ) -> some View {
        VStack(spacing: 0) {
            Button {} label: {
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundStyle(NectarColors.textPrimary)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(NectarFonts.elmsSans(size: 15.scaled, weight: .medium))
                            .foregroundStyle(NectarColors.textPrimary)
                        if let subtitle, !subtitle.isEmpty {
                            Text(subtitle)
                                .font(NectarFonts.elmsSans(size: 12.scaled, weight: .regular))
                                .foregroundStyle(NectarColors.textSecondary)
                        }
                    }

                    Spacer(minLength: 8)
                    trailing()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(NectarColors.textSecondary)
                }
                .padding(.horizontal, NectarMetrics.layout.screenHorizontal)
                .padding(.vertical, 16)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Divider()
                .padding(.leading, NectarMetrics.layout.screenHorizontal + 36)
        }
    }
}
