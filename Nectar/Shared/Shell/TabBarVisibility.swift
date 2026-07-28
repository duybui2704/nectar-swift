import SwiftUI
import Combine

/// Chia sẻ trạng thái hiện/ẩn floating tab bar giữa các màn scroll.
@MainActor
final class TabBarVisibility: ObservableObject {
    @Published private(set) var isVisible = true

    private var lastOffset: CGFloat = 0
    private let threshold: CGFloat = 8

    /// Gọi từ scroll observer (đã defer qua DispatchQueue.main.async).
    func handleScroll(offset: CGFloat) {
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

        guard isVisible != next else { return }
        isVisible = next
    }

    func setVisible(_ visible: Bool) {
        guard isVisible != visible else { return }
        isVisible = visible
    }

    func reset() {
        lastOffset = 0
        guard isVisible != true else { return }
        isVisible = true
    }
}
