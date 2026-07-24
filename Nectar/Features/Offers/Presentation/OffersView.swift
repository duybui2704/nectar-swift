import SwiftUI

struct OffersView: View {
    @StateObject private var viewModel = OffersViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if case .failure(let message) = viewModel.status {
                    StatusBanner(message: message, style: .error)
                }
                if viewModel.status == .loading && viewModel.offers.isEmpty {
                    ProgressView("Đang tải ưu đãi…")
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                } else if viewModel.offers.isEmpty {
                    EmptyStateView(
                        title: "Chưa có ưu đãi",
                        message: "Khuyến mãi và cashback sẽ hiện tại đây."
                    )
                } else {
                    ForEach(viewModel.offers) { offer in
                        OfferCard(offer: offer)
                    }
                }
            }
            .padding(16)
        }
        .background(BankColors.background.ignoresSafeArea())
        .navigationTitle("Ưu đãi")
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
    }
}

struct OfferCard: View {
    let offer: Offer

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(offer.title)
                    .font(BankTypography.headline)
                Spacer()
                Text(offer.badge)
                    .font(BankTypography.caption)
                    .foregroundStyle(BankColors.brand)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(BankColors.brandSoft)
                    .clipShape(Capsule())
            }
            Text(offer.subtitle)
                .font(BankTypography.caption)
                .foregroundStyle(BankColors.textSecondary)
            Text("HSD: \(offer.expiryText)")
                .font(.system(size: 11))
                .foregroundStyle(BankColors.textSecondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(BankColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(BankColors.border, lineWidth: 1)
        )
    }
}
