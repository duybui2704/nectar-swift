import SwiftUI

struct ShopView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: NectarMetrics.spacing.md) {
                    ScrollOffsetTracker()

                    Text("Find products you love")
                        .font(NectarTypography.body)
                        .foregroundStyle(NectarColors.textSecondary)

                    ForEach(0..<12, id: \.self) { index in
                        demoRow(
                            title: "Fresh pick #\(index + 1)",
                            subtitle: "Groceries delivered to your door"
                        )
                    }
                }
                .screenPadding()
                .padding(.top, NectarMetrics.spacing.md)
                .padding(.bottom, 100)
            }
            .hidesTabBarOnScroll()
            .background(NectarColors.background.ignoresSafeArea())
            .navigationTitle("Shop")
        }
    }

    private func demoRow(title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(NectarColors.brandSoft)
                .frame(width: 56, height: 56)
                .overlay(
                    Image(systemName: "leaf.fill")
                        .foregroundStyle(NectarColors.green)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(NectarTypography.headline)
                Text(subtitle)
                    .font(NectarTypography.caption)
                    .foregroundStyle(NectarColors.textSecondary)
            }
            Spacer()
        }
        .padding(14)
        .background(NectarColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
