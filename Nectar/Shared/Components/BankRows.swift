import SwiftUI

struct AccountRow: View {
    let account: BankAccount
    var hideBalance: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .foregroundStyle(BankColors.brand)
                .frame(width: 40, height: 40)
                .background(BankColors.brandSoft)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(account.name)
                    .font(BankTypography.headline)
                    .foregroundStyle(BankColors.textPrimary)
                Text(account.numberMasked)
                    .font(BankTypography.caption)
                    .foregroundStyle(BankColors.textSecondary)
            }
            Spacer()
            Text(hideBalance ? "••••••" : MoneyFormatter.format(account.balance, currency: account.currency))
                .font(BankTypography.amountSmall)
                .foregroundStyle(BankColors.textPrimary)
        }
        .padding(14)
        .background(BankColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(BankColors.border, lineWidth: 1)
        )
    }

    private var iconName: String {
        switch account.type {
        case .checking: return "banknote"
        case .savings: return "building.columns"
        case .foreign: return "globe"
        }
    }
}

struct TransactionRow: View {
    let transaction: Transaction

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(transaction.isCredit ? BankColors.success : BankColors.brand)
                .frame(width: 40, height: 40)
                .background(BankColors.background)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.title)
                    .font(BankTypography.headline)
                Text(transaction.subtitle)
                    .font(BankTypography.caption)
                    .foregroundStyle(BankColors.textSecondary)
            }
            Spacer()
            Text(signedAmount)
                .font(BankTypography.amountSmall)
                .foregroundStyle(transaction.isCredit ? BankColors.success : BankColors.textPrimary)
        }
        .padding(.vertical, 8)
    }

    private var signedAmount: String {
        let formatted = MoneyFormatter.format(abs(transaction.amount), currency: transaction.currency)
        return transaction.isCredit ? "+\(formatted)" : "-\(formatted)"
    }

    private var icon: String {
        switch transaction.category {
        case .food: return "fork.knife"
        case .income: return "arrow.down.circle"
        case .transfer: return "arrow.left.arrow.right"
        case .bills: return "bolt.fill"
        case .cash: return "banknote"
        case .other: return "circle"
        }
    }
}

struct EmptyStateView: View {
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "tray")
                .font(.title)
                .foregroundStyle(BankColors.textSecondary)
            Text(title).font(BankTypography.headline)
            Text(message)
                .font(BankTypography.caption)
                .foregroundStyle(BankColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(BankColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct StatusBanner: View {
    enum Style {
        case error, info
    }

    let message: String
    var style: Style = .info

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: style == .error ? "exclamationmark.triangle.fill" : "info.circle.fill")
            Text(message)
                .font(BankTypography.caption)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .foregroundStyle(style == .error ? BankColors.danger : BankColors.brand)
        .padding(12)
        .background(style == .error ? BankColors.danger.opacity(0.08) : BankColors.brandSoft)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
