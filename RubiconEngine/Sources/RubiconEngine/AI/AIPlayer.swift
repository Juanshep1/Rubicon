import Foundation

public actor AIPlayer {
    public let difficulty: AIDifficulty
    public let player: Player

    private let rulesEngine = RulesEngine()
    private let evaluator = MoveEvaluator()

    public init(difficulty: AIDifficulty, player: Player) {
        self.difficulty = difficulty
        self.player = player
    }

    public func selectMove(state: GameState) async -> Move? {
        guard state.currentPlayer == player && !state.isGameOver else { return nil }

        let validMoves = rulesEngine.validMoves(for: state)
        guard !validMoves.isEmpty else { return nil }

        // Categorize moves for strategic selection
        let lockMoves = validMoves.filter { if case .lock = $0.type { return true }; return false }
        let captureMoves = validMoves.filter { move in
            if case .shift(_, let to) = move.type {
                return state.board.stone(at: to) != nil
            }
            return false
        }
        let riverMoves = validMoves.filter { if case .drawFromRiver = $0.type { return true }; return false }

        switch difficulty {
        case .beginner:
            return selectBeginnerMove(validMoves: validMoves, lockMoves: lockMoves, state: state)
        case .easy:
            return selectEasyMove(validMoves: validMoves, lockMoves: lockMoves, captureMoves: captureMoves, riverMoves: riverMoves, state: state)
        case .medium:
            return await selectMediumMove(validMoves: validMoves, lockMoves: lockMoves, captureMoves: captureMoves, riverMoves: riverMoves, state: state)
        case .hard:
            return await selectHardMove(validMoves: validMoves, state: state)
        case .expert:
            return await selectExpertMove(validMoves: validMoves, state: state)
        case .master:
            return await selectMasterMove(validMoves: validMoves, state: state)
        }
    }

    // MARK: - Beginner: Completely random, makes many mistakes

    private func selectBeginnerMove(validMoves: [Move], lockMoves: [Move], state: GameState) -> Move {
        // Beginner: Almost entirely random - perfect for learning the game
        // Only locks patterns 15% of the time (often misses opportunities)
        if !lockMoves.isEmpty && Double.random(in: 0...1) < 0.15 {
            return lockMoves.randomElement()!
        }

        // 80% of the time, just pick a completely random move (including suboptimal ones)
        let nonPassMoves = validMoves.filter { if case .pass = $0.type { return false }; return true }
        if !nonPassMoves.isEmpty {
            return nonPassMoves.randomElement()!
        }
        return validMoves.randomElement()!
    }

    // MARK: - Easy: Mostly random with occasional smart moves

    private func selectEasyMove(validMoves: [Move], lockMoves: [Move], captureMoves: [Move], riverMoves: [Move], state: GameState) -> Move {
        // Easy: Mostly random but occasionally makes good moves
        // This should be beatable by most players

        // 70% of the time, just play randomly like beginner
        if Double.random(in: 0...1) < 0.7 {
            return selectBeginnerMove(validMoves: validMoves, lockMoves: lockMoves, state: state)
        }

        // 30% of the time, make a somewhat smart move:

        // Lock if available (but only 40% of the remaining 30% = 12% overall)
        if !lockMoves.isEmpty && Double.random(in: 0...1) < 0.4 {
            return lockMoves.randomElement()! // Random lock, not strategic
        }

        // Capture if possible (30% of remaining = 9% overall)
        if !captureMoves.isEmpty && Double.random(in: 0...1) < 0.3 {
            return captureMoves.randomElement()!
        }

        // Draw from river only when very low on stones
        if !riverMoves.isEmpty && state.currentPlayerStonesInHand < 3 && Double.random(in: 0...1) < 0.3 {
            return riverMoves.first!
        }

        // Otherwise random (not greedy - greedy is too strong for Easy)
        let nonPassMoves = validMoves.filter { if case .pass = $0.type { return false }; return true }
        if !nonPassMoves.isEmpty {
            return nonPassMoves.randomElement()!
        }
        return validMoves.randomElement()!
    }

    // MARK: - Medium: Balanced challenge with some strategy

    private func selectMediumMove(validMoves: [Move], lockMoves: [Move], captureMoves: [Move], riverMoves: [Move], state: GameState) async -> Move {
        // Medium: A fair challenge - uses strategy but makes mistakes

        // 30% of the time, play like Easy (introduces mistakes)
        if Double.random(in: 0...1) < 0.3 {
            return selectEasyMove(validMoves: validMoves, lockMoves: lockMoves, captureMoves: captureMoves, riverMoves: riverMoves, state: state)
        }

        // Check for winning lock moves (always take a win)
        if !lockMoves.isEmpty {
            for lockMove in lockMoves {
                let result = rulesEngine.executeMove(lockMove, on: state)
                if result.victoryResult.hasWinner && result.victoryResult.winner == player {
                    return lockMove // Take the win!
                }
            }

            // 60% chance to lock a pattern (not always)
            if Double.random(in: 0...1) < 0.6 {
                // Prefer larger patterns but don't use full strategic selection
                let sortedLocks = lockMoves.sorted { m1, m2 in
                    if case .lock(_, let p1) = m1.type, case .lock(_, let p2) = m2.type {
                        return p1.count > p2.count
                    }
                    return false
                }
                return sortedLocks.first!
            }
        }

        // 50% chance to take captures
        if !captureMoves.isEmpty && Double.random(in: 0...1) < 0.5 {
            return captureMoves.randomElement()!
        }

        // Use shallow minimax for other moves (depth 1 = just immediate evaluation)
        return await selectMinimaxMove(validMoves: validMoves, state: state, depth: 1)
    }

    // MARK: - Hard: Very challenging AI (deep search, smart strategy)

    private func selectHardMove(validMoves: [Move], state: GameState) async -> Move {
        // Hard: Strong AI - deep search, full threat analysis, positional play

        // Check for immediate wins (including strategic locks)
        let lockMoves = validMoves.filter { if case .lock = $0.type { return true }; return false }
        if !lockMoves.isEmpty {
            if let bestLock = selectStrategicLock(lockMoves: lockMoves, state: state) {
                return bestLock
            }
        }

        // Check for any other immediate wins
        for move in validMoves {
            let result = rulesEngine.executeMove(move, on: state)
            if result.victoryResult.hasWinner && result.victoryResult.winner == player {
                return move
            }
        }

        // Block opponent wins (CRITICAL)
        if let blockMove = findOpponentWinBlock(validMoves: validMoves, state: state) {
            return blockMove
        }

        // Block opponent threats
        if let threatBlock = findThreatBlockingMove(validMoves: validMoves, state: state) {
            return threatBlock
        }

        // Use break strategically if opponent is close to winning
        if let breakMove = findStrategicBreak(validMoves: validMoves, state: state) {
            return breakMove
        }

        // Order moves with killer move heuristic (top 15 for deeper search)
        let orderedMoves = Array(orderMovesAdvanced(validMoves, state: state).prefix(15))

        // Use minimax with depth 4 (challenging)
        return await selectMinimaxMove(validMoves: orderedMoves, state: state, depth: 4)
    }

    // MARK: - Expert: Master level - optimal play with deep analysis

    private func selectExpertMove(validMoves: [Move], state: GameState) async -> Move {
        // Expert: Very strong AI - deep search, full threat analysis, positional mastery

        // Check for winning locks first (always take a win)
        let lockMoves = validMoves.filter { if case .lock = $0.type { return true }; return false }
        if !lockMoves.isEmpty {
            if let bestLock = selectStrategicLock(lockMoves: lockMoves, state: state) {
                return bestLock
            }
        }

        // Check for other immediate wins
        for move in validMoves {
            let result = rulesEngine.executeMove(move, on: state)
            if result.victoryResult.hasWinner && result.victoryResult.winner == player {
                return move
            }
        }

        // Block opponent wins (CRITICAL - check all possible win moves)
        if let blockMove = findOpponentWinBlock(validMoves: validMoves, state: state) {
            return blockMove
        }

        // Block opponent near-wins (one move away from victory)
        if let threatBlock = findThreatBlockingMove(validMoves: validMoves, state: state) {
            return threatBlock
        }

        // Look for forcing moves (moves that create multiple threats)
        if let forcingMove = findForcingMove(validMoves: validMoves, state: state) {
            return forcingMove
        }

        // Use break strategically
        if let breakMove = findStrategicBreak(validMoves: validMoves, state: state) {
            return breakMove
        }

        // Order moves with advanced heuristics (top 18 for deep search)
        let orderedMoves = Array(orderMovesAdvanced(validMoves, state: state).prefix(18))

        // Use minimax with depth 5 (very challenging)
        return await selectMinimaxMove(validMoves: orderedMoves, state: state, depth: 5)
    }

    // MARK: - Master: Near-perfect play with comprehensive analysis

    private func selectMasterMove(validMoves: [Move], state: GameState) async -> Move {
        // Master: Near-perfect AI - deepest search, comprehensive analysis, multi-turn planning

        // Check for winning locks first (always take a win)
        let lockMoves = validMoves.filter { if case .lock = $0.type { return true }; return false }
        if !lockMoves.isEmpty {
            if let bestLock = selectStrategicLock(lockMoves: lockMoves, state: state) {
                return bestLock
            }
        }

        // Check for other immediate wins
        for move in validMoves {
            let result = rulesEngine.executeMove(move, on: state)
            if result.victoryResult.hasWinner && result.victoryResult.winner == player {
                return move
            }
        }

        // Block opponent wins (CRITICAL)
        if let blockMove = findOpponentWinBlock(validMoves: validMoves, state: state) {
            return blockMove
        }

        // Block all threats comprehensively
        if let threatBlock = findThreatBlockingMove(validMoves: validMoves, state: state) {
            return threatBlock
        }

        // Look for forcing sequences (moves that force opponent into bad positions)
        if let forcingMove = findForcingMove(validMoves: validMoves, state: state) {
            return forcingMove
        }

        // Evaluate long-term positional play
        if let positionalMove = findBestPositionalMove(validMoves: validMoves, state: state) {
            return positionalMove
        }

        // Use break strategically to disrupt opponent's plans
        if let breakMove = findStrategicBreak(validMoves: validMoves, state: state) {
            return breakMove
        }

        // Order all moves with comprehensive heuristics (evaluate more moves)
        let orderedMoves = Array(orderMovesAdvanced(validMoves, state: state).prefix(20))

        // Use minimax with depth 6 (maximum challenge)
        return await selectMinimaxMove(validMoves: orderedMoves, state: state, depth: 6)
    }

    // MARK: - Advanced Strategic Methods

    /// Find a move that creates multiple simultaneous threats
    private func findForcingMove(validMoves: [Move], state: GameState) -> Move? {
        var bestMove: Move?
        var bestThreatCount = 1 // Need at least 2 threats to be forcing

        for move in validMoves {
            let result = rulesEngine.executeMove(move, on: state)
            if result.success {
                // Count patterns we can lock after this move
                let patterns = evaluator.patternDetector.detectPatterns(on: result.newState.board, for: player, unlockedOnly: true)

                // Count how many would lead to victory
                var winThreats = 0
                for pattern in patterns {
                    // Simulate locking this pattern
                    if wouldPatternLeadToVictory(pattern: pattern, state: result.newState) {
                        winThreats += 1
                    }
                }

                if winThreats > bestThreatCount {
                    bestThreatCount = winThreats
                    bestMove = move
                }
            }
        }

        return bestMove
    }

    /// Check if locking a pattern would lead to victory (or very close)
    private func wouldPatternLeadToVictory(pattern: Pattern, state: GameState) -> Bool {
        let lockedPatterns = state.lockedPatterns(for: player)
        let lines = lockedPatterns.filter { $0.type == .line }
        let gates = lockedPatterns.filter { $0.type == .gate }
        let bends = lockedPatterns.filter { $0.type == .bend }

        switch pattern.type {
        case .cross:
            return true // Instant win
        case .line:
            if pattern.positions.count >= 5 { return true } // Long Road
            if lines.count >= 1 { return true } // Twin Rivers
            if gates.count >= 1 { return true } // Gate & Path
            return false
        case .gate:
            if gates.count >= 1 { return true } // Fortress
            if lines.count >= 1 { return true } // Gate & Path
            return false
        case .bend:
            if bends.count >= 2 { return true } // Three Bends
            return false
        }
    }

    /// Find the best positional move (control key positions)
    private func findBestPositionalMove(validMoves: [Move], state: GameState) -> Move? {
        // Only for drops/shifts, prefer center control and pattern-building positions
        var bestMove: Move?
        var bestScore = 0.0

        let dropMoves = validMoves.filter { if case .drop = $0.type { return true }; return false }
        let shiftMoves = validMoves.filter { if case .shift = $0.type { return true }; return false }

        for move in dropMoves + shiftMoves {
            var score = 0.0
            let targetPos: Position

            switch move.type {
            case .drop(let pos):
                targetPos = pos
            case .shift(_, let to):
                targetPos = to
            default:
                continue
            }

            // Center control bonus
            if targetPos.column >= 2 && targetPos.column <= 3 && targetPos.row >= 2 && targetPos.row <= 3 {
                score += 50.0
            }

            // Pattern building potential
            let result = rulesEngine.executeMove(move, on: state)
            if result.success {
                let newPatterns = evaluator.patternDetector.detectPatterns(on: result.newState.board, for: player, unlockedOnly: true)
                score += Double(newPatterns.count) * 40.0

                // Bonus for patterns that would complete a victory set
                for pattern in newPatterns {
                    if wouldPatternLeadToVictory(pattern: pattern, state: result.newState) {
                        score += 100.0
                    }
                }
            }

            // Adjacency to own stones (connectivity)
            var adjacentFriendly = 0
            for neighbor in targetPos.orthogonalNeighbors where neighbor.isValid {
                if let stone = state.board.stone(at: neighbor), stone.owner == player {
                    adjacentFriendly += 1
                }
            }
            score += Double(adjacentFriendly) * 15.0

            if score > bestScore {
                bestScore = score
                bestMove = move
            }
        }

        return bestScore > 100.0 ? bestMove : nil // Only return if significantly good
    }

    /// Find a strategic break move
    private func findStrategicBreak(validMoves: [Move], state: GameState) -> Move? {
        let breakMoves = validMoves.filter { if case .breakLock = $0.type { return true }; return false }
        guard !breakMoves.isEmpty else { return nil }

        // Only break if opponent is close to winning
        let oppLockedPatterns = state.lockedPatterns(for: player.opponent)
        let oppLines = oppLockedPatterns.filter { $0.type == .line }
        let oppGates = oppLockedPatterns.filter { $0.type == .gate }
        let oppBends = oppLockedPatterns.filter { $0.type == .bend }

        // Check if opponent is close to a victory set
        let isOpponentCloseToWin =
            oppLines.count >= 1 ||
            oppGates.count >= 1 ||
            oppBends.count >= 2 ||
            oppLockedPatterns.contains { $0.positions.count >= 4 } // Long line

        if isOpponentCloseToWin {
            // Find the best pattern to break (the one closest to completing their victory)
            var bestBreak: Move?
            var bestValue = 0.0

            for move in breakMoves {
                if case .breakLock(_, let targetPos) = move.type {
                    // Find which pattern contains this position
                    for pattern in oppLockedPatterns {
                        if pattern.positions.contains(targetPos) {
                            var value = 0.0

                            // Value based on pattern type and victory proximity
                            switch pattern.type {
                            case .line:
                                value += Double(pattern.positions.count) * 50.0
                                if oppLines.count >= 1 { value += 200.0 } // Would complete Twin Rivers
                                if oppGates.count >= 1 { value += 150.0 } // Would complete Gate & Path
                            case .gate:
                                value += 150.0
                                if oppGates.count >= 1 { value += 200.0 } // Would complete Fortress
                                if oppLines.count >= 1 { value += 150.0 } // Would complete Gate & Path
                            case .bend:
                                value += 80.0
                                if oppBends.count >= 2 { value += 200.0 } // Would complete Three Bends
                            case .cross:
                                value += 500.0 // Breaking a near-cross is critical
                            }

                            if value > bestValue {
                                bestValue = value
                                bestBreak = move
                            }
                            break
                        }
                    }
                }
            }

            return bestBreak
        }

        return nil
    }

    /// Advanced move ordering with multiple heuristics
    private func orderMovesAdvanced(_ moves: [Move], state: GameState) -> [Move] {
        return moves.sorted { move1, move2 in
            let score1 = evaluateMoveAdvanced(move1, state: state)
            let score2 = evaluateMoveAdvanced(move2, state: state)
            return score1 > score2
        }
    }

    /// Advanced move evaluation with multiple factors
    private func evaluateMoveAdvanced(_ move: Move, state: GameState) -> Double {
        var score = evaluator.evaluateMove(move, state: state, for: player)

        // Additional scoring for advanced heuristics
        switch move.type {
        case .lock(_, let positions):
            // Huge bonus for winning moves
            let result = rulesEngine.executeMove(move, on: state)
            if result.victoryResult.hasWinner && result.victoryResult.winner == player {
                score += 50000.0
            }
            // Bonus for patterns that set up wins
            if positions.count >= 4 {
                score += 500.0 // Long line
            }
        case .shift(_, let to):
            // Bonus for captures that disrupt opponent patterns
            if let target = state.board.stone(at: to), target.owner == player.opponent {
                if target.isLocked {
                    score += 300.0 // Can't capture locked, but indicates threat
                } else {
                    // Check if this stone is part of a potential pattern
                    let oppPatterns = evaluator.patternDetector.detectPatterns(on: state.board, for: player.opponent, unlockedOnly: true)
                    for pattern in oppPatterns {
                        if pattern.positions.contains(to) {
                            score += 200.0 // Disrupts their pattern
                        }
                    }
                }
            }
        case .drop(let pos):
            // Bonus for drops that create pattern opportunities
            var testBoard = state.board
            testBoard.place(Stone(owner: player), at: pos)
            let newPatterns = evaluator.patternDetector.detectPatterns(on: testBoard, for: player, unlockedOnly: true)
            if newPatterns.count >= 2 {
                score += 100.0 // Creates multiple pattern options
            }
        default:
            break
        }

        return score
    }

    /// Find a move that blocks an opponent's immediate win
    private func findOpponentWinBlock(validMoves: [Move], state: GameState) -> Move? {
        let opponentMoves = rulesEngine.moveValidator.validMoves(for: player.opponent, state: simulatePassTurn(state))
        for oppMove in opponentMoves {
            var testState = simulatePassTurn(state)
            testState = rulesEngine.executeMove(oppMove, on: testState).newState
            if testState.winner == player.opponent {
                if let blockingMove = findBlockingMove(against: oppMove, validMoves: validMoves, state: state) {
                    return blockingMove
                }
            }
        }
        return nil
    }

    /// Find moves that block opponent threats (near-win situations)
    private func findThreatBlockingMove(validMoves: [Move], state: GameState) -> Move? {
        let opponentPatterns = evaluator.detectOpponentThreats(state: state, opponent: player.opponent)

        // If opponent has patterns that could lead to victory, try to disrupt
        for pattern in opponentPatterns {
            // Try to capture one of the threatening stones
            for move in validMoves {
                if case .shift(_, let to) = move.type {
                    if pattern.positions.contains(to) {
                        return move // Capture a stone in their pattern
                    }
                }
            }
        }
        return nil
    }

    // MARK: - Core Algorithms

    private func selectGreedyMove(validMoves: [Move], state: GameState) -> Move {
        var bestMove = validMoves[0]
        var bestScore = Double.leastNormalMagnitude

        for move in validMoves {
            let result = rulesEngine.executeMove(move, on: state)
            if result.success {
                let score = evaluator.evaluate(state: result.newState, for: player)
                if score > bestScore {
                    bestScore = score
                    bestMove = move
                }
            }
        }

        return bestMove
    }

    private func selectMinimaxMove(validMoves: [Move], state: GameState, depth: Int) async -> Move {
        var bestMove = validMoves[0]
        var bestScore = Double.leastNormalMagnitude
        let alpha = Double.leastNormalMagnitude
        let beta = Double.greatestFiniteMagnitude

        for move in validMoves {
            let result = rulesEngine.executeMove(move, on: state)
            if result.success {
                let score = minimax(
                    state: result.newState,
                    depth: depth - 1,
                    alpha: alpha,
                    beta: beta,
                    isMaximizing: false
                )
                if score > bestScore {
                    bestScore = score
                    bestMove = move
                }
            }

            // Allow other tasks to run (cooperative multitasking)
            await Task.yield()
        }

        return bestMove
    }

    private func minimax(state: GameState, depth: Int, alpha: Double, beta: Double, isMaximizing: Bool) -> Double {
        // Terminal conditions
        if depth == 0 || state.isGameOver {
            return evaluator.evaluate(state: state, for: player)
        }

        let validMoves = rulesEngine.validMoves(for: state)
        if validMoves.isEmpty {
            return evaluator.evaluate(state: state, for: player)
        }

        var currentAlpha = alpha
        var currentBeta = beta

        if isMaximizing {
            var maxScore = Double.leastNormalMagnitude

            for move in validMoves {
                let result = rulesEngine.executeMove(move, on: state)
                if result.success {
                    let score = minimax(
                        state: result.newState,
                        depth: depth - 1,
                        alpha: currentAlpha,
                        beta: currentBeta,
                        isMaximizing: false
                    )
                    maxScore = max(maxScore, score)
                    currentAlpha = max(currentAlpha, score)

                    if currentBeta <= currentAlpha {
                        break // Beta cutoff
                    }
                }
            }

            return maxScore
        } else {
            var minScore = Double.greatestFiniteMagnitude

            for move in validMoves {
                let result = rulesEngine.executeMove(move, on: state)
                if result.success {
                    let score = minimax(
                        state: result.newState,
                        depth: depth - 1,
                        alpha: currentAlpha,
                        beta: currentBeta,
                        isMaximizing: true
                    )
                    minScore = min(minScore, score)
                    currentBeta = min(currentBeta, score)

                    if currentBeta <= currentAlpha {
                        break // Alpha cutoff
                    }
                }
            }

            return minScore
        }
    }

    // MARK: - Utility Methods

    private func orderMoves(_ moves: [Move], state: GameState) -> [Move] {
        // Sort moves by their immediate tactical value for better pruning
        return moves.sorted { move1, move2 in
            let score1 = evaluator.evaluateMove(move1, state: state, for: player)
            let score2 = evaluator.evaluateMove(move2, state: state, for: player)
            return score1 > score2
        }
    }

    private func simulatePassTurn(_ state: GameState) -> GameState {
        var newState = state
        newState.advanceTurn()
        return newState
    }

    private func findBlockingMove(against oppMove: Move, validMoves: [Move], state: GameState) -> Move? {
        // Try to find a move that blocks the opponent's winning move
        if case .lock(_, let oppPositions) = oppMove.type {
            // Try to capture one of the stones in the pattern
            for move in validMoves {
                if case .shift(_, let to) = move.type {
                    if oppPositions.contains(to) {
                        return move
                    }
                }
            }
        }
        return nil
    }

    // MARK: - Strategic Lock Selection

    /// Intelligently select which pattern to lock based on victory set progress
    private func selectStrategicLock(lockMoves: [Move], state: GameState) -> Move? {
        guard !lockMoves.isEmpty else { return nil }

        // Extract pattern info from lock moves
        var lockInfo: [(move: Move, type: PatternType, size: Int, positions: Set<Position>)] = []
        for move in lockMoves {
            if case .lock(let patternID, let positions) = move.type {
                let patternType = inferPatternType(positions: positions)
                lockInfo.append((move, patternType, positions.count, positions))

                // Check if this lock wins the game - take it immediately!
                let result = rulesEngine.executeMove(move, on: state)
                if result.victoryResult.hasWinner && result.victoryResult.winner == player {
                    return move
                }
            }
        }

        // Get current locked patterns to determine best strategy
        let myLockedPatterns = state.lockedPatterns(for: player)
        let lockedLines = myLockedPatterns.filter { $0.type == .line }
        let lockedBends = myLockedPatterns.filter { $0.type == .bend }
        let lockedGates = myLockedPatterns.filter { $0.type == .gate }

        // Priority 1: Complete an instant win (5+ line or cross)
        for info in lockInfo {
            if info.type == .cross {
                return info.move // The Star - instant win!
            }
            if info.type == .line && info.size >= 5 {
                return info.move // The Long Road - instant win!
            }
        }

        // Priority 2: Complete a victory set (check if locking would win)
        // Twin Rivers: need 2 non-overlapping lines
        if lockedLines.count == 1 {
            for info in lockInfo where info.type == .line {
                if !patternsOverlap(lockedLines[0].positions, info.positions) {
                    return info.move // Complete Twin Rivers!
                }
            }
        }

        // Fortress: need 2 non-overlapping gates
        if lockedGates.count == 1 {
            for info in lockInfo where info.type == .gate {
                if !patternsOverlap(lockedGates[0].positions, info.positions) {
                    return info.move // Complete Fortress!
                }
            }
        }

        // Gate & Path: need 1 gate + 1 line
        if lockedGates.count == 1 && lockedLines.isEmpty {
            for info in lockInfo where info.type == .line {
                if !patternsOverlap(lockedGates[0].positions, info.positions) {
                    return info.move // Complete Gate & Path!
                }
            }
        }
        if lockedLines.count >= 1 && lockedGates.isEmpty {
            for info in lockInfo where info.type == .gate {
                let line = lockedLines[0]
                if !patternsOverlap(line.positions, info.positions) {
                    return info.move // Complete Gate & Path!
                }
            }
        }

        // Three Bends: need 3 non-overlapping bends
        if lockedBends.count == 2 {
            for info in lockInfo where info.type == .bend {
                let nonOverlapping = lockedBends.allSatisfy { !patternsOverlap($0.positions, info.positions) }
                if nonOverlapping {
                    return info.move // Complete Three Bends!
                }
            }
        }

        // Priority 3: Progress toward the best victory set
        // Determine which victory set we're closest to and lock accordingly
        let victoryProgress = evaluateVictorySetProgress(lockedPatterns: myLockedPatterns)

        // Score each available lock move
        var scoredMoves: [(move: Move, score: Double)] = []
        for info in lockInfo {
            var score = 0.0

            switch info.type {
            case .line:
                // Longer lines are more valuable
                score += Double(info.size) * 50.0
                // Bonus if working toward Twin Rivers and would be non-overlapping
                if victoryProgress.bestSet == .twinRivers || lockedLines.isEmpty {
                    let wouldBeNonOverlapping = lockedLines.allSatisfy { !patternsOverlap($0.positions, info.positions) }
                    if wouldBeNonOverlapping {
                        score += 100.0
                    }
                }
                // Bonus if working toward Gate & Path
                if victoryProgress.bestSet == .gateAndPath && lockedGates.count >= 1 {
                    let wouldBeNonOverlapping = lockedGates.allSatisfy { !patternsOverlap($0.positions, info.positions) }
                    if wouldBeNonOverlapping {
                        score += 120.0
                    }
                }
                // Big bonus for 4-length line (one away from Long Road)
                if info.size == 4 {
                    score += 200.0
                }

            case .gate:
                score += 80.0
                // Bonus if working toward Fortress
                if victoryProgress.bestSet == .theFortress || lockedGates.isEmpty {
                    let wouldBeNonOverlapping = lockedGates.allSatisfy { !patternsOverlap($0.positions, info.positions) }
                    if wouldBeNonOverlapping {
                        score += 150.0
                    }
                }
                // Bonus if working toward Gate & Path
                if victoryProgress.bestSet == .gateAndPath && lockedLines.count >= 1 {
                    let wouldBeNonOverlapping = lockedLines.allSatisfy { !patternsOverlap($0.positions, info.positions) }
                    if wouldBeNonOverlapping {
                        score += 120.0
                    }
                }

            case .bend:
                score += 40.0
                // Bonus if working toward Three Bends
                if victoryProgress.bestSet == .threeBends || lockedBends.count >= 1 {
                    let wouldBeNonOverlapping = lockedBends.allSatisfy { !patternsOverlap($0.positions, info.positions) }
                    if wouldBeNonOverlapping {
                        score += 80.0
                    }
                }

            case .cross:
                score += 10000.0 // Instant win, should have been caught earlier
            }

            scoredMoves.append((info.move, score))
        }

        // Sort by score and return best
        scoredMoves.sort { $0.score > $1.score }
        if let best = scoredMoves.first, best.score > 0 {
            return best.move
        }

        // Fallback: return highest evaluated move
        return lockMoves.max { m1, m2 in
            evaluator.evaluateMove(m1, state: state, for: player) < evaluator.evaluateMove(m2, state: state, for: player)
        }
    }

    /// Infer pattern type from positions
    private func inferPatternType(positions: Set<Position>) -> PatternType {
        let count = positions.count
        let sortedPositions = positions.sorted { ($0.column, $0.row) < ($1.column, $1.row) }

        // Cross: 5 stones in + shape
        if count == 5 {
            for pos in sortedPositions {
                let neighbors = pos.orthogonalNeighbors.filter { positions.contains($0) }
                if neighbors.count == 4 {
                    return .cross
                }
            }
        }

        // Gate: 4 stones in 2x2
        if count == 4 {
            let cols = positions.map { $0.column }
            let rows = positions.map { $0.row }
            if let maxCol = cols.max(), let minCol = cols.min(),
               let maxRow = rows.max(), let minRow = rows.min() {
                if maxCol - minCol == 1 && maxRow - minRow == 1 {
                    return .gate
                }
            }
        }

        // Bend: 3 stones in L shape
        if count == 3 {
            let posArray = Array(positions)
            // Check if it's an L shape (one stone is the corner, other two extend from it)
            for corner in posArray {
                let others = posArray.filter { $0 != corner }
                if others.count == 2 {
                    let diff1 = (others[0].column - corner.column, others[0].row - corner.row)
                    let diff2 = (others[1].column - corner.column, others[1].row - corner.row)
                    // L shape if one horizontal and one vertical
                    let isHorizontal1 = diff1.1 == 0 && abs(diff1.0) == 1
                    let isVertical1 = diff1.0 == 0 && abs(diff1.1) == 1
                    let isHorizontal2 = diff2.1 == 0 && abs(diff2.0) == 1
                    let isVertical2 = diff2.0 == 0 && abs(diff2.1) == 1

                    if (isHorizontal1 && isVertical2) || (isVertical1 && isHorizontal2) {
                        return .bend
                    }
                }
            }
        }

        // Default to line for 3+ inline stones
        return .line
    }

    /// Check if two sets of positions overlap
    private func patternsOverlap(_ p1: Set<Position>, _ p2: Set<Position>) -> Bool {
        !p1.isDisjoint(with: p2)
    }

    /// Evaluate which victory set we're closest to
    private func evaluateVictorySetProgress(lockedPatterns: [Pattern]) -> (bestSet: VictorySetType, progress: Double) {
        let lines = lockedPatterns.filter { $0.type == .line }
        let bends = lockedPatterns.filter { $0.type == .bend }
        let gates = lockedPatterns.filter { $0.type == .gate }

        var progress: [(VictorySetType, Double)] = []

        // Twin Rivers: 2 lines
        progress.append((.twinRivers, Double(lines.count) / 2.0))

        // Gate & Path: 1 gate + 1 line
        let gatePathProgress = (gates.isEmpty ? 0 : 0.5) + (lines.isEmpty ? 0 : 0.5)
        progress.append((.gateAndPath, gatePathProgress))

        // Three Bends: 3 bends
        progress.append((.threeBends, Double(bends.count) / 3.0))

        // The Fortress: 2 gates
        progress.append((.theFortress, Double(gates.count) / 2.0))

        // The Long Road: best line length toward 5
        let maxLineLength = lines.map { $0.positions.count }.max() ?? 0
        progress.append((.theLongRoad, Double(maxLineLength) / 5.0))

        // Sort by progress (highest first)
        progress.sort { $0.1 > $1.1 }

        // Return best option, defaulting to Twin Rivers if no progress
        return progress.first ?? (.twinRivers, 0)
    }
}

