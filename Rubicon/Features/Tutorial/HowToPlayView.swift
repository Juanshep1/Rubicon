import SwiftUI
import RubiconEngine

struct HowToPlayView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0

    private let pages: [TutorialPage] = [
        .overview,
        .theBoard,
        .droppingStones,
        .shiftingStones,
        .capturing,
        .patterns,
        .locking,
        .victorySets,
        .theRiver,
        .breaking,
        .strategy
    ]

    var body: some View {
        ZStack {
            RubiconColors.menuBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                header

                // Page content
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        TutorialPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Navigation
                navigationBar
            }
        }
    }

    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "xmark")
                    Text("Close")
                }
                .font(RubiconFonts.body(16))
                .foregroundColor(RubiconColors.textSecondary)
            }

            Spacer()

            Text("How to Play")
                .font(RubiconFonts.heading(20))
                .foregroundColor(RubiconColors.textPrimary)

            Spacer()

            Text("\(currentPage + 1)/\(pages.count)")
                .font(RubiconFonts.caption(14))
                .foregroundColor(RubiconColors.textSecondary)
                .frame(width: 60, alignment: .trailing)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(RubiconColors.cardBackground)
    }

    private var navigationBar: some View {
        HStack(spacing: 16) {
            // Previous button
            Button {
                withAnimation {
                    currentPage = max(0, currentPage - 1)
                }
            } label: {
                HStack {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .font(RubiconFonts.body(16))
                .foregroundColor(currentPage > 0 ? RubiconColors.textPrimary : RubiconColors.textSecondary.opacity(0.5))
            }
            .disabled(currentPage == 0)

            Spacer()

            // Page indicators
            HStack(spacing: 6) {
                ForEach(0..<pages.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentPage ? RubiconColors.textAccent : RubiconColors.textSecondary.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .onTapGesture {
                            withAnimation {
                                currentPage = index
                            }
                        }
                }
            }

            Spacer()

            // Next button
            Button {
                withAnimation {
                    if currentPage < pages.count - 1 {
                        currentPage += 1
                    } else {
                        dismiss()
                    }
                }
            } label: {
                HStack {
                    Text(currentPage < pages.count - 1 ? "Next" : "Done")
                    Image(systemName: currentPage < pages.count - 1 ? "chevron.right" : "checkmark")
                }
                .font(RubiconFonts.body(16))
                .foregroundColor(RubiconColors.textAccent)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(RubiconColors.cardBackground)
    }
}

// MARK: - Tutorial Page Enum

enum TutorialPage: String, CaseIterable {
    case overview
    case theBoard
    case droppingStones
    case shiftingStones
    case capturing
    case patterns
    case locking
    case victorySets
    case theRiver
    case breaking
    case strategy

    var title: String {
        switch self {
        case .overview: return "Welcome to Rubicon"
        case .theBoard: return "The Board"
        case .droppingStones: return "Dropping Stones"
        case .shiftingStones: return "Shifting Stones"
        case .capturing: return "Capturing (Surrounding)"
        case .patterns: return "Patterns"
        case .locking: return "Locking Patterns"
        case .victorySets: return "Victory Sets"
        case .theRiver: return "The River"
        case .breaking: return "Breaking"
        case .strategy: return "Strategy Tips"
        }
    }

    var icon: String {
        switch self {
        case .overview: return "star.fill"
        case .theBoard: return "square.grid.3x3"
        case .droppingStones: return "arrow.down.circle.fill"
        case .shiftingStones: return "arrow.left.and.right"
        case .capturing: return "target"
        case .patterns: return "square.3.layers.3d"
        case .locking: return "lock.fill"
        case .victorySets: return "crown.fill"
        case .theRiver: return "drop.fill"
        case .breaking: return "hammer.fill"
        case .strategy: return "lightbulb.fill"
        }
    }
}

// MARK: - Tutorial Page View

struct TutorialPageView: View {
    let page: TutorialPage
    @StateObject private var themeManager = ThemeManager.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Icon and title
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(RubiconColors.textAccent.opacity(0.15))
                            .frame(width: 80, height: 80)

                        Image(systemName: page.icon)
                            .font(.system(size: 36))
                            .foregroundColor(RubiconColors.textAccent)
                    }

                    Text(page.title)
                        .font(RubiconFonts.title(28))
                        .foregroundColor(RubiconColors.textPrimary)
                }
                .padding(.top, 20)

                // Content based on page
                pageContent
                    .padding(.horizontal, 24)

                Spacer(minLength: 40)
            }
        }
    }

    @ViewBuilder
    private var pageContent: some View {
        switch page {
        case .overview:
            overviewContent
        case .theBoard:
            boardContent
        case .droppingStones:
            droppingContent
        case .shiftingStones:
            shiftingContent
        case .capturing:
            capturingContent
        case .patterns:
            patternsContent
        case .locking:
            lockingContent
        case .victorySets:
            victorySetsContent
        case .theRiver:
            riverContent
        case .breaking:
            breakingContent
        case .strategy:
            strategyContent
        }
    }

    // MARK: - Page Contents

    private var overviewContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            TutorialText("""
            Rubicon is an abstract strategy game where two players compete to form and lock patterns on a 6x6 board.
            """)

            TutorialHighlight(
                title: "Your Goal",
                text: "Complete a Victory Set by locking the required patterns before your opponent does!",
                icon: "flag.checkered"
            )

            TutorialText("""
            Each player starts with 12 stones. On your turn, you can:
            """)

            VStack(alignment: .leading, spacing: 12) {
                TutorialBullet(icon: "arrow.down.circle", text: "Drop a stone onto an empty space")
                TutorialBullet(icon: "arrow.left.and.right", text: "Shift a stone 1-2 spaces")
                TutorialBullet(icon: "lock.fill", text: "Lock a pattern you've formed")
                TutorialBullet(icon: "drop.fill", text: "Draw from your river (once per game)")
            }

            TutorialText("""
            The game requires careful planning, pattern recognition, and tactical awareness. Let's learn each mechanic!
            """)
        }
    }

    private var boardContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            TutorialText("""
            The game is played on a 6x6 grid. Columns are labeled a-f, rows are labeled 1-6.
            """)

            // Mini board preview
            MiniBoardPreview()
                .frame(height: 200)

            TutorialHighlight(
                title: "Two Players",
                text: "Light plays first, then players alternate turns. Light stones are white/cream, Dark stones are black/gray.",
                icon: "person.2.fill"
            )

            TutorialText("""
            Positions are referenced like chess notation: a1 is bottom-left, f6 is top-right.
            """)

            TutorialHighlight(
                title: "Starting Stones",
                text: "Each player begins with 12 stones in hand. Place them strategically to form patterns!",
                icon: "hand.raised.fill"
            )
        }
    }

    private var droppingContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            TutorialText("""
            Dropping is how you place new stones from your hand onto the board.
            """)

            // Animated drop demo
            DropDemoView()
                .frame(height: 180)

            TutorialHighlight(
                title: "How to Drop",
                text: "Tap any empty space on the board to drop a stone there. Simple!",
                icon: "hand.tap.fill"
            )

            VStack(alignment: .leading, spacing: 12) {
                TutorialBullet(icon: "checkmark.circle", text: "You must have stones in hand")
                TutorialBullet(icon: "checkmark.circle", text: "The target space must be empty")
                TutorialBullet(icon: "xmark.circle", text: "Cannot drop on occupied spaces")
            }

            TutorialText("""
            Plan your drops to build toward patterns and control key areas of the board!
            """)
        }
    }

    private var shiftingContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            TutorialText("""
            Shifting lets you move your unlocked stones on the board to new positions.
            """)

            // Shift demo
            ShiftDemoView()
                .frame(height: 180)

            TutorialHighlight(
                title: "Movement Rules",
                text: "Move 1 or 2 spaces in any orthogonal direction (up, down, left, right). No diagonal moves!",
                icon: "arrow.up.and.down.and.arrow.left.and.right"
            )

            VStack(alignment: .leading, spacing: 12) {
                TutorialBullet(icon: "1.circle", text: "Move 1 space in any direction")
                TutorialBullet(icon: "2.circle", text: "Move 2 spaces if path is clear")
                TutorialBullet(icon: "xmark.circle", text: "Cannot jump over other stones")
                TutorialBullet(icon: "lock.slash", text: "Cannot move locked stones")
            }

            TutorialHighlight(
                title: "Strike!",
                text: "Land on an opponent's UNLOCKED stone to capture it! The captured stone goes to their river.",
                icon: "bolt.fill"
            )
        }
    }

    private var capturingContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            TutorialText("""
            Surrounding is another way to capture opponent stones. When a stone has no empty neighbors, it's captured!
            """)

            // Capture demo
            CaptureDemoView()
                .frame(height: 200)

            TutorialHighlight(
                title: "Surrounding Rule",
                text: "A stone is captured when ALL 4 orthogonal neighbors are occupied (by any stone) or off the board.",
                icon: "circle.hexagongrid.fill"
            )

            VStack(alignment: .leading, spacing: 12) {
                TutorialBullet(icon: "exclamationmark.triangle", text: "Both locked AND unlocked stones can be captured by surrounding")
                TutorialBullet(icon: "arrow.down.to.line", text: "Edge and corner stones are easier to surround")
                TutorialBullet(icon: "drop.fill", text: "Captured stones go to the owner's river")
            }

            TutorialText("""
            Be careful placing stones near edges - they're vulnerable to surrounding!
            """)
        }
    }

    private var patternsContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            TutorialText("""
            Patterns are specific arrangements of your stones. Form patterns to lock them and progress toward victory!
            """)

            // Pattern showcase
            VStack(spacing: 16) {
                PatternShowcase(type: .line, name: "Line", description: "3+ stones in a row (horizontal or vertical)")
                PatternShowcase(type: .bend, name: "Bend", description: "L-shaped: 3 stones forming a corner")
                PatternShowcase(type: .gate, name: "Gate", description: "2x2 square of 4 stones")
                PatternShowcase(type: .cross, name: "Cross", description: "+ shape: 5 stones (center + 4 arms)")
            }

            TutorialHighlight(
                title: "Important!",
                text: "Patterns can only be locked if ALL stones in the pattern are unlocked. Plan ahead!",
                icon: "exclamationmark.circle"
            )
        }
    }

    private var lockingContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            TutorialText("""
            Locking a pattern protects it and counts toward your Victory Sets. This is how you win!
            """)

            // Lock demo
            LockDemoView()
                .frame(height: 180)

            TutorialHighlight(
                title: "How to Lock",
                text: "When you have a valid pattern, tap 'Lock' to secure it. Locked stones glow blue and cannot be moved!",
                icon: "lock.shield.fill"
            )

            VStack(alignment: .leading, spacing: 12) {
                TutorialBullet(icon: "shield.fill", text: "Locked stones cannot be moved")
                TutorialBullet(icon: "xmark.shield", text: "Locked stones cannot be struck (captured by landing on)")
                TutorialBullet(icon: "exclamationmark.triangle", text: "BUT locked stones CAN still be surrounded!")
            }

            TutorialText("""
            Locking uses your turn, so time it wisely. Lock patterns when they're safe from capture!
            """)
        }
    }

    private var victorySetsContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            TutorialText("""
            Complete a Victory Set to win the game! Each set requires specific locked patterns.
            """)

            VStack(spacing: 12) {
                VictorySetCard(
                    name: "Twin Rivers",
                    requirement: "2 Lines",
                    description: "Lock two non-overlapping lines",
                    isInstant: false
                )

                VictorySetCard(
                    name: "Gate & Path",
                    requirement: "1 Gate + 1 Line",
                    description: "Lock one gate and one line",
                    isInstant: false
                )

                VictorySetCard(
                    name: "Three Bends",
                    requirement: "3 Bends",
                    description: "Lock three non-overlapping bends",
                    isInstant: false
                )

                VictorySetCard(
                    name: "The Fortress",
                    requirement: "2 Gates",
                    description: "Lock two non-overlapping gates",
                    isInstant: false
                )

                VictorySetCard(
                    name: "The Long Road",
                    requirement: "5+ Line",
                    description: "Lock a line of 5 or more stones",
                    isInstant: true
                )

                VictorySetCard(
                    name: "The Star",
                    requirement: "1 Cross",
                    description: "Lock a cross pattern",
                    isInstant: true
                )
            }

            TutorialHighlight(
                title: "Elimination Win",
                text: "If your opponent has fewer than 2 total stones, you win automatically!",
                icon: "flame.fill"
            )
        }
    }

    private var riverContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            TutorialText("""
            The River is where your captured stones go. You can reclaim one stone from your river once per game!
            """)

            // River demo
            RiverDemoView()
                .frame(height: 160)

            TutorialHighlight(
                title: "Your Personal River",
                text: "Each player has their own river. When YOUR stone is captured, it goes to YOUR river.",
                icon: "person.crop.circle"
            )

            VStack(alignment: .leading, spacing: 12) {
                TutorialBullet(icon: "drop.fill", text: "Captured stones go to the owner's river")
                TutorialBullet(icon: "hand.raised.fill", text: "Draw once per game to get a stone back")
                TutorialBullet(icon: "arrow.uturn.backward", text: "The stone returns to your hand")
            }

            TutorialText("""
            Save your river draw for a crucial moment when you need that extra stone!
            """)
        }
    }

    private var breakingContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            TutorialText("""
            Breaking lets you disrupt an opponent's locked pattern by sacrificing your own locked stones.
            """)

            TutorialHighlight(
                title: "Break Cost",
                text: "Sacrifice 2 of your locked stones to unlock 1 of your opponent's locked stones.",
                icon: "hammer.fill"
            )

            VStack(alignment: .leading, spacing: 12) {
                TutorialBullet(icon: "2.circle", text: "You must sacrifice exactly 2 of YOUR locked stones")
                TutorialBullet(icon: "1.circle", text: "Choose 1 opponent locked stone to unlock")
                TutorialBullet(icon: "drop.fill", text: "Sacrificed stones go to YOUR river")
                TutorialBullet(icon: "exclamationmark.circle", text: "Can only be used once per game")
            }

            TutorialText("""
            Breaking is a desperate but powerful move. Use it to prevent an opponent from completing their victory set!
            """)
        }
    }

    private var strategyContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            TutorialText("""
            Here are some tips to improve your Rubicon game:
            """)

            StrategyTip(
                number: 1,
                title: "Control the Center",
                text: "Center stones have more options and are harder to surround than edge stones."
            )

            StrategyTip(
                number: 2,
                title: "Build Multiple Patterns",
                text: "Work on several patterns at once. If one gets blocked, you have backups."
            )

            StrategyTip(
                number: 3,
                title: "Watch Your Opponent",
                text: "Track which patterns they're building. Disrupt them before they lock!"
            )

            StrategyTip(
                number: 4,
                title: "Protect Before Locking",
                text: "Ensure your pattern stones aren't vulnerable to capture before locking."
            )

            StrategyTip(
                number: 5,
                title: "Save Your River",
                text: "Don't use your river draw early. Save it for a crucial moment."
            )

            StrategyTip(
                number: 6,
                title: "Instant Wins",
                text: "The Long Road and The Star are instant wins - always watch for these!"
            )

            TutorialHighlight(
                title: "Good Luck!",
                text: "You're ready to play Rubicon. May the best strategist win!",
                icon: "hand.thumbsup.fill"
            )
        }
    }
}

