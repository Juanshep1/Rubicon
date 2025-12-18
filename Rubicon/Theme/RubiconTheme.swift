import SwiftUI

// MARK: - Board Themes

public enum BoardTheme: Int, CaseIterable, Identifiable {
    case classicOak = 0
    case darkWalnut = 1
    case midnightEbony = 2
    case cherryBlossom = 3
    case oceanBreeze = 4
    case emeraldForest = 5

    public var id: Int { rawValue }

    public var name: String {
        switch self {
        case .classicOak: return "Classic Oak"
        case .darkWalnut: return "Dark Walnut"
        case .midnightEbony: return "Midnight Ebony"
        case .cherryBlossom: return "Cherry Blossom"
        case .oceanBreeze: return "Ocean Breeze"
        case .emeraldForest: return "Emerald Forest"
        }
    }

    public var background: Color {
        switch self {
        case .classicOak: return Color(red: 0.55, green: 0.35, blue: 0.20)
        case .darkWalnut: return Color(red: 0.35, green: 0.22, blue: 0.14)
        case .midnightEbony: return Color(red: 0.12, green: 0.10, blue: 0.12)
        case .cherryBlossom: return Color(red: 0.85, green: 0.72, blue: 0.68)
        case .oceanBreeze: return Color(red: 0.18, green: 0.32, blue: 0.42)
        case .emeraldForest: return Color(red: 0.15, green: 0.30, blue: 0.20)
        }
    }

    public var lightSquare: Color {
        switch self {
        case .classicOak: return Color(red: 0.65, green: 0.45, blue: 0.28)
        case .darkWalnut: return Color(red: 0.45, green: 0.32, blue: 0.22)
        case .midnightEbony: return Color(red: 0.22, green: 0.20, blue: 0.24)
        case .cherryBlossom: return Color(red: 0.95, green: 0.85, blue: 0.82)
        case .oceanBreeze: return Color(red: 0.28, green: 0.45, blue: 0.55)
        case .emeraldForest: return Color(red: 0.25, green: 0.42, blue: 0.30)
        }
    }

    public var darkSquare: Color {
        switch self {
        case .classicOak: return Color(red: 0.45, green: 0.28, blue: 0.15)
        case .darkWalnut: return Color(red: 0.28, green: 0.16, blue: 0.10)
        case .midnightEbony: return Color(red: 0.08, green: 0.06, blue: 0.08)
        case .cherryBlossom: return Color(red: 0.75, green: 0.58, blue: 0.55)
        case .oceanBreeze: return Color(red: 0.12, green: 0.22, blue: 0.32)
        case .emeraldForest: return Color(red: 0.10, green: 0.22, blue: 0.14)
        }
    }

    public var gridLine: Color {
        switch self {
        case .classicOak: return Color(red: 0.30, green: 0.18, blue: 0.08).opacity(0.6)
        case .darkWalnut: return Color(red: 0.20, green: 0.12, blue: 0.06).opacity(0.7)
        case .midnightEbony: return Color(red: 0.40, green: 0.38, blue: 0.45).opacity(0.5)
        case .cherryBlossom: return Color(red: 0.55, green: 0.40, blue: 0.38).opacity(0.5)
        case .oceanBreeze: return Color(red: 0.08, green: 0.15, blue: 0.22).opacity(0.6)
        case .emeraldForest: return Color(red: 0.05, green: 0.12, blue: 0.08).opacity(0.6)
        }
    }

    public var border: Color {
        switch self {
        case .classicOak: return Color(red: 0.35, green: 0.20, blue: 0.10)
        case .darkWalnut: return Color(red: 0.22, green: 0.12, blue: 0.08)
        case .midnightEbony: return Color(red: 0.35, green: 0.32, blue: 0.40)
        case .cherryBlossom: return Color(red: 0.65, green: 0.48, blue: 0.45)
        case .oceanBreeze: return Color(red: 0.10, green: 0.20, blue: 0.28)
        case .emeraldForest: return Color(red: 0.08, green: 0.18, blue: 0.12)
        }
    }

