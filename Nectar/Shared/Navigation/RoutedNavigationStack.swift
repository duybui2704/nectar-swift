import SwiftUI

/// `NavigationStack` gắn path typed + đăng ký mọi `AppDestination`.
struct RoutedNavigationStack<Content: View>: View {
    @Binding var path: [AppDestination]
    @ViewBuilder var content: () -> Content

    var body: some View {
        NavigationStack(path: $path) {
            content()
                .navigationDestination(for: AppDestination.self) { destination in
                    AppDestinationView(destination: destination)
                }
        }
    }
}

extension View {
    /// Convenience: `NavigationLink` value-based tới destination dùng chung.
    func appLink<Label: View>(
        _ destination: AppDestination,
        @ViewBuilder label: () -> Label
    ) -> some View {
        NavigationLink(value: destination, label: label)
    }
}
