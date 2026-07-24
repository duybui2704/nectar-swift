import SwiftUI

struct TransferView: View {
    @StateObject private var viewModel = TransferViewModel()
    @Environment(\.dismiss) private var dismiss
    @HotReloadObserver private var _hr

    var body: some View {
        Group {
            switch viewModel.step {
            case .form:
                formContent
            case .confirm:
                confirmContent
            case .otp:
                otpContent
            case .success(let result):
                successContent(result)
            }
        }
        .navigationTitle("Chuyển tiền")
        .navigationBarTitleDisplayMode(.inline)
        .background(NectarColors.background.ignoresSafeArea())
        .task { await viewModel.load() }
        .hotReload()
    }

    private var formContent: some View {
        Form {
            Section("Từ tài khoản") {
                Picker("Tài khoản", selection: $viewModel.fromAccountId) {
                    ForEach(viewModel.accounts.filter { $0.currency == "VND" }) { account in
                        Text("\(account.name) · \(MoneyFormatter.format(account.availableBalance))")
                            .tag(account.id)
                    }
                }
            }

            Section("Người nhận") {
                Picker("Hình thức", selection: $viewModel.recipientMode) {
                    ForEach(TransferViewModel.RecipientMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                if viewModel.recipientMode == .saved {
                    Picker("Thụ hưởng", selection: $viewModel.beneficiaryId) {
                        ForEach(viewModel.beneficiaries) { ben in
                            Text("\(ben.name) · \(ben.bankName)").tag(ben.id)
                        }
                    }
                } else {
                    TextField("Tên người nhận", text: $viewModel.newName)
                    TextField("Ngân hàng", text: $viewModel.newBank)
                    TextField("Số tài khoản", text: $viewModel.newAccountNumber)
                        .keyboardType(.numberPad)
                }
            }

            Section("Số tiền (VND)") {
                TextField("Tối thiểu 10.000", text: $viewModel.amountText)
                    .keyboardType(.numberPad)
                TextField("Nội dung", text: $viewModel.note)
            }

            if case .error(let message) = viewModel.status {
                Section { Text(message).foregroundStyle(NectarColors.danger) }
            }

            Section {
                Button("Tiếp tục") { viewModel.validateAndConfirm() }
                    .disabled(viewModel.status == .loading)
            }
        }
    }

    private var confirmContent: some View {
        VStack(spacing: 16) {
            Spacer()
            Text("Xác nhận chuyển khoản").font(NectarTypography.title)
            if let amount = viewModel.amount {
                Text(MoneyFormatter.format(amount))
                    .font(NectarTypography.amount)
                    .foregroundStyle(NectarColors.brand)
            }
            summaryCard
            if case .error(let message) = viewModel.status {
                Text(message).foregroundStyle(NectarColors.danger)
            }
            Button { viewModel.proceedToOTP() } label: {
                Text("Tiếp tục xác thực OTP")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .foregroundStyle(.white)
            .background(NectarColors.brand)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal)
            Button("Quay lại") { viewModel.goBackToForm() }
                .foregroundStyle(NectarColors.brand)
            Spacer()
        }
    }

    private var otpContent: some View {
        VStack(spacing: 16) {
            Spacer()
            OTPInputView(
                code: $viewModel.otpCode,
                length: 6,
                title: "Nhập mã OTP",
                subtitle: "Mã xác thực đã gửi đến số điện thoại đăng ký (demo)."
            )
            if case .error(let message) = viewModel.status {
                Text(message).foregroundStyle(NectarColors.danger)
            }
            Button {
                Task { await viewModel.verifyOTPAndSubmit() }
            } label: {
                Group {
                    if viewModel.isSubmitting {
                        ProgressView().tint(.white)
                    } else {
                        Label("Xác nhận & gửi", systemImage: "faceid")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .foregroundStyle(.white)
            .background(NectarColors.brand)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal)
            .disabled(viewModel.isSubmitting)
            Button("Quay lại") { viewModel.goBackToConfirm() }
                .foregroundStyle(NectarColors.brand)
            Spacer()
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            labeled("Từ", viewModel.selectedAccount?.name ?? "")
            labeled("Đến", viewModel.confirmRecipientName)
            labeled("Ngân hàng", viewModel.confirmRecipientBank)
            labeled("STK", viewModel.confirmRecipientAccount)
            labeled("Nội dung", viewModel.note.isEmpty ? "—" : viewModel.note)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(NectarColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal)
    }

    private func successContent(_ result: TransferResult) -> some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(NectarColors.success)
            Text("Chuyển thành công").font(NectarTypography.title)
            Text("Mã tham chiếu: \(result.referenceId)")
                .font(NectarTypography.caption)
                .foregroundStyle(NectarColors.textSecondary)
            if let amount = viewModel.amount {
                Text(MoneyFormatter.format(amount)).font(NectarTypography.amountSmall)
            }
            Button("Hoàn tất") {
                viewModel.reset()
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .tint(NectarColors.brand)
            Spacer()
        }
    }

    private func labeled(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title).foregroundStyle(NectarColors.textSecondary)
            Spacer()
            Text(value).font(NectarTypography.headline)
        }
    }
}