    public var previewColors: [Color] {
        [background, lightSquare, darkSquare]
    }
}

// MARK: - Stone Themes

public enum StoneTheme: Int, CaseIterable, Identifiable {
    case classicMarbleObsidian = 0
    case warmAmberJade = 1
    case royalGoldSilver = 2
    case sunsetCoralTeal = 3
    case crystalIceVolcanic = 4
    case zenWhiteShadow = 5

    public var id: Int { rawValue }

    public var name: String {
        switch self {
        case .classicMarbleObsidian: return "Marble & Obsidian"
        case .warmAmberJade: return "Amber & Jade"
        case .royalGoldSilver: return "Gold & Silver"
        case .sunsetCoralTeal: return "Coral & Teal"
        case .crystalIceVolcanic: return "Ice & Volcanic"
        case .zenWhiteShadow: return "Zen White & Shadow"
        }
    }

    // Light stone colors
    public var lightStone: Color {
        switch self {
        case .classicMarbleObsidian: return Color(red: 0.96, green: 0.96, blue: 0.88)
        case .warmAmberJade: return Color(red: 0.95, green: 0.75, blue: 0.35)
        case .royalGoldSilver: return Color(red: 1.0, green: 0.85, blue: 0.35)
        case .sunsetCoralTeal: return Color(red: 1.0, green: 0.55, blue: 0.45)
        case .crystalIceVolcanic: return Color(red: 0.85, green: 0.95, blue: 1.0)
        case .zenWhiteShadow: return Color(red: 1.0, green: 1.0, blue: 1.0)
        }
    }

    public var lightStoneHighlight: Color {
        switch self {
        case .classicMarbleObsidian: return Color.white
        case .warmAmberJade: return Color(red: 1.0, green: 0.90, blue: 0.60)
        case .royalGoldSilver: return Color(red: 1.0, green: 0.95, blue: 0.70)
        case .sunsetCoralTeal: return Color(red: 1.0, green: 0.75, blue: 0.65)
        case .crystalIceVolcanic: return Color(red: 1.0, green: 1.0, blue: 1.0)
        case .zenWhiteShadow: return Color(red: 1.0, green: 1.0, blue: 1.0)
        }
    }

    public var lightStoneShadow: Color {
        switch self {
        case .classicMarbleObsidian: return Color(red: 0.85, green: 0.85, blue: 0.78)
        case .warmAmberJade: return Color(red: 0.75, green: 0.55, blue: 0.20)
        case .royalGoldSilver: return Color(red: 0.80, green: 0.65, blue: 0.20)
        case .sunsetCoralTeal: return Color(red: 0.80, green: 0.35, blue: 0.30)
        case .crystalIceVolcanic: return Color(red: 0.65, green: 0.80, blue: 0.90)
        case .zenWhiteShadow: return Color(red: 0.85, green: 0.85, blue: 0.85)
        }
    }

    // Dark stone colors
    public var darkStone: Color {
        switch self {
        case .classicMarbleObsidian: return Color(red: 0.15, green: 0.15, blue: 0.18)
        case .warmAmberJade: return Color(red: 0.18, green: 0.45, blue: 0.28)
        case .royalGoldSilver: return Color(red: 0.60, green: 0.62, blue: 0.68)
        case .sunsetCoralTeal: return Color(red: 0.15, green: 0.55, blue: 0.58)
        case .crystalIceVolcanic: return Color(red: 0.25, green: 0.12, blue: 0.10)
        case .zenWhiteShadow: return Color(red: 0.25, green: 0.25, blue: 0.28)
        }
    }

