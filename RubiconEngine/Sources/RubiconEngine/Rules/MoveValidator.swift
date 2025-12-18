import Foundation

public enum MoveValidationResult: Equatable, Sendable {
    case valid
    case invalid(reason: String)

    public var isValid: Bool { if case .valid = self { return true }; return false }
    public var errorMessage: String? { if case .invalid(let r) = self { return r }; return nil }
}

public struct MoveValidator: Sendable {
    private let patternDetector = PatternDetector()

    public init() {}

    public func validate(_ move: Move, state: GameState) -> MoveValidationResult {
        if state.isGameOver { return .invalid(reason: "Game is over") }
        if move.player != state.currentPlayer { return .invalid(reason: "Not your turn") }

        switch move.type {
        case .drop(let pos): return validateDrop(at: pos, state: state)
        case .shift(let from, let to): return validateShift(from: from, to: to, player: move.player, state: state)
        case .lock(_, let positions): return validateLock(positions: positions, player: move.player, state: state)
        case .drawFromRiver: return validateDrawFromRiver(player: move.player, state: state)
        case .breakLock(let sacrifice, let target): return validateBreak(sacrifice: sacrifice, target: target, player: move.player, state: state)
        case .pass: return validatePass(player: move.player, state: state)
        }
    }

    public func validateDrop(at pos: Position, state: GameState) -> MoveValidationResult {
        guard pos.isValid else { return .invalid(reason: "Invalid position") }
        guard state.board.isEmpty(at: pos) else { return .invalid(reason: "Position occupied") }
        guard state.currentPlayerStonesInHand > 0 else { return .invalid(reason: "No stones in hand") }
        return .valid
    }

    public func validateShift(from: Position, to: Position, player: Player, state: GameState) -> MoveValidationResult {
        guard from.isValid, to.isValid else { return .invalid(reason: "Invalid position") }
        guard let stone = state.board.stone(at: from), stone.owner == player else { return .invalid(reason: "No stone to move") }
        guard !stone.isLocked else { return .invalid(reason: "Cannot move locked stone") }

        let colDiff = abs(to.column - from.column)
        let rowDiff = abs(to.row - from.row)
        guard (colDiff == 0) != (rowDiff == 0) else { return .invalid(reason: "Must move orthogonally") }

        let distance = colDiff + rowDiff
        guard distance >= 1, distance <= 2 else { return .invalid(reason: "Must move 1-2 squares") }

        if distance == 2 {
            let mid = Position(column: (from.column + to.column) / 2, row: (from.row + to.row) / 2)
            if state.board.isOccupied(at: mid) { return .invalid(reason: "Cannot jump over stones") }
        }

        if let target = state.board.stone(at: to) {
            if target.owner == player { return .invalid(reason: "Cannot capture own stone") }
            if target.isLocked { return .invalid(reason: "Cannot strike locked stone") }
        }
        return .valid
    }

    public func validateLock(positions: Set<Position>, player: Player, state: GameState) -> MoveValidationResult {
        guard positions.count >= 3 else { return .invalid(reason: "Need at least 3 stones") }

        // Check if any positions are on cooldown (recently broken by opponent)
        if state.lockCooldownPlayer == player && !state.lockCooldownPositions.isDisjoint(with: positions) {
            return .invalid(reason: "Cannot re-lock broken pattern this turn")
        }

        for pos in positions {
            guard let stone = state.board.stone(at: pos), stone.owner == player, !stone.isLocked else {
                return .invalid(reason: "Invalid stone for pattern")
            }
        }
        return .valid
    }

    public func validateDrawFromRiver(player: Player, state: GameState) -> MoveValidationResult {
        // Players can draw from river unlimited times (as long as river has stones)
        guard !state.river(for: player).isEmpty else { return .invalid(reason: "Your river is empty") }
        return .valid
    }

    public func validatePass(player: Player, state: GameState) -> MoveValidationResult {
        // Players can only pass 3 times per game
        guard state.canPass(player: player) else {
            return .invalid(reason: "No passes remaining (max \(GameState.maxPassesPerPlayer) per game)")
        }
        return .valid
    }

