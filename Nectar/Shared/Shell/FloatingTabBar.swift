import SwiftUI

/// Floating tab bar — **Glassmorphism / Liquid Glass** (kiểu Control Center):
/// nền kính mờ + viền sáng + shadow; tab active sáng đặc; press scale nhẹ.
struct FloatingTabBar: View {
    @Binding var selection: MainTab
    @EnvironmentObject private var tabBarVisibility: TabBarVisibility
    @Namespace private var tabNamespace

    private let items: [(tab: MainTab, title: String, icon: String)] = [
        (.shop, "Home", "house.fill"),
        (.explore, "Explore", "magnifyingglass"),
        (.cart, "Cart", "cart.badge.plus"),
        (.favourite, "Favourite", "heart"),
        (.account, "Account", "person.crop.circle"),
    ]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(items, id: \.tab) { item in
                glassTabButton(item)
            }
        }
        .padding(6)
        .background(glassBarBackground)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .offset(y: tabBarVisibility.isVisible ? 0 : 110)
        .opacity(tabBarVisibility.isVisible ? 1 : 0)
        .animation(.spring(response: 0.32, dampingFraction: 0.86), value: tabBarVisibility.isVisible)
        .allowsHitTesting(tabBarVisibility.isVisible)
        .accessibilityHidden(!tabBarVisibility.isVisible)
    }

    // MARK: - Glass container (Control Center style)

    private var glassBarBackground: some View {
        RoundedRectangle(cornerRadius: 30, style: .continuous)
            .fill(.ultraThinMaterial)
            .background {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.55),
                                Color.white.opacity(0.22),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            // Viền kính (inner highlight)
            .overlay {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.85),
                                Color.white.opacity(0.25),
                                Color.white.opacity(0.45),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.8
                    )
            }
            .shadow(color: Color.black.opacity(0.08), radius: 3, x: 0, y: 1)
            .shadow(color: Color.black.opacity(0.12), radius: 16, x: 0, y: 8)
            .shadow(color: Color.black.opacity(0.06), radius: 28, x: 0, y: 14)
    }

    // MARK: - Tab button

    private func glassTabButton(_ item: (tab: MainTab, title: String, icon: String)) -> some View {
        let isSelected = selection == item.tab

        return Button {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.78)) {
                selection = item.tab
            }
            tabBarVisibility.setVisible(true)
        } label: {
            VStack(spacing: 2) {
                Image(systemName: item.icon)
                    .font(.system(size: 18, weight: isSelected ? .semibold : .regular))
                    .symbolVariant(isSelected ? .fill : .none)

                Text(item.title)
                    .font(.system(size: 9, weight: isSelected ? .semibold : .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .foregroundStyle(isSelected ? NectarColors.green : NectarColors.textPrimary.opacity(0.75))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background {
                if isSelected {
                    Capsule(style: .continuous)
                        .fill(Color.white.opacity(0.95))
                        .overlay {
                            Capsule(style: .continuous)
                                .strokeBorder(Color.white.opacity(0.9), lineWidth: 0.5)
                        }
                        .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 2)
                        .matchedGeometryEffect(id: "tabHighlight", in: tabNamespace)
                }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(GlassPressButtonStyle())
        .accessibilityLabel(item.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Press effect (scale + bounce)

/// Hiệu ứng bấm kính: thu nhỏ nhẹ khi nhấn, nảy lại khi thả.
private struct GlassPressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.88 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.65), value: configuration.isPressed)
    }
}
