import SwiftUI

struct ShopView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: NectarMetrics.spacing.md) {
                    Text("Find products you love")
                        .font(NectarTypography.body)
                        .foregroundStyle(NectarColors.textSecondary)

                    EmptyStateView(
                        title: "Shop",
                        message: "Browse groceries and everyday essentials."
                    )
                }
                .screenPadding()
                .padding(.top, NectarMetrics.spacing.md)
            }
            .background(NectarColors.background.ignoresSafeArea())
            .navigationTitle("Shop")
        }
    }
}
