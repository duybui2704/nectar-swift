import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var session: AppSession
    @StateObject private var viewModel = DashboardViewModel()
    @State private var balanceHidden = AppStorageService.shared.balanceHidden
    @HotReloadObserver private var _hr

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    if case .failure(let message) = viewModel.status {
                        StatusBanner(message: message, style: .error)
                    }
                    walletCard
                    quickActions
                    accountsSection
                    recentSection
                }
                .padding(16)
            }
            .background(BankColors.background.ignoresSafeArea())
            .navigationBarHidden(true)
            .task { await viewModel.load() }
            .refreshable { await viewModel.load() }
            .navigationDestination(for: String.self) { accountId in
                AccountDetailView(accountId: accountId)
            }
            .hotReload()
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Xin chào,")
                    .font(BankTypography.caption)
                    .foregroundStyle(BankColors.textSecondary)
                Text(session.userDisplayName)
                    .font(BankTypography.title)
            }
            Spacer()
            Image(systemName: "bell")
                .font(.title3)
                .foregroundStyle(BankColors.brand)
                .frame(width: 40, height: 40)
                .background(BankColors.surface)
                .clipShape(Circle())
        }
    }

    private var walletCard: some View {
        WalletCardView(
            totalBalanceVND: viewModel.totalBalanceVND,
            maskedNumber: viewModel.accounts.first?.numberMasked ?? "**** ----",
            isLoading: viewModel.status == .loading && viewModel.accounts.isEmpty,
            balanceHidden: $balanceHidden
        )
    }

  

    private func walletAction<Destination: View>(
        title: String,
        icon: String,
        @ViewBuilder destination: () -> Destination
    ) -> some View {
        NavigationLink(destination: destination) {
            VStack(spacing: 6) {
                Image(systemName: icon).font(.body.weight(.semibold))
                Text(title).font(.system(size: 11, weight: .medium))
            }
            .foregroundStyle(BankColors.brand)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(BankColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(BankColors.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var quickActions: some View {
        HStack(spacing: 12) {
            NavigationLink { TransferView() } label: {
                QuickActionChip(title: "Chuyển tiền", icon: "arrow.left.arrow.right")
            }
            NavigationLink { CardsView() } label: {
                QuickActionChip(title: "Thẻ", icon: "creditcard")
            }
            NavigationLink { HistoryView() } label: {
                QuickActionChip(title: "Lịch sử", icon: "clock.arrow.circlepath")
            }
        }
    }

    private var accountsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Tài khoản / Ví").font(BankTypography.headline)
            if viewModel.accounts.isEmpty, viewModel.status == .loading {
                ProgressView()
            } else {
                ForEach(viewModel.accounts) { account in
                    NavigationLink(value: account.id) {
                        AccountRow(account: account, hideBalance: balanceHidden)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Giao dịch gần đây").font(BankTypography.headline)
                Spacer()
                NavigationLink("Xem tất cả") { HistoryView() }
                    .font(BankTypography.caption)
                    .foregroundStyle(BankColors.brand)
            }
            if viewModel.recentTransactions.isEmpty && viewModel.status == .loading {
                ProgressView()
            } else if viewModel.recentTransactions.isEmpty {
                EmptyStateView(title: "Chưa có giao dịch", message: "Giao dịch sẽ xuất hiện tại đây.")
            } else {
                ForEach(viewModel.recentTransactions) { tx in
                    TransactionRow(transaction: tx)
                        .padding(12)
                        .background(BankColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }
}

struct QuickActionChip: View {
    let title: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(BankColors.brand)
                .frame(width: 44, height: 44)
                .background(BankColors.brandSoft)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            Text(title)
                .font(BankTypography.caption)
                .foregroundStyle(BankColors.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(BankColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(BankColors.border, lineWidth: 1))
    }
}

struct PlaceholderFeatureView: View {
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "hammer.fill")
                .font(.largeTitle)
                .foregroundStyle(BankColors.brand)
            Text(title).font(BankTypography.title)
            Text(message)
                .font(BankTypography.body)
                .foregroundStyle(BankColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(BankColors.background.ignoresSafeArea())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
