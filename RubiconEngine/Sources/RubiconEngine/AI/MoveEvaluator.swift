import Foundation

public struct MoveEvaluator: Sendable {
    public let patternDetector = PatternDetector()
    private let victoryChecker = VictoryChecker()

    public init() {}

    /// Evaluate a game state from a player's perspective
    /// Returns a score where positive favors the player and negative favors opponent
    public func evaluate(state: GameState, for player: Player) -> Double {
        // Check for terminal states first
        if state.isGameOver {
            if state.winner == player {
                return 100000.0  // Winning is extremely valuable
            } else if state.winner == player.opponent {
                return -100000.0  // Losing is extremely bad
            }
        }

        var score = 0.0

        // Material advantage (stones on board + in hand)
        let myTotal = state.totalStones(for: player)
        let oppTotal = state.totalStones(for: player.opponent)
        score += Double(myTotal - oppTotal) * 50.0

        // Board presence (stones on board - more important than hand)
        let myBoardStones = state.board.stoneCount(for: player)
        let oppBoardStones = state.board.stoneCount(for: player.opponent)
        score += Double(myBoardStones - oppBoardStones) * 40.0

        // Locked patterns value (VERY important)
        let myLockedPatterns = state.lockedPatterns(for: player)
        let oppLockedPatterns = state.lockedPatterns(for: player.opponent)
        score += evaluateLockedPatterns(myLockedPatterns) - evaluateLockedPatterns(oppLockedPatterns)

        // Pattern potential (unlocked patterns that could be locked)
        let myPatterns = patternDetector.detectPatterns(on: state.board, for: player, unlockedOnly: true)
        let oppPatterns = patternDetector.detectPatterns(on: state.board, for: player.opponent, unlockedOnly: true)
        score += Double(myPatterns.count) * 30.0 - Double(oppPatterns.count) * 30.0

        // Victory progress - how close to winning
        let myProgress = victoryChecker.victoryProgress(for: player, state: state)
        let oppProgress = victoryChecker.victoryProgress(for: player.opponent, state: state)
        score += evaluateVictoryProgress(myProgress) - evaluateVictoryProgress(oppProgress)

        // Near-win detection - huge bonus for being one pattern away
        score += evaluateNearWinBonus(lockedPatterns: myLockedPatterns, for: player)
        score -= evaluateNearWinBonus(lockedPatterns: oppLockedPatterns, for: player.opponent)

        // Center control bonus
        score += evaluateCenterControl(state: state, for: player)

        // Connectivity bonus (stones adjacent to friendly stones)
        score += evaluateConnectivity(state: state, for: player)

        // River resources (having stones in river is a backup supply)
        let myRiverCount = state.river(for: player).count
        let oppRiverCount = state.river(for: player.opponent).count
        // Slight bonus for having more stones in river than opponent (recovery potential)
        score += Double(myRiverCount - oppRiverCount) * 5.0

        return score
    }

    private func evaluateLockedPatterns(_ patterns: [Pattern]) -> Double {
        var score = 0.0
        for pattern in patterns {
            switch pattern.type {
            case .line:
                let lineLength = pattern.positions.count
                score += Double(lineLength) * 120.0
                if lineLength >= 5 {
                    score += 5000.0 // Instant win (The Long Road)
                } else if lineLength == 4 {
                    score += 300.0 // Very close to instant win
                }
            case .bend:
                score += 100.0
            case .gate:
                score += 200.0  // Gates are valuable for multiple victory sets
            case .cross:
                score += 10000.0 // Instant win (The Star)
            case .pod:
                score += 80.0  // Minor pattern
            case .hook:
                score += 150.0  // Hooks are valuable for The Pincer victory
            }
        }
        return score
    }

