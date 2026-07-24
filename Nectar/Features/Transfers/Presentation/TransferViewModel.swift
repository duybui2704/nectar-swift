import Foundation
import Combine

@MainActor
final class TransferViewModel: ObservableObject {
    enum Step: Equatable {
        case form
        case confirm
        case otp
        case success(TransferResult)
    }

    enum Status: Equatable {
        case idle, loading, error(String)
    }

    enum RecipientMode: String, CaseIterable, Identifiable {
        case saved = "Đã lưu"
        case new = "Mới"
        var id: String { rawValue }
    }

    @Published var fromAccountId = ""
    @Published var beneficiaryId = ""
    @Published var recipientMode: RecipientMode = .saved
    @Published var newName = ""
    @Published var newBank = ""
    @Published var newAccountNumber = ""
    @Published var amountText = ""
    @Published var note = ""
    @Published var otpCode = ""
    @Published private(set) var accounts: [BankAccount] = []
    @Published private(set) var beneficiaries: [Beneficiary] = []
    @Published private(set) var step: Step = .form
    @Published private(set) var status: Status = .idle
    @Published private(set) var isSubmitting = false

    private let accountRepo: AccountRepository
    private let transferRepo: TransferRepository
    private let biometric: BiometricAuthService
    private let storage: AppStorageService

    init(
        accountRepo: AccountRepository = MockAccountRepository(),
        transferRepo: TransferRepository = MockTransferRepository(),
        biometric: BiometricAuthService? = nil,
        storage: AppStorageService = .shared
    ) {
        self.accountRepo = accountRepo
        self.transferRepo = transferRepo
        self.biometric = biometric ?? .shared
        self.storage = storage
    }

    var amount: Decimal? {
        let cleaned = amountText.replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: ".", with: "")
            .trimmingCharacters(in: .whitespaces)
        guard let value = Decimal(string: cleaned), value > 0 else { return nil }
        return value
    }

    var selectedAccount: BankAccount? {
        accounts.first { $0.id == fromAccountId }
    }

    var selectedBeneficiary: Beneficiary? {
        beneficiaries.first { $0.id == beneficiaryId }
    }

    var confirmRecipientName: String {
        switch recipientMode {
        case .saved: return selectedBeneficiary?.name ?? ""
        case .new: return newName
        }
    }

    var confirmRecipientBank: String {
        switch recipientMode {
        case .saved: return selectedBeneficiary?.bankName ?? ""
        case .new: return newBank
        }
    }

    var confirmRecipientAccount: String {
        switch recipientMode {
        case .saved: return selectedBeneficiary?.accountMasked ?? ""
        case .new:
            let digits = newAccountNumber.filter(\.isNumber)
            guard digits.count >= 4 else { return newAccountNumber }
            return "**** \(String(digits.suffix(4)))"
        }
    }

    func load() async {
        status = .loading
        do {
            async let a = accountRepo.fetchAccounts()
            async let b = transferRepo.fetchBeneficiaries()
            accounts = try await a
            beneficiaries = try await b
            if fromAccountId.isEmpty {
                fromAccountId = accounts.first(where: { $0.currency == "VND" })?.id
                    ?? accounts.first?.id ?? ""
            }
            if beneficiaryId.isEmpty { beneficiaryId = beneficiaries.first?.id ?? "" }
            status = .idle
        } catch {
            status = .error(error.localizedDescription)
        }
    }

    func validateAndConfirm() {
        guard let validationError = validateForm() else {
            status = .idle
            step = .confirm
            return
        }
        status = .error(validationError)
    }

    func proceedToOTP() {
        step = .otp
        otpCode = ""
        status = .idle
    }

    func verifyOTPAndSubmit() async {
        guard !isSubmitting else { return }
        guard otpCode == TransferConstants.mockOTPCode else {
            status = .error("OTP không đúng. Demo: \(TransferConstants.mockOTPCode)")
            return
        }
        await submitTransfer()
    }

    func submit() async {
        await submitTransfer()
    }

    private func submitTransfer() async {
        guard !isSubmitting else { return }
        guard let amount, let from = selectedAccount else { return }

        if storage.biometricEnabled {
            let ok = await biometric.authenticate(reason: "Xác nhận chuyển \(MoneyFormatter.format(amount))")
            guard ok else {
                status = .error("Xác thực sinh trắc học thất bại.")
                return
            }
        }

        isSubmitting = true
        status = .loading
        do {
            let request: TransferRequest
            switch recipientMode {
            case .saved:
                request = TransferRequest(
                    fromAccountId: from.id,
                    beneficiaryId: beneficiaryId,
                    newRecipientName: nil,
                    newRecipientBank: nil,
                    newRecipientAccount: nil,
                    amount: amount,
                    note: note,
                    currency: from.currency
                )
            case .new:
                request = TransferRequest(
                    fromAccountId: from.id,
                    beneficiaryId: nil,
                    newRecipientName: newName,
                    newRecipientBank: newBank,
                    newRecipientAccount: newAccountNumber.filter(\.isNumber),
                    amount: amount,
                    note: note,
                    currency: from.currency
                )
            }
            let result = try await transferRepo.submit(request)
            beneficiaries = try await transferRepo.fetchBeneficiaries()
            accounts = try await accountRepo.fetchAccounts()
            step = .success(result)
            status = .idle
        } catch {
            status = .error(error.localizedDescription)
        }
        isSubmitting = false
    }

    func validateForm() -> String? {
        guard selectedAccount != nil else { return "Chọn tài khoản nguồn." }
        switch recipientMode {
        case .saved:
            guard selectedBeneficiary != nil else { return "Chọn người nhận." }
        case .new:
            let name = newName.trimmingCharacters(in: .whitespacesAndNewlines)
            let bank = newBank.trimmingCharacters(in: .whitespacesAndNewlines)
            let account = newAccountNumber.filter(\.isNumber)
            if name.isEmpty { return "Nhập tên người nhận." }
            if bank.isEmpty { return "Nhập ngân hàng nhận." }
            if account.count < 6 { return "Số tài khoản cần ít nhất 6 số." }
        }
        guard let amount else { return "Nhập số tiền hợp lệ." }
        if amount < TransferConstants.minimumAmountVND {
            return "Số tiền tối thiểu \(MoneyFormatter.format(TransferConstants.minimumAmountVND))."
        }
        if amount > TransferConstants.maximumAmountVND {
            return "Vượt hạn mức chuyển khoản."
        }
        if let available = selectedAccount?.availableBalance, amount > available {
            return "Số dư không đủ."
        }
        return nil
    }

    func goBackToForm() {
        step = .form
        status = .idle
    }

    func goBackToConfirm() {
        step = .confirm
        status = .idle
    }

    func reset() {
        amountText = ""
        note = ""
        otpCode = ""
        newName = ""
        newBank = ""
        newAccountNumber = ""
        recipientMode = .saved
        step = .form
        status = .idle
        isSubmitting = false
    }
}
