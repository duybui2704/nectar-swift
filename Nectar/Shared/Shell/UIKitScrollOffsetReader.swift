import SwiftUI
import UIKit

/// Đọc contentOffset từ UIScrollView bên trong `List` / `ScrollView` (UIKit).
struct UIKitScrollOffsetReader: UIViewRepresentable {
    var onOffsetChange: (CGFloat) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onOffsetChange: onOffsetChange)
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.isUserInteractionEnabled = false
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.onOffsetChange = onOffsetChange
        DispatchQueue.main.async {
            guard let scrollView = uiView.enclosingScrollView() else { return }
            context.coordinator.attach(to: scrollView)
        }
    }

    final class Coordinator: NSObject {
        var onOffsetChange: (CGFloat) -> Void
        private weak var scrollView: UIScrollView?
        private var observation: NSKeyValueObservation?

        init(onOffsetChange: @escaping (CGFloat) -> Void) {
            self.onOffsetChange = onOffsetChange
        }

        func attach(to scrollView: UIScrollView) {
            guard self.scrollView !== scrollView else { return }
            observation?.invalidate()
            self.scrollView = scrollView
            observation = scrollView.observe(\.contentOffset, options: [.new]) { [weak self] scroll, _ in
                let y = -scroll.contentOffset.y
                DispatchQueue.main.async {
                    self?.onOffsetChange(y)
                }
            }
        }

        deinit {
            observation?.invalidate()
        }
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
