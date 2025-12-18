import SwiftUI
import RubiconEngine

struct StoneView: View {
    let stone: Stone
    let isSelected: Bool
    let size: CGFloat

    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var customization = PieceCustomizationManager.shared

    private var stoneTheme: StoneTheme { themeManager.stoneTheme }

    init(stone: Stone, isSelected: Bool = false, size: CGFloat = RubiconDimensions.stoneSize) {
        self.stone = stone
        self.isSelected = isSelected
        self.size = size
    }

    private var pieceStyle: PieceStyle {
        let styleInt = stone.owner == .light ? customization.lightPieceStyle : customization.darkPieceStyle
        return PieceStyle(rawValue: styleInt) ?? .solid
    }

    private var pieceIcon: String {
        stone.owner == .light ? customization.lightPieceIcon : customization.darkPieceIcon
    }

    private var customImage: UIImage? {
        stone.owner == .light ? customization.lightPieceImage : customization.darkPieceImage
    }

    var body: some View {
        ZStack {
            // Shadow layer
            Circle()
                .fill(shadowColor)
                .offset(x: 2, y: 3)
                .blur(radius: 2)

            // Main stone content based on style
            switch pieceStyle {
            case .solid:
                solidStoneView
            case .icon:
                iconStoneView
            case .customImage:
                if let image = customImage {
                    customImageView(image: image)
                } else {
                    solidStoneView
                }
            }

            // Locked indicator (crystalline overlay)
            if stone.isLocked {
                lockedOverlay
            }

            // Selection ring
            if isSelected {
                Circle()
                    .stroke(RubiconColors.selected, lineWidth: 3)
                    .scaleEffect(1.15)
                    .shadow(color: RubiconColors.selected.opacity(0.5), radius: 4)
            }
        }
        .frame(width: size, height: size)
        .animation(RubiconAnimations.quick, value: isSelected)
        .animation(RubiconAnimations.standard, value: stone.isLocked)
    }

    // MARK: - Solid Stone (Default)

    private var solidStoneView: some View {
        ZStack {
            // Main stone
            Circle()
                .fill(mainGradient)
                .overlay(
                    Circle()
                        .fill(highlightGradient)
                        .padding(size * 0.15)
                )

            // Inner shine
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            innerShineColor.opacity(0.4),
                            Color.clear
                        ],
                        center: UnitPoint(x: 0.35, y: 0.35),
                        startRadius: 0,
                        endRadius: size * 0.3
                    )
                )
        }
    }

    // MARK: - Icon Stone

    private var iconStoneView: some View {
        ZStack {
            // Base circle with gradient
            Circle()
                .fill(mainGradient)

            // Icon
            Image(systemName: pieceIcon)
                .font(.system(size: size * 0.5, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: stone.owner == .light
                            ? [Color.black.opacity(0.7), Color.black.opacity(0.5)]
                            : [Color.white.opacity(0.9), Color.white.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: stone.owner == .light ? .white.opacity(0.5) : .black.opacity(0.5), radius: 1, x: 0, y: 1)
        }
    }

    // MARK: - Custom Image Stone

    private func customImageView(image: UIImage) -> some View {
        ZStack {
            // Base circle with subtle gradient for depth
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.gray.opacity(0.3),
                            Color.gray.opacity(0.1)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.5
                    )
                )

            // Custom image
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: size * 0.85, height: size * 0.85)
                .clipShape(Circle())

            // Subtle border for definition
            Circle()
                .stroke(
                    LinearGradient(
                        colors: stone.owner == .light
                            ? [Color.white.opacity(0.6), Color.gray.opacity(0.3)]
                            : [Color.gray.opacity(0.5), Color.black.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        }
    }

    // MARK: - Locked Overlay

    private var lockedOverlay: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            stoneTheme.lockedGlow.opacity(0.6),
                            stoneTheme.lockedGlow.opacity(0.2),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.5
                    )
                )

            // Glowing ring
            Circle()
                .stroke(stoneTheme.lockedGlow, lineWidth: 2)
                .blur(radius: 2)

            // Locked symbol
            Image(systemName: "lock.fill")
                .font(.system(size: size * 0.28, weight: .bold))
                .foregroundColor(.white.opacity(0.9))
                .shadow(color: stoneTheme.lockedGlow, radius: 4)
        }
    }

    private var mainGradient: RadialGradient {
        if stone.owner == .light {
            return RadialGradient(
                colors: [
                    stoneTheme.lightStoneHighlight,
                    stoneTheme.lightStone,
                    stoneTheme.lightStoneShadow
                ],
                center: .topLeading,
                startRadius: 0,
                endRadius: size * 0.8
            )
        } else {
            return RadialGradient(
                colors: [
                    stoneTheme.darkStoneHighlight,
                    stoneTheme.darkStone,
                    stoneTheme.darkStoneShadow
                ],
                center: .topLeading,
                startRadius: 0,
                endRadius: size * 0.8
            )
        }
    }

    private var highlightGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(stone.owner == .light ? 0.6 : 0.3),
                Color.clear
            ],
            startPoint: .topLeading,
            endPoint: .center
        )
    }

    private var innerShineColor: Color {
        stone.owner == .light
            ? stoneTheme.lightStoneHighlight
            : stoneTheme.darkStoneHighlight
    }

    private var shadowColor: Color {
        stone.owner == .light
            ? Color.black.opacity(0.25)
            : Color.black.opacity(0.4)
    }
}

// MARK: - Preview

#Preview("Light Stone") {
    VStack(spacing: 20) {
        StoneView(stone: Stone(owner: .light), isSelected: false)
        StoneView(stone: Stone(owner: .light), isSelected: true)
        StoneView(stone: Stone(owner: .light, isLocked: true))
    }
    .padding(40)
    .background(RubiconColors.boardBackground)
}

#Preview("Dark Stone") {
    VStack(spacing: 20) {
        StoneView(stone: Stone(owner: .dark), isSelected: false)
        StoneView(stone: Stone(owner: .dark), isSelected: true)
        StoneView(stone: Stone(owner: .dark, isLocked: true))
    }
    .padding(40)
    .background(RubiconColors.boardBackground)
}
