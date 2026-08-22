import SwiftUI

struct ProductTrustBadges: View {
    var deliveryRegion: String = "Viet Nam"
    var shipping: ShippingInfo?
    var deliveryWindow: String
    
    init(shipping: ShippingInfo?) {
           self.shipping = shipping
           self.deliveryWindow =
                   "\(shipping?.nameShipping ?? "Standard Shipping") - \(DateUtils.deliveryWindow(minDays: shipping?.defaultMinTime ?? 1, maxDays: shipping?.defaultMaxTime ?? 1))"
       }
    var body: some View {
        VStack(spacing: 0) {
            trustRow(
                icon: "ic_guarantee",
                iconColor: Color(hex: 0xE87722),
                title: "Nectar Guarantee",
                subtitle: "Don't love it? We'll fix it. For free."
            )
            Divider().padding(.leading, 44)
            trustRow(
                icon: "ic_vn",
                iconColor: Color(hex: 0xE87722),
                title: "Deliver to \(shipping?.location ?? "Viet Nam")",
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
            Image(icon)
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
