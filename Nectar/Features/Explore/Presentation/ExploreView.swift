import SwiftUI

struct ExploreView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: NectarMetrics.spacing.md) {
                    Text("Discover categories & deals")
                        .font(NectarTypography.body)
                        .foregroundStyle(NectarColors.textSecondary)

                    ForEach(0..<12, id: \.self) { index in
                        HStack(spacing: 12) {
                            Image(systemName: "tag.fill")
                                .foregroundStyle(NectarColors.green)
                                .frame(width: 40, height: 40)
                                .background(NectarColors.brandSoft)
                                .clipShape(RoundedRectangle(cornerRadius: 10))

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Category \(index + 1)").font(NectarTypography.headline)
                                Text("Browse deals and new arrivals")
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
                .screenPadding()
                .padding(.top, NectarMetrics.spacing.md)
                .padding(.bottom, 100)
            }
            .hidesTabBarOnScroll()
            .background(NectarColors.background.ignoresSafeArea())
            .navigationTitle("Find Products")
        }
    }
}
