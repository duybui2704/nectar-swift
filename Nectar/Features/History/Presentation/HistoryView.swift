import SwiftUI

struct HistoryView: View {
    @State private var viewModel = HistoryViewModelObservable()
    @HotReloadObserver private var _hr

    var body: some View {
        VStack(spacing: 0) {
            filterBar
            content
        }
        .background(NectarColors.background.ignoresSafeArea())
        .navigationTitle("Lịch sử")
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
        .hotReload()
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(HistoryViewModelObservable.Filter.allCases) { filter in
                    Button {
                        viewModel.selectedFilter = filter
                    } label: {
                        Text(filter.rawValue)
                            .font(NectarTypography.caption)
                            .fontWeight(viewModel.selectedFilter == filter ? .semibold : .regular)
                            .foregroundStyle(viewModel.selectedFilter == filter ? .white : NectarColors.textPrimary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(viewModel.selectedFilter == filter ? NectarColors.brand : NectarColors.surface)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(NectarColors.border, lineWidth: viewModel.selectedFilter == filter ? 0 : 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.status {
        case .loading where viewModel.transactions.isEmpty:
            ProgressView("Đang tải giao dịch…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .failure(let message) where viewModel.transactions.isEmpty:
            VStack(spacing: 12) {
                StatusBanner(message: message, style: .error)
                Button("Thử lại") { Task { await viewModel.load() } }
                    .foregroundStyle(NectarColors.brand)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        default:
            if viewModel.filteredTransactions.isEmpty {
                EmptyStateView(
                    title: "Chưa có giao dịch",
                    message: "Lịch sử chuyển tiền và thanh toán sẽ hiện tại đây."
                )
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            } else {
                List(viewModel.filteredTransactions) { tx in
                    TransactionRow(transaction: tx)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowBackground(NectarColors.surface)
                }
                .listStyle(.plain)
            }
        }
    }
}
