import SwiftUI

/// Horizontal category rail dưới Search — data từ API `category/tree` (root nodes).
struct CategoryList: View {
    let categories: [CategoryTree]
    var onSelect: ((CategoryTree) -> Void)?

    private let itemWidth: CGFloat = 72

    var body: some View {
        Group {
            if categories.isEmpty {
                EmptyView()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(alignment: .top, spacing: NectarMetrics.spacing.sm) {
                        ForEach(categories) { category in
                            Button {
                                onSelect?(category)
                            } label: {
                                categoryItem(category)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Categories")
                .foregroundColor(NectarColors.textPrimary)
            }
        }
    }

    private func categoryItem(_ category: CategoryTree) -> some View {
        VStack(spacing: NectarMetrics.spacing.xxs) {
            RemoteImageView(url: category.imageURL, contentMode: .fill)
                .frame(width: 58.scaled, height: 58.scaled)
                .clipShape(Circle())
                .overlay {
                    Circle()
                        .stroke(NectarColors.border.opacity(0.7), lineWidth: 1)
                }

            Text(category.name)
                .font(NectarFonts.elmsSans(size: 12.scaled, weight: .medium))
                .foregroundStyle(NectarColors.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: itemWidth.scaled)
        }
        .frame(width: itemWidth.scaled)
    }
}
