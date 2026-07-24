import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            NectarColors.green
                .ignoresSafeArea()
            Image("splash")
                .frame(width: NectarMetrics.icon.splashWidth, height: NectarMetrics.icon.splashHeight)
        }
        .preferredColorScheme(.dark)
        .hotReload()
    }
}