    public var darkStoneHighlight: Color {
        switch self {
        case .classicMarbleObsidian: return Color(red: 0.30, green: 0.30, blue: 0.35)
        case .warmAmberJade: return Color(red: 0.35, green: 0.60, blue: 0.42)
        case .royalGoldSilver: return Color(red: 0.75, green: 0.78, blue: 0.82)
        case .sunsetCoralTeal: return Color(red: 0.30, green: 0.70, blue: 0.72)
        case .crystalIceVolcanic: return Color(red: 0.50, green: 0.25, blue: 0.22)
        case .zenWhiteShadow: return Color(red: 0.45, green: 0.45, blue: 0.50)
        }
    }

    public var darkStoneShadow: Color {
        switch self {
        case .classicMarbleObsidian: return Color(red: 0.08, green: 0.08, blue: 0.10)
        case .warmAmberJade: return Color(red: 0.10, green: 0.30, blue: 0.18)
        case .royalGoldSilver: return Color(red: 0.45, green: 0.48, blue: 0.52)
        case .sunsetCoralTeal: return Color(red: 0.08, green: 0.38, blue: 0.40)
        case .crystalIceVolcanic: return Color(red: 0.15, green: 0.05, blue: 0.03)
        case .zenWhiteShadow: return Color(red: 0.12, green: 0.12, blue: 0.15)
        }
    }

    public var lockedGlow: Color {
        switch self {
        case .classicMarbleObsidian: return Color(red: 0.29, green: 0.56, blue: 0.85)
        case .warmAmberJade: return Color(red: 0.85, green: 0.65, blue: 0.25)
        case .royalGoldSilver: return Color(red: 0.75, green: 0.45, blue: 0.85)
        case .sunsetCoralTeal: return Color(red: 0.95, green: 0.85, blue: 0.35)
        case .crystalIceVolcanic: return Color(red: 0.45, green: 0.85, blue: 0.95)
        case .zenWhiteShadow: return Color(red: 0.55, green: 0.75, blue: 0.95)
        }
    }
}

// MARK: - Theme Manager

public class ThemeManager: ObservableObject {
    public static let shared = ThemeManager()

    @AppStorage("boardTheme") public var boardThemeIndex: Int = 0
    @AppStorage("stoneTheme") public var stoneThemeIndex: Int = 0

    public var boardTheme: BoardTheme {
        BoardTheme(rawValue: boardThemeIndex) ?? .classicOak
    }

    public var stoneTheme: StoneTheme {
        StoneTheme(rawValue: stoneThemeIndex) ?? .classicMarbleObsidian
    }

    private init() {}
}

// MARK: - Color Palette (Static defaults for backward compatibility)

public enum RubiconColors {
    // Board colors (now use ThemeManager for dynamic colors)
    public static let boardBackground = Color(red: 0.55, green: 0.35, blue: 0.20)
    public static let boardLight = Color(red: 0.65, green: 0.45, blue: 0.28)
    public static let boardDark = Color(red: 0.45, green: 0.28, blue: 0.15)
    public static let boardBorder = Color(red: 0.35, green: 0.20, blue: 0.10)
    public static let gridLine = Color(red: 0.30, green: 0.18, blue: 0.08).opacity(0.6)

    // Stone colors
    public static let lightStone = Color(red: 0.96, green: 0.96, blue: 0.88)
    public static let lightStoneHighlight = Color.white
    public static let lightStoneShadow = Color(red: 0.85, green: 0.85, blue: 0.78)

    public static let darkStone = Color(red: 0.15, green: 0.15, blue: 0.18)
    public static let darkStoneHighlight = Color(red: 0.30, green: 0.30, blue: 0.35)
    public static let darkStoneShadow = Color(red: 0.08, green: 0.08, blue: 0.10)

    // UI colors
    public static let locked = Color(red: 0.29, green: 0.56, blue: 0.85).opacity(0.8)
    public static let selected = Color(red: 0.95, green: 0.75, blue: 0.20)
    public static let validMove = Color(red: 0.40, green: 0.75, blue: 0.40).opacity(0.5)
    public static let captureTarget = Color(red: 0.85, green: 0.30, blue: 0.25).opacity(0.6)
    public static let victory = Color(red: 1.0, green: 0.84, blue: 0.0)

