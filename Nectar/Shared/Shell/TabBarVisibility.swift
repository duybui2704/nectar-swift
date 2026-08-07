import SwiftUI
import Combine

/// Chia sẻ trạng thái hiện/ẩn floating tab bar giữa các màn scroll / push.
@MainActor
final class TabBarVisibility: ObservableObject {
    @Published private(set) var isVisible = true

    /// Push stack không rỗng → luôn ẩn (PDP, category, …).
    private var isNavigationHidden = false
    private var lastOffset: CGFloat = 0
    private let threshold: CGFloat = 8

    /// Gọi từ scroll observer (đã defer qua DispatchQueue.main.async).
    func handleScroll(offset: CGFloat) {
        guard !isNavigationHidden else { return }

        let delta = offset - lastOffset
        lastOffset = offset

        var next = isVisible
        if delta < -threshold {
            next = false
        } else if delta > threshold {
            next = true
        }
        if offset > -4 {
            next = true
        }

        applyVisible(next)
    }

    func setVisible(_ visible: Bool) {
        guard !isNavigationHidden else { return }
        applyVisible(visible)
    }

    /// Ẩn tab bar khi NavigationStack có destination (single source of truth từ router).
    func setNavigationHidden(_ hidden: Bool) {
        isNavigationHidden = hidden
        applyVisible(!hidden)
    }

    func reset() {
        lastOffset = 0
        if isNavigationHidden {
            applyVisible(false)
        } else {
            applyVisible(true)
        }
    }

    private func applyVisible(_ visible: Bool) {
        guard isVisible != visible else { return }
        isVisible = visible
    }
}
