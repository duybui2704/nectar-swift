import SwiftUI
import UIKit

// MARK: - UIKit observer (không dùng PreferenceKey → tránh relayout mỗi frame)

/// Gắn vào background của ScrollView/List, đọc contentOffset qua KVO.
/// Chỉ forward offset 1 lần / run loop — không tạo Task hay PreferenceKey propagation.
private struct TabBarScrollObserver: UIViewRepresentable {
    @EnvironmentObject private var tabBarVisibility: TabBarVisibility

    func makeCoordinator() -> Coordinator {
        Coordinator(tabBarVisibility: tabBarVisibility)
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.isUserInteractionEnabled = false
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.tabBarVisibility = tabBarVisibility
        context.coordinator.scheduleAttach(to: uiView)
    }

    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        coordinator.detach()
    }

    final class Coordinator {
        weak var tabBarVisibility: TabBarVisibility?
        private weak var scrollView: UIScrollView?
        private var observation: NSKeyValueObservation?
        private var pendingOffset: CGFloat = 0
        private var isDispatchScheduled = false

        init(tabBarVisibility: TabBarVisibility) {
            self.tabBarVisibility = tabBarVisibility
        }

        func scheduleAttach(to view: UIView) {
            DispatchQueue.main.async { [weak self, weak view] in
                guard let self, let view else { return }
                guard let scrollView = view.enclosingScrollView() else { return }
                self.attach(to: scrollView)
            }
        }

        func attach(to scrollView: UIScrollView) {
            guard self.scrollView !== scrollView else { return }
            detach()
            self.scrollView = scrollView
            // Capture offset value only — tránh giữ strong ref vào scroll / coordinator qua closure sống lâu.
            observation = scrollView.observe(\.contentOffset, options: [.new]) { [weak self] scroll, change in
                guard let self else { return }
                let y = -(change.newValue?.y ?? scroll.contentOffset.y)
                self.reportOffset(y)
            }
        }

        func detach() {
            observation?.invalidate()
            observation = nil
            scrollView = nil
            isDispatchScheduled = false
        }

        private func reportOffset(_ offset: CGFloat) {
            pendingOffset = offset
            guard !isDispatchScheduled else { return }
            isDispatchScheduled = true

            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.isDispatchScheduled = false
                // Sau hot-reload / dismantle, visibility có thể đã nil — bỏ qua an toàn.
                self.tabBarVisibility?.handleScroll(offset: self.pendingOffset)
            }
        }

        deinit {
            observation?.invalidate()
            observation = nil
        }
    }
}

// MARK: - Modifier

private struct HidesTabBarOnScrollModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.background {
            TabBarScrollObserver()
                .frame(width: 0, height: 0)
                .allowsHitTesting(false)
        }
    }
}

extension View {
    /// Gắn vào `ScrollView` / `List` để tự ẩn/hiện floating tab bar theo hướng scroll (kiểu Facebook).
    func hidesTabBarOnScroll() -> some View {
        modifier(HidesTabBarOnScrollModifier())
    }
}

private extension UIView {
    func enclosingScrollView() -> UIScrollView? {
        var current: UIView? = self
        while let view = current {
            if let scroll = view as? UIScrollView {
                return scroll
            }
            current = view.superview
        }
        return nil
    }
}
