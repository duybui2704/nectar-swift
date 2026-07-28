import SwiftUI
import Combine

/// Chia sẻ trạng thái hiện/ẩn floating tab bar giữa các màn scroll.
@MainActor
final class TabBarVisibility: ObservableObject {
    @Published var isVisible = true

    private var lastOffset: CGFloat = 0
    private let threshold: CGFloat = 8

    func handleScroll(offset: CGFloat) {
        let delta = offset - lastOffset

        // Kéo lên nội dung (offset giảm) = scroll xuống → ẩn
        // Kéo xuống nội dung (offset tăng) = scroll lên → hiện
        if delta < -threshold {
            setVisible(false)
        } else if delta > threshold {
            setVisible(true)
        }

        // Gần đầu list luôn hiện
        if offset > -4 {
            setVisible(true)
        }

        lastOffset = offset
    }

    func setVisible(_ visible: Bool) {
        guard isVisible != visible else { return }
        withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
            isVisible = visible
        }
    }

    func reset() {
        lastOffset = 0
        setVisible(true)
    }
}
