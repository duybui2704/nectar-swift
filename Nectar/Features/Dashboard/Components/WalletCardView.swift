import SwiftUI

struct WalletCardView: View {
    let totalBalanceVND: Decimal
    let maskedNumber: String
    let isLoading: Bool
    @Binding var balanceHidden: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Số dư khả dụng")
                    .font(BankTypography.caption)
                    .foregroundStyle(.white.opacity(0.85))
                Spacer()
                Button {
                    balanceHidden.toggle()
                    AppStorageService.shared.balanceHidden = balanceHidden
                } label: {
                    Image(systemName: balanceHidden ? "eye.slash" : "eye")
                        .foregroundStyle(.white.opacity(0.9))
                }
                .accessibilityLabel(balanceHidden ? "Hiện số dư" : "Ẩn số dư")
            }

            Group {
                if isLoading {
                    ProgressView().tint(.white)
                } else if balanceHidden {
                    Text("••••••••")
                        .font(BankTypography.amount)
                        .foregroundStyle(.white)
                        .accessibilityLabel("Số dư đã ẩn")
                } else {
                    Text(MoneyFormatter.format(totalBalanceVND))
                        .font(BankTypography.amount)
                        .foregroundStyle(.white)
                        .accessibilityLabel("Số dư \(MoneyFormatter.format(totalBalanceVND))")
                }
            }

            Text(maskedNumber)
                .font(BankTypography.caption)
                .foregroundStyle(.white.opacity(0.75))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            LinearGradient(
                colors: [BankColors.brand, BankColors.navySoft],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: BankColors.brand.opacity(0.25), radius: 12, y: 6)
    }
}
