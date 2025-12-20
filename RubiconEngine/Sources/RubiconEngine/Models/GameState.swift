import Foundation

public enum GameMode: Codable, Sendable, Equatable, Hashable {
    case localPassAndPlay
    case vsAI(difficulty: AIDifficulty)
    case onlineRanked, onlineCasual, puzzle, tutorial
}

public enum AIDifficulty: Int, Codable, CaseIterable, Sendable, Hashable {
    case beginner = 1, easy = 2, medium = 3, hard = 4, expert = 5, master = 6

    public var displayName: String {
        switch self {
        case .beginner: return "Beginner"
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        case .expert: return "Expert"
        case .master: return "Master"
        }
    }

    /// Get the next difficulty level (for ladder progression)
    public var next: AIDifficulty? {
        switch self {
        case .beginner: return .easy
        case .easy: return .medium
        case .medium: return .hard
        case .hard: return .expert
        case .expert: return .master
        case .master: return nil
        }
    }

    /// Get the previous difficulty level (for ladder demotion)
    public var previous: AIDifficulty? {
        switch self {
        case .beginner: return nil
        case .easy: return .beginner
        case .medium: return .easy
        case .hard: return .medium
        case .expert: return .hard
        case .master: return .expert
        }
    }
}

public struct GameState: Codable, Sendable, Equatable {
    public let id: UUID
    public var board: Board
    public var currentPlayer: Player
    public var lightStonesInHand: Int
    public var darkStonesInHand: Int
    // Separate rivers for each player - contains their own captured stones
    public var lightRiver: [Stone]
    public var darkRiver: [Stone]
    public var lightHasUsedBreak: Bool
    public var darkHasUsedBreak: Bool
    public var lockedPatterns: [Pattern]
    public var moveHistory: [Move]
    public var turnNumber: Int
    public var winner: Player?
    public var winCondition: VictorySetType?
    public var wonByElimination: Bool
    public var gameMode: GameMode
    public let startedAt: Date
    // Lock cooldown: positions that can't be locked this turn (after opponent breaks)
    public var lockCooldownPositions: Set<Position>
    public var lockCooldownPlayer: Player?
    // Pass limits: each player can only pass 3 times per game
    public var lightPassCount: Int
    public var darkPassCount: Int

    public static let startingStonesPerPlayer = 12
    public static let eliminationThreshold = 2
    public static let maxPassesPerPlayer = 3

    public init(id: UUID = UUID(), gameMode: GameMode = .localPassAndPlay, startingPlayer: Player = .light) {
        self.id = id
        self.board = Board()
        self.currentPlayer = startingPlayer
        self.lightStonesInHand = 12
        self.darkStonesInHand = 12
        self.lightRiver = []
        self.darkRiver = []
        self.lightHasUsedBreak = false
        self.darkHasUsedBreak = false
        self.lockedPatterns = []
        self.moveHistory = []
        self.turnNumber = 1
        self.winner = nil
        self.winCondition = nil
        self.wonByElimination = false
        self.gameMode = gameMode
        self.startedAt = Date()
        self.lockCooldownPositions = []
        self.lockCooldownPlayer = nil
        self.lightPassCount = 0
        self.darkPassCount = 0
    }

    public var isGameOver: Bool { winner != nil }
    public var currentPlayerStonesInHand: Int { currentPlayer == .light ? lightStonesInHand : darkStonesInHand }

    // River for a specific player (contains their captured stones they can reclaim)
    public func river(for player: Player) -> [Stone] {
        player == .light ? lightRiver : darkRiver
    }

    public var currentPlayerRiver: [Stone] {
        river(for: currentPlayer)
    }

    public func totalStones(for player: Player) -> Int {
        (player == .light ? lightStonesInHand : darkStonesInHand) + board.stoneCount(for: player)
    }

    public func canDrawFromRiver(player: Player) -> Bool {
        // Players can draw from river unlimited times (as long as river has stones)
        !river(for: player).isEmpty
    }

    public func canUseBreak(player: Player) -> Bool {
        let hasUsed = player == .light ? lightHasUsedBreak : darkHasUsedBreak
        return !hasUsed && board.lockedStoneCount(for: player) >= 2 && board.lockedStoneCount(for: player.opponent) > 0
    }

    public func passCount(for player: Player) -> Int {
        player == .light ? lightPassCount : darkPassCount
    }

    public func canPass(player: Player) -> Bool {
        passCount(for: player) < GameState.maxPassesPerPlayer
    }

    public func remainingPasses(for player: Player) -> Int {
        GameState.maxPassesPerPlayer - passCount(for: player)
    }

    public func lockedPatterns(for player: Player) -> [Pattern] {
        lockedPatterns.filter { $0.owner == player }
    }

    public mutating func decrementStonesInHand(for player: Player) {
        if player == .light { lightStonesInHand = max(0, lightStonesInHand - 1) }
        else { darkStonesInHand = max(0, darkStonesInHand - 1) }
    }

    public mutating func incrementStonesInHand(for player: Player) {
        if player == .light { lightStonesInHand += 1 } else { darkStonesInHand += 1 }
    }

    public mutating func markBreakUsed(for player: Player) {
        if player == .light { lightHasUsedBreak = true } else { darkHasUsedBreak = true }
    }

    public mutating func incrementPassCount(for player: Player) {
        if player == .light { lightPassCount += 1 } else { darkPassCount += 1 }
    }

    public mutating func setLockCooldown(positions: Set<Position>, for player: Player) {
        lockCooldownPositions = positions
        lockCooldownPlayer = player
    }

    public mutating func clearLockCooldown() {
        lockCooldownPositions = []
        lockCooldownPlayer = nil
    }

    public mutating func advanceTurn() {
        // Clear lock cooldown after the affected player has taken their turn
        if lockCooldownPlayer == currentPlayer {
            clearLockCooldown()
        }
        currentPlayer = currentPlayer.opponent
        turnNumber += 1
    }

    public mutating func setWinner(_ player: Player, victorySet: VictorySetType?, byElimination: Bool = false) {
        winner = player
        winCondition = victorySet
        wonByElimination = byElimination
    }

    // Add stone to the owner's river (when their stone is captured)
    public mutating func addToRiver(_ stone: Stone) {
        if stone.owner == .light {
            lightRiver.append(stone)
        } else {
            darkRiver.append(stone)
        }
    }

    // Draw from own river (single stone - legacy)
    @discardableResult
    public mutating func drawFromRiver(for player: Player) -> Stone? {
        if player == .light {
            return lightRiver.isEmpty ? nil : lightRiver.removeFirst()
        } else {
            return darkRiver.isEmpty ? nil : darkRiver.removeFirst()
        }
    }

    // River Reclamation (Third Edition): Take ALL stones from river at once
    // Returns count of stones reclaimed
    @discardableResult
    public mutating func reclaimAllFromRiver(for player: Player) -> Int {
        if player == .light {
            let count = lightRiver.count
            lightRiver.removeAll()
            lightStonesInHand += count
            return count
        } else {
            let count = darkRiver.count
            darkRiver.removeAll()
            darkStonesInHand += count
            return count
        }
    }

    public mutating func addMove(_ move: Move) { moveHistory.append(move) }
    public mutating func addLockedPattern(_ pattern: Pattern) {
        var p = pattern; p.isLocked = true; lockedPatterns.append(p)
    }
    public mutating func removeLockedPattern(id: UUID) { lockedPatterns.removeAll { $0.id == id } }

    public func toJSON() throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(self)
    }

    public static func fromJSON(_ data: Data) throws -> GameState {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(GameState.self, from: data)
    }
}
