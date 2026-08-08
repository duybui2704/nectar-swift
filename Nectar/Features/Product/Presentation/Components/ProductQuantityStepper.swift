import SwiftUI

struct ProductQuantityStepper: View {
    @Binding var quantity: Int
    var bulkHint: String?
    var onDecrement: () -> Void
    var onIncrement: () -> Void

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Quantity")
                    .font(NectarFonts.elmsSans(size: 14.scaled, weight: .semibold))
                    .foregroundStyle(NectarColors.textPrimary)
                if let bulkHint, !bulkHint.isEmpty {
                    Text(bulkHint)
                        .font(NectarFonts.elmsSans(size: 12.scaled, weight: .regular))
                        .foregroundStyle(NectarColors.textSecondary)
                }
            }

            Spacer()

            HStack(spacing: 0) {
                stepButton(systemName: "minus", action: onDecrement)
                Text("\(quantity)")
                    .font(NectarFonts.elmsSans(size: 16.scaled, weight: .semibold))
                    .foregroundStyle(NectarColors.textPrimary)
                    .frame(width: 44)
                stepButton(systemName: "plus", action: onIncrement)
            }
            .background(NectarColors.inputBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .padding(.horizontal, NectarMetrics.layout.screenHorizontal)
        .padding(.top, 20)
    }

    private func stepButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(NectarColors.textPrimary)
                .frame(width: 40, height: 40)
        }
        .buttonStyle(.plain)
    }
}