// MARK: - Tutorial Components

struct TutorialText: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(RubiconFonts.body(16))
            .foregroundColor(RubiconColors.textSecondary)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
    }
}

struct TutorialHighlight: View {
    let title: String
    let text: String
    let icon: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(RubiconColors.textAccent)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(RubiconFonts.body(16))
                    .fontWeight(.semibold)
                    .foregroundColor(RubiconColors.textPrimary)

                Text(text)
                    .font(RubiconFonts.body(14))
                    .foregroundColor(RubiconColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(RubiconColors.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(RubiconColors.textAccent.opacity(0.3), lineWidth: 1)
        )
    }
}

struct TutorialBullet: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(RubiconColors.textAccent)
                .frame(width: 20)

            Text(text)
                .font(RubiconFonts.body(14))
                .foregroundColor(RubiconColors.textSecondary)
        }
    }
}

struct PatternShowcase: View {
    let type: PatternType
    let name: String
    let description: String

    @StateObject private var themeManager = ThemeManager.shared

    var body: some View {
        HStack(spacing: 16) {
            // Pattern visual
            PatternMiniView(type: type)
                .frame(width: 70, height: 70)

            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(RubiconFonts.body(16))
                    .fontWeight(.semibold)
                    .foregroundColor(RubiconColors.textPrimary)

                Text(description)
                    .font(RubiconFonts.caption(13))
                    .foregroundColor(RubiconColors.textSecondary)
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(RubiconColors.cardBackground)
        )
    }
}

