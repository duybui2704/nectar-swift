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

                    ForEach(0..<10, id: \.self) { index in
                        HStack(spacing: 12) {
                            Image(systemName: "heart.fill")
                                .foregroundStyle(NectarColors.danger.opacity(0.7))
                            Text("Saved product \(index + 1)")
                                .font(NectarTypography.headline)
                            Spacer()
                        }
                        .padding(14)
                        .background(NectarColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
                .screenPadding()
                .padding(.top, NectarMetrics.spacing.md)
                .padding(.bottom, 100)
            }
            .hidesTabBarOnScroll()
            .background(NectarColors.background.ignoresSafeArea())
            .navigationTitle("Favourite")
        }
    }
}
