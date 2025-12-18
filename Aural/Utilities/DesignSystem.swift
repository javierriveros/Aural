// swiftlint:disable:next identifier_name
import SwiftUI

// MARK: - Brand Colors

enum BrandColors {
    static let primaryBlue = Color(red: 0.357, green: 0.498, blue: 1.0)
    static let primaryCyan = Color(red: 0.373, green: 0.875, blue: 1.0)
    static let accentPurple = Color(red: 0.545, green: 0.373, blue: 1.0)

    static let success = Color(red: 0.204, green: 0.780, blue: 0.349)
    static let warning = Color(red: 1.0, green: 0.584, blue: 0.0)
    static let error = Color(red: 1.0, green: 0.231, blue: 0.188)

    static let gradientPrimary = LinearGradient(
        colors: [primaryBlue, primaryCyan],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let gradientSecondary = LinearGradient(
        colors: [primaryBlue.opacity(0.6), primaryCyan.opacity(0.6)],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let gradientAccent = LinearGradient(
        colors: [accentPurple, primaryBlue],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Typography

enum Typography {
    static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
    static let title = Font.system(size: 28, weight: .bold, design: .rounded)
    static let title2 = Font.system(size: 22, weight: .semibold, design: .rounded)
    static let headline = Font.system(size: 17, weight: .semibold, design: .rounded)
    static let body = Font.system(size: 15, weight: .regular, design: .default)
    static let callout = Font.system(size: 14, weight: .medium, design: .default)
    static let caption = Font.system(size: 12, weight: .regular, design: .default)
    static let caption2 = Font.system(size: 11, weight: .regular, design: .default)

    static let monoBody = Font.system(size: 15, weight: .regular, design: .monospaced)
    static let monoCaption = Font.system(size: 12, weight: .regular, design: .monospaced)
}

// MARK: - Spacing

enum Spacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Corner Radius

enum CornerRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let full: CGFloat = 9999
}

// MARK: - Shadows

enum Shadows {
    static let sm = Shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    static let md = Shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    static let lg = Shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 8)
    static let xl = Shadow(color: .black.opacity(0.16), radius: 24, x: 0, y: 12)

    struct Shadow {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }
}

// MARK: - View Extensions

extension View {
    func cardStyle() -> some View {
        self
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(CornerRadius.md)
            .shadow(color: Shadows.sm.color, radius: Shadows.sm.radius, x: Shadows.sm.x, y: Shadows.sm.y)
    }

    func elevatedCardStyle() -> some View {
        self
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(CornerRadius.lg)
            .shadow(color: Shadows.md.color, radius: Shadows.md.radius, x: Shadows.md.x, y: Shadows.md.y)
    }

    func gradientBackground() -> some View {
        self
            .background(BrandColors.gradientPrimary)
    }

    func glassBackground() -> some View {
        self
            .background(.ultraThinMaterial)
    }
}

// MARK: - Custom Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typography.callout)
            .foregroundStyle(.white)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(BrandColors.gradientPrimary)
            .cornerRadius(CornerRadius.sm)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typography.callout)
            .foregroundStyle(BrandColors.primaryBlue)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(BrandColors.primaryBlue.opacity(0.1))
            .cornerRadius(CornerRadius.sm)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct IconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body)
            .foregroundStyle(.primary)
            .padding(Spacing.xs)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(CornerRadius.sm)
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
