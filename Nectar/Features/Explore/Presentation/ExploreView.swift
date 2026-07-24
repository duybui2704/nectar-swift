import SwiftUI

struct ExploreView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: NectarMetrics.spacing.md) {
                    Text("Discover categories & deals")
                        .font(NectarTypography.body)
                        .foregroundStyle(NectarColors.textSecondary)

                    EmptyStateView(
                        title: "Explore",
                        message: "Search products and find new favourites."
                    )
                }
                .screenPadding()
                .padding(.top, NectarMetrics.spacing.md)
            }
            .background(NectarColors.background.ignoresSafeArea())
            .navigationTitle("Find Products")
        }
    }
}
