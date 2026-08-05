import SwiftUI

struct CartView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: NectarMetrics.spacing.md) {
                EmptyStateView(
                    title: "Your cart is empty",
                    message: "Items you add will show up here."
                )

                ForEach(0..<10, id: \.self) { index in
                    HStack {
                        Text("Suggested item \(index + 1)")
                            .font(NectarTypography.headline)
                        Spacer()
                        Text("Add")
                            .font(NectarTypography.caption)
                            .foregroundStyle(NectarColors.green)
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
        .navigationTitle("My Cart")
    }
}
