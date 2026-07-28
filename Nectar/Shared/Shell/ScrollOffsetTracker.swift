import SwiftUI

// MARK: - Preference

private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Tracker (đặt trong ScrollView content)

struct ScrollOffsetTracker: View {
    var body: some View {
        GeometryReader { geo in
            Color.clear
                .preference(
                    key: ScrollOffsetPreferenceKey.self,
                    value: geo.frame(in: .named("tabScroll")).minY
                )
        }
        .frame(height: 0)
    }
}

// MARK: - Modifier

private struct HidesTabBarOnScrollModifier: ViewModifier {
    @EnvironmentObject private var tabBarVisibility: TabBarVisibility

    func body(content: Content) -> some View {
        content
            .coordinateSpace(name: "tabScroll")
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
                tabBarVisibility.handleScroll(offset: offset)
            }
    }
}

extension View {
    /// Gắn vào `ScrollView` để tự ẩn/hiện floating tab bar theo hướng scroll (kiểu Facebook).
    func hidesTabBarOnScroll() -> some View {
        modifier(HidesTabBarOnScrollModifier())
    }
}
