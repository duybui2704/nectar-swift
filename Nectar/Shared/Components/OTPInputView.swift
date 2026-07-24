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
                .foregroundStyle(NectarColors.brand)
            Text(title)
                .font(NectarTypography.title)
            Text(subtitle)
                .font(NectarTypography.caption)
                .foregroundStyle(NectarColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            TextField("Nhập \(length) số OTP", text: $code)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(.system(size: 28, weight: .semibold, design: .monospaced))
                .padding()
                .background(NectarColors.inputBackground)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 32)
                .onChange(of: code) { _, newValue in
                    let digits = newValue.filter(\.isNumber)
                    code = String(digits.prefix(length))
                }

            Text("Demo OTP: \(TransferConstants.mockOTPCode)")
                .font(NectarTypography.caption)
                .foregroundStyle(NectarColors.textSecondary)
        }
    }
}
