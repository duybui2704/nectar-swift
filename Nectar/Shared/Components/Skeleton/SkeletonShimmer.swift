import SwiftUI

// MARK: - Environment (một phase chung → mọi bone sync)

private struct SkeletonPhaseKey: EnvironmentKey {
    static let defaultValue: CGFloat = 0
}

extension EnvironmentValues {
    var skeletonPhase: CGFloat {
        get { self[SkeletonPhaseKey.self] }
        set { self[SkeletonPhaseKey.self] = newValue }
    }
}

/// Bọc content skeleton — chạy shimmer 1 lần, sync toàn bộ children.
struct SkeletonScope<Content: View>: View {
    @State private var phase: CGFloat = -1
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .environment(\.skeletonPhase, phase)
            .onAppear {
                phase = -1
                withAnimation(
                    .linear(duration: SkeletonStyle.animationDuration)
                    .repeatForever(autoreverses: false)
                ) {
                    phase = 1
                }
            }
    }
}

// MARK: - Shimmer overlay

struct SkeletonShimmerModifier: ViewModifier {
    @Environment(\.skeletonPhase) private var phase

    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { geo in
                    let width = geo.size.width
                    LinearGradient(
                        colors: [
                            .clear,
                            SkeletonStyle.highlight,
                            .clear,
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: width * 0.55)
                    .offset(x: phase * (width + width * 0.55) - width * 0.55)
                    .blendMode(.plusLighter)
                }
                .allowsHitTesting(false)
            }
            .clipped()
    }
}

extension View {
    func skeletonShimmer() -> some View {
        modifier(SkeletonShimmerModifier())
    }
}
