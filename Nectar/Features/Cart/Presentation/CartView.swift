import SwiftUI

struct CartView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: NectarMetrics.spacing.md) {
                    EmptyStateView(
                        title: "Your cart is empty",
                        message: "Items you add will show up here."
                    )
                }
                .screenPadding()
                .padding(.top, NectarMetrics.spacing.md)
            }
            .background(NectarColors.background.ignoresSafeArea())
            .navigationTitle("My Cart")
        }
    }
}
