import SwiftUI
import RubiconEngine

struct GameHUDView: View {
    let state: GameState
    let availablePatterns: [Pattern]
    let onLockPattern: (Pattern) -> Void
    let onDrawFromRiver: () -> Void
    let onPass: () -> Void
    let onBreak: () -> Void

    @StateObject private var themeManager = ThemeManager.shared

    private var stoneTheme: StoneTheme { themeManager.stoneTheme }

    var body: some View {
        VStack(spacing: RubiconDimensions.spacing) {
            // Turn indicator
            turnIndicator

            // Player info panels
            HStack(spacing: RubiconDimensions.spacing) {
                playerPanel(player: .light)
                playerPanel(player: .dark)
            }

            // Action buttons
            actionButtons

            // Available patterns
            if !availablePatterns.isEmpty && !state.isGameOver {
                patternSelector
            }
        }
        .padding(RubiconDimensions.spacing)
    }

    // MARK: - Turn Indicator

    private var turnIndicator: some View {
        HStack(spacing: 12) {
            // Animated stone indicator
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: state.currentPlayer == .light
                                ? [stoneTheme.lightStoneHighlight, stoneTheme.lightStone, stoneTheme.lightStoneShadow]
                                : [stoneTheme.darkStoneHighlight, stoneTheme.darkStone, stoneTheme.darkStoneShadow],
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: 20
                        )
                    )
                    .frame(width: 28, height: 28)
                    .shadow(color: .black.opacity(0.4), radius: 3, x: 1, y: 2)

                // Pulse animation for current turn
                if !state.isGameOver {
                    Circle()
                        .stroke(RubiconColors.selected.opacity(0.6), lineWidth: 2)
                        .frame(width: 36, height: 36)
                        .scaleEffect(1.0)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(state.isGameOver ? "Game Over" : "\(state.currentPlayer == .light ? "Light" : "Dark")'s Turn")
                    .font(RubiconFonts.heading(18))
                    .foregroundColor(RubiconColors.textPrimary)

                Text("Turn \(state.turnNumber)")
                    .font(RubiconFonts.caption(12))
                    .foregroundColor(RubiconColors.textSecondary)
            }

            Spacer()