struct PatternMiniView: View {
    let type: PatternType
    @StateObject private var themeManager = ThemeManager.shared

    private var stonePositions: [(col: Int, row: Int)] {
        switch type {
        case .line:
            return [(0, 1), (1, 1), (2, 1)]
        case .bend:
            return [(0, 0), (0, 1), (1, 1)]
        case .gate:
            return [(0, 0), (1, 0), (0, 1), (1, 1)]
        case .cross:
            return [(1, 0), (0, 1), (1, 1), (2, 1), (1, 2)]
        }
    }

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let cellSize = size / 3
            let stoneSize = cellSize * 0.7

            ZStack {
                // Grid
                RoundedRectangle(cornerRadius: 6)
                    .fill(themeManager.boardTheme.background)

                // Stones - use index for unique ID since tuples can have same column
                ForEach(Array(stonePositions.enumerated()), id: \.offset) { index, pos in
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    themeManager.stoneTheme.lightStoneHighlight,
                                    themeManager.stoneTheme.lightStone,
                                    themeManager.stoneTheme.lightStoneShadow
                                ],
                                center: .topLeading,
                                startRadius: 0,
                                endRadius: stoneSize
                            )
                        )
                        .frame(width: stoneSize, height: stoneSize)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 1, y: 1)
                        .position(
                            x: CGFloat(pos.col) * cellSize + cellSize / 2,
                            y: CGFloat(pos.row) * cellSize + cellSize / 2
                        )
                }
            }
            .frame(width: size, height: size)
        }
    }
}

