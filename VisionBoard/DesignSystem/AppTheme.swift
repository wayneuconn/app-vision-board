import SwiftUI

// MARK: - Colors

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

enum AppColor {
    // Primary
    static let primary = Color(hex: "#C8A2C8")
    static let primaryLight = Color(hex: "#E8D5E8")
    static let primaryDark = Color(hex: "#9B7A9B")

    // Secondary
    static let secondary = Color(hex: "#E8B5BC")
    static let secondaryLight = Color(hex: "#F5DDE0")

    // Accent
    static let accent = Color(hex: "#A3D9C2")
    static let accentDark = Color(hex: "#6BAA91")

    // Warm
    static let warm = Color(hex: "#F7C59F")
    static let warmDark = Color(hex: "#D4956A")

    // Backgrounds
    static let bgPrimary = Color(hex: "#FDFBF9")
    static let bgSecondary = Color(hex: "#F7F3EF")
    static let bgTertiary = Color(hex: "#F0EBE5")
    static let bgElevated = Color.white

    // Text
    static let textPrimary = Color(hex: "#2C2C2E")
    static let textSecondary = Color(hex: "#6B6B6F")
    static let textTertiary = Color(hex: "#AEAEB2")

    // Borders
    static let border = Color(hex: "#E5E0DA")
    static let divider = Color(hex: "#EDEDEB")

    // Semantic
    static let success = Color(hex: "#7FC9A5")
    static let warning = Color(hex: "#F0C87A")
    static let error = Color(hex: "#D87B7B")
}

// MARK: - Typography

enum AppFont {
    static let displayLarge = Font.system(size: 34, weight: .bold, design: .rounded)
    static let displayMedium = Font.system(size: 28, weight: .bold, design: .rounded)
    static let titleLarge = Font.system(size: 22, weight: .bold)
    static let titleMedium = Font.system(size: 20, weight: .semibold)
    static let titleSmall = Font.system(size: 17, weight: .semibold)
    static let bodyLarge = Font.system(size: 17, weight: .regular)
    static let bodyMedium = Font.system(size: 15, weight: .regular)
    static let bodySmall = Font.system(size: 13, weight: .regular)
    static let caption1 = Font.system(size: 12, weight: .regular)
    static let caption2 = Font.system(size: 11, weight: .regular)
}

// MARK: - Spacing

enum AppSpacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 20
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let xxxl: CGFloat = 40
}

// MARK: - Radius

enum AppRadius {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let pill: CGFloat = 999
}

// MARK: - Animation

enum AppAnimation {
    static let fast = Animation.easeOut(duration: 0.15)
    static let standard = Animation.easeInOut(duration: 0.25)
    static let slow = Animation.easeInOut(duration: 0.4)
    static let springGentle = Animation.spring(response: 0.5, dampingFraction: 0.8)
    static let springBouncy = Animation.spring(response: 0.4, dampingFraction: 0.6)
    static let springSnappy = Animation.spring(response: 0.3, dampingFraction: 0.85)
}

// MARK: - View Modifiers

struct AppCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(AppSpacing.md)
            .background(AppColor.bgElevated)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(AppColor.primary)
            .clipShape(Capsule())
            .shadow(color: AppColor.primary.opacity(0.3), radius: 16, x: 0, y: 6)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(AppAnimation.fast, value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(AppColor.primaryDark)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(AppColor.primaryLight)
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(AppAnimation.fast, value: configuration.isPressed)
    }
}

extension View {
    func appCard() -> some View {
        modifier(AppCardModifier())
    }
}
