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

    // MARK: - Beginner: Plays like a new player learning Rubicon

    private func selectBeginnerMove(validMoves: [Move], lockMoves: [Move], state: GameState) -> Move {
        // Beginner AI understands Rubicon basics but makes tactical errors:
        // - Knows to lock patterns (but sometimes picks suboptimal ones)
        // - Tries to build toward patterns (but inefficiently)
        // - Low threat awareness (often misses opponent wins)
        // - Prefers center control (basic strategy)
        // - Makes positional mistakes

        let captureMoves = validMoves.filter { move in
            if case .shift(_, let to) = move.type {
                return state.board.stone(at: to) != nil
            }
            return false
        }
        let riverMoves = validMoves.filter { if case .drawFromRiver = $0.type { return true }; return false }

        // PRIORITY 1: Always take a winning lock (knows how to win!)
        for lockMove in lockMoves {
            let result = rulesEngine.executeMove(lockMove, on: state)
            if result.victoryResult.hasWinner && result.victoryResult.winner == player {
                return lockMove
            }
        }

        // PRIORITY 2: Lock patterns when available (70% of the time)
        // Beginner often locks eagerly without considering if it's the best pattern
        if !lockMoves.isEmpty && Double.random(in: 0...1) < 0.70 {
            // Beginner doesn't always pick the best pattern - sometimes picks randomly
            if Double.random(in: 0...1) < 0.4 {
                // 40% chance: just pick any pattern (suboptimal)
                return lockMoves.randomElement()!
            }
            // 60% chance: pick the largest pattern (decent choice)
            let sortedLocks = lockMoves.sorted { m1, m2 in
                if case .lock(_, let p1) = m1.type, case .lock(_, let p2) = m2.type {
                    return p1.count > p2.count
                }
                return false
            }
            return sortedLocks.first!
        }

        // PRIORITY 3: Take obvious captures (50% of the time)
        // Beginner sees captures but doesn't always take them
        if !captureMoves.isEmpty && Double.random(in: 0...1) < 0.50 {
            return captureMoves.randomElement()!
        }

        // PRIORITY 4: Draw from river when low on stones (60% of the time)
        if !riverMoves.isEmpty && state.currentPlayerStonesInHand <= 3 && Double.random(in: 0...1) < 0.60 {
            return riverMoves.first!
        }

        // PRIORITY 5: Try to build patterns (basic pattern awareness)
        if let patternBuildMove = findPatternBuildingMove(validMoves: validMoves, state: state, mistakeChance: 0.5) {
            return patternBuildMove
        }

        // PRIORITY 6: Prefer center control (basic positional play)
        if let centerMove = findCenterControlMove(validMoves: validMoves, state: state, mistakeChance: 0.4) {
            return centerMove
        }

        // FALLBACK: Pick a reasonable drop or shift (not completely random)
        return selectReasonableMove(validMoves: validMoves, state: state)
    }

    // MARK: - Easy: Plays like an intermediate player

    private func selectEasyMove(validMoves: [Move], lockMoves: [Move], captureMoves: [Move], riverMoves: [Move], state: GameState) -> Move {
        // Easy AI plays like someone who knows Rubicon well but still makes mistakes:
        // - Always takes wins
        // - Usually locks patterns (prefers good ones)
        // - Better threat awareness (sometimes blocks opponent wins)
        // - Actively pursues patterns
        // - Takes good captures
        // - Occasional tactical errors (20% mistake rate)

        // PRIORITY 1: Always take a winning lock
        for lockMove in lockMoves {
            let result = rulesEngine.executeMove(lockMove, on: state)
            if result.victoryResult.hasWinner && result.victoryResult.winner == player {
                return lockMove
            }
        }

        // PRIORITY 2: Block opponent wins (50% awareness - sometimes misses)
        if Double.random(in: 0...1) < 0.50 {
            if let blockMove = findBasicOpponentWinBlock(validMoves: validMoves, state: state) {
                return blockMove
            }
        }

        // PRIORITY 3: Lock patterns strategically (85% of the time)
        if !lockMoves.isEmpty && Double.random(in: 0...1) < 0.85 {
            // Easy AI usually picks the best pattern
            if Double.random(in: 0...1) < 0.75 {
                // 75%: Strategic lock (prefer valuable patterns)
                return selectBasicStrategicLock(lockMoves: lockMoves, state: state)
            } else {
                // 25%: Random lock (mistake)
                return lockMoves.randomElement()!
            }
        }

        // PRIORITY 4: Take good captures (70% of the time)
        if !captureMoves.isEmpty && Double.random(in: 0...1) < 0.70 {
            // Prefer captures that disrupt patterns
            if let goodCapture = findBasicGoodCapture(captureMoves: captureMoves, state: state) {
                return goodCapture
            }
            return captureMoves.randomElement()!
        }

        // PRIORITY 5: Draw from river when needed (80% of the time)
        if !riverMoves.isEmpty && state.currentPlayerStonesInHand <= 4 && Double.random(in: 0...1) < 0.80 {
            return riverMoves.first!
        }

        // PRIORITY 6: Build toward patterns (better than Beginner)
        if let patternBuildMove = findPatternBuildingMove(validMoves: validMoves, state: state, mistakeChance: 0.25) {
            return patternBuildMove
        }

        // PRIORITY 7: Good positional play
        if let positionalMove = findCenterControlMove(validMoves: validMoves, state: state, mistakeChance: 0.2) {
            return positionalMove
        }

        // FALLBACK: Select a reasonable move
        return selectReasonableMove(validMoves: validMoves, state: state)
    }

    // MARK: - Helper Methods for Lower Difficulty AI

    /// Find a move that builds toward forming a pattern
    private func findPatternBuildingMove(validMoves: [Move], state: GameState, mistakeChance: Double) -> Move? {
        // Mistake chance: sometimes pick a suboptimal move
        if Double.random(in: 0...1) < mistakeChance {
            return nil  // "Miss" this opportunity
        }

        let dropMoves = validMoves.filter { if case .drop = $0.type { return true }; return false }
        let shiftMoves = validMoves.filter { if case .shift = $0.type { return true }; return false }

        var bestMoves: [(Move, Int)] = []

        for move in dropMoves + shiftMoves {
            var testState = state

            // Simulate the move
            let targetPos: Position
            switch move.type {
            case .drop(let pos):
                testState.board.place(Stone(owner: player), at: pos)
                targetPos = pos
            case .shift(let from, let to):
                testState.board.move(from: from, to: to)
                targetPos = to
            default:
                continue
            }

            // Count how many patterns this creates or extends
            let newPatterns = evaluator.patternDetector.detectPatterns(on: testState.board, for: player, unlockedOnly: true)
            var patternValue = 0

            for pattern in newPatterns {
                if pattern.positions.contains(targetPos) {
                    patternValue += pattern.positions.count * 10
                    // Bonus for specific pattern types
                    switch pattern.type {
                    case .cross: patternValue += 100  // Instant win potential
                    case .line: patternValue += pattern.positions.count >= 4 ? 50 : 20
                    case .gate: patternValue += 30
                    case .hook: patternValue += 25
                    case .bend: patternValue += 15
                    case .pod: patternValue += 10
                    }
                }
            }

            if patternValue > 0 {
                bestMoves.append((move, patternValue))
            }
        }

        // Sort by value and pick from top moves (with some randomness)
        bestMoves.sort { $0.1 > $1.1 }

        if bestMoves.count > 3 {
            // Pick from top 3 (introduces some suboptimality)
            let topMoves = Array(bestMoves.prefix(3))
            return topMoves.randomElement()?.0
        } else if let best = bestMoves.first {
            return best.0
        }

        return nil
    }

    /// Find a move that controls the center of the board
    private func findCenterControlMove(validMoves: [Move], state: GameState, mistakeChance: Double) -> Move? {
        if Double.random(in: 0...1) < mistakeChance {
            return nil
        }

        let centerPositions = [
            Position(column: 2, row: 2), Position(column: 2, row: 3),
            Position(column: 3, row: 2), Position(column: 3, row: 3)
        ]

        let nearCenterPositions = [
            Position(column: 1, row: 2), Position(column: 1, row: 3),
            Position(column: 4, row: 2), Position(column: 4, row: 3),
            Position(column: 2, row: 1), Position(column: 3, row: 1),
            Position(column: 2, row: 4), Position(column: 3, row: 4)
        ]

        var centerMoves: [Move] = []
        var nearCenterMoves: [Move] = []

        for move in validMoves {
            if case .drop(let pos) = move.type {
                if centerPositions.contains(pos) && state.board.stone(at: pos) == nil {
                    centerMoves.append(move)
                } else if nearCenterPositions.contains(pos) && state.board.stone(at: pos) == nil {
                    nearCenterMoves.append(move)
                }
            }
        }

        if !centerMoves.isEmpty {
            return centerMoves.randomElement()
        }
        if !nearCenterMoves.isEmpty && Double.random(in: 0...1) < 0.6 {
            return nearCenterMoves.randomElement()
        }

        return nil
    }

    /// Select a basic strategic lock (for Easy AI)
    private func selectBasicStrategicLock(lockMoves: [Move], state: GameState) -> Move {
        // Prefer: Cross > Long Line > Gate > Hook > Line > Bend > Pod
        var scoredMoves: [(Move, Int)] = []

        for move in lockMoves {
            if case .lock(_, let positions) = move.type {
                var score = positions.count * 10
                let patternType = inferPatternType(positions: positions)

                switch patternType {
                case .cross: score += 500
                case .line:
                    score += positions.count >= 4 ? 200 : 50
                case .gate: score += 100
                case .hook: score += 75
                case .bend: score += 40
                case .pod: score += 20
                }

                scoredMoves.append((move, score))
            }
        }

        scoredMoves.sort { $0.1 > $1.1 }
        return scoredMoves.first?.0 ?? lockMoves.first!
    }

    /// Find a basic opponent win block (for Easy AI)
    private func findBasicOpponentWinBlock(validMoves: [Move], state: GameState) -> Move? {
        let opponent = player.opponent
        let opponentPatterns = evaluator.patternDetector.detectPatterns(on: state.board, for: opponent, unlockedOnly: true)

        // Look for near-wins (cross or long line)
        for pattern in opponentPatterns {
            if pattern.type == .cross || (pattern.type == .line && pattern.positions.count >= 4) {
                // Find a capture or disruptive move
                for move in validMoves {
                    if case .shift(_, let to) = move.type {
                        if pattern.positions.contains(to) {
                            if let targetStone = state.board.stone(at: to), targetStone.owner == opponent {
                                return move  // Capture disrupts the pattern
                            }
                        }
                    }
                }
            }
        }

        return nil
    }

    /// Find a capture that disrupts opponent patterns (for Easy AI)
    private func findBasicGoodCapture(captureMoves: [Move], state: GameState) -> Move? {
        let opponent = player.opponent
        let opponentPatterns = evaluator.patternDetector.detectPatterns(on: state.board, for: opponent, unlockedOnly: true)

        if opponentPatterns.isEmpty {
            return nil
        }

        // Prefer captures that hit pattern stones
        for move in captureMoves {
            if case .shift(_, let to) = move.type {
                for pattern in opponentPatterns {
                    if pattern.positions.contains(to) {
                        return move
                    }
                }
            }
        }

        return nil
    }

    /// Select a reasonable (non-random) move as fallback
    private func selectReasonableMove(validMoves: [Move], state: GameState) -> Move {
        // Filter out passes unless necessary
        let nonPassMoves = validMoves.filter { if case .pass = $0.type { return false }; return true }

        guard !nonPassMoves.isEmpty else {
            return validMoves.randomElement()!
        }

        // Prefer drops over shifts (building presence)
        let dropMoves = nonPassMoves.filter { if case .drop = $0.type { return true }; return false }
        let shiftMoves = nonPassMoves.filter { if case .shift = $0.type { return true }; return false }

        // Evaluate drops by position value
        var scoredDrops: [(Move, Int)] = []
        for move in dropMoves {
            if case .drop(let pos) = move.type {
                var score = 0
                // Center preference
                if pos.column >= 2 && pos.column <= 3 && pos.row >= 2 && pos.row <= 3 {
                    score += 30
                } else if pos.column >= 1 && pos.column <= 4 && pos.row >= 1 && pos.row <= 4 {
                    score += 15
                }
                // Adjacency bonus (near own stones)
                for neighbor in pos.orthogonalNeighbors {
                    if let stone = state.board.stone(at: neighbor), stone.owner == player {
                        score += 10
                    }
                }
                scoredDrops.append((move, score))
            }
        }

        if !scoredDrops.isEmpty {
            scoredDrops.sort { $0.1 > $1.1 }
            // Pick from top 3 with some randomness
            let topMoves = Array(scoredDrops.prefix(min(3, scoredDrops.count)))
            return topMoves.randomElement()?.0 ?? scoredDrops[0].0
        }

        if !shiftMoves.isEmpty {
            return shiftMoves.randomElement()!
        }

        return nonPassMoves.randomElement()!
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
        // Hard: Strong AI - deep search, full threat analysis, positional play, CUTTHROAT

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

        // CUTTHROAT: Aggressive pattern disruption captures
        if let aggressiveCapture = findAggressiveCapture(validMoves: validMoves, state: state) {
            return aggressiveCapture
        }

        // Block opponent threats
        if let threatBlock = findThreatBlockingMove(validMoves: validMoves, state: state) {
            return threatBlock
        }

        // Use break strategically if opponent is close to winning
        if let breakMove = findStrategicBreak(validMoves: validMoves, state: state) {
            return breakMove
        }

        // CUTTHROAT: Deny river stones when advantageous
        if let riverDeny = findRiverDenialMove(validMoves: validMoves, state: state) {
            return riverDeny
        }

        // Order moves with killer move heuristic (top 15 for deeper search)
        let orderedMoves = Array(orderMovesAdvanced(validMoves, state: state).prefix(15))

        // Use minimax with depth 4 (challenging)
        return await selectMinimaxMove(validMoves: orderedMoves, state: state, depth: 4)
    }

    // MARK: - Expert: Master level - optimal play with deep analysis

    private func selectExpertMove(validMoves: [Move], state: GameState) async -> Move {
        // Expert: Very strong AI - deep search, full threat analysis, positional mastery, RUTHLESS

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

        // CUTTHROAT: Hunt down opponent patterns aggressively
        if let huntMove = findPatternHuntingMove(validMoves: validMoves, state: state) {
            return huntMove
        }

        // CUTTHROAT: Aggressive captures to dominate material
        if let aggressiveCapture = findAggressiveCapture(validMoves: validMoves, state: state) {
            return aggressiveCapture
        }

        // Block opponent near-wins (one move away from victory)
        if let threatBlock = findThreatBlockingMove(validMoves: validMoves, state: state) {
            return threatBlock
        }

        // Look for forcing moves (moves that create multiple threats)
        if let forcingMove = findForcingMove(validMoves: validMoves, state: state) {
            return forcingMove
        }

        // CUTTHROAT: Elimination pressure - drive opponent toward elimination
        if let eliminationPressure = findEliminationPressureMove(validMoves: validMoves, state: state) {
            return eliminationPressure
        }

        // Use break aggressively to disrupt any locked patterns
        if let breakMove = findAggressiveBreak(validMoves: validMoves, state: state) {
            return breakMove
        }

        // Deny river when opponent needs it
        if let riverDeny = findRiverDenialMove(validMoves: validMoves, state: state) {
            return riverDeny
        }

        // Order moves with advanced heuristics (top 18 for deep search)
        let orderedMoves = Array(orderMovesAdvanced(validMoves, state: state).prefix(18))

        // Use minimax with depth 5 (very challenging)
        return await selectMinimaxMove(validMoves: orderedMoves, state: state, depth: 5)
    }

    // MARK: - Master: Near-perfect play with comprehensive analysis

    private func selectMasterMove(validMoves: [Move], state: GameState) async -> Move {
        // Master: Near-perfect AI - ABSOLUTELY RUTHLESS, shows no mercy, exploits every weakness

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

        // RUTHLESS: Maximum aggression - hunt and destroy all enemy patterns
        if let huntMove = findPatternHuntingMove(validMoves: validMoves, state: state) {
            return huntMove
        }

        // RUTHLESS: Multiple threat creation
        if let forcingMove = findForcingMove(validMoves: validMoves, state: state) {
            return forcingMove
        }

        // RUTHLESS: Aggressive multi-capture setup
        if let multiCapture = findMultiCaptureSetup(validMoves: validMoves, state: state) {
            return multiCapture
        }

        // RUTHLESS: Suffocation strategy - cut off opponent options
        if let suffocateMove = findSuffocationMove(validMoves: validMoves, state: state) {
            return suffocateMove
        }

        // RUTHLESS: Drive toward elimination when possible
        if let eliminationPressure = findEliminationPressureMove(validMoves: validMoves, state: state) {
            return eliminationPressure
        }

        // Block all threats comprehensively
        if let threatBlock = findThreatBlockingMove(validMoves: validMoves, state: state) {
            return threatBlock
        }

        // Aggressive captures
        if let aggressiveCapture = findAggressiveCapture(validMoves: validMoves, state: state) {
            return aggressiveCapture
        }

        // Use break aggressively - break ANY pattern that could help opponent
        if let breakMove = findAggressiveBreak(validMoves: validMoves, state: state) {
            return breakMove
        }

        // Evaluate long-term positional domination
        if let positionalMove = findBestPositionalMove(validMoves: validMoves, state: state) {
            return positionalMove
        }

        // River denial
        if let riverDeny = findRiverDenialMove(validMoves: validMoves, state: state) {
            return riverDeny
        }

        // Order all moves with comprehensive heuristics (evaluate more moves)
        let orderedMoves = Array(orderMovesAdvanced(validMoves, state: state).prefix(20))

        // Use minimax with depth 6 (maximum challenge)
        return await selectMinimaxMove(validMoves: orderedMoves, state: state, depth: 6)
    }

    // MARK: - Cutthroat Tactical Methods

    /// Find captures that aggressively disrupt opponent's patterns
    private func findAggressiveCapture(validMoves: [Move], state: GameState) -> Move? {
        let captureMoves = validMoves.filter { move in
            if case .shift(_, let to) = move.type {
                if let stone = state.board.stone(at: to), stone.owner == player.opponent, !stone.isLocked {
                    return true
                }
            }
            return false
        }

        guard !captureMoves.isEmpty else { return nil }

        // Score each capture by how much it disrupts opponent
        var bestCapture: Move?
        var bestScore = 0.0

        let opponentPatterns = evaluator.patternDetector.detectPatterns(
            on: state.board, for: player.opponent, unlockedOnly: true
        )

        for move in captureMoves {
            if case .shift(_, let to) = move.type {
                var score = 50.0 // Base capture value

                // Huge bonus for capturing stone that's part of a pattern
                for pattern in opponentPatterns {
                    if pattern.positions.contains(to) {
                        switch pattern.type {
                        case .cross:
                            score += 500.0 // Prevent potential instant win
                        case .line:
                            score += Double(pattern.positions.count) * 60.0
                        case .gate:
                            score += 150.0
                        case .bend:
                            score += 80.0
                        case .pod:
                            score += 40.0
                        case .hook:
                            score += 100.0 // Hooks are part of The Pincer
                        }
                    }
                }

                // Bonus for captures that also create our own patterns
                let result = rulesEngine.executeMove(move, on: state)
                if result.success {
                    let newPatterns = evaluator.patternDetector.detectPatterns(
                        on: result.newState.board, for: player, unlockedOnly: true
                    )
                    score += Double(newPatterns.count) * 30.0
                }

                // Bonus for captures near center (strategic position)
                if to.column >= 2 && to.column <= 3 && to.row >= 2 && to.row <= 3 {
                    score += 25.0
                }

                if score > bestScore {
                    bestScore = score
                    bestCapture = move
                }
            }
        }

        // Only return if significantly valuable
        return bestScore > 100.0 ? bestCapture : nil
    }

    /// Hunt down and destroy opponent patterns aggressively
    private func findPatternHuntingMove(validMoves: [Move], state: GameState) -> Move? {
        let opponentPatterns = evaluator.patternDetector.detectPatterns(
            on: state.board, for: player.opponent, unlockedOnly: true
        )

        guard !opponentPatterns.isEmpty else { return nil }

        // Prioritize patterns by threat level
        var targetPositions: [(Position, Double)] = []

        for pattern in opponentPatterns {
            var threatValue = 0.0
            switch pattern.type {
            case .cross:
                threatValue = 1000.0 // Must destroy
            case .line:
                threatValue = Double(pattern.positions.count) * 100.0
                if pattern.positions.count >= 4 { threatValue += 300.0 } // Near Long Road
            case .gate:
                threatValue = 200.0
            case .bend:
                threatValue = 100.0
            case .pod:
                threatValue = 50.0
            case .hook:
                threatValue = 150.0 // Part of The Pincer
            }

            for pos in pattern.positions {
                targetPositions.append((pos, threatValue))
            }
        }

        // Find moves that can capture these high-value targets
        var bestMove: Move?
        var bestValue = 0.0

        for move in validMoves {
            if case .shift(_, let to) = move.type {
                if let stone = state.board.stone(at: to), stone.owner == player.opponent, !stone.isLocked {
                    let value = targetPositions.filter { $0.0 == to }.map { $0.1 }.reduce(0, +)
                    if value > bestValue {
                        bestValue = value
                        bestMove = move
                    }
                }
            }
        }

        return bestValue > 150.0 ? bestMove : nil
    }

    /// Find moves that pressure opponent toward elimination
    private func findEliminationPressureMove(validMoves: [Move], state: GameState) -> Move? {
        let opponentRiver = state.river(for: player.opponent).count
        let opponentHand = player.opponent == .light ? state.lightStonesInHand : state.darkStonesInHand
        let opponentReserves = opponentRiver + opponentHand

        // Only apply pressure if opponent is getting low
        guard opponentReserves <= 5 else { return nil }

        // Look for captures that push them closer to elimination
        var bestMove: Move?
        var bestPressure = 0.0

        for move in validMoves {
            let result = rulesEngine.executeMove(move, on: state)
            if result.success {
                let newOpponentRiver = result.newState.river(for: player.opponent).count
                let newOpponentHand = player.opponent == .light
                    ? result.newState.lightStonesInHand
                    : result.newState.darkStonesInHand
                let newReserves = newOpponentRiver + newOpponentHand

                // Big bonus for reducing their reserves
                let pressureScore = Double(opponentReserves - newReserves) * 100.0

                // Huge bonus if this could lead to elimination
                if newReserves <= 2 {
                    if pressureScore > bestPressure {
                        bestPressure = pressureScore + 500.0
                        bestMove = move
                    }
                } else if pressureScore > bestPressure {
                    bestPressure = pressureScore
                    bestMove = move
                }
            }
        }

        return bestPressure > 50.0 ? bestMove : nil
    }

    /// Draw from river to deny opponent stones
    private func findRiverDenialMove(validMoves: [Move], state: GameState) -> Move? {
        let riverMoves = validMoves.filter { if case .drawFromRiver = $0.type { return true }; return false }
        guard let riverMove = riverMoves.first else { return nil }

        // Check if opponent might want river stones
        let opponentHand = player.opponent == .light ? state.lightStonesInHand : state.darkStonesInHand
        let myHand = state.currentPlayerStonesInHand
        let riverCount = state.river(for: player).count

        // Deny if:
        // 1. Opponent is low on stones (needs river)
        // 2. We have good material advantage (can afford to take)
        // 3. River has multiple stones we could use

        if opponentHand <= 3 && riverCount >= 1 {
            return riverMove // Deny them resources
        }

        if myHand <= 4 && riverCount >= 2 {
            return riverMove // We need stones too
        }

        // Strategic denial when we're ahead
        let myTotal = state.board.allPositions(for: player).count + myHand
        let oppTotal = state.board.allPositions(for: player.opponent).count + opponentHand
        if myTotal > oppTotal + 2 && riverCount >= 1 {
            return riverMove // Maintain advantage
        }

        return nil
    }

    /// Aggressively break any opponent locked pattern
    private func findAggressiveBreak(validMoves: [Move], state: GameState) -> Move? {
        let breakMoves = validMoves.filter { if case .breakLock = $0.type { return true }; return false }
        guard !breakMoves.isEmpty else { return nil }

        let oppLockedPatterns = state.lockedPatterns(for: player.opponent)
        guard !oppLockedPatterns.isEmpty else { return nil }

        // Score each break target
        var bestBreak: Move?
        var bestValue = 0.0

        for move in breakMoves {
            if case .breakLock(_, let targetPos) = move.type {
                for pattern in oppLockedPatterns {
                    if pattern.positions.contains(targetPos) {
                        var value = 0.0

                        // Value based on pattern type
                        switch pattern.type {
                        case .cross:
                            value = 1000.0
                        case .line:
                            value = Double(pattern.positions.count) * 80.0
                        case .gate:
                            value = 200.0
                        case .bend:
                            value = 100.0
                        case .pod:
                            value = 50.0
                        case .hook:
                            value = 120.0 // Part of The Pincer
                        }

                        // Bonus if this disrupts their victory path
                        let lockedLines = oppLockedPatterns.filter { $0.type == .line }.count
                        let lockedGates = oppLockedPatterns.filter { $0.type == .gate }.count
                        let lockedBends = oppLockedPatterns.filter { $0.type == .bend }.count

                        if pattern.type == .line && lockedLines >= 1 { value += 150.0 }
                        if pattern.type == .gate && lockedGates >= 1 { value += 150.0 }
                        if pattern.type == .gate && lockedLines >= 1 { value += 100.0 }
                        if pattern.type == .bend && lockedBends >= 2 { value += 150.0 }

                        if value > bestValue {
                            bestValue = value
                            bestBreak = move
                        }
                        break
                    }
                }
            }
        }

        // Always break if opponent has any significant locked pattern
        return bestValue > 80.0 ? bestBreak : nil
    }

    /// Set up positions to capture multiple stones
    private func findMultiCaptureSetup(validMoves: [Move], state: GameState) -> Move? {
        var bestMove: Move?
        var bestPotential = 0

        for move in validMoves {
            let result = rulesEngine.executeMove(move, on: state)
            if result.success {
                // Count how many captures we can make next turn
                let nextMoves = rulesEngine.validMoves(for: result.newState)
                var captureCount = 0

                for nextMove in nextMoves {
                    if case .shift(_, let to) = nextMove.type {
                        if let stone = result.newState.board.stone(at: to),
                           stone.owner == player.opponent, !stone.isLocked {
                            captureCount += 1
                        }
                    }
                }

                if captureCount > bestPotential {
                    bestPotential = captureCount
                    bestMove = move
                }
            }
        }

        return bestPotential >= 3 ? bestMove : nil
    }

    /// Restrict opponent's movement options (suffocation)
    private func findSuffocationMove(validMoves: [Move], state: GameState) -> Move? {
        var bestMove: Move?
        var bestReduction = 0

        let currentOppMoves = rulesEngine.moveValidator.validMoves(for: player.opponent, state: simulatePassTurn(state)).count

        for move in validMoves {
            let result = rulesEngine.executeMove(move, on: state)
            if result.success {
                // Simulate opponent's turn after our move
                var nextState = result.newState
                nextState.advanceTurn()
                let newOppMoves = rulesEngine.moveValidator.validMoves(for: player.opponent, state: nextState).count

                let reduction = currentOppMoves - newOppMoves

                if reduction > bestReduction {
                    bestReduction = reduction
                    bestMove = move
                }
            }
        }

        // Only use if we significantly reduce their options
        return bestReduction >= 5 ? bestMove : nil
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

        let hooks = lockedPatterns.filter { $0.type == .hook }
        let crosses = lockedPatterns.filter { $0.type == .cross }

        switch pattern.type {
        case .cross:
            return true // Instant win
        case .line:
            if pattern.positions.count >= 5 { return true } // Long Road
            if lines.count >= 1 { return true } // Twin Rivers
            if gates.count >= 1 { return true } // Gate & Path
            if bends.count >= 2 { return true } // The Serpent (2 bends + 1 line)
            return false
        case .gate:
            if gates.count >= 1 { return true } // Fortress
            if gates.count >= 2 { return true } // The Constellation (3 gates)
            if lines.count >= 1 { return true } // Gate & Path
            if crosses.count >= 1 { return true } // The Phalanx (gate + cross)
            return false
        case .bend:
            if bends.count >= 2 { return true } // Three Bends
            if bends.count >= 1 && lines.count >= 1 { return true } // The Serpent progress
            return false
        case .pod:
            return false // Pod isn't part of victory sets
        case .hook:
            if hooks.count >= 1 { return true } // The Pincer (2 hooks)
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
                            let oppHooks = oppLockedPatterns.filter { $0.type == .hook }
                            switch pattern.type {
                            case .line:
                                value += Double(pattern.positions.count) * 50.0
                                if oppLines.count >= 1 { value += 200.0 } // Would complete Twin Rivers
                                if oppGates.count >= 1 { value += 150.0 } // Would complete Gate & Path
                                if oppBends.count >= 2 { value += 150.0 } // Would complete The Serpent
                            case .gate:
                                value += 150.0
                                if oppGates.count >= 1 { value += 200.0 } // Would complete Fortress
                                if oppGates.count >= 2 { value += 250.0 } // Would complete Constellation
                                if oppLines.count >= 1 { value += 150.0 } // Would complete Gate & Path
                            case .bend:
                                value += 80.0
                                if oppBends.count >= 2 { value += 200.0 } // Would complete Three Bends
                                if oppBends.count >= 1 && oppLines.count >= 1 { value += 100.0 } // Serpent progress
                            case .cross:
                                value += 500.0 // Breaking a near-cross is critical
                            case .pod:
                                value += 30.0
                            case .hook:
                                value += 100.0
                                if oppHooks.count >= 1 { value += 200.0 } // Would complete The Pincer
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

            case .pod:
                score += 30.0 // Minor pattern, not part of victory sets

            case .hook:
                let lockedHooks = myLockedPatterns.filter { $0.type == .hook }
                score += 60.0
                // Bonus if working toward The Pincer (2 hooks)
                if lockedHooks.count >= 1 {
                    let wouldBeNonOverlapping = lockedHooks.allSatisfy { !patternsOverlap($0.positions, info.positions) }
                    if wouldBeNonOverlapping {
                        score += 200.0 // Would complete The Pincer!
                    }
                }
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

// MARK: - Story Mode AI

extension AIPlayer {

    /// Select a move based on story character personality
    /// Each opponent has unique behaviors that match their character
    public func selectMoveForStory(state: GameState, personality: StoryAIPersonality, lastPlayerMoveType: MoveType? = nil) async -> Move? {
        guard state.currentPlayer == player && !state.isGameOver else { return nil }

        let config = personality.config
        let validMoves = rulesEngine.validMoves(for: state)
        guard !validMoves.isEmpty else { return nil }

        // Categorize moves
        let lockMoves = validMoves.filter { if case .lock = $0.type { return true }; return false }
        let captureMoves = validMoves.filter { move in
            if case .shift(_, let to) = move.type {
                return state.board.stone(at: to) != nil
            }
            return false
        }
        let breakMoves = validMoves.filter { if case .breakLock = $0.type { return true }; return false }
        let riverMoves = validMoves.filter { if case .drawFromRiver = $0.type { return true }; return false }
        let dropMoves = validMoves.filter { if case .drop = $0.type { return true }; return false }

        // ═══════════════════════════════════════════════════════════════════
        // CHAOS FACTOR: Random "genius" moves (Twins specialty)
        // ═══════════════════════════════════════════════════════════════════
        if config.chaosFactor > 0 && Double.random(in: 0...1) < config.chaosFactor {
            // Make a random but not terrible move
            let nonPassMoves = validMoves.filter { if case .pass = $0.type { return false }; return true }
            if !nonPassMoves.isEmpty {
                return nonPassMoves.randomElement()!
            }
        }

        // ═══════════════════════════════════════════════════════════════════
        // MIRROR PLAY: Copy player's move type (Twins specialty)
        // ═══════════════════════════════════════════════════════════════════
        if config.mirrorChance > 0 && Double.random(in: 0...1) < config.mirrorChance {
            if let lastMove = lastPlayerMoveType {
                if let mirrored = findMirrorMove(lastMoveType: lastMove, validMoves: validMoves, state: state) {
                    return mirrored
                }
            }
        }

        // ═══════════════════════════════════════════════════════════════════
        // ALWAYS: Check for immediate wins
        // ═══════════════════════════════════════════════════════════════════
        if !lockMoves.isEmpty {
            for lockMove in lockMoves {
                let result = rulesEngine.executeMove(lockMove, on: state)
                if result.victoryResult.hasWinner && result.victoryResult.winner == player {
                    // Ishara's hesitation - gives player ONE chance
                    if config.hesitationOnKillingBlow && Double.random(in: 0...1) < 0.15 {
                        // Don't take the winning move yet
                    } else {
                        return lockMove
                    }
                }
            }
        }

        // Check other instant wins
        for move in validMoves {
            let result = rulesEngine.executeMove(move, on: state)
            if result.victoryResult.hasWinner && result.victoryResult.winner == player {
                if config.hesitationOnKillingBlow && Double.random(in: 0...1) < 0.15 {
                    // Skip this one chance
                } else {
                    return move
                }
            }
        }

        // ═══════════════════════════════════════════════════════════════════
        // THREAT AWARENESS: Block opponent wins (based on awareness)
        // ═══════════════════════════════════════════════════════════════════
        if Double.random(in: 0...1) < config.threatAwareness {
            if let blockMove = findOpponentWinBlock(validMoves: validMoves, state: state) {
                return blockMove
            }
        }

        // ═══════════════════════════════════════════════════════════════════
        // DESPERATION AGGRESSION (Viktor specialty)
        // ═══════════════════════════════════════════════════════════════════
        if config.desperationAggression {
            let myMaterial = state.board.allPositions(for: player).count + (player == .light ? state.lightStonesInHand : state.darkStonesInHand)
            let oppMaterial = state.board.allPositions(for: player.opponent).count + (player.opponent == .light ? state.lightStonesInHand : state.darkStonesInHand)

            if myMaterial < oppMaterial - 2 {
                // Behind on material - get aggressive!
                if let aggressiveCapture = findAggressiveCapture(validMoves: validMoves, state: state) {
                    return aggressiveCapture
                }
            }
        }

        // ═══════════════════════════════════════════════════════════════════
        // CENTER OBSESSION (Marcus specialty)
        // ═══════════════════════════════════════════════════════════════════
        if config.centerObsession {
            if let centerMove = findCenterMove(dropMoves: dropMoves, state: state) {
                return centerMove
            }
        }

        // ═══════════════════════════════════════════════════════════════════
        // PATTERN PREFERENCE (based on character)
        // ═══════════════════════════════════════════════════════════════════
        if let preferredType = config.patternPreference, !lockMoves.isEmpty {
            let preferredLocks = lockMoves.filter { move in
                if case .lock(_, let positions) = move.type {
                    let patternType = inferPatternType(positions: positions)
                    return patternType == preferredType
                }
                return false
            }
            if !preferredLocks.isEmpty && Double.random(in: 0...1) < 0.7 {
                return preferredLocks.randomElement()!
            }
        }

        // ═══════════════════════════════════════════════════════════════════
        // AGGRESSION vs DEFENSE
        // ═══════════════════════════════════════════════════════════════════
        let isAggressive = Double.random(in: 0...1) < config.aggressionBias

        if isAggressive {
            // Offensive play
            if !lockMoves.isEmpty {
                if let strategicLock = selectStrategicLockForPersonality(lockMoves: lockMoves, state: state, config: config) {
                    return strategicLock
                }
            }

            if !captureMoves.isEmpty {
                if let capture = findAggressiveCapture(validMoves: validMoves, state: state) {
                    return capture
                }
                return captureMoves.randomElement()!
            }

            // Pattern hunting (if enabled)
            if config.useTrapMoves {
                if let huntMove = findPatternHuntingMove(validMoves: validMoves, state: state) {
                    return huntMove
                }
            }
        } else {
            // Defensive play
            if Double.random(in: 0...1) < config.threatAwareness {
                if let threatBlock = findThreatBlockingMove(validMoves: validMoves, state: state) {
                    return threatBlock
                }
            }

            // Build patterns defensively
            if !lockMoves.isEmpty {
                let gateLocks = lockMoves.filter { move in
                    if case .lock(_, let positions) = move.type {
                        return inferPatternType(positions: positions) == .gate
                    }
                    return false
                }
                if !gateLocks.isEmpty {
                    return gateLocks.randomElement()!
                }
            }
        }

        // ═══════════════════════════════════════════════════════════════════
        // BREAKS (based on personality)
        // ═══════════════════════════════════════════════════════════════════
        if config.useBreaks && !config.neverBreaksPatterns && !breakMoves.isEmpty {
            if let breakMove = findAggressiveBreak(validMoves: validMoves, state: state) {
                return breakMove
            }
        }

        // ═══════════════════════════════════════════════════════════════════
        // TRAP MOVES (Elias, Amara specialty)
        // ═══════════════════════════════════════════════════════════════════
        if config.useTrapMoves {
            if let forcingMove = findForcingMove(validMoves: validMoves, state: state) {
                return forcingMove
            }
        }

        // ═══════════════════════════════════════════════════════════════════
        // SUFFOCATION (Ghost, Grandmaster specialty)
        // ═══════════════════════════════════════════════════════════════════
        if config.useSuffocation {
            if let suffocateMove = findSuffocationMove(validMoves: validMoves, state: state) {
                return suffocateMove
            }
        }

        // ═══════════════════════════════════════════════════════════════════
        // RIVER DENIAL
        // ═══════════════════════════════════════════════════════════════════
        if config.useRiverDenial {
            if let riverDeny = findRiverDenialMove(validMoves: validMoves, state: state) {
                return riverDeny
            }
        }

        // ═══════════════════════════════════════════════════════════════════
        // ADAPTIVE STRATEGY (Amara specialty)
        // ═══════════════════════════════════════════════════════════════════
        if config.adaptiveness > 0.5 && state.moveHistory.count > 10 {
            // After 10 moves, try to counter player's strategy
            if let counterMove = findCounterStrategyMove(validMoves: validMoves, state: state) {
                return counterMove
            }
        }

        // ═══════════════════════════════════════════════════════════════════
        // FALL BACK TO MINIMAX
        // ═══════════════════════════════════════════════════════════════════
        let orderedMoves = Array(orderMovesAdvanced(validMoves, state: state).prefix(config.movesToEvaluate))
        return await selectMinimaxMove(validMoves: orderedMoves, state: state, depth: config.minimaxDepth)
    }

    // MARK: - Personality-Specific Helpers

    /// Find a move that mirrors the player's last move type
    private func findMirrorMove(lastMoveType: MoveType, validMoves: [Move], state: GameState) -> Move? {
        switch lastMoveType {
        case .drop:
            let drops = validMoves.filter { if case .drop = $0.type { return true }; return false }
            return drops.randomElement()
        case .shift:
            let shifts = validMoves.filter { if case .shift = $0.type { return true }; return false }
            return shifts.randomElement()
        case .lock:
            let locks = validMoves.filter { if case .lock = $0.type { return true }; return false }
            return locks.randomElement()
        case .drawFromRiver:
            let rivers = validMoves.filter { if case .drawFromRiver = $0.type { return true }; return false }
            return rivers.first
        case .breakLock:
            let breaks = validMoves.filter { if case .breakLock = $0.type { return true }; return false }
            return breaks.randomElement()
        case .pass:
            return nil // Don't mirror passes
        }
    }

    /// Find a move to the center of the board (Marcus obsession)
    private func findCenterMove(dropMoves: [Move], state: GameState) -> Move? {
        let centerPositions = [
            Position(column: 2, row: 2),
            Position(column: 2, row: 3),
            Position(column: 3, row: 2),
            Position(column: 3, row: 3)
        ]

        for pos in centerPositions {
            if state.board.stone(at: pos) == nil {
                for move in dropMoves {
                    if case .drop(let dropPos) = move.type, dropPos == pos {
                        return move
                    }
                }
            }
        }
        return nil
    }

    /// Select strategic lock based on personality preferences
    private func selectStrategicLockForPersonality(lockMoves: [Move], state: GameState, config: StoryAIConfig) -> Move? {
        guard !lockMoves.isEmpty else { return nil }

        // If we have a signature victory, prioritize that
        if let signature = config.signatureVictory {
            let myLocked = state.lockedPatterns(for: player)

            switch signature {
            case .theLongRoad:
                // Look for 4+ length lines
                for move in lockMoves {
                    if case .lock(_, let positions) = move.type, positions.count >= 4 {
                        if inferPatternType(positions: positions) == .line {
                            return move
                        }
                    }
                }

            case .theStar:
                // Look for cross patterns
                for move in lockMoves {
                    if case .lock(_, let positions) = move.type {
                        if inferPatternType(positions: positions) == .cross {
                            return move
                        }
                    }
                }

            case .twinRivers:
                // Look for lines, prefer non-overlapping with existing
                let existingLines = myLocked.filter { $0.type == .line }
                for move in lockMoves {
                    if case .lock(_, let positions) = move.type {
                        if inferPatternType(positions: positions) == .line {
                            let wouldOverlap = existingLines.contains { !$0.positions.isDisjoint(with: positions) }
                            if !wouldOverlap {
                                return move
                            }
                        }
                    }
                }

            case .theFortress:
                // Look for gates
                for move in lockMoves {
                    if case .lock(_, let positions) = move.type {
                        if inferPatternType(positions: positions) == .gate {
                            return move
                        }
                    }
                }

            case .gateAndPath, .threeBends:
                // Use standard selection
                break

            case .thePhalanx:
                // Look for gate + cross combo
                for move in lockMoves {
                    if case .lock(_, let positions) = move.type {
                        let type = inferPatternType(positions: positions)
                        if type == .gate || type == .cross {
                            return move
                        }
                    }
                }

            case .thePincer:
                // Look for hooks
                for move in lockMoves {
                    if case .lock(_, let positions) = move.type {
                        if inferPatternType(positions: positions) == .hook {
                            return move
                        }
                    }
                }

            case .theSerpent:
                // Look for bends and lines
                for move in lockMoves {
                    if case .lock(_, let positions) = move.type {
                        let type = inferPatternType(positions: positions)
                        if type == .bend || type == .line {
                            return move
                        }
                    }
                }

            case .theConstellation:
                // Look for gates (need 3)
                for move in lockMoves {
                    if case .lock(_, let positions) = move.type {
                        if inferPatternType(positions: positions) == .gate {
                            return move
                        }
                    }
                }
            }
        }

        // Fall back to standard strategic lock
        return selectStrategicLock(lockMoves: lockMoves, state: state)
    }

    /// Find a move that counters the player's apparent strategy (Amara)
    private func findCounterStrategyMove(validMoves: [Move], state: GameState) -> Move? {
        // Analyze player's locked patterns to determine their strategy
        let playerLocked = state.lockedPatterns(for: player.opponent)
        let playerLines = playerLocked.filter { $0.type == .line }
        let playerGates = playerLocked.filter { $0.type == .gate }
        let playerBends = playerLocked.filter { $0.type == .bend }

        // Determine likely player strategy
        if playerLines.count >= 1 {
            // Player going for Twin Rivers or Long Road - block lines!
            if let blockMove = findThreatBlockingMove(validMoves: validMoves, state: state) {
                return blockMove
            }
            // Or break their lines
            if let breakMove = findAggressiveBreak(validMoves: validMoves, state: state) {
                return breakMove
            }
        }

        if playerGates.count >= 1 {
            // Player going for Fortress or Gate & Path - break gates!
            let breakMoves = validMoves.filter { if case .breakLock = $0.type { return true }; return false }
            for move in breakMoves {
                if case .breakLock(_, let targetPos) = move.type {
                    for gate in playerGates {
                        if gate.positions.contains(targetPos) {
                            return move
                        }
                    }
                }
            }
        }

        if playerBends.count >= 2 {
            // Player going for Three Bends - break bends!
            let breakMoves = validMoves.filter { if case .breakLock = $0.type { return true }; return false }
            for move in breakMoves {
                if case .breakLock(_, let targetPos) = move.type {
                    for bend in playerBends {
                        if bend.positions.contains(targetPos) {
                            return move
                        }
                    }
                }
            }
        }

        return nil
    }
}

// MARK: - Story Mode Game Controller Extension

@MainActor
public extension GameController {

    /// Execute AI move with story personality
    func executeStoryAIMove(personality: StoryAIPersonality, lastPlayerMoveType: MoveType? = nil) async {
        guard state.currentPlayer == .dark && !state.isGameOver else { return }

        let ai = AIPlayer(difficulty: personality.config.baseDifficulty, player: .dark)

        if let move = await ai.selectMoveForStory(state: state, personality: personality, lastPlayerMoveType: lastPlayerMoveType) {
            // Add delay for UX
            try? await Task.sleep(nanoseconds: 500_000_000)

            guard state.currentPlayer == .dark && !state.isGameOver else { return }

            // Validate move is still valid
            let validation = RulesEngine().moveValidator.validate(move, state: state)
            guard validation.isValid else {
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
                    performPass()
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
