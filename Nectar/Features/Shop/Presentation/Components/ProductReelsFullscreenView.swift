import AVFoundation
import SwiftUI

/// Fullscreen vertical Reels — chỉ **1 page active** giữ `AVPlayerItem`; page khác release buffer.
struct ProductReelsFullscreenView: View {
    let reels: [ProductReel]
    let initialID: Int

    @Environment(\.dismiss) private var dismiss
    @State private var currentID: Int?
    @State private var isMuted = false

    init(reels: [ProductReel], initialID: Int) {
        self.reels = reels
        self.initialID = initialID
        _currentID = State(initialValue: initialID)
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.black.ignoresSafeArea()

            ScrollView(.vertical) {
                LazyVStack(spacing: 0) {
                    ForEach(reels) { reel in
                        FullscreenReelPage(
                            reel: reel,
                            isActive: currentID == reel.id,
                            isMuted: isMuted
                        )
                        .containerRelativeFrame(.vertical)
                        .id(reel.id)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $currentID)
            .ignoresSafeArea()

            topChrome
        }
        .statusBarHidden(true)
        .background(Color.black.ignoresSafeArea())
    }

    private var topChrome: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(.ultraThinMaterial.opacity(0.55), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")

            Spacer()

            Button {
                isMuted.toggle()
            } label: {
                Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(.ultraThinMaterial.opacity(0.55), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isMuted ? "Unmute" : "Mute")
        }
        .padding(.horizontal, NectarMetrics.spacing.sm)
        .padding(.top, 8)
    }
}

// MARK: - Page

private struct FullscreenReelPage: View {
    let reel: ProductReel
    let isActive: Bool
    let isMuted: Bool

    @StateObject private var model = FullscreenReelPlayerModel()
    @State private var showPauseHint = false

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottomLeading) {
                Color.black

                RemoteImageView(
                    url: reel.thumbnailURL,
                    contentMode: .fill,
                    showsLoadingIndicator: false
                )
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()

                if isActive {
                    FullscreenPlayerLayerView(player: model.player)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .opacity(model.isReady ? 1 : 0)
                        .allowsHitTesting(false)
                }

                LinearGradient(
                    colors: [
                        .black.opacity(0.35),
                        .clear,
                        .clear,
                        .black.opacity(0.85),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .allowsHitTesting(false)

                if showPauseHint && isActive && !model.isPlaying {
                    Image(systemName: "play.fill")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundStyle(.white.opacity(0.9))
                        .shadow(radius: 8)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .allowsHitTesting(false)
                }

                productOverlay
                    .padding(.horizontal, NectarMetrics.spacing.md)
                    .padding(.bottom, 36)
                    .allowsHitTesting(false)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                guard isActive else { return }
                model.togglePlay()
                showPauseHint = true
            }
        }
        .onChange(of: isActive, initial: true) { _, active in
            if active {
                model.activate(url: reel.videoURL, muted: isMuted)
            } else {
                model.deactivate()
            }
        }
        .onChange(of: isMuted) { _, muted in
            guard isActive else { return }
            model.setMuted(muted)
        }
        .onDisappear {
            model.deactivate()
        }
    }

    private var productOverlay: some View {
        VStack(alignment: .leading, spacing: NectarMetrics.spacing.xxs) {
            HStack(alignment: .center, spacing: NectarMetrics.spacing.xs) {
                RemoteImageView(
                    url: reel.productImageURL ?? reel.thumbnailURL,
                    contentMode: .fill,
                    showsLoadingIndicator: false
                )
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(reel.productName)
                        .font(NectarFonts.elmsSans(size: 16.scaled, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                    if !reel.displayPrice.isEmpty {
                        Text(reel.displayPrice)
                            .font(NectarFonts.elmsSans(size: 14.scaled, weight: .medium))
                            .foregroundStyle(.white.opacity(0.92))
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Player

@MainActor
private final class FullscreenReelPlayerModel: ObservableObject {
    let player = AVPlayer()
    @Published private(set) var isReady = false
    @Published private(set) var isPlaying = false

    private var loopObserver: NSObjectProtocol?
    private var statusObservation: NSKeyValueObservation?
    private var attachedURL: URL?

    /// Gắn item + play — chỉ gọi khi page active.
    func activate(url: URL?, muted: Bool) {
        guard let url else { return }
        setMuted(muted)

        if attachedURL != url {
            attach(url: url)
        }
        play()
    }

    /// Pause + **bỏ AVPlayerItem** để giải phóng buffer decoder.
    func deactivate() {
        pause()
        detach()
    }

    func setMuted(_ muted: Bool) {
        player.isMuted = muted
    }

    func play() {
        guard attachedURL != nil else { return }
        player.play()
        isPlaying = true
    }

    func pause() {
        player.pause()
        isPlaying = false
    }

    func togglePlay() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }

    private func attach(url: URL) {
        detachObserversOnly()
        attachedURL = url
        isReady = false

        let item = AVPlayerItem(url: url)
        // Giới hạn buffer phía trước — giảm RAM khi swipe nhanh.
        item.preferredForwardBufferDuration = 2

        player.replaceCurrentItem(with: item)
        player.automaticallyWaitsToMinimizeStalling = true
        player.actionAtItemEnd = .none

        statusObservation = item.observe(\.status, options: [.new]) { [weak self] item, _ in
            Task { @MainActor in
                self?.isReady = item.status == .readyToPlay
                if item.status == .readyToPlay, self?.isPlaying == true {
                    self?.player.play()
                }
            }
        }

        loopObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            self?.player.seek(to: .zero)
            self?.player.play()
            self?.isPlaying = true
        }
    }

    private func detach() {
        detachObserversOnly()
        player.replaceCurrentItem(with: nil)
        attachedURL = nil
        isReady = false
    }

    private func detachObserversOnly() {
        statusObservation?.invalidate()
        statusObservation = nil
        if let loopObserver {
            NotificationCenter.default.removeObserver(loopObserver)
            self.loopObserver = nil
        }
    }

    deinit {
        statusObservation?.invalidate()
        if let loopObserver {
            NotificationCenter.default.removeObserver(loopObserver)
        }
    }
}

private struct FullscreenPlayerLayerView: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> FullscreenPlayerContainerView {
        let view = FullscreenPlayerContainerView()
        view.playerLayer.player = player
        view.playerLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: FullscreenPlayerContainerView, context: Context) {
        uiView.playerLayer.player = player
    }
}

private final class FullscreenPlayerContainerView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }
    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
}