    private func evaluateNearWinBonus(lockedPatterns: [Pattern], for player: Player) -> Double {
        var bonus = 0.0

        let lines = lockedPatterns.filter { $0.type == .line }
        let bends = lockedPatterns.filter { $0.type == .bend }
        let gates = lockedPatterns.filter { $0.type == .gate }
        let hooks = lockedPatterns.filter { $0.type == .hook }
        let crosses = lockedPatterns.filter { $0.type == .cross }

        // One line away from Twin Rivers
        if lines.count == 1 {
            bonus += 150.0
        }

        // One pattern away from Gate & Path
        if (gates.count == 1 && lines.isEmpty) || (gates.isEmpty && lines.count == 1) {
            bonus += 100.0
        }
        if gates.count >= 1 && lines.count >= 1 {
            bonus += 500.0 // Very close to Gate & Path
        }

        // Two bends toward Three Bends
        if bends.count == 2 {
            bonus += 200.0
        }

        // One gate away from Fortress
        if gates.count == 1 {
            bonus += 150.0
        }

        // NEW VICTORY SET BONUSES (Third Edition)

        // One hook away from The Pincer
        if hooks.count == 1 {
            bonus += 120.0
        }

        // The Phalanx progress (Gate + Cross)
        if gates.count >= 1 && crosses.count >= 1 {
            bonus += 600.0 // Very close to The Phalanx
        }

        // The Serpent progress (2 Bends + Line)
        if bends.count >= 2 && lines.count >= 1 {
            bonus += 400.0 // Very close to The Serpent
        } else if bends.count >= 2 {
            bonus += 150.0 // Two bends, need line
        }

        // Two gates toward The Constellation (3 Gates)
        if gates.count == 2 {
            bonus += 250.0
        }

        return bonus
    }

    private func evaluateVictoryProgress(_ progress: [VictorySetType: Double]) -> Double {
        var score = 0.0
        for (victoryType, progressValue) in progress {
            let multiplier: Double
            switch victoryType {
            case .theLongRoad, .theStar:
                multiplier = 300.0 // Instant wins are worth more
            case .theFortress:
                multiplier = 200.0
            case .gateAndPath:
                multiplier = 180.0
            case .twinRivers:
                multiplier = 150.0
            case .threeBends:
                multiplier = 140.0
            case .thePhalanx:
                multiplier = 250.0 // Gate + Cross is powerful
            case .thePincer:
                multiplier = 160.0
            case .theSerpent:
                multiplier = 155.0
            case .theConstellation:
                multiplier = 180.0 // 3 Gates - very defensive
            }
            score += progressValue * multiplier
        }
        return score
    }

    private func evaluateCenterControl(state: GameState, for player: Player) -> Double {
        var score = 0.0
        let centerPositions = [
            Position(column: 2, row: 2), Position(column: 2, row: 3),
            Position(column: 3, row: 2), Position(column: 3, row: 3)
        ]

        for pos in centerPositions {
            if let stone = state.board.stone(at: pos) {
                if stone.owner == player {
                    score += 20.0
                    if stone.isLocked {
                        score += 10.0  // Locked center stones are extra valuable
                    }
                } else {
                    score -= 20.0
                }
            }
        }

        return score
    }

    private func evaluateConnectivity(state: GameState, for player: Player) -> Double {
        var score = 0.0

        for position in state.board.allPositions(for: player) {
            var connectedCount = 0
            for neighbor in position.orthogonalNeighbors where neighbor.isValid {
                if let stone = state.board.stone(at: neighbor), stone.owner == player {
                    connectedCount += 1
                }
            }
            score += Double(connectedCount) * 8.0
        }

        return score
    }

