import SwiftUI

struct ProductTrustBadges: View {
    var deliveryRegion: String = "Viet Nam"
    var deliveryWindow: String = "Aug 22 – Sep 05"

    var body: some View {
        VStack(spacing: 0) {
            trustRow(
                icon: "checkmark.shield.fill",
                iconColor: Color(hex: 0xE87722),
                title: "Printerval Guarantee",
                subtitle: nil
            )
            Divider().padding(.leading, 44)
            trustRow(
                icon: "flag.fill",
                iconColor: Color(hex: 0xE87722),
                title: "Deliver to \(deliveryRegion)",
                subtitle: deliveryWindow
            )
        }
        .padding(.vertical, 4)
        .background(Color(hex: 0xFFF4EC))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.horizontal, NectarMetrics.layout.screenHorizontal)
        .padding(.top, 16)
    }

    private func trustRow(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String?
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(iconColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(NectarFonts.elmsSans(size: 14.scaled, weight: .semibold))
                    .foregroundStyle(NectarColors.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(NectarFonts.elmsSans(size: 12.scaled, weight: .regular))
                        .foregroundStyle(NectarColors.textSecondary)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}