struct VictorySetCard: View {
    let name: String
    let requirement: String
    let description: String
    let isInstant: Bool

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(name)
                        .font(RubiconFonts.body(15))
                        .fontWeight(.semibold)
                        .foregroundColor(RubiconColors.textPrimary)

                    if isInstant {
                        Text("INSTANT")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(RubiconColors.victory))
                    }
                }

                Text(requirement)
                    .font(RubiconFonts.caption(13))
                    .foregroundColor(RubiconColors.textAccent)

                Text(description)
                    .font(RubiconFonts.caption(12))
                    .foregroundColor(RubiconColors.textSecondary)
            }

            Spacer()

            Image(systemName: isInstant ? "bolt.fill" : "checkmark.seal.fill")
                .font(.system(size: 24))
                .foregroundColor(isInstant ? RubiconColors.victory : RubiconColors.textSecondary.opacity(0.5))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(RubiconColors.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isInstant ? RubiconColors.victory.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
}

struct StrategyTip: View {
    let number: Int
    let title: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(Circle().fill(RubiconColors.textAccent))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(RubiconFonts.body(15))
                    .fontWeight(.semibold)
                    .foregroundColor(RubiconColors.textPrimary)

                Text(text)
                    .font(RubiconFonts.caption(13))
                    .foregroundColor(RubiconColors.textSecondary)
            }
        }
    }
}

