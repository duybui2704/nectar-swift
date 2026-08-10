import SwiftUI

/// Title + stock + rating + seller.
struct ProductInfoHeader: View {
    let product: ProductDetail
    @Binding var showReturnsSheet: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            
            ExpandableText(text: product.name, lineLimit: 1)

            HStack(spacing: 12) {
                Label {
                    Text(product.inStock ? "In Stock" : "Out of Stock")
                        .font(NectarFonts.elmsSans(size: 13.scaled, weight: .medium))
                } icon: {
                    Image(systemName: product.inStock ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(product.inStock ? NectarColors.success : NectarColors.danger)
                }
                .foregroundStyle(NectarColors.textPrimary)

                Button {
                    showReturnsSheet = true
                } label: {
                    HStack(spacing: 4) {
                        Text("FREE Returns")
                            .font(NectarFonts.elmsSans(size: 13.scaled, weight: .medium))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(NectarColors.textPrimary)
                }
                .buttonStyle(.plain)

                if let rating = product.rating {
                    HStack(spacing: 4) {
                        Text(String(format: "%.1f", rating))
                            .font(NectarFonts.elmsSans(size: 13.scaled, weight: .semibold))
                        Image(systemName: "star.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Color(hex: 0xF5A623))
                    }
                    .foregroundStyle(NectarColors.textPrimary)
                }

                Spacer(minLength: 0)
            }

            Text("Designed and sold by \(product.sellerName)")
                .font(NectarFonts.elmsSans(size: 13.scaled, weight: .regular))
                .foregroundStyle(NectarColors.textSecondary)
        }
        .padding(.horizontal, NectarMetrics.layout.screenHorizontal)
        .padding(.top, 16)
    }
}
