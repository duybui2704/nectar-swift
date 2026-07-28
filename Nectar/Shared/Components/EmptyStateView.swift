import SwiftUI

/// Empty state dùng chung (Cart / Favourite / …).
struct EmptyStateView: View {
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "tray")
                .font(.title)
                .foregroundStyle(NectarColors.textSecondary)
            Text(title).font(NectarTypography.headline)
            Text(message)
                .font(NectarTypography.caption)
                .foregroundStyle(NectarColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(NectarColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

/// Banner lỗi / info dùng chung.
struct StatusBanner: View {
    enum Style {
        case error, info
    }

    let message: String
    var style: Style = .info

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: style == .error ? "exclamationmark.triangle.fill" : "info.circle.fill")
            Text(message)
                .font(NectarTypography.caption)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .foregroundStyle(style == .error ? NectarColors.danger : NectarColors.brand)
        .padding(12)
        .background(style == .error ? NectarColors.danger.opacity(0.08) : NectarColors.brandSoft)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