// MARK: - Demo Views

struct MiniBoardPreview: View {
    @StateObject private var themeManager = ThemeManager.shared

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let cellSize = size / 6

            ZStack {
                // Board
                RoundedRectangle(cornerRadius: 8)
                    .fill(themeManager.boardTheme.background)

                // Grid lines
                ForEach(0..<7) { i in
                    // Vertical
                    Rectangle()
                        .fill(themeManager.boardTheme.gridLine)
                        .frame(width: 1, height: size)
                        .position(x: CGFloat(i) * cellSize, y: size / 2)

                    // Horizontal
                    Rectangle()
                        .fill(themeManager.boardTheme.gridLine)
                        .frame(width: size, height: 1)
                        .position(x: size / 2, y: CGFloat(i) * cellSize)
                }

                // Labels
                HStack {
                    ForEach(["a", "b", "c", "d", "e", "f"], id: \.self) { col in
                        Text(col)
                            .font(.system(size: 10))
                            .foregroundColor(RubiconColors.textSecondary)
                            .frame(maxWidth: .infinity)
                    }
                }
                .position(x: size / 2, y: size + 12)
            }
            .frame(width: size, height: size)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
    }
}

struct DropDemoView: View {
    @State private var showStone = false
    @StateObject private var themeManager = ThemeManager.shared

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                // Mini board
                RoundedRectangle(cornerRadius: 8)
                    .fill(themeManager.boardTheme.background)
                    .frame(width: 120, height: 120)

