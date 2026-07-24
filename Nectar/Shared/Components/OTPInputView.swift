import SwiftUI

struct OTPInputView: View {
    @Binding var code: String
    let length: Int
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.shield")
                .font(.system(size: 48))
                .foregroundStyle(BankColors.brand)
            Text(title)
                .font(BankTypography.title)
            Text(subtitle)
                .font(BankTypography.caption)
                .foregroundStyle(BankColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            TextField("Nhập \(length) số OTP", text: $code)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(.system(size: 28, weight: .semibold, design: .monospaced))
                .padding()
                .background(BankColors.inputBackground)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 32)
                .onChange(of: code) { _, newValue in
                    let digits = newValue.filter(\.isNumber)
                    code = String(digits.prefix(length))
                }

            Text("Demo OTP: \(TransferConstants.mockOTPCode)")
                .font(BankTypography.caption)
                .foregroundStyle(BankColors.textSecondary)
        }
    }
}