    // Background colors
    public static let menuBackground = Color(red: 0.12, green: 0.10, blue: 0.08)
    public static let cardBackground = Color(red: 0.18, green: 0.15, blue: 0.12)
    public static let hudBackground = Color(red: 0.15, green: 0.12, blue: 0.10).opacity(0.95)

    // Text colors
    public static let textPrimary = Color(red: 0.95, green: 0.92, blue: 0.88)
    public static let textSecondary = Color(red: 0.70, green: 0.65, blue: 0.60)
    public static let textAccent = Color(red: 0.95, green: 0.75, blue: 0.20)
}

// MARK: - Typography

public enum RubiconFonts {
    public static func title(_ size: CGFloat = 32) -> Font {
        .system(size: size, weight: .bold, design: .serif)
    }

    public static func heading(_ size: CGFloat = 24) -> Font {
        .system(size: size, weight: .semibold, design: .serif)
    }

    public static func body(_ size: CGFloat = 16) -> Font {
        .system(size: size, weight: .regular, design: .rounded)
    }

    public static func caption(_ size: CGFloat = 12) -> Font {
        .system(size: size, weight: .medium, design: .rounded)
    }

    public static func notation(_ size: CGFloat = 10) -> Font {
        .system(size: size, weight: .medium, design: .monospaced)
    }
}

// MARK: - Dimensions

public enum RubiconDimensions {
    public static let stoneSize: CGFloat = 44
    public static let cellSize: CGFloat = 52
    public static let boardPadding: CGFloat = 24
    public static let gridLineWidth: CGFloat = 1.5
    public static let cornerRadius: CGFloat = 12
    public static let buttonHeight: CGFloat = 56
    public static let spacing: CGFloat = 16
    public static let smallSpacing: CGFloat = 8
}

// MARK: - View Modifiers

struct WoodGrainBackground: ViewModifier {
    let theme: BoardTheme

    init(theme: BoardTheme = ThemeManager.shared.boardTheme) {
        self.theme = theme
    }

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    theme.background
                    LinearGradient(
                        colors: [
                            theme.lightSquare.opacity(0.3),
                            theme.background,
                            theme.darkSquare.opacity(0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            )
    }
}

struct RubiconButtonStyle: ButtonStyle {
    let isPrimary: Bool

    init(isPrimary: Bool = true) {
        self.isPrimary = isPrimary
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(RubiconFonts.body(18))
            .foregroundColor(isPrimary ? RubiconColors.menuBackground : RubiconColors.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: RubiconDimensions.buttonHeight)
            .background(
                RoundedRectangle(cornerRadius: RubiconDimensions.cornerRadius)
                    .fill(isPrimary ? RubiconColors.textAccent : RubiconColors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: RubiconDimensions.cornerRadius)
                    .stroke(isPrimary ? Color.clear : RubiconColors.textSecondary.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: RubiconDimensions.cornerRadius)
                    .fill(RubiconColors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: RubiconDimensions.cornerRadius)
                    .stroke(RubiconColors.boardBorder.opacity(0.3), lineWidth: 1)
            )
    }
}

// MARK: - View Extensions

public extension View {
    func woodGrainBackground(theme: BoardTheme = ThemeManager.shared.boardTheme) -> some View {
        modifier(WoodGrainBackground(theme: theme))
    }

    func rubiconCard() -> some View {
        modifier(CardStyle())
    }
}

public extension Button {
    func rubiconStyle(isPrimary: Bool = true) -> some View {
        self.buttonStyle(RubiconButtonStyle(isPrimary: isPrimary))
    }
}

// MARK: - Animations

public enum RubiconAnimations {
    public static let standard = Animation.easeInOut(duration: 0.25)
    public static let quick = Animation.easeInOut(duration: 0.15)
    public static let slow = Animation.easeInOut(duration: 0.4)
    public static let spring = Animation.spring(response: 0.35, dampingFraction: 0.7)
    public static let bounce = Animation.spring(response: 0.4, dampingFraction: 0.5)
}
