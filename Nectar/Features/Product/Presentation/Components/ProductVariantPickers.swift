import SwiftUI

enum VariantSection {
    case colors
    case types
    case styles
    case sizes
    case printLocations
}
/// Color / Type / Style / Size / Print location pickers.
struct ProductVariantPickers: View {
    @Binding var variants: ProductVariantState

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if !variants.colors.isEmpty {
                colorSection
            }
            if !variants.types.isEmpty {
                typeSection
            }
            if !variants.styles.isEmpty {
                styleSection
            }
            if !variants.sizes.isEmpty {
                sizeSection
            }            
            if !variants.printLocations.isEmpty {
                printSection
            }
        }
        .padding(.horizontal, NectarMetrics.layout.screenHorizontal)
        .padding(.top, 16)
        .onAppear {
          
        }
    }

    // MARK: - Color

    private var colorSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Color:", value: variants.selectedColorName)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(variants.colors) { color in
                        colorSwatch(color)
                    }
                }
            }
        }
    }

    private func colorSwatch(_ color: ProductColorOption) -> some View {
        let selected = variants.selectedColorId == color.id
        let fill = NectarColorMap.resolve(name: color.name, hex: color.hex)

        return Button {
            variants.selectedColorId = color.id
        } label: {
            ZStack {
                if let url = color.imageURL {
                    RemoteImageView(url: url, contentMode: .fill, showsLoadingIndicator: false)
                } else {
                    // Giống RN: fill theo `item.name` (ColorMap), không phụ thuộc image.
                    Circle().fill(fill)
                }

                if selected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(NectarColorMap.contrastingForeground(for: fill))
                }
            }
            .frame(width: 36.scaled, height: 36.scaled)
            .overlay(
                Circle()
                    .stroke(selected ? NectarColors.green : NectarColors.border, lineWidth: NectarMetrics.s(1.5))
            )
            .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(color.name)
    }

    // MARK: - Type

    private var typeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Type:", value: variants.selectedTypeName)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(variants.types) { chip in
                        let selected = variants.selectedTypeId == chip.id
                        Button {
                            variants.selectedTypeId = chip.id
                        } label: {
                            Text(chip.title)
                                .font(NectarFonts.elmsSans(size: 13.scaled, weight: .semibold))
                                .foregroundStyle(selected ? .white : NectarColors.textPrimary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(selected ? NectarColors.navy : NectarColors.surface)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(NectarColors.border, lineWidth: selected ? 0 : 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Style

    private var styleSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Style")
                    .font(NectarFonts.elmsSans(size: 14.scaled, weight: .semibold))
                    .foregroundStyle(NectarColors.textPrimary)
                Spacer()
                Button {} label: {
                    Text("Style Guide")
                        .font(NectarFonts.elmsSans(size: 13.scaled, weight: .medium))
                        .foregroundStyle(NectarColors.googleBlue)
                }
                .buttonStyle(.plain)
            }

            if let style = variants.selectedStyle {
                Button {} label: {
                    HStack {
                        Text(styleTitle(style))
                            .font(NectarFonts.elmsSans(size: 14.scaled, weight: .medium))
                            .foregroundStyle(NectarColors.textPrimary)
                            .lineLimit(1)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(NectarColors.textSecondary)
                    }
                    .padding(14)
                    .background(NectarColors.inputBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Size

    private var sizeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                sectionLabel("Size:", value: variants.selectedSizeName)
                Spacer()
                Button {} label: {
                    Text("Size Guide")
                        .font(NectarFonts.elmsSans(size: 13.scaled, weight: .medium))
                        .foregroundStyle(NectarColors.googleBlue)
                }
                .buttonStyle(.plain)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(variants.sizes) { size in
                        let selected = variants.selectedSizeId == size.id
                        Button {
                            variants.selectedSizeId = size.id
                        } label: {
                            Text(size.title)
                                .font(NectarFonts.elmsSans(size: 13.scaled, weight: .semibold))
                                .foregroundStyle(selected ? .white : NectarColors.textPrimary)
                                .frame(minWidth: 44.scaled)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 12)
                                .background(selected ? NectarColors.navy : NectarColors.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .stroke(NectarColors.border, lineWidth: selected ? 0 : 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Print

    private var printSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Print Location:", value: variants.selectedPrintName)

            HStack(spacing: 12) {
                ForEach(variants.printLocations) { location in
                    let selected = variants.selectedPrintId == location.id
                    Button {
                        variants.selectedPrintId = location.id
                    } label: {
                        Image(systemName: location.iconSystemName)
                            .font(.system(size: 20))
                            .foregroundStyle(selected ? NectarColors.navy : NectarColors.textSecondary)
                            .frame(width: 52.scaled, height: 52.scaled)
                            .background(NectarColors.inputBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(selected ? NectarColors.navy : Color.clear, lineWidth: 2)
                            )
                    }
                    .buttonStyle(.plain)
                }
                Spacer(minLength: 0)
            }
        }
    }

    // MARK: - Helpers

    private func sectionLabel(_ prefix: String, value: String) -> some View {
        (Text(prefix)
            .font(NectarFonts.elmsSans(size: 14.scaled, weight: .semibold))
            .foregroundStyle(NectarColors.textPrimary)
         + Text(" \(value)")
            .font(NectarFonts.elmsSans(size: 14.scaled, weight: .regular))
            .foregroundStyle(NectarColors.textPrimary))
    }

    private func styleTitle(_ style: ProductStyleOption) -> String {
        if let price = style.priceLabel, !price.isEmpty {
            return "\(style.title) | \(price)"
        }
        return style.title
    }
}
