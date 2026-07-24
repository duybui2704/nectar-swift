import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [BankColors.brand, BankColors.navySoft],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            VStack(spacing: 12) {
                Image(systemName: "building.columns.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.white)
                Text("Nectar")
                    .font(BankTypography.largeTitle)
                    .foregroundStyle(.white)
                ProgressView()
                    .tint(.white)
                    .padding(.top, 16)
            }
        }
    }
}
