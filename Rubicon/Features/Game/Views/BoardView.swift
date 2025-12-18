import SwiftUI
import RubiconEngine

struct BoardView: View {
    let board: Board
    let selectedPosition: Position?
    let validDestinations: [Position]
    var breakModeSelections: [Position] = []
    var breakModeTargets: [Position] = []
    let onCellTap: (Position) -> Void

    @StateObject private var themeManager = ThemeManager.shared

    private let columns = ["a", "b", "c", "d", "e", "f"]
    private let rows = ["1", "2", "3", "4", "5", "6"]

    private var boardTheme: BoardTheme { themeManager.boardTheme }

    var body: some View {
        GeometryReader { geometry in
            let availableSize = max(1, min(geometry.size.width, geometry.size.height))
            let boardSize = max(1, availableSize - (RubiconDimensions.boardPadding * 2))
            let cellSize = max(1, boardSize / 6)

            if geometry.size.width > 0 && geometry.size.height > 0 {
                ZStack {
                    // Board background with wood texture
                    boardBackground(size: availableSize)

                    VStack(spacing: 0) {
                        // Column labels (top)
                        HStack(spacing: 0) {
                            Spacer()
                                .frame(width: RubiconDimensions.boardPadding)

                            ForEach(columns, id: \.self) { col in
                                Text(col)
                                    .font(RubiconFonts.notation(12))
                                    .foregroundColor(RubiconColors.textSecondary)
                                    .frame(width: cellSize)
                            }

                            Spacer()
                                .frame(width: RubiconDimensions.boardPadding)
                        }
                        .frame(height: RubiconDimensions.boardPadding * 0.8)

                        // Main board with row labels
                        HStack(spacing: 0) {
                            // Row labels (left)
                            VStack(spacing: 0) {
                                ForEach(rows.reversed(), id: \.self) { row in
                                    Text(row)
                                        .font(RubiconFonts.notation(12))
                                        .foregroundColor(RubiconColors.textSecondary)
                                        .frame(width: RubiconDimensions.boardPadding, height: cellSize)
                                }
                            }

                            // The board grid
                            boardGrid(cellSize: cellSize, boardSize: boardSize)

                            // Row labels (right)
                            VStack(spacing: 0) {
                                ForEach(rows.reversed(), id: \.self) { row in
                                    Text(row)
                                        .font(RubiconFonts.notation(12))
                                        .foregroundColor(RubiconColors.textSecondary)
                                        .frame(width: RubiconDimensions.boardPadding, height: cellSize)
                                }
                            }
                        }

                        // Column labels (bottom)
                        HStack(spacing: 0) {
                            Spacer()
                                .frame(width: RubiconDimensions.boardPadding)

                            ForEach(columns, id: \.self) { col in
                                Text(col)
                                    .font(RubiconFonts.notation(12))
                                    .foregroundColor(RubiconColors.textSecondary)
                                    .frame(width: cellSize)
                            }

                            Spacer()
                                .frame(width: RubiconDimensions.boardPadding)
                        }
                        .frame(height: RubiconDimensions.boardPadding * 0.8)
                    }
                    .frame(width: availableSize, height: availableSize)
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    @ViewBuilder
    private func boardBackground(size: CGFloat) -> some View {
        let safeSize = max(1, size)
        ZStack {
            // Wood background
            RoundedRectangle(cornerRadius: 16)
                .fill(boardTheme.background)

            // Wood grain texture simulation
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            boardTheme.lightSquare.opacity(0.4),
                            boardTheme.background,
                            boardTheme.darkSquare.opacity(0.4),
                            boardTheme.background,
                            boardTheme.lightSquare.opacity(0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Subtle diagonal grain lines
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: boardTheme.darkSquare.opacity(0.1), location: 0),
                            .init(color: .clear, location: 0.2),
                            .init(color: boardTheme.lightSquare.opacity(0.08), location: 0.4),
                            .init(color: .clear, location: 0.6),
                            .init(color: boardTheme.darkSquare.opacity(0.1), location: 0.8),
                            .init(color: .clear, location: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            // Border
            RoundedRectangle(cornerRadius: 16)
                .stroke(boardTheme.border, lineWidth: 4)
        }
        .frame(width: safeSize, height: safeSize)
        .shadow(color: .black.opacity(0.4), radius: 12, x: 0, y: 6)
    }

    @ViewBuilder
    private func boardGrid(cellSize: CGFloat, boardSize: CGFloat) -> some View {
        let safeCellSize = max(1, cellSize)
        let safeBoardSize = max(1, boardSize)

        ZStack {
            // Grid lines
            gridLines(cellSize: safeCellSize, boardSize: safeBoardSize)

            // Cells and stones
            VStack(spacing: 0) {
                ForEach((0..<6).reversed(), id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<6, id: \.self) { col in
                            let position = Position(column: col, row: row)
                            cellView(for: position, size: safeCellSize)
                        }
                    }
                }
            }
        }
        .frame(width: safeBoardSize, height: safeBoardSize)
    }

    @ViewBuilder
    private func gridLines(cellSize: CGFloat, boardSize: CGFloat) -> some View {
        let safeCellSize = max(1, cellSize)
        let safeBoardSize = max(1, boardSize)

        Canvas { context, size in
            let lineColor = boardTheme.gridLine

            // Vertical lines
            for i in 0...6 {
                let x = CGFloat(i) * safeCellSize
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: safeBoardSize))
                context.stroke(path, with: .color(lineColor), lineWidth: RubiconDimensions.gridLineWidth)
            }

            // Horizontal lines
            for i in 0...6 {
                let y = CGFloat(i) * safeCellSize
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: safeBoardSize, y: y))
                context.stroke(path, with: .color(lineColor), lineWidth: RubiconDimensions.gridLineWidth)
            }
        }
        .frame(width: safeBoardSize, height: safeBoardSize)
    }

    @ViewBuilder
    private func cellView(for position: Position, size: CGFloat) -> some View {
        let safeSize = max(1, size)
        let isSelected = position == selectedPosition
        let isValidDestination = validDestinations.contains(position)
        let isBreakSelection = breakModeSelections.contains(position)
        let isBreakTarget = breakModeTargets.contains(position)
        let stone = board.stone(at: position)

        ZStack {
            // Break mode sacrifice selection highlight (orange/red)
            if isBreakSelection {
                Circle()
                    .stroke(Color(red: 0.9, green: 0.4, blue: 0.3), lineWidth: 3)
                    .frame(width: safeSize * 0.9, height: safeSize * 0.9)

                Circle()
                    .fill(Color(red: 0.9, green: 0.4, blue: 0.3).opacity(0.2))
                    .frame(width: safeSize * 0.9, height: safeSize * 0.9)
            }

            // Break mode target highlight (pulsing red border on opponent locked stones)
            if isBreakTarget {
                Circle()
                    .stroke(Color.red.opacity(0.8), lineWidth: 2)
                    .frame(width: safeSize * 0.88, height: safeSize * 0.88)
            }

            // Valid destination highlight
            if isValidDestination {
                if stone != nil {
                    // Capture target
                    Circle()
                        .fill(RubiconColors.captureTarget)
                        .frame(width: safeSize * 0.85, height: safeSize * 0.85)
                } else {
                    // Empty valid destination
                    Circle()
                        .fill(RubiconColors.validMove)
                        .frame(width: safeSize * 0.35, height: safeSize * 0.35)
                }
            }

            // Stone
            if let stone = stone {
                StoneView(
                    stone: stone,
                    isSelected: isSelected,
                    size: safeSize * 0.82
                )
            }
        }
        .frame(width: safeSize, height: safeSize)
        .contentShape(Rectangle())
        .onTapGesture {
            onCellTap(position)
        }
    }
}

// MARK: - Preview

#Preview {
    let board = Board()
    BoardView(
        board: board,
        selectedPosition: nil,
        validDestinations: [],
        onCellTap: { _ in }
    )
    .frame(width: 350, height: 350)
    .background(RubiconColors.menuBackground)
}
