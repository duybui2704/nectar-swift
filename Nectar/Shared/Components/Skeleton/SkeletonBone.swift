import SwiftUI

/// Các “xương” cơ bản — ghép thành layout skeleton.
enum SkeletonBone {
    /// Hình chữ nhật bo góc.
    static func rect(
        width: CGFloat? = nil,
        height: CGFloat,
        cornerRadius: CGFloat = SkeletonStyle.cornerSmall
    ) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(SkeletonStyle.base)
            .frame(width: width, height: height)
            .frame(maxWidth: width == nil ? .infinity : nil, alignment: .leading)
            .skeletonShimmer()
    }

    /// Hình tròn (avatar / category).
    static func circle(size: CGFloat) -> some View {
        Circle()
            .fill(SkeletonStyle.base)
            .frame(width: size, height: size)
            .skeletonShimmer()
    }

    /// Dòng text giả (chiều rộng theo tỉ lệ 0…1 của parent).
    static func line(
        height: CGFloat = 12,
        widthFactor: CGFloat = 1,
        cornerRadius: CGFloat = SkeletonStyle.cornerSmall
    ) -> some View {
        GeometryReader { geo in
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(SkeletonStyle.base)
                .frame(width: max(0, geo.size.width * min(max(widthFactor, 0), 1)), height: height)
                .skeletonShimmer()
        }
        .frame(height: height)
    }
}