    /// Evaluate a specific move's immediate tactical value
    public func evaluateMove(_ move: Move, state: GameState, for player: Player) -> Double {
        var score = 0.0

        switch move.type {
        case .drop(let position):
            // Bonus for center drops
            if position.column >= 2 && position.column <= 3 && position.row >= 2 && position.row <= 3 {
                score += 15.0
            }
            // Check if this creates pattern opportunities
            var testBoard = state.board
            testBoard.place(Stone(owner: player), at: position)
            let newPatterns = patternDetector.detectPatterns(on: testBoard, for: player, unlockedOnly: true)
            score += Double(newPatterns.count) * 25.0

            // Extra bonus if it creates a lockable pattern immediately
            if !newPatterns.isEmpty {
                score += 50.0
            }

        case .shift(_, let to):
            // Check if this is a capture (strike)
            if let target = state.board.stone(at: to), target.owner == player.opponent {
                score += 150.0 // Capture is very valuable
                if target.isLocked {
                    score += 100.0 // Can't actually capture locked, but this shouldn't happen
                }
            }
            // Bonus for center moves
            if to.column >= 2 && to.column <= 3 && to.row >= 2 && to.row <= 3 {
                score += 12.0
            }

        case .lock(_, let positions):
            // Locking is extremely valuable
            let patternSize = positions.count
            score += Double(patternSize) * 80.0

            // Check if this lock wins the game
            var testState = state
            for pos in positions {
                testState.board.lockStone(at: pos, patternID: UUID())
            }
            // Simulate the pattern type
            if patternSize >= 5 {
                score += 5000.0 // Likely The Long Road
            } else if patternSize == 5 && isLikelyCross(positions: positions) {
                score += 10000.0 // Likely The Star
            } else if patternSize == 4 && isLikelyGate(positions: positions) {
                score += 300.0 // Gate
            } else if patternSize == 3 {
                score += 150.0 // Line or Bend
            }

        case .drawFromRiver:
            // Drawing is valuable when low on stones
            let stonesInHand = player == .light ? state.lightStonesInHand : state.darkStonesInHand
            if stonesInHand < 4 {
                score += 80.0
            } else if stonesInHand < 8 {
                score += 50.0
            } else {
                score += 30.0
            }

        case .breakLock(_, _):
            // Breaking is very tactical - disrupts opponent
            score += 120.0

        case .pass:
            score -= 100.0 // Passing is very bad
        }

        return score
    }

    private func isLikelyCross(positions: Set<Position>) -> Bool {
        // A cross has exactly 5 positions in a + shape
        guard positions.count == 5 else { return false }
        let sortedPositions = positions.sorted { ($0.column, $0.row) < ($1.column, $1.row) }
        // Check if there's a center with 4 orthogonal neighbors
        for pos in sortedPositions {
            let neighbors = pos.orthogonalNeighbors.filter { positions.contains($0) }
            if neighbors.count == 4 {
                return true
            }
        }
        return false
    }

    private func isLikelyGate(positions: Set<Position>) -> Bool {
        // A gate is a 2x2 square
        guard positions.count == 4 else { return false }
        let cols = positions.map { $0.column }
        let rows = positions.map { $0.row }
        let colRange = (cols.max()! - cols.min()!)
        let rowRange = (rows.max()! - rows.min()!)
        return colRange == 1 && rowRange == 1
    }

    /// Detect opponent patterns that are threats (unlocked patterns they could lock)
    public func detectOpponentThreats(state: GameState, opponent: Player) -> [Pattern] {
        // Find unlocked patterns the opponent has formed
        let opponentPatterns = patternDetector.detectPatterns(on: state.board, for: opponent, unlockedOnly: true)

        // Also check their locked patterns to see how close they are to victory
        let lockedPatterns = state.lockedPatterns(for: opponent)
        let lockedLines = lockedPatterns.filter { $0.type == .line }
        let lockedBends = lockedPatterns.filter { $0.type == .bend }
        let lockedGates = lockedPatterns.filter { $0.type == .gate }

        var threats: [Pattern] = []

        for pattern in opponentPatterns {
            var isThreat = false

            switch pattern.type {
            case .cross:
                // Cross is always a threat (instant win)
                isThreat = true
            case .line:
                // Long lines (4+) are major threats
                if pattern.positions.count >= 4 {
                    isThreat = true
                }
                // If they already have a line, another line completes Twin Rivers
                if lockedLines.count >= 1 {
                    isThreat = true
                }
                // If they have a gate, line completes Gate & Path
                if lockedGates.count >= 1 {
                    isThreat = true
                }
            case .gate:
                // If they have a line, gate completes Gate & Path
                if lockedLines.count >= 1 {
                    isThreat = true
                }
                // If they have a gate, another completes Fortress
                if lockedGates.count >= 1 {
                    isThreat = true
                }
            case .bend:
                // If they have 2 bends, third completes Three Bends
                if lockedBends.count >= 2 {
                    isThreat = true
                }
            case .pod:
                // Pod is a minor pattern, not typically a major threat
                isThreat = false
            case .hook:
                // If they have a hook, another completes The Pincer
                let lockedHooks = lockedPatterns.filter { $0.type == .hook }
                if lockedHooks.count >= 1 {
                    isThreat = true
                }
            }

            if isThreat {
                threats.append(pattern)
            }
        }

        return threats
    }
}