            // Game mode badge
            HStack(spacing: 4) {
                Image(systemName: gameModeIcon)
                    .font(.system(size: 12))
                Text(gameModeText)
                    .font(RubiconFonts.caption(11))
            }
            .foregroundColor(RubiconColors.textSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(RubiconColors.hudBackground)
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(RubiconColors.cardBackground)
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(RubiconColors.textSecondary.opacity(0.1), lineWidth: 1)
        )
    }

    private var gameModeIcon: String {
        switch state.gameMode {
        case .localPassAndPlay: return "person.2.fill"
        case .vsAI: return "cpu"
        case .onlineRanked, .onlineCasual: return "globe"
        case .puzzle: return "puzzlepiece.fill"
        case .tutorial: return "book.fill"
        }
    }

    private var gameModeText: String {
        switch state.gameMode {
        case .localPassAndPlay: return "Local"
        case .vsAI(let difficulty): return difficulty.displayName
        case .onlineRanked: return "Ranked"
        case .onlineCasual: return "Casual"
        case .puzzle: return "Puzzle"
        case .tutorial: return "Tutorial"
        }
    }

    // MARK: - Player Panel

    private func playerPanel(player: Player) -> some View {
        let isCurrentTurn = state.currentPlayer == player && !state.isGameOver
        let stonesInHand = player == .light ? state.lightStonesInHand : state.darkStonesInHand
        let stonesOnBoard = state.board.stoneCount(for: player)
        let lockedPatterns = state.lockedPatterns(for: player)
        let riverCount = state.river(for: player).count
        let isWinner = state.winner == player

        return VStack(alignment: .leading, spacing: 10) {
            // Header with stone
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: player == .light
                                    ? [stoneTheme.lightStoneHighlight, stoneTheme.lightStone, stoneTheme.lightStoneShadow]
                                    : [stoneTheme.darkStoneHighlight, stoneTheme.darkStone, stoneTheme.darkStoneShadow],
                                center: .topLeading,
                                startRadius: 0,
                                endRadius: 18
                            )
                        )
                        .frame(width: 22, height: 22)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 1, y: 1)
                }

                Text(player == .light ? "Light" : "Dark")
                    .font(RubiconFonts.body(15))
                    .fontWeight(.semibold)
                    .foregroundColor(RubiconColors.textPrimary)

                Spacer()

                if isWinner {
                    HStack(spacing: 4) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 14))
                        Text("Winner")
                            .font(RubiconFonts.caption(11))
                    }
                    .foregroundColor(RubiconColors.victory)
                }
            }

            // Stats row
            HStack(spacing: 0) {
                // Stones in hand
                StatBadge(
                    icon: "hand.raised.fill",
                    value: "\(stonesInHand)",
                    label: "Hand",
                    color: RubiconColors.textSecondary
                )

                Spacer()

                // Stones on board
                StatBadge(
                    icon: "circle.grid.2x2.fill",
                    value: "\(stonesOnBoard)",
                    label: "Board",
                    color: RubiconColors.textSecondary
                )

                Spacer()

                // River (captured stones)
                StatBadge(
                    icon: "drop.fill",
                    value: "\(riverCount)",
                    label: "River",
                    color: Color(red: 0.3, green: 0.6, blue: 0.9)
                )

                Spacer()

                // Locked patterns
                StatBadge(
                    icon: "lock.fill",
                    value: "\(lockedPatterns.count)",
                    label: "Locked",
                    color: stoneTheme.lockedGlow
                )
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(RubiconColors.cardBackground)
                .shadow(color: .black.opacity(isCurrentTurn ? 0.25 : 0.15), radius: isCurrentTurn ? 10 : 6, x: 0, y: isCurrentTurn ? 5 : 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    isCurrentTurn
                        ? RubiconColors.selected
                        : (isWinner ? RubiconColors.victory.opacity(0.5) : RubiconColors.textSecondary.opacity(0.1)),
                    lineWidth: isCurrentTurn ? 2 : 1
                )
        )
        .scaleEffect(isCurrentTurn ? 1.02 : 1.0)
        .animation(RubiconAnimations.spring, value: isCurrentTurn)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 12) {
            // River button - draw from your own river
            let myRiverCount = state.river(for: state.currentPlayer).count
            ActionButton(
                icon: "drop.fill",
                label: "River",
                badge: myRiverCount > 0 ? "\(myRiverCount)" : nil,
                isEnabled: state.canDrawFromRiver(player: state.currentPlayer) && !state.isGameOver,
                accentColor: Color(red: 0.3, green: 0.6, blue: 0.9),
                action: onDrawFromRiver
            )

            // Pass button (shows remaining passes)
            let remainingPasses = state.remainingPasses(for: state.currentPlayer)
            ActionButton(
                icon: "arrow.forward.circle.fill",
                label: "Pass",
                badge: remainingPasses < 3 ? "\(remainingPasses)" : nil,
                isEnabled: state.canPass(player: state.currentPlayer) && !state.isGameOver,
                accentColor: RubiconColors.textSecondary,
                action: onPass
            )

            // Break button (if available)
            if state.canUseBreak(player: state.currentPlayer) {
                ActionButton(
                    icon: "hammer.fill",
                    label: "Break",
                    badge: nil,
                    isEnabled: !state.isGameOver,
                    accentColor: Color(red: 0.9, green: 0.4, blue: 0.3),
                    action: onBreak
                )
            }
        }
    }

    // MARK: - Pattern Selector

    private var patternSelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(stoneTheme.lockedGlow)
                Text("Lock a Pattern")
                    .font(RubiconFonts.body(14))
                    .fontWeight(.medium)
                    .foregroundColor(RubiconColors.textPrimary)
                Spacer()
                Text("\(availablePatterns.count) available")
                    .font(RubiconFonts.caption(11))
                    .foregroundColor(RubiconColors.textSecondary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(availablePatterns, id: \.id) { pattern in
                        PatternCard(pattern: pattern, lockedColor: stoneTheme.lockedGlow, onTap: {
                            onLockPattern(pattern)
                        })
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(RubiconColors.cardBackground)
                .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(stoneTheme.lockedGlow.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Supporting Views

struct StatBadge: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                Text(value)
                    .font(RubiconFonts.body(14))
                    .fontWeight(.semibold)
            }
            .foregroundColor(color)

            Text(label)
                .font(RubiconFonts.caption(9))
                .foregroundColor(RubiconColors.textSecondary.opacity(0.7))
        }
    }
}

struct ActionButton: View {
    let icon: String
    let label: String
    let badge: String?
    let isEnabled: Bool
    let accentColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(isEnabled ? accentColor.opacity(0.15) : RubiconColors.hudBackground)
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(isEnabled ? accentColor : RubiconColors.textSecondary.opacity(0.5))

