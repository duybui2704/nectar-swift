import SwiftUI

/// Color / Type / Style / Size / Print location pickers.
struct ProductVariantPickers: View {
    @Binding var variants: ProductVariantState
    /// Sheet style picker — phải gắn ở ProductDetailView (full screen), không gắn ở đây.
    @Binding var showStylePickerSheet: Bool

    /// < 5 → chip ngang như Type; ≥ 5 → hàng compact + bottom sheet.
    private static let inlineStyleLimit = 5

    private var usesInlineStylePicker: Bool {
        variants.styles.count < Self.inlineStyleLimit
    }

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
            NectarLog.log("printSection === \(variants.printLocations)")
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
                        optionChip(
                            title: chip.title,
                            isSelected: variants.selectedTypeId == chip.id
                        ) {
                            variants.selectedTypeId = chip.id
                        }
                    }
                }
            }
        }
    }

    // MARK: - Style

    @ViewBuilder
    private var styleSection: some View {
        if usesInlineStylePicker {
            styleInlineSection
        } else {
            styleCompactSection
        }
    }

    /// Ít option (< 5) — chọn trực tiếp bằng chip ngang giống Type.
    private var styleInlineSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Style:", value: variants.selectedStyleName)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(variants.styles) { style in
                        optionChip(
                            title: styleChipTitle(style),
                            isSelected: variants.selectedStyleId == style.id
                        ) {
                            variants.selectedStyleId = style.id
                        }
                    }
                }
            }
        }
    }

    /// Nhiều option (≥ 5) — hàng compact, bấm mở bottom sheet.
    private var styleCompactSection: some View {
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
                Button {
                    showStylePickerSheet = true
                } label: {
                    HStack {
                        Text(styleRowTitle(style))
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
                        Image(systemName: "tshirt.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(selected ? NectarColors.green : NectarColors.textSecondary)
                            .frame(width: 52.scaled, height: 52.scaled)
                            .background(NectarColors.inputBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(selected ? NectarColors.green : Color.clear, lineWidth: 2)
                            )
                    }
                    .buttonStyle(.plain)
                }
                Spacer(minLength: 0)
            }
        }
    }

    // MARK: - Shared chips

    private func optionChip(
        title: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(NectarFonts.elmsSans(size: 13.scaled, weight: .semibold))
                .foregroundStyle(isSelected ? .white : NectarColors.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(isSelected ? NectarColors.navy : NectarColors.surface)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(NectarColors.border, lineWidth: isSelected ? 0 : 1)
                )
        }
        .buttonStyle(.plain)
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

    private func styleChipTitle(_ style: ProductStyleOption) -> String {
        style.title
    }

    private func styleRowTitle(_ style: ProductStyleOption) -> String {
        if let price = style.priceLabel, !price.isEmpty {
            return "\(style.title) | \(price)"
        }
        return style.title
    }
}

// MARK: - Style picker sheet (≥ 5 options)

struct ProductStylePickerSheet: View {
    let styles: [ProductStyleOption]
    let selectedStyleId: String?
    var onSelect: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Style")
                .font(.system(size: NectarMetrics.font.title, weight: .bold))
                .foregroundColor(NectarColors.black)

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(styles) { style in
                        styleRow(style)
                        if style.id != styles.last?.id {
                            Divider()
                        }
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func styleRow(_ style: ProductStyleOption) -> some View {
        let selected = selectedStyleId == style.id

        return Button {
            onSelect(style.id)
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(style.title)
                        .font(NectarFonts.elmsSans(size: 15.scaled, weight: .semibold))
                        .foregroundStyle(NectarColors.textPrimary)
                        .multilineTextAlignment(.leading)

                    if let price = style.priceLabel, !price.isEmpty {
                        Text(price)
                            .font(NectarFonts.elmsSans(size: 13.scaled, weight: .regular))
                            .foregroundStyle(NectarColors.textSecondary)
                    }
                }

                Spacer(minLength: 8)

                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(NectarColors.green)
                }
            }
            .padding(.horizontal, 0)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
