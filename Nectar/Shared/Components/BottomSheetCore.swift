import SwiftUI

// MARK: - Height

/// Chiều cao cố định của sheet.
enum SheetHeight: Equatable {
    case fraction(CGFloat) // % chiều cao container, VD 0.35 = 35%
    case height(CGFloat)   // point cố định

    func resolved(containerHeight: CGFloat) -> CGFloat {
        switch self {
        case .fraction(let f):
            return containerHeight * min(max(f, 0), 1)
        case .height(let h):
            return min(max(h, 0), containerHeight)
        }
    }
}

/// Alias cũ — call site dùng `SheetDetent` vẫn compile.
typealias SheetDetent = SheetHeight

// MARK: - Shape bo góc riêng 2 góc trên

private struct TopRoundedCorner: Shape {
    var radius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let r = min(radius, min(rect.width, rect.height) / 2)
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + r))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + r, y: rect.minY),
            control: CGPoint(x: rect.minX, y: rect.minY)
        )
        path.addLine(to: CGPoint(x: rect.maxX - r, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + r),
            control: CGPoint(x: rect.maxX, y: rect.minY)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Bottom Sheet (cố định chiều cao, không kéo)

struct BottomSheetCore<SheetContent: View>: View {
    @Binding var isPresented: Bool
    var height: SheetHeight = .fraction(0.35)
    var cornerRadius: CGFloat = 24
    var backgroundColor: Color = Color(.systemBackground)
    var dimOpacity: CGFloat = 0.35
    var showGrabber: Bool = true
    var onDismiss: (() -> Void)? = nil

    @ViewBuilder var sheetContent: SheetContent

    @State private var containerHeight: CGFloat = 0
    @State private var isMounted = false
    @State private var isDismissing = false
    /// 0 = ẩn dưới, 1 = hiện đủ chiều cao.
    @State private var revealProgress: CGFloat = 0

    private let presentAnimation = Animation.spring(response: 0.36, dampingFraction: 0.9)

    private var sheetHeight: CGFloat {
        guard containerHeight > 0 else { return 0 }
        return height.resolved(containerHeight: containerHeight)
    }

    var body: some View {
        GeometryReader { geo in
            let sizeHeight = geo.size.height

            ZStack(alignment: .bottom) {
                if isMounted {
                    Color.black
                        .opacity(dimOpacity * revealProgress)
                        .contentShape(Rectangle())
                        .onTapGesture { dismiss() }

                    sheetPanel
                        .frame(height: sheetHeight, alignment: .top)
                        .frame(maxWidth: .infinity)
                        .offset(y: sheetHeight * (1 - revealProgress))
                }
            }
            .onAppear {
                syncContainerHeight(sizeHeight)
            }
            .onChange(of: sizeHeight) { _, newValue in
                syncContainerHeight(newValue)
            }
            .onChange(of: isPresented) { _, presented in
                if presented {
                    isDismissing = false
                    presentSheet()
                } else if isMounted, !isDismissing {
                    animateDismiss()
                }
            }
        }
    }

    private var sheetPanel: some View {
        VStack(spacing: 0) {
            if showGrabber {
                Capsule()
                    .fill(Color.secondary.opacity(0.4))
                    .frame(width: 36, height: 5)
                    .padding(.top, 8)
                    .padding(.bottom, 4)
            }
            sheetContent
        }
        .background(
            TopRoundedCorner(radius: cornerRadius)
                .fill(backgroundColor)
                .shadow(color: .black.opacity(0.12), radius: 10, y: -3)
        )
        .clipShape(TopRoundedCorner(radius: cornerRadius))
    }

    // MARK: - Present / Dismiss

    private func presentSheet() {
        var prepare = Transaction()
        prepare.disablesAnimations = true
        withTransaction(prepare) {
            isMounted = true
            revealProgress = 0
        }
        withAnimation(presentAnimation) {
            revealProgress = 1
        }
    }

    private func dismiss() {
        guard isMounted, !isDismissing else {
            isPresented = false
            return
        }
        isDismissing = true
        withAnimation(presentAnimation) {
            revealProgress = 0
            isPresented = false
        }
        scheduleUnmount()
    }

    private func animateDismiss() {
        guard isMounted, !isDismissing else { return }
        isDismissing = true
        withAnimation(presentAnimation) {
            revealProgress = 0
        }
        scheduleUnmount()
    }

    private func scheduleUnmount() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            guard !isPresented else {
                isDismissing = false
                return
            }
            isMounted = false
            isDismissing = false
            onDismiss?()
        }
    }

    private func syncContainerHeight(_ height: CGFloat) {
        guard height > 0 else { return }
        containerHeight = height
        if isPresented && !isMounted {
            presentSheet()
        }
    }
}

// MARK: - Modifier

private struct BottomSheetModifier<SheetContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    var height: SheetHeight
    var cornerRadius: CGFloat
    var showGrabber: Bool
    var onDismiss: (() -> Void)?
    @ViewBuilder var sheetContent: SheetContent

    func body(content: Content) -> some View {
        content
            .overlay {
                BottomSheetCore(
                    isPresented: $isPresented,
                    height: height,
                    cornerRadius: cornerRadius,
                    showGrabber: showGrabber,
                    onDismiss: onDismiss,
                    sheetContent: { sheetContent }
                )
                .allowsHitTesting(isPresented)
            }
    }
}

extension View {
    /// Bottom sheet chiều cao cố định — chỉ mở/đóng, không kéo resize.
    func customBottomSheet<SheetContent: View>(
        isPresented: Binding<Bool>,
        height: SheetHeight = .fraction(0.35),
        cornerRadius: CGFloat = 24,
        showGrabber: Bool = true,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> SheetContent
    ) -> some View {
        modifier(
            BottomSheetModifier(
                isPresented: isPresented,
                height: height,
                cornerRadius: cornerRadius,
                showGrabber: showGrabber,
                onDismiss: onDismiss,
                sheetContent: content
            )
        )
    }

    /// Tương thích call site cũ dùng `detents` — chỉ lấy detent đầu / `initialDetent`.
    func customBottomSheet<SheetContent: View>(
        isPresented: Binding<Bool>,
        detents: [SheetDetent],
        initialDetent: Int = 0,
        cornerRadius: CGFloat = 24,
        showDragIndicator: Bool = true,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> SheetContent
    ) -> some View {
        let index = detents.indices.contains(initialDetent) ? initialDetent : 0
        let height = detents[safe: index] ?? detents.first ?? .fraction(0.35)
        return customBottomSheet(
            isPresented: isPresented,
            height: height,
            cornerRadius: cornerRadius,
            showGrabber: showDragIndicator,
            onDismiss: onDismiss,
            content: content
        )
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