                // Target indicator
                if !showStone {
                    Circle()
                        .stroke(RubiconColors.validMove, lineWidth: 2)
                        .frame(width: 30, height: 30)
                }

                // Dropping stone
                if showStone {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    themeManager.stoneTheme.lightStoneHighlight,
                                    themeManager.stoneTheme.lightStone
                                ],
                                center: .topLeading,
                                startRadius: 0,
                                endRadius: 20
                            )
                        )
                        .frame(width: 30, height: 30)
                        .shadow(color: .black.opacity(0.3), radius: 3, x: 1, y: 2)
                        .transition(.scale.combined(with: .opacity))
                }
            }

            Button("Tap to Drop") {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    showStone.toggle()
                }
            }
            .font(RubiconFonts.caption(14))
            .foregroundColor(RubiconColors.textAccent)
        }
    }
}

struct ShiftDemoView: View {
    @State private var stonePosition: CGFloat = 0
    @StateObject private var themeManager = ThemeManager.shared

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                // Mini board
                RoundedRectangle(cornerRadius: 8)
                    .fill(themeManager.boardTheme.background)
                    .frame(width: 160, height: 80)

                // Arrow
                HStack(spacing: 4) {
                    ForEach(0..<3) { i in
                        Circle()
                            .fill(i == 0 ? Color.clear : RubiconColors.validMove.opacity(0.5))
                            .frame(width: 30, height: 30)
                    }
                }

                // Moving stone
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                themeManager.stoneTheme.lightStoneHighlight,
                                themeManager.stoneTheme.lightStone
                            ],
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: 20
                        )
                    )
                    .frame(width: 30, height: 30)
                    .shadow(color: .black.opacity(0.3), radius: 3, x: 1, y: 2)
                    .offset(x: stonePosition)
            }

            Button("Tap to Shift") {
                withAnimation(.easeInOut(duration: 0.4)) {
                    stonePosition = stonePosition == 0 ? 50 : 0
                }
            }
            .font(RubiconFonts.caption(14))
            .foregroundColor(RubiconColors.textAccent)
        }
    }
}

struct CaptureDemoView: View {
    @State private var showCapture = false
    @StateObject private var themeManager = ThemeManager.shared

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                // Mini board
                RoundedRectangle(cornerRadius: 8)
                    .fill(themeManager.boardTheme.background)
                    .frame(width: 140, height: 140)

