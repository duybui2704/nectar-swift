import SwiftUI

struct ExpandableText: View {
    let text: String
    var lineLimit: Int = 3
    var textColor: Color = .primary
    var iconColor: Color = .secondary

    @State private var isExpanded = false
    /// nil = chưa đo xong, true/false = đã biết chắc có tràn hay không
    @State private var isTruncated: Bool? = nil

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                isExpanded.toggle()
            }
        } label: {
            HStack(alignment: .top, spacing: 4) {
                ZStack(alignment: .topLeading) {
                    Text(text)
                        .font(.system(size: NectarMetrics.font.textBig, weight: .bold))
                        .foregroundColor(textColor)
                        .lineLimit(isExpanded ? nil : lineLimit)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)          // căn trái khi xuống dòng
                        .frame(maxWidth: .infinity, alignment: .leading)  // ép Text bám lề trái, không co theo dòng ngắn nhất

                    // Text ẩn, chỉ dùng để ĐO xem full text có vượt quá lineLimit không.
                    if isTruncated == nil {
                        Text(text)
                            .font(.system(size: NectarMetrics.font.textBig, weight: .bold))
                            .lineLimit(lineLimit)
                            .fixedSize(horizontal: false, vertical: true)
                            .background(
                                GeometryReader { visibleGeo in
                                    Color.clear.onAppear {
                                        let full = fullHeight()
                                        let visible = visibleGeo.size.height
                                        isTruncated = full > visible + 1 // +1 để tránh sai số float
                                    }
                                }
                            )
                            .opacity(0)
                            .allowsHitTesting(false)
                    }
                }

                // Chỉ hiện icon khi text thực sự bị tràn (giữ đúng yêu cầu gốc: text ngắn không có icon)
                if isTruncated == true {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption2.weight(.bold))
                        .foregroundColor(iconColor)
                        .frame(width: NectarMetrics.icon.md, height: NectarMetrics.icon.md)
                        .padding(.top, NectarMetrics.s(2))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading) // ép cả HStack bám lề trái trong container cha
        }
        .buttonStyle(.plain)
        .disabled(isTruncated != true) // text ngắn thì không cho bấm (vì không có gì để expand)
    }

    /// Đo chiều cao thật sự của toàn bộ text (không giới hạn dòng) để so sánh.
    private func fullHeight() -> CGFloat {
        let uiFont = UIFont.systemFont(ofSize: 14) // khớp với .font(.system(size: 14)) đang dùng ở Text
        let width = UIScreen.main.bounds.width - 32 // trừ padding ước lượng, chỉnh theo layout thực tế
        let boundingBox = (text as NSString).boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin,
            attributes: [.font: uiFont],
            context: nil
        )
        return boundingBox.height
    }
}
