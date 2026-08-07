import SwiftUI

/// Hero gallery — overlay back / share / heart, page dots, video badge, variant thumb.
struct ProductGalleryView: View {
    let items: [ProductGalleryItem]
    var variantThumbURL: URL?
    var isFavorite: Bool
    var onBack: () -> Void
    var onShare: () -> Void
    var onToggleFavorite: () -> Void

    @State private var page = 0

    private let galleryHeight: CGFloat = 360

    var body: some View {
        ZStack(alignment: .top) {
            TabView(selection: $page) {
                if items.isEmpty {
                    placeholder
                        .tag(0)
                } else {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        ZStack {
                            RemoteImageView(url: item.imageURL, contentMode: .fit, showsLoadingIndicator: true)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Color(hex: 0xF5F5F5))

                            if item.isVideo {
                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundStyle(.white.opacity(0.95))
                                    .shadow(radius: 4)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                                    .padding(16)
                            }
                        }
                        .tag(index)
                    }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: galleryHeight.scaled)
            .background(Color(hex: 0xF5F5F5))

            // Top chrome — tôn trọng Dynamic Island / notch
            HStack {
                chromeButton(systemName: "chevron.left", action: onBack)
                Spacer()
                chromeButton(systemName: "square.and.arrow.up", action: onShare)
                chromeButton(
                    systemName: isFavorite ? "heart.fill" : "heart",
                    tint: isFavorite ? NectarColors.danger : NectarColors.textPrimary,
                    action: onToggleFavorite
                )
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .safeAreaPadding(.top)

            // Bottom: dots + variant thumb
            HStack(alignment: .bottom) {
                Spacer()
                pageDots
                Spacer()
            }
            .overlay(alignment: .bottomTrailing) {
                if let variantThumbURL {
                    RemoteImageView(url: variantThumbURL, contentMode: .fill, showsLoadingIndicator: false)
                        .frame(width: 48.scaled, height: 48.scaled)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(NectarColors.border, lineWidth: 1)
                        )
                        .padding(.trailing, 16)
                }
            }
            .padding(.bottom, 12)
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
        .frame(height: galleryHeight.scaled)
    }

    private var pageDots: some View {
        HStack(spacing: 6) {
            let count = max(items.count, 1)
            ForEach(0..<count, id: \.self) { index in
                Circle()
                    .fill(index == page ? NectarColors.textPrimary : NectarColors.border)
                    .frame(width: 6, height: 6)
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

    private func chromeButton(
        systemName: String,
        tint: Color = NectarColors.textPrimary,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 40, height: 40)
                .background(.ultraThinMaterial, in: Circle())
        }
        .buttonStyle(.plain)
    }
}