                // Surrounding stones
                let offsets: [(CGFloat, CGFloat)] = [(0, -35), (0, 35), (-35, 0), (35, 0)]
                ForEach(0..<4, id: \.self) { i in
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    themeManager.stoneTheme.lightStoneHighlight,
                                    themeManager.stoneTheme.lightStone
                                ],
                                center: .topLeading,
                                startRadius: 0,
                                endRadius: 15
                            )
                        )
                        .frame(width: 28, height: 28)
                        .offset(x: offsets[i].0, y: offsets[i].1)
                }

                // Captured stone
                if !showCapture {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    themeManager.stoneTheme.darkStoneHighlight,
                                    themeManager.stoneTheme.darkStone
                                ],
                                center: .topLeading,
                                startRadius: 0,
                                endRadius: 15
                            )
                        )
                        .frame(width: 28, height: 28)
                        .overlay(
                            Circle()
                                .stroke(Color.red.opacity(0.6), lineWidth: 2)
                        )
                }
            }

            Button(showCapture ? "Reset" : "Capture!") {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showCapture.toggle()
                }
            }
            .font(RubiconFonts.caption(14))
            .foregroundColor(showCapture ? RubiconColors.textSecondary : Color.red)
        }
    }
}

struct LockDemoView: View {
    @State private var isLocked = false
    @StateObject private var themeManager = ThemeManager.shared

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                // Mini board
                RoundedRectangle(cornerRadius: 8)
                    .fill(themeManager.boardTheme.background)
                    .frame(width: 140, height: 80)

                // Line pattern
                HStack(spacing: 10) {
                    ForEach(0..<3, id: \.self) { _ in
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            themeManager.stoneTheme.lightStoneHighlight,
                                            themeManager.stoneTheme.lightStone
                                        ],
                                        center: .topLeading,
                                        startRadius: 0,
                                        endRadius: 15
                                    )
                                )
                                .frame(width: 30, height: 30)

                            if isLocked {
                                Circle()
                                    .stroke(themeManager.stoneTheme.lockedGlow, lineWidth: 2)
                                    .frame(width: 34, height: 34)

                                Image(systemName: "lock.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
            }

            Button(isLocked ? "Unlock" : "Lock Pattern") {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isLocked.toggle()
                }
            }
            .font(RubiconFonts.caption(14))
            .foregroundColor(isLocked ? themeManager.stoneTheme.lockedGlow : RubiconColors.textAccent)
        }
    }
}

struct RiverDemoView: View {
    @State private var stonesInRiver = 3
    @StateObject private var themeManager = ThemeManager.shared

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                // River
                VStack(spacing: 8) {
                    Text("Your River")
                        .font(RubiconFonts.caption(12))
                        .foregroundColor(RubiconColors.textSecondary)

                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(0.15))
                            .frame(width: 80, height: 60)

                        HStack(spacing: -8) {
                            ForEach(0..<stonesInRiver, id: \.self) { _ in
                                Circle()
                                    .fill(
                                        RadialGradient(
                                            colors: [
                                                themeManager.stoneTheme.lightStoneHighlight,
                                                themeManager.stoneTheme.lightStone
                                            ],
                                            center: .topLeading,
                                            startRadius: 0,
                                            endRadius: 12
                                        )
                                    )
                                    .frame(width: 24, height: 24)
                                    .shadow(color: .black.opacity(0.2), radius: 2)
                            }
                        }
                    }
                }

                Image(systemName: "arrow.right")
                    .foregroundColor(RubiconColors.textSecondary)

                // Hand
                VStack(spacing: 8) {
                    Text("Your Hand")
                        .font(RubiconFonts.caption(12))
                        .foregroundColor(RubiconColors.textSecondary)

                    Image(systemName: "hand.raised.fill")
                        .font(.system(size: 32))
                        .foregroundColor(RubiconColors.textSecondary.opacity(0.5))
                }
            }

            Button(stonesInRiver > 0 ? "Draw from River" : "Reset") {
                withAnimation {
                    if stonesInRiver > 0 {
                        stonesInRiver -= 1
                    } else {
                        stonesInRiver = 3
                    }
                }
            }
            .font(RubiconFonts.caption(14))
            .foregroundColor(Color.blue)
        }
    }
}

#Preview {
    HowToPlayView()
}
