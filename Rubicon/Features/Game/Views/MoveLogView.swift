import SwiftUI
import RubiconEngine
#if canImport(UIKit)
import UIKit
#endif

struct MoveLogView: View {
    let moves: [Move]
    let currentPlayer: Player

    @StateObject private var themeManager = ThemeManager.shared
    @State private var showCopiedFeedback = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Image(systemName: "list.bullet.rectangle")
                    .font(.system(size: 14))
                Text("Move History")
                    .font(RubiconFonts.caption(14))
                Spacer()

                // Copy button
                Button {
                    copyMovesToClipboard()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: showCopiedFeedback ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 11))
                        Text(showCopiedFeedback ? "Copied!" : "Copy")
                            .font(RubiconFonts.caption(11))
                    }
                    .foregroundColor(showCopiedFeedback ? .green : RubiconColors.textAccent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(showCopiedFeedback ? Color.green.opacity(0.15) : RubiconColors.textAccent.opacity(0.1))
                    )
                }
                .disabled(moves.isEmpty)
                .opacity(moves.isEmpty ? 0.5 : 1)

                Text("\(moves.count) moves")
                    .font(RubiconFonts.caption(12))
                    .foregroundColor(RubiconColors.textSecondary)
            }
            .foregroundColor(RubiconColors.textPrimary)
            .padding(.horizontal, 12)
            .padding(.top, 8)

            // Move list
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(Array(moves.enumerated()), id: \.element.id) { index, move in
                            MoveEntryView(
                                moveNumber: index + 1,
                                move: move,
                                isLatest: index == moves.count - 1
                            )
                            .id(move.id)
                        }

                        // Empty state
                        if moves.isEmpty {
                            Text("No moves yet")
                                .font(RubiconFonts.caption(12))
                                .foregroundColor(RubiconColors.textSecondary)
                                .padding(.horizontal, 12)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
                }
                .onChange(of: moves.count) {
                    // Auto-scroll to latest move
                    if let lastMove = moves.last {
                        withAnimation {
                            proxy.scrollTo(lastMove.id, anchor: .trailing)
                        }
                    }
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(RubiconColors.cardBackground.opacity(0.8))
        )
    }

    // MARK: - Copy Functions

    private func copyMovesToClipboard() {
        let formattedText = formatMovesForCopy()
        #if canImport(UIKit)
        UIPasteboard.general.string = formattedText
        #endif

        // Show feedback
        withAnimation {
            showCopiedFeedback = true
        }

        // Reset feedback after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showCopiedFeedback = false
            }
        }
    }

    private func formatMovesForCopy() -> String {
        var lines: [String] = []
        lines.append("Rubicon Game - Move History")
        lines.append("===========================")
        lines.append("")

        // Group moves by pairs (Light then Dark)
        var moveIndex = 0
        var turnNumber = 1

        while moveIndex < moves.count {
            var turnLine = "\(turnNumber). "

            // Light's move
            if moveIndex < moves.count {
                let lightMove = moves[moveIndex]
                if lightMove.player == .light {
                    turnLine += "Light: \(formatMoveForText(lightMove))"
                    moveIndex += 1
                } else {
                    turnLine += "Light: --"
                }
            }

            // Dark's move
            if moveIndex < moves.count {
                let darkMove = moves[moveIndex]
                if darkMove.player == .dark {
                    turnLine += "  |  Dark: \(formatMoveForText(darkMove))"
                    moveIndex += 1
                } else {
                    turnLine += "  |  Dark: --"
                }
            }

            lines.append(turnLine)
            turnNumber += 1
        }

        lines.append("")
        lines.append("Total: \(moves.count) moves")

        return lines.joined(separator: "\n")
    }

    private func formatMoveForText(_ move: Move) -> String {
        switch move.type {
        case .drop(let position):
            let captureText = !move.capturedPositions.isEmpty ? " (captured \(move.capturedPositions.count))" : ""
            return "Drop \(position.notation)\(captureText)"
        case .shift(let from, let to):
            let captureText = !move.capturedPositions.isEmpty ? " (captured \(move.capturedPositions.count))" : ""
            return "\(from.notation)-\(to.notation)\(captureText)"
        case .lock(_, let positions):
            return "Lock (\(positions.count) stones)"
        case .drawFromRiver:
            return "Draw from River"
        case .breakLock(let sacrifice, let target):
            return "Break at \(target.notation) (sacrificed \(sacrifice.count))"
        case .pass:
            return "Pass"
        }
    }
}

struct MoveEntryView: View {
    let moveNumber: Int
    let move: Move
    let isLatest: Bool

    @StateObject private var themeManager = ThemeManager.shared

    var body: some View {
        HStack(spacing: 6) {
            // Move number
            Text("\(moveNumber).")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(RubiconColors.textSecondary)

            // Player indicator
            Circle()
                .fill(
                    move.player == .light
                        ? themeManager.stoneTheme.lightStone
                        : themeManager.stoneTheme.darkStone
                )
                .frame(width: 12, height: 12)
                .overlay(
                    Circle()
                        .stroke(Color.black.opacity(0.2), lineWidth: 0.5)
                )

            // Move description
            Text(moveDescription)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(RubiconColors.textPrimary)

            // Capture indicator
            if !move.capturedPositions.isEmpty || !move.surroundedPositions.isEmpty {
                Image(systemName: "burst.fill")
                    .font(.system(size: 8))
                    .foregroundColor(.red)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isLatest ? RubiconColors.textAccent.opacity(0.15) : RubiconColors.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isLatest ? RubiconColors.textAccent.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }

    private var moveDescription: String {
        switch move.type {
        case .drop(let position):
            return "▼\(position.notation)"
        case .shift(let from, let to):
            let capture = !move.capturedPositions.isEmpty ? "×" : ""
            return "\(from.notation)→\(to.notation)\(capture)"
        case .lock(_, let positions):
            return "🔒\(positions.count)"
        case .drawFromRiver:
            return "💧River"
        case .breakLock(_, _):
            return "💥Break"
        case .pass:
            return "⏭Pass"
        }
    }
}

// Compact version for landscape or smaller displays
struct CompactMoveLogView: View {
    let moves: [Move]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Recent Moves")
                .font(RubiconFonts.caption(11))
                .foregroundColor(RubiconColors.textSecondary)

            // Show last 5 moves
            ForEach(Array(moves.suffix(5).enumerated()), id: \.element.id) { index, move in
                HStack(spacing: 4) {
                    Text("\(moves.count - 4 + index).")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(RubiconColors.textSecondary)

                    Circle()
                        .fill(move.player == .light ? Color.white : Color.black)
                        .frame(width: 8, height: 8)

                    Text(move.notation)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(RubiconColors.textPrimary)
                }
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(RubiconColors.cardBackground.opacity(0.6))
        )
    }
}

#Preview {
    VStack {
        MoveLogView(
            moves: [
                Move(player: .light, type: .drop(position: Position(column: 2, row: 2))),
                Move(player: .dark, type: .drop(position: Position(column: 3, row: 3))),
                Move(player: .light, type: .shift(from: Position(column: 2, row: 2), to: Position(column: 3, row: 2))),
                Move(player: .dark, type: .pass),
                Move(player: .light, type: .lock(patternID: UUID(), positions: [Position(column: 0, row: 0), Position(column: 1, row: 0), Position(column: 2, row: 0)]))
            ],
            currentPlayer: .dark
        )
    }
    .padding()
    .background(RubiconColors.menuBackground)
}
