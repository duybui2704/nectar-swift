import SwiftUI
import WebKit

// MARK: - Screen (push trong NavigationStack)

/// Màn WebView riêng — push qua `AppRouter` (`AppDestination.webView`).
struct WebViewScreen: View {
    @EnvironmentObject private var router: AppRouter

    let url: URL
    var title: String = ""

    @State private var isLoading = true

    var body: some View {
        VStack(spacing: 0) {
            header
            ZStack {
                WebViewCore(url: url, isLoading: $isLoading)
                if isLoading {
                    ProgressView()
                        .tint(NectarColors.brand)
                }
            }
        }
        .background(NectarColors.background.ignoresSafeArea())
        .navigationBarHidden(true)
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button(action: { router.pop() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(NectarColors.textPrimary)
                    .frame(width: 40, height: 40)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")

            if !title.isEmpty {
                Text(title)
                    .font(NectarTypography.headline)
                    .foregroundStyle(NectarColors.textPrimary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
//        .safeAreaPadding(.top)
        .background(NectarColors.surface)
    }
}

// MARK: - WKWebView

struct WebViewCore: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool

    init(url: URL, isLoading: Binding<Bool> = .constant(false)) {
        self.url = url
        self._isLoading = isLoading
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(isLoading: $isLoading)
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        private var isLoading: Binding<Bool>

        init(isLoading: Binding<Bool>) {
            self.isLoading = isLoading
        }

        func webView(
            _ webView: WKWebView,
            didStartProvisionalNavigation navigation: WKNavigation?
        ) {
            isLoading.wrappedValue = true
        }

        func webView(
            _ webView: WKWebView,
            didFinish navigation: WKNavigation?
        ) {
            isLoading.wrappedValue = false
        }

        func webView(
            _ webView: WKWebView,
            didFail navigation: WKNavigation?,
            withError error: Error
        ) {
            isLoading.wrappedValue = false
            NectarLog.log("WebView failed: \(error.localizedDescription)", title: "WebView")
        }

        func webView(
            _ webView: WKWebView,
            didFailProvisionalNavigation navigation: WKNavigation?,
            withError error: Error
        ) {
            isLoading.wrappedValue = false
            NectarLog.log("WebView provisional failed: \(error.localizedDescription)", title: "WebView")
        }
    }
}
