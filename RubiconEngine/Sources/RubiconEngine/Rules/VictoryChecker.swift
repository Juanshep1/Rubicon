import Foundation

public struct VictoryCheckResult: Sendable, Equatable {
    public let hasWinner: Bool
    public let winner: Player?
    public let victorySet: VictorySetType?
    public let winningPatterns: [Pattern]
    public let isInstantWin: Bool
    public let isElimination: Bool

    public init(hasWinner: Bool = false, winner: Player? = nil, victorySet: VictorySetType? = nil,
                winningPatterns: [Pattern] = [], isInstantWin: Bool = false, isElimination: Bool = false) {
        self.hasWinner = hasWinner
        self.winner = winner
        self.victorySet = victorySet
        self.winningPatterns = winningPatterns
        self.isInstantWin = isInstantWin
        self.isElimination = isElimination
    }

    public static let noWinner = VictoryCheckResult()
}

public struct VictoryChecker: Sendable {
    private let patternDetector = PatternDetector()

    public init() {}

    public func checkVictory(state: GameState) -> VictoryCheckResult {
        // Check elimination first (Third Edition rule)
        // Elimination: player loses if their TOTAL stones <= 2
        // Total = Stones in Hand + Stones on Board (both locked and unlocked)
        // Note: River stones do NOT count (they're in the shared pool)
        for player in [Player.light, Player.dark] {
            let opponent = player.opponent

            let opponentStonesInHand = opponent == .light ? state.lightStonesInHand : state.darkStonesInHand
            let opponentStonesOnBoard = state.board.stoneCount(for: opponent)
            let opponentTotalStones = opponentStonesInHand + opponentStonesOnBoard

            // Elimination: opponent has 2 or fewer total stones (hand + board)
            if opponentTotalStones <= GameState.eliminationThreshold {
                return VictoryCheckResult(hasWinner: true, winner: player, isElimination: true)
            }
        }

        // Check instant wins and victory sets for both players
        for player in [Player.light, Player.dark] {
            if let result = checkVictoryForPlayer(player, state: state) {
                return result
            }
        }

        return .noWinner
    }

    private func checkVictoryForPlayer(_ player: Player, state: GameState) -> VictoryCheckResult? {
        let lockedPatterns = state.lockedPatterns(for: player)

        // Check for instant wins first (The Long Road - 5+ line, The Star - Cross)
        if let instantWin = checkInstantWins(lockedPatterns: lockedPatterns, player: player) {
            return instantWin
        }

        // Check for victory sets
        if let victorySet = checkVictorySets(lockedPatterns: lockedPatterns, player: player) {
            return victorySet
        }

        return nil
    }

    private func checkInstantWins(lockedPatterns: [Pattern], player: Player) -> VictoryCheckResult? {
        // The Long Road: 5+ stone line
        for pattern in lockedPatterns where pattern.type == .line && pattern.positions.count >= 5 {
            return VictoryCheckResult(
                hasWinner: true,
                winner: player,
                victorySet: .theLongRoad,
                winningPatterns: [pattern],
                isInstantWin: true
            )
        }

        // The Star: Cross pattern
        for pattern in lockedPatterns where pattern.type == .cross {
            return VictoryCheckResult(
                hasWinner: true,
                winner: player,
                victorySet: .theStar,
                winningPatterns: [pattern],
                isInstantWin: true
            )
        }

        return nil
    }

    private func checkVictorySets(lockedPatterns: [Pattern], player: Player) -> VictoryCheckResult? {
        let lines = lockedPatterns.filter { $0.type == .line }
        let bends = lockedPatterns.filter { $0.type == .bend }
        let gates = lockedPatterns.filter { $0.type == .gate }
        let crosses = lockedPatterns.filter { $0.type == .cross }
        let hooks = lockedPatterns.filter { $0.type == .hook }

        // Twin Rivers: 2 Lines (non-overlapping)
        if let twinRivers = findNonOverlappingPair(from: lines) {
            return VictoryCheckResult(
                hasWinner: true,
                winner: player,
                victorySet: .twinRivers,
                winningPatterns: [twinRivers.0, twinRivers.1]
            )
        }

        // Gate & Path: 1 Gate + 1 Line (non-overlapping)
        if let gateAndPath = findNonOverlappingPair(first: gates, second: lines) {
            return VictoryCheckResult(
                hasWinner: true,
                winner: player,
                victorySet: .gateAndPath,
                winningPatterns: [gateAndPath.0, gateAndPath.1]
            )
        }

        // Three Bends: 3 Bends (non-overlapping)
        if let threeBends = findNonOverlappingTriple(from: bends) {
            return VictoryCheckResult(
                hasWinner: true,
                winner: player,
                victorySet: .threeBends,
                winningPatterns: threeBends
            )
        }

        // The Fortress: 2 Gates (non-overlapping)
        if let fortress = findNonOverlappingPair(from: gates) {
            return VictoryCheckResult(
                hasWinner: true,
                winner: player,
                victorySet: .theFortress,
                winningPatterns: [fortress.0, fortress.1]
            )
        }

        // NEW VICTORY SETS (Third Edition)

        // The Phalanx: Gate + Cross (non-overlapping)
        if let phalanx = findNonOverlappingPair(first: gates, second: crosses) {
            return VictoryCheckResult(
                hasWinner: true,
                winner: player,
                victorySet: .thePhalanx,
                winningPatterns: [phalanx.0, phalanx.1]
            )
        }

        // The Pincer: 2 Hooks (non-overlapping)
        if let pincer = findNonOverlappingPair(from: hooks) {
            return VictoryCheckResult(
                hasWinner: true,
                winner: player,
                victorySet: .thePincer,
                winningPatterns: [pincer.0, pincer.1]
            )
        }

        // The Serpent: 2 Bends + 1 Line (all non-overlapping)
        if let serpent = findSerpent(bends: bends, lines: lines) {
            return VictoryCheckResult(
                hasWinner: true,
                winner: player,
                victorySet: .theSerpent,
                winningPatterns: serpent
            )
        }

        // The Constellation: 3 Gates (non-overlapping)
        if let constellation = findNonOverlappingTriple(from: gates) {
            return VictoryCheckResult(
                hasWinner: true,
                winner: player,
                victorySet: .theConstellation,
                winningPatterns: constellation
            )
        }

        return nil
    }

