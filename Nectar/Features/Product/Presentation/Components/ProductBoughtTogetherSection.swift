import SwiftUI

struct ProductBoughtTogetherSection: View {
    @Binding var items: [BoughtTogetherItem]
    var totalLabel: String
    var onToggle: (String) -> Void
    var onAddAll: () -> Void

    var body: some View {
        if items.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: 14) {
                Text("Frequently Bought Together")
                    .font(NectarFonts.elmsSans(size: 17.scaled, weight: .bold))
                    .foregroundStyle(NectarColors.textPrimary)
                    .padding(.horizontal, NectarMetrics.layout.screenHorizontal)

                VStack(spacing: 0) {
                    ForEach(items) { item in
                        boughtRow(item)
                        if item.id != items.last?.id {
                            Divider().padding(.leading, 56)
                        }
                    }
                }
                .padding(.vertical, 4)
                .background(Color(hex: 0xFFF8F0))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.horizontal, NectarMetrics.layout.screenHorizontal)

                HStack {
                    Text(totalLabel)
                        .font(NectarFonts.elmsSans(size: 18.scaled, weight: .bold))
                        .foregroundStyle(NectarColors.danger)
                    Spacer()
                    Button(action: onAddAll) {
                        Text("ADD ALL TO CART")
                            .font(NectarFonts.elmsSans(size: 13.scaled, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(NectarColors.danger)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, NectarMetrics.layout.screenHorizontal)
            }
            .padding(.vertical, 16)
            .background(Color(hex: 0xFFF8F0).opacity(0.5))
        }
    }

    private func boughtRow(_ item: BoughtTogetherItem) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Button {
                onToggle(item.id)
            } label: {
                Image(systemName: item.isSelected ? "checkmark.square.fill" : "square")
                    .font(.system(size: 22))
                    .foregroundStyle(item.isSelected ? NectarColors.danger : NectarColors.border)
            }
            .buttonStyle(.plain)
            .padding(.top, 8)

            RemoteImageView(url: item.imageURL, contentMode: .fit, showsLoadingIndicator: false)
                .frame(width: 64.scaled, height: 64.scaled)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                Text(item.name)
                    .font(NectarFonts.elmsSans(size: 14.scaled, weight: .medium))
                    .foregroundStyle(NectarColors.textPrimary)
                    .lineLimit(2)

                Text(item.displayPrice)
                    .font(NectarFonts.elmsSans(size: 15.scaled, weight: .bold))
                    .foregroundStyle(NectarColors.danger)

                Button {} label: {
                    Text("Edit")
                        .font(NectarFonts.elmsSans(size: 13.scaled, weight: .semibold))
                        .foregroundStyle(NectarColors.googleBlue)
                }
                .buttonStyle(.plain)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}