// MARK: - AI Game Integration

@MainActor
public extension GameController {
    func executeAIMove() async {
        guard case .vsAI(let difficulty) = state.gameMode else { return }
        guard state.currentPlayer == .dark && !state.isGameOver else { return }

        let ai = AIPlayer(difficulty: difficulty, player: .dark)

        if let move = await ai.selectMove(state: state) {
            // Add a small delay for better UX
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

            // Re-validate that it's still AI's turn and game isn't over
            guard state.currentPlayer == .dark && !state.isGameOver else { return }

            // Validate the move is still valid after the delay
            let rulesEngine = RulesEngine()
            let validation = rulesEngine.moveValidator.validate(move, state: state)
            guard validation.isValid else {
                // Move is no longer valid, pass instead
                performPass()
                return
            }

            switch move.type {
            case .drop(let position):
                performDrop(at: position)
            case .shift(let from, let to):
                performShift(from: from, to: to)
            case .lock(_, let positions):
                if let pattern = availablePatterns.first(where: { $0.positions == positions }) {
                    performLock(pattern: pattern)
                } else {
                    performPass() // Pattern no longer available
                }
            case .drawFromRiver:
                performDrawFromRiver()
            case .breakLock(let sacrifice, let target):
                performBreak(sacrificePositions: sacrifice, targetPosition: target)
            case .pass:
                performPass()
            }
        }
    }
}

// Helper to extract lock positions from MoveType
extension MoveType {
    var lockPositions: Set<Position>? {
        if case .lock(_, let positions) = self {
            return positions
        }
        return nil
    }
}
