import SwiftUI

/// Tương thích call site cũ — ủy quyền sang `NectarImage`.
struct RemoteImageView: View {
    let url: URL?
    var contentMode: ContentMode = .fill
    var showsLoadingIndicator: Bool = true
    var maxPixelSize: CGFloat = 360

    var body: some View {
        NectarImage(
            url: url,
            kind: NectarImageKind.closest(to: maxPixelSize),
            contentMode: contentMode,
            showsLoadingIndicator: showsLoadingIndicator
        )
    }
}