    // Helper for The Serpent: 2 Bends + 1 Line
    private func findSerpent(bends: [Pattern], lines: [Pattern]) -> [Pattern]? {
        guard bends.count >= 2 && lines.count >= 1 else { return nil }

        for i in 0..<bends.count {
            for j in (i + 1)..<bends.count {
                guard !patternsOverlap(bends[i], bends[j]) else { continue }
                for line in lines {
                    if !patternsOverlap(bends[i], line) && !patternsOverlap(bends[j], line) {
                        return [bends[i], bends[j], line]
                    }
                }
            }
        }
        return nil
    }

    private func findNonOverlappingPair(from patterns: [Pattern]) -> (Pattern, Pattern)? {
        guard patterns.count >= 2 else { return nil }

        for i in 0..<patterns.count {
            for j in (i + 1)..<patterns.count {
                if !patternsOverlap(patterns[i], patterns[j]) {
                    return (patterns[i], patterns[j])
                }
            }
        }
        return nil
    }

    private func findNonOverlappingPair(first: [Pattern], second: [Pattern]) -> (Pattern, Pattern)? {
        guard !first.isEmpty && !second.isEmpty else { return nil }

        for p1 in first {
            for p2 in second {
                if !patternsOverlap(p1, p2) {
                    return (p1, p2)
                }
            }
        }
        return nil
    }

    private func findNonOverlappingTriple(from patterns: [Pattern]) -> [Pattern]? {
        guard patterns.count >= 3 else { return nil }

        for i in 0..<patterns.count {
            for j in (i + 1)..<patterns.count {
                for k in (j + 1)..<patterns.count {
                    if !patternsOverlap(patterns[i], patterns[j]) &&
                       !patternsOverlap(patterns[i], patterns[k]) &&
                       !patternsOverlap(patterns[j], patterns[k]) {
                        return [patterns[i], patterns[j], patterns[k]]
                    }
                }
            }
        }
        return nil
    }

    private func patternsOverlap(_ p1: Pattern, _ p2: Pattern) -> Bool {
        !p1.positions.isDisjoint(with: p2.positions)
    }

    /// Get possible victory sets a player is working toward
    public func potentialVictorySets(for player: Player, state: GameState) -> [VictorySetType] {
        let lockedPatterns = state.lockedPatterns(for: player)
        var potential: [VictorySetType] = []

        let lines = lockedPatterns.filter { $0.type == .line }
        let bends = lockedPatterns.filter { $0.type == .bend }
        let gates = lockedPatterns.filter { $0.type == .gate }

        // Check progress toward each victory set
        if lines.count >= 1 { potential.append(.twinRivers) }
        if gates.count >= 1 || lines.count >= 1 { potential.append(.gateAndPath) }
        if bends.count >= 1 { potential.append(.threeBends) }
        if gates.count >= 1 { potential.append(.theFortress) }

        // Always potentially working toward instant wins
        potential.append(.theLongRoad)
        potential.append(.theStar)

        return potential
    }

    /// Calculate how close a player is to each victory condition (0.0 to 1.0)
    public func victoryProgress(for player: Player, state: GameState) -> [VictorySetType: Double] {
        let lockedPatterns = state.lockedPatterns(for: player)
        var progress: [VictorySetType: Double] = [:]

        let lines = lockedPatterns.filter { $0.type == .line }
        let bends = lockedPatterns.filter { $0.type == .bend }
        let gates = lockedPatterns.filter { $0.type == .gate }

        // Twin Rivers: need 2 non-overlapping lines
        progress[.twinRivers] = min(1.0, Double(lines.count) / 2.0)

        // Gate & Path: need 1 gate + 1 line
        let gateAndPathProgress = (gates.isEmpty ? 0 : 0.5) + (lines.isEmpty ? 0 : 0.5)
        progress[.gateAndPath] = gateAndPathProgress

        // Three Bends: need 3 non-overlapping bends
        progress[.threeBends] = min(1.0, Double(bends.count) / 3.0)

        // The Fortress: need 2 non-overlapping gates
        progress[.theFortress] = min(1.0, Double(gates.count) / 2.0)

        // The Long Road: need a 5+ line
        let maxLineLength = lines.map { $0.positions.count }.max() ?? 0
        progress[.theLongRoad] = min(1.0, Double(maxLineLength) / 5.0)

        // The Star: need a cross
        let hasCross = lockedPatterns.contains { $0.type == .cross }
        progress[.theStar] = hasCross ? 1.0 : 0.0

        return progress
    }
}
