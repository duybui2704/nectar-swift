import SwiftUI

/// Đổi content ↔ skeleton theo `isLoading` — dùng cho từng section.
struct SkeletonGate<Content: View, Skeleton: View>: View {
    let isLoading: Bool
    @ViewBuilder var content: () -> Content
    @ViewBuilder var skeleton: () -> Skeleton

    var body: some View {
        if isLoading {
            SkeletonScope {
                skeleton()
            }
            .accessibilityLabel("Loading")
        } else {
            content()
        }
    }
}

extension View {
    /// Áp skeleton thay thế view khi đang load.
    ///
    /// ```swift
    /// ProductHorizontalRail(...)
    ///   .skeleton(isLoading: vm.isLoadingHome && vm.bestSelling.isEmpty) {
    ///     SkeletonLayout.productRail(title: true, count: 3)
    ///   }
    /// ```
    func skeleton<S: View>(
        isLoading: Bool,
        @ViewBuilder skeleton: @escaping () -> S
    ) -> some View {
        SkeletonGate(isLoading: isLoading, content: { self }, skeleton: skeleton)
    }
}
