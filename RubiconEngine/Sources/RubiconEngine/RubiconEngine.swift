// RubiconEngine - Core game logic for the Rubicon board game
// A Swift Package providing all game rules, AI, and state management

import Foundation

// MARK: - Public API

/// Main entry point for the Rubicon game engine
public enum RubiconEngine {
    /// Current version of the engine
    public static let version = "1.0.0"

    /// Create a new game with specified settings
    public static func newGame(mode: GameMode = .localPassAndPlay, startingPlayer: Player = .light) -> GameState {
        GameState(gameMode: mode, startingPlayer: startingPlayer)
    }

    /// Create a game controller for managing game flow
    @MainActor
    public static func createController(mode: GameMode = .localPassAndPlay, startingPlayer: Player = .light) -> GameController {
        GameController(gameMode: mode, startingPlayer: startingPlayer)
    }

    /// Create an AI player with specified difficulty
    public static func createAI(difficulty: AIDifficulty, player: Player) -> AIPlayer {
        AIPlayer(difficulty: difficulty, player: player)
    }

    /// Create a rules engine for move validation and execution
    public static func createRulesEngine() -> RulesEngine {
        RulesEngine()
    }
}

// MARK: - Re-exports for convenience

// Models
public typealias RubiconPlayer = Player
public typealias RubiconPosition = Position
public typealias RubiconStone = Stone
public typealias RubiconBoard = Board
public typealias RubiconPattern = Pattern
public typealias RubiconMove = Move
public typealias RubiconGameState = GameState

// Rules
public typealias RubiconMoveValidator = MoveValidator
public typealias RubiconPatternDetector = PatternDetector
public typealias RubiconCaptureResolver = CaptureResolver
public typealias RubiconVictoryChecker = VictoryChecker
public typealias RubiconRulesEngine = RulesEngine

// Game
public typealias RubiconGameController = GameController

// AI
public typealias RubiconAIPlayer = AIPlayer
public typealias RubiconMoveEvaluator = MoveEvaluator
