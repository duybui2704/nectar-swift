import SwiftUI

/// Header section: title + "See all".
struct HomeSectionHeader: View {
    let title: String
    var onSeeAll: (() -> Void)?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(NectarTypography.title)
                    .foregroundStyle(NectarColors.textPrimary)

            Spacer(minLength: 8)

            Button {
                onSeeAll?()
            } label: {
                Text("See all")
                    .font(NectarTypography.caption.weight(.semibold))
                    .foregroundStyle(NectarColors.green)
            }
            .buttonStyle(.plain)
        }
    }
}