                    if let badge = badge, !badge.isEmpty && badge != "0" {
                        Text(badge)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(4)
                            .background(Circle().fill(accentColor))
                            .offset(x: 14, y: -14)
                    }
                }

                Text(label)
                    .font(RubiconFonts.caption(11))
                    .foregroundColor(isEnabled ? RubiconColors.textPrimary : RubiconColors.textSecondary.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(RubiconColors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isEnabled ? accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .disabled(!isEnabled)
    }
}

struct PatternCard: View {
    let pattern: Pattern
    let lockedColor: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(lockedColor.opacity(0.1))
                        .frame(width: 50, height: 50)

                    patternIcon(for: pattern.type)
                        .font(.system(size: 24))
                        .foregroundColor(lockedColor)
                }

                VStack(spacing: 2) {
                    Text(pattern.type.displayName)
                        .font(RubiconFonts.caption(11))
                        .fontWeight(.medium)
                        .foregroundColor(RubiconColors.textPrimary)

                    Text("\(pattern.positions.count) stones")
                        .font(RubiconFonts.caption(9))
                        .foregroundColor(RubiconColors.textSecondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(RubiconColors.hudBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(lockedColor.opacity(0.4), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }

    @ViewBuilder
    private func patternIcon(for type: PatternType) -> some View {
        switch type {
        case .line:
            Image(systemName: "line.horizontal.3")
        case .bend:
            Image(systemName: "arrow.turn.down.right")
        case .gate:
            Image(systemName: "square.grid.2x2")
        case .cross:
            Image(systemName: "plus")
        }
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Victory Banner

struct VictoryBannerView: View {
    let winner: Player
    let victorySet: VictorySetType?
    let totalMoves: Int
    let onNewGame: () -> Void
    let onMainMenu: () -> Void
    let onViewBoard: () -> Void

    @StateObject private var themeManager = ThemeManager.shared

    var body: some View {
        VStack(spacing: 20) {
            // Decorative top
            ZStack {
                // Glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [RubiconColors.victory.opacity(0.4), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 80
                        )
                    )
                    .frame(width: 140, height: 140)

                // Crown icon
                Image(systemName: "crown.fill")
                    .font(.system(size: 48))
                    .foregroundColor(RubiconColors.victory)
                    .shadow(color: RubiconColors.victory.opacity(0.5), radius: 10)
            }

            // Winner stone
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: winner == .light
                                ? [themeManager.stoneTheme.lightStoneHighlight, themeManager.stoneTheme.lightStone, themeManager.stoneTheme.lightStoneShadow]
                                : [themeManager.stoneTheme.darkStoneHighlight, themeManager.stoneTheme.darkStone, themeManager.stoneTheme.darkStoneShadow],
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: 30
                        )
                    )
                    .frame(width: 44, height: 44)
                    .shadow(color: .black.opacity(0.4), radius: 6, x: 2, y: 4)
            }

            VStack(spacing: 6) {
                // Winner text
                Text("\(winner == .light ? "Light" : "Dark") Wins!")
                    .font(RubiconFonts.title(28))
                    .foregroundColor(RubiconColors.textPrimary)

                // Victory condition
                if let victorySet = victorySet {
                    HStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 11))
                        Text(victorySet.displayName)
                            .font(RubiconFonts.heading(16))
                    }
                    .foregroundColor(RubiconColors.textAccent)
                }

                // Move count
                Text("\(totalMoves) moves played")
                    .font(RubiconFonts.caption(12))
                    .foregroundColor(RubiconColors.textSecondary)
                    .padding(.top, 2)
            }

            // Buttons
            VStack(spacing: 10) {
                Button("Play Again", action: onNewGame)
                    .rubiconStyle(isPrimary: true)

                HStack(spacing: 10) {
                    Button {
                        onViewBoard()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "square.grid.3x3")
                            Text("View Board")
                        }
                    }
                    .rubiconStyle(isPrimary: false)

                    Button("Menu", action: onMainMenu)
                        .rubiconStyle(isPrimary: false)
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(28)
        .frame(maxWidth: 320)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(RubiconColors.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    LinearGradient(
                        colors: [RubiconColors.victory.opacity(0.6), RubiconColors.victory.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
        .shadow(color: .black.opacity(0.5), radius: 30, x: 0, y: 15)
    }
}

// MARK: - Preview

#Preview {
    VStack {
        GameHUDView(
            state: GameState(),
            availablePatterns: [],
            onLockPattern: { _ in },
            onDrawFromRiver: {},
            onPass: {},
            onBreak: {}
        )
    }
    .background(RubiconColors.menuBackground)
}
