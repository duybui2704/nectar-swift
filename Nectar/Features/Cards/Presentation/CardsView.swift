import SwiftUI

struct CardsView: View {
    @StateObject private var viewModel = CardsViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if case .failure(let message) = viewModel.status {
                        StatusBanner(message: message, style: .error)
                    }
                    if viewModel.status == .loading && viewModel.cards.isEmpty {
                        ProgressView().padding(.top, 40)
                    }
                    ForEach(viewModel.cards) { card in
                        CardVisual(card: card)
                        Button {
                            Task { await viewModel.toggleFreeze(card) }
                        } label: {
                            Label(
                                card.isFrozen ? "Mở khóa thẻ" : "Khóa thẻ tạm thời",
                                systemImage: card.isFrozen ? "lock.open" : "lock.fill"
                            )
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(.bordered)
                        .tint(card.isFrozen ? BankColors.success : BankColors.danger)
                    }

                    if viewModel.cards.isEmpty, viewModel.status == .success {
                        EmptyStateView(title: "Chưa có thẻ", message: "Thẻ sẽ hiển thị tại đây.")
                    }
                }
                .padding(16)
            }
            .background(BankColors.background.ignoresSafeArea())
            .navigationTitle("Thẻ")
            .task { await viewModel.load() }
            .refreshable { await viewModel.load() }
        }
    }
}

struct CardVisual: View {
    let card: BankCard

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text(card.brand)
                    .font(BankTypography.headline)
                    .foregroundStyle(.white)
                Spacer()
                if card.isFrozen {
                    Text("FROZEN")
                        .font(BankTypography.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.white.opacity(0.2))
                        .clipShape(Capsule())
                        .foregroundStyle(.white)
                }
            }
            Text("••••  ••••  ••••  \(card.last4)")
                .font(.system(size: 20, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white)
            HStack {
                VStack(alignment: .leading) {
                    Text("CHỦ THẺ").font(BankTypography.caption).foregroundStyle(.white.opacity(0.7))
                    Text(card.holderName).foregroundStyle(.white)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("HẾT HẠN").font(BankTypography.caption).foregroundStyle(.white.opacity(0.7))
                    Text(card.expiry).foregroundStyle(.white)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: card.brand.lowercased().contains("visa")
                    ? [BankColors.navy, BankColors.navySoft]
                    : [Color(hex: 0x1E293B), Color(hex: 0x334155)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .opacity(card.isFrozen ? 0.7 : 1)
    }
}
