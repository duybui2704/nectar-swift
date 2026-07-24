import SwiftUI

struct AccountDetailView: View {
    let accountId: String
    @StateObject private var viewModel: AccountDetailViewModel

    init(accountId: String) {
        self.accountId = accountId
        _viewModel = StateObject(wrappedValue: AccountDetailViewModel(accountId: accountId))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if case .failure(let message) = viewModel.status {
                    StatusBanner(message: message, style: .error)
                }

                if let account = viewModel.account {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(account.name)
                            .font(BankTypography.caption)
                            .foregroundStyle(.white.opacity(0.8))
                        Text(MoneyFormatter.format(account.balance, currency: account.currency))
                            .font(BankTypography.amount)
                            .foregroundStyle(.white)
                            .accessibilityLabel("Số dư \(MoneyFormatter.format(account.balance, currency: account.currency))")
                        Text(account.numberMasked)
                            .font(BankTypography.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(BankColors.brand)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                } else if viewModel.status == .loading {
                    ProgressView().frame(maxWidth: .infinity).padding()
                }

                Text("Lịch sử giao dịch")
                    .font(BankTypography.headline)

                if viewModel.transactions.isEmpty, viewModel.status == .success {
                    EmptyStateView(title: "Trống", message: "Tài khoản chưa có giao dịch.")
                } else if viewModel.transactions.isEmpty, viewModel.status == .loading {
                    ProgressView()
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.transactions) { tx in
                            TransactionRow(transaction: tx)
                            Divider()
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(BankColors.background.ignoresSafeArea())
        .navigationTitle("Chi tiết tài khoản")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
    }
}
