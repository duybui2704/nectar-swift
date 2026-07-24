import SwiftUI

struct FavouriteView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: NectarMetrics.spacing.md) {
                    EmptyStateView(
                        title: "No favourites yet",
                        message: "Tap the heart on a product to save it here."
                    )
                }
                .screenPadding()
                .padding(.top, NectarMetrics.spacing.md)
            }
            .background(NectarColors.background.ignoresSafeArea())
            .navigationTitle("Favourite")
        }
    }
}
