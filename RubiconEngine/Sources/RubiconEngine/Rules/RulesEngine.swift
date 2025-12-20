import Foundation

public struct MoveResult: Sendable, Equatable {
    public let success: Bool
    public let newState: GameState
    public let captureResult: CaptureResult
    public let victoryResult: VictoryCheckResult
    public let lockedPattern: Pattern?
    public let errorMessage: String?

    public init(success: Bool, newState: GameState, captureResult: CaptureResult = CaptureResult(),
                victoryResult: VictoryCheckResult = .noWinner, lockedPattern: Pattern? = nil, errorMessage: String? = nil) {
        self.success = success
        self.newState = newState
        self.captureResult = captureResult
        self.victoryResult = victoryResult
        self.lockedPattern = lockedPattern
        self.errorMessage = errorMessage
    }

    public var isGameOver: Bool { victoryResult.hasWinner }
}

public struct RulesEngine: Sendable {
    public let moveValidator = MoveValidator()
    public let patternDetector = PatternDetector()
    public let captureResolver = CaptureResolver()
    public let victoryChecker = VictoryChecker()

    public init() {}

    public func executeMove(_ move: Move, on state: GameState) -> MoveResult {
        // Validate the move
        let validation = moveValidator.validate(move, state: state)
        guard validation.isValid else {
            return MoveResult(success: false, newState: state, errorMessage: validation.errorMessage)
        }

        var newState = state
        let previousBoard = state.board
        var captureResult = CaptureResult()
        var lockedPattern: Pattern? = nil

        // Execute based on move type
        switch move.type {
        case .drop(let position):
            newState.board.place(Stone(owner: move.player), at: position)
            newState.decrementStonesInHand(for: move.player)

        case .shift(let from, let to):
            // Check if this is a strike (capture) - only capture opponent stones!
            if let targetStone = newState.board.stone(at: to) {
                // Safety check: only capture opponent's stones, never your own
                if targetStone.owner != move.player {
                    newState.addToRiver(targetStone)
                }
            }
            newState.board.move(from: from, to: to)

        case .lock(let patternID, let positions):
            // Find the matching pattern
            let patterns = patternDetector.detectPatterns(on: newState.board, for: move.player, unlockedOnly: true)
            if let pattern = patterns.first(where: { $0.positions == positions }) {
                // Lock all stones in the pattern
                for pos in positions {
                    newState.board.lockStone(at: pos, patternID: pattern.id)
                }
                newState.addLockedPattern(pattern)
                lockedPattern = pattern
            }

        case .drawFromRiver:
            // River Reclamation (Third Edition): Take ALL stones from river at once
            // Players can reclaim unlimited times (as long as river has stones)
            // Each reclamation costs one turn but retrieves ALL captured stones
            _ = newState.reclaimAllFromRiver(for: move.player)

        case .breakLock(let sacrificePositions, let targetPosition):
            // Remove sacrificed stones (add to river) - only remove player's own stones!
            for pos in sacrificePositions {
                if let stone = newState.board.stone(at: pos) {
                    // Safety check: only sacrifice your own locked stones
                    if stone.owner == move.player && stone.isLocked {
                        newState.addToRiver(stone)
                        newState.board.remove(at: pos)
                    }
                }
            }
            // Find the pattern that contains the target stone
            // and unlock ALL stones in that pattern, not just the target
            for pattern in newState.lockedPatterns {
                if pattern.positions.contains(targetPosition) {
                    // Unlock ALL stones in the broken pattern
                    for pos in pattern.positions {
                        newState.board.unlockStone(at: pos)
                    }
                    // Set lock cooldown: opponent can't re-lock these positions next turn
                    newState.setLockCooldown(positions: pattern.positions, for: move.player.opponent)
                    // Remove the pattern from locked patterns
                    newState.removeLockedPattern(id: pattern.id)
                    break
                }
            }
            newState.markBreakUsed(for: move.player)

        case .pass:
            newState.incrementPassCount(for: move.player)
        }

        // Check for surrounding captures (only after shifts, NOT drops)
        // Drops just place stones - they cannot capture
        // Shifts can capture via "strike" (landing on opponent) which is handled above,
        // AND can cause surrounding captures if the shift completes a surround
        if case .shift = move.type {
            captureResult = captureResolver.resolveCaptures(after: move, on: newState.board, previousBoard: previousBoard)
            for pos in captureResult.capturedPositions {
                if let stone = newState.board.stone(at: pos) {
                    // Safety check: only capture opponent stones, never your own
                    guard stone.owner != move.player else { continue }

                    // If this stone was part of a locked pattern, invalidate that pattern
                    if stone.isLocked, let patternID = stone.lockedInPatternID {
                        invalidatePattern(id: patternID, state: &newState)
                    }
                    newState.addToRiver(stone)
                    newState.board.remove(at: pos)
                }
            }
        }

        // Record the move with capture info
        var recordedMove = move
        recordedMove.capturedPositions = captureResult.capturedPositions
        recordedMove.surroundedPositions = captureResult.surroundedPositions
        newState.addMove(recordedMove)

        // Check victory conditions
        let victoryResult = victoryChecker.checkVictory(state: newState)
        if victoryResult.hasWinner {
            newState.setWinner(victoryResult.winner!, victorySet: victoryResult.victorySet, byElimination: victoryResult.isElimination)
        }

        // Advance turn (unless game is over)
        if !newState.isGameOver {
            newState.advanceTurn()
        }

        return MoveResult(
            success: true,
            newState: newState,
            captureResult: captureResult,
            victoryResult: victoryResult,
            lockedPattern: lockedPattern
        )
    }

    /// Get all valid moves for the current player
    public func validMoves(for state: GameState) -> [Move] {
        moveValidator.validMoves(for: state.currentPlayer, state: state)
    }

    /// Get all lockable patterns for a player
    public func lockablePatterns(for player: Player, on state: GameState) -> [Pattern] {
        patternDetector.detectPatterns(on: state.board, for: player, unlockedOnly: true)
    }

    /// Check if a specific pattern can be locked
    public func canLockPattern(_ pattern: Pattern, state: GameState) -> Bool {
        guard pattern.owner == state.currentPlayer else { return false }
        return patternDetector.isValidPattern(
            positions: pattern.positions,
            type: pattern.type,
            owner: pattern.owner,
            on: state.board,
            unlockedOnly: true
        )
    }

    /// Get stones that could be captured if player places at position
    public func potentialCaptures(at position: Position, for player: Player, state: GameState) -> [Position] {
        var testBoard = state.board
        testBoard.place(Stone(owner: player), at: position)

        var captures: [Position] = []
        for neighbor in position.orthogonalNeighbors where neighbor.isValid {
            if let stone = state.board.stone(at: neighbor), stone.owner == player.opponent {
                if captureResolver.isSurrounded(at: neighbor, on: testBoard) {
                    captures.append(neighbor)
                }
            }
        }
        return captures
    }

    /// Simulate a move and return the resulting state without modifying the original
    public func simulateMove(_ move: Move, on state: GameState) -> MoveResult {
        executeMove(move, on: state)
    }

    /// Invalidate a locked pattern - unlock all stones in it and remove from locked patterns
    private func invalidatePattern(id patternID: UUID, state: inout GameState) {
        // Find the pattern
        guard let pattern = state.lockedPatterns.first(where: { $0.id == patternID }) else { return }

        // Unlock all stones that are still on the board
        for pos in pattern.positions {
            if state.board.stone(at: pos) != nil {
                state.board.unlockStone(at: pos)
            }
        }

        // Remove the pattern from locked patterns
        state.removeLockedPattern(id: patternID)
    }
}