    public func validateBreak(sacrifice: [Position], target: Position, player: Player, state: GameState) -> MoveValidationResult {
        guard state.canUseBreak(player: player) else { return .invalid(reason: "Cannot use Break") }
        guard sacrifice.count == 2 else { return .invalid(reason: "Must sacrifice exactly 2 stones") }

        for pos in sacrifice {
            guard let stone = state.board.stone(at: pos), stone.owner == player, stone.isLocked else {
                return .invalid(reason: "Invalid sacrifice stone")
            }
        }

        guard let targetStone = state.board.stone(at: target), targetStone.owner == player.opponent, targetStone.isLocked else {
            return .invalid(reason: "Invalid target")
        }
        return .valid
    }

    public func validMoves(for player: Player, state: GameState) -> [Move] {
        guard !state.isGameOver, state.currentPlayer == player else { return [] }
        var moves: [Move] = []

        // Drop moves (placing stones from hand)
        let stonesInHand = player == .light ? state.lightStonesInHand : state.darkStonesInHand
        if stonesInHand > 0 {
            for pos in state.board.allEmptyPositions() {
                moves.append(Move(player: player, type: .drop(position: pos)))
            }
        }

        // Shift moves (moving stones on board)
        for from in state.board.allPositions(for: player) {
            if let stone = state.board.stone(at: from), !stone.isLocked {
                for to in shiftDestinations(from: from, player: player, state: state) {
                    moves.append(Move(player: player, type: .shift(from: from, to: to)))
                }
            }
        }

        // Lock moves (locking patterns)
        let availablePatterns = patternDetector.detectPatterns(on: state.board, for: player, unlockedOnly: true)
        for pattern in availablePatterns {
            moves.append(Move(player: player, type: .lock(patternID: pattern.id, positions: pattern.positions)))
        }

        // Draw from river
        if state.canDrawFromRiver(player: player) {
            moves.append(Move(player: player, type: .drawFromRiver))
        }

        // Break moves (if available)
        if state.canUseBreak(player: player) {
            let lockedOwnStones = state.board.allPositions(for: player).filter { pos in
                state.board.stone(at: pos)?.isLocked == true
            }
            let lockedOpponentStones = state.board.allPositions(for: player.opponent).filter { pos in
                state.board.stone(at: pos)?.isLocked == true
            }

            if lockedOwnStones.count >= 2 && !lockedOpponentStones.isEmpty {
                // Generate a few break move options (not all combinations to avoid explosion)
                for i in 0..<min(lockedOwnStones.count, 3) {
                    for j in (i+1)..<min(lockedOwnStones.count, 4) {
                        for target in lockedOpponentStones.prefix(2) {
                            moves.append(Move(player: player, type: .breakLock(
                                sacrificePositions: [lockedOwnStones[i], lockedOwnStones[j]],
                                targetPosition: target
                            )))
                        }
                    }
                }
            }
        }

        // Pass only if no other moves available AND player has passes remaining
        if moves.isEmpty && state.canPass(player: player) {
            moves.append(Move(player: player, type: .pass))
        }

        return moves
    }

    private func shiftDestinations(from: Position, player: Player, state: GameState) -> [Position] {
        var destinations: [Position] = []
        for dir in [(0,1), (0,-1), (1,0), (-1,0)] {
            let pos1 = Position(column: from.column + dir.0, row: from.row + dir.1)
            if pos1.isValid {
                if state.board.isEmpty(at: pos1) {
                    destinations.append(pos1)
                    let pos2 = Position(column: from.column + dir.0 * 2, row: from.row + dir.1 * 2)
                    if pos2.isValid {
                        if state.board.isEmpty(at: pos2) { destinations.append(pos2) }
                        else if let t = state.board.stone(at: pos2), t.owner != player, !t.isLocked { destinations.append(pos2) }
                    }
                } else if let t = state.board.stone(at: pos1), t.owner != player, !t.isLocked {
                    destinations.append(pos1)
                }
            }
        }
        return destinations
    }
}
