import SwiftUI

struct ProductGalleryView: View {
    let items: [ProductGalleryItem]
    var variantThumbURL: URL?
    var isFavorite: Bool
    /// Chiều cao khung gallery (parent điều khiển collapse).
    var height: CGFloat = 360.scaled
    /// 0 = full, 1 = collapsed tối đa — fade dots / thumb.
    var collapseProgress: CGFloat = 0
    var onBack: () -> Void = {}
    var onShare: () -> Void = {}
    var onToggleFavorite: () -> Void = {}

    @HotReloadObserver private var _hr

    @State private var pageID: String?
    @State private var isVariantExpanded = false
    @Namespace private var galleryAnimation

    private var chromeOpacity: Double {
        Double(1 - min(1, max(0, collapseProgress)) * 1.25)
    }

    private var currentPageIndex: Int {
        guard let pageID,
              let index = items.firstIndex(where: { $0.id == pageID }) else { return 0 }
        return index
    }

    var body: some View {
        GeometryReader { geo in
            let pageWidth = max(geo.size.width - 32, 0)

            ZStack(alignment: .top) {
                pagingScroll(pageWidth: pageWidth)
                    .padding(.horizontal, 16)
                    .opacity(isVariantExpanded ? 0 : 1)

                bottomChrome
                    .opacity(isVariantExpanded ? 0 : chromeOpacity)
                    .allowsHitTesting(chromeOpacity > 0.05)

                if isVariantExpanded, let variantThumbURL {
                    NectarImage(
                        url: variantThumbURL,
                        kind: .hero,
                        contentMode: .fit
                    )
                    .matchedGeometryEffect(id: "variantImage", in: galleryAnimation)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(hex: 0xF5F5F5))
                    .allowsHitTesting(false)
                    .transition(.identity)
                }
            }
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
        .background(Color(hex: 0xF5F5F5))
        .clipped()
        .onAppear {
            if pageID == nil {
                pageID = items.first?.id
            }
        }
        .onChange(of: items.map(\.id)) { _, ids in
            if pageID == nil || !(ids.contains(pageID ?? "")) {
                pageID = ids.first
            }
        }
        .hotReload()
    }

    // MARK: - Horizontal paging (orthogonal với ScrollView dọc → gesture mượt)

    @ViewBuilder
    private func pagingScroll(pageWidth: CGFloat) -> some View {
        if items.isEmpty {
            placeholder
                .frame(width: pageWidth, height: height)
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(items) { item in
                        galleryPage(item)
                            .frame(width: pageWidth, height: max(height, 1))
                            .id(item.id)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $pageID)
        }
    }

    private func galleryPage(_ item: ProductGalleryItem) -> some View {
        ZStack {
            NectarImage(
                url: item.imageURL,
                kind: .hero,
                contentMode: .fit,
                showsLoadingIndicator: true
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(hex: 0xF5F5F5))
            .opacity(isVariantExpanded && item.id == pageID ? 0 : 1)

            if item.isVideo {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.white.opacity(0.95))
                    .shadow(radius: 4)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                    .padding(16)
            }
        }
    }

    private var bottomChrome: some View {
        HStack(alignment: .bottom) {
            Spacer()
            pageDots
            Spacer()
        }
        .overlay(alignment: .bottomTrailing) {
            if let variantThumbURL {
                ExpandableThumbnail(
                    variantThumbURL: variantThumbURL,
                    namespace: galleryAnimation,
                    isExpanded: isVariantExpanded
                ) { pressing in
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                        isVariantExpanded = pressing
                    }
                }
                .opacity(chromeOpacity)
            }
        }
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    }

    @ViewBuilder
    private var pageDots: some View {
        if items.count > 1 {
            HStack(spacing: 6) {
                ForEach(0..<items.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentPageIndex ? NectarColors.green : NectarColors.border)
                        .frame(width: 6, height: 6)
                }
            }
        }
    }

    private var placeholder: some View {
        Image(systemName: "photo")
            .font(.system(size: 40))
            .foregroundStyle(NectarColors.textSecondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(hex: 0xF5F5F5))
    }
}

struct ExpandableThumbnail: View {
    let variantThumbURL: URL?
    let namespace: Namespace.ID
    let isExpanded: Bool
    var onPressChange: (Bool) -> Void

    @GestureState private var isPressing = false

    var body: some View {
        NectarImage(url: variantThumbURL, kind: .thumbnail, contentMode: .fill)
            .frame(width: 48.scaled, height: 48.scaled)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(NectarColors.border, lineWidth: 1)
            )
            .opacity(isExpanded ? 0 : 1)
            .padding(.trailing, 16)
            .contentShape(Rectangle())
            .gesture(
                LongPressGesture(minimumDuration: 0.2)
                    .sequenced(before: DragGesture(minimumDistance: 0))
                    .updating($isPressing) { value, state, _ in
                        switch value {
                        case .first(true), .second(true, _):
                            state = true
                        default:
                            state = false
                        }
                    }
            )
            .onChange(of: isPressing) { _, newValue in
                onPressChange(newValue)
            }
    }
}
