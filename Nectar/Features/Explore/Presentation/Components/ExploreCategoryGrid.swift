import SwiftUI

/// Lưới category 2 cột — UI Explore (pastel card).
struct ExploreCategoryGrid: View {
    let categories: [CategoryTree]
    var onSelect: ((CategoryTree) -> Void)?

    private let columns = [
        GridItem(.flexible(), spacing: NectarMetrics.spacing.sm),
        GridItem(.flexible(), spacing: NectarMetrics.spacing.sm),
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: NectarMetrics.spacing.sm) {
            ForEach(Array(categories.enumerated()), id: \.element.id) { index, category in
                Button {
                    onSelect?(category)
                } label: {
                    ExploreCategoryCard(
                        category: category,
                        style: ExploreCategoryPalette.style(at: index)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Card

private struct ExploreCategoryCard: View {
    let category: CategoryTree
    let style: ExploreCategoryPalette.Style

    var body: some View {
        VStack(spacing: NectarMetrics.spacing.xs) {
            RemoteImageView(
                url: category.resolvedImageURL,
                contentMode: .fit,
                showsLoadingIndicator: false
            )
            .frame(height: 90.scaled)
            .frame(maxWidth: .infinity)

            Text(category.name)
                .font(NectarFonts.elmsSans(size: 15.scaled, weight: .bold))
                .foregroundStyle(NectarColors.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .padding(.horizontal, 6)
                .padding(.bottom, NectarMetrics.spacing.xs)
        }
        .padding(.top, NectarMetrics.spacing.sm)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 180.scaled)
        .background(style.background)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(style.border, lineWidth: 1.5)
        }
    }
}

// MARK: - Palette (theo mock)

enum ExploreCategoryPalette {
    struct Style {
        let background: Color
        let border: Color
    }

    private static let styles: [Style] = [
        Style(background: Color(red: 0.90, green: 0.97, blue: 0.92), border: Color(red: 0.45, green: 0.72, blue: 0.52)),
        Style(background: Color(red: 0.99, green: 0.94, blue: 0.88), border: Color(red: 0.93, green: 0.62, blue: 0.35)),
        Style(background: Color(red: 0.99, green: 0.90, blue: 0.92), border: Color(red: 0.90, green: 0.45, blue: 0.55)),
        Style(background: Color(red: 0.94, green: 0.90, blue: 0.98), border: Color(red: 0.70, green: 0.50, blue: 0.88)),
        Style(background: Color(red: 0.99, green: 0.96, blue: 0.85), border: Color(red: 0.90, green: 0.75, blue: 0.25)),
        Style(background: Color(red: 0.88, green: 0.95, blue: 0.99), border: Color(red: 0.55, green: 0.75, blue: 0.92)),
    ]

    static func style(at index: Int) -> Style {
        styles[index % styles.count]
    }
}
