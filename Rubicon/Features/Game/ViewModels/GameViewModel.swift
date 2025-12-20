import SwiftUI
import RubiconEngine
import Combine

@MainActor
class GameViewModel: ObservableObject {
    @Published private(set) var gameController: GameController
    @Published var showVictoryBanner = false
    @Published var showPatternLockAnimation = false
    @Published var lastLockedPattern: Pattern?

    // Break mode state
    @Published var isInBreakMode = false
    @Published var breakSacrificePositions: [Position] = []

    // Audio manager reference
    private let audioManager = AudioManager.shared

    // Achievement tracking
    private let achievementManager = AchievementManager.shared
    private var stonesLostByPlayer = 0
    private var wasPlayerDown5Stones = false

    private var cancellables = Set<AnyCancellable>()
    private var previousMoveCount = 0

    private var currentGameMode: GameMode = .localPassAndPlay

    // Story mode AI personality (each opponent has unique playstyle)
    var storyPersonality: StoryAIPersonality?
    private var lastPlayerMoveType: MoveType?

    init(gameMode: GameMode = .localPassAndPlay) {
        self.currentGameMode = gameMode
        self.gameController = GameController(gameMode: gameMode)
        setupObservers()
    }

    /// Initialize with a story personality for unique opponent behavior
    init(gameMode: GameMode = .localPassAndPlay, storyPersonality: StoryAIPersonality?) {
        self.currentGameMode = gameMode
        self.storyPersonality = storyPersonality
        self.gameController = GameController(gameMode: gameMode)
        setupObservers()
    }

    func resetGame() {
        // Clear all state
        showVictoryBanner = false
        showPatternLockAnimation = false
        lastLockedPattern = nil
        isInBreakMode = false
        breakSacrificePositions = []
        stonesLostByPlayer = 0
        wasPlayerDown5Stones = false
        previousMoveCount = 0

        // Create new game controller
        cancellables.removeAll()
        gameController = GameController(gameMode: currentGameMode)
        setupObservers()
    }

    private func setupObservers() {
        // Forward all GameController changes to trigger view updates
        gameController.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    // MARK: - Game State Access

    var state: GameState { gameController.state }
    var board: Board { gameController.state.board }
    var currentPlayer: Player { gameController.state.currentPlayer }
    var isGameOver: Bool { gameController.state.isGameOver }
    var winner: Player? { gameController.state.winner }
    var victorySet: VictorySetType? { gameController.state.winCondition }

    var selectedPosition: Position? { gameController.selectedPosition }
    var validDestinations: [Position] { gameController.validDestinations }
    var availablePatterns: [Pattern] { gameController.availablePatterns }

    // MARK: - Actions

    func selectPosition(_ position: Position) {
        gameController.selectPosition(position)
    }

    func performLock(pattern: Pattern) {
        lastLockedPattern = pattern
        showPatternLockAnimation = true
        gameController.performLock(pattern: pattern)

        // Play lock sound
        audioManager.playLock()

        // Track achievement
        if state.currentPlayer.opponent == .light { // Player just locked
            achievementManager.recordLock()
            if pattern.type == .cross {
                achievementManager.recordCrossFormed()
            }
            if pattern.type == .line && pattern.positions.count >= 5 {
                achievementManager.recordLongRoadFormed()
            }
        }

        // Check for victory
        if isGameOver {
            playVictorySound()
            postLadderGameEndedNotification()
            withAnimation(RubiconAnimations.slow) {
                showVictoryBanner = true
            }
        }

        // Hide animation after delay and trigger AI turn
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            showPatternLockAnimation = false

            // Trigger AI turn after animation
            if !isGameOver {
                checkForAITurn()
            }
        }
    }

    func drawFromRiver() {
        let wasPlayerDraw = state.currentPlayer == .light
        gameController.performDrawFromRiver()

        // Play move sound
        audioManager.playStoneMove()

        // Track achievement
        if wasPlayerDraw {
            achievementManager.recordRiverDraw()
        }

        // Check for victory or AI turn
        if isGameOver {
            playVictorySound()
            postLadderGameEndedNotification()
            withAnimation(RubiconAnimations.slow) {
                showVictoryBanner = true
            }
        }

        // Small delay then check AI turn
        Task {
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            if !isGameOver {
                checkForAITurn()
            }
        }
    }

    func pass() {
        gameController.performPass()

        // Small delay then check AI turn
        Task {
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            checkForAITurn()
        }
    }

    func startNewGame(gameMode: GameMode = .localPassAndPlay) {
        showVictoryBanner = false
        isInBreakMode = false
        breakSacrificePositions = []
        stonesLostByPlayer = 0
        wasPlayerDown5Stones = false
        gameController.startNewGame(gameMode: gameMode)
    }

    // MARK: - Break Mode

    func startBreakMode() {
        isInBreakMode = true
        breakSacrificePositions = []
        gameController.clearSelection()
    }

    func cancelBreakMode() {
        isInBreakMode = false
        breakSacrificePositions = []
    }

    func handleBreakSelection(_ position: Position) {
        guard isInBreakMode else { return }

        if let stone = state.board.stone(at: position), stone.isLocked {
            if stone.owner == currentPlayer {
                // Selecting own stone to sacrifice
                if breakSacrificePositions.contains(position) {
                    // Deselect if already selected
                    breakSacrificePositions.removeAll { $0 == position }
                    audioManager.playSelect()
                } else if breakSacrificePositions.count < 2 {
                    // Add to sacrifice list
                    breakSacrificePositions.append(position)
                    audioManager.playSelect()
                }
            } else {
                // Selecting opponent stone to break
                if breakSacrificePositions.count == 2 {
                    // Execute break
                    performBreak(sacrificePositions: breakSacrificePositions, targetPosition: position)
                }
            }
        }
    }

    func performBreak(sacrificePositions: [Position], targetPosition: Position) {
        let wasPlayerBreak = state.currentPlayer == .light
        gameController.performBreak(sacrificePositions: sacrificePositions, targetPosition: targetPosition)
        isInBreakMode = false
        breakSacrificePositions = []

        // Play lock sound for breaking
        audioManager.playLock()

        // Track achievement
        if wasPlayerBreak {
            achievementManager.recordBreak()
        }

        // Check for victory
        if isGameOver {
            playVictorySound()
            postLadderGameEndedNotification()
            withAnimation(RubiconAnimations.slow) {
                showVictoryBanner = true
            }
        }

        // Trigger AI turn after break
        Task {
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            if !isGameOver {
                checkForAITurn()
            }
        }
    }

    /// Get opponent's locked positions (valid break targets)
    var opponentLockedPositions: [Position] {
        state.board.allPositions(for: currentPlayer.opponent).filter { pos in
            state.board.stone(at: pos)?.isLocked == true
        }
    }

    /// Get current player's locked positions (valid sacrifice options)
    var ownLockedPositions: [Position] {
        state.board.allPositions(for: currentPlayer).filter { pos in
            state.board.stone(at: pos)?.isLocked == true
        }
    }

    // MARK: - AI Integration

    func checkForAITurn() {
        guard case .vsAI = state.gameMode else { return }
        guard state.currentPlayer == .dark && !state.isGameOver else { return }

        let moveCountBefore = state.moveHistory.count

        Task { @MainActor in
            // Use story personality if available (unique opponent playstyles)
            if let personality = storyPersonality {
                await gameController.executeStoryAIMove(
                    personality: personality,
                    lastPlayerMoveType: lastPlayerMoveType
                )
            } else {
                await gameController.executeAIMove()
            }

            // Play sound if AI made a move
            if gameController.state.moveHistory.count > moveCountBefore {
                // Check what type of move was made
                if let lastMove = gameController.state.moveHistory.last {
                    switch lastMove.type {
                    case .lock:
                        audioManager.playLock()
                    case .pass:
                        break // No sound for pass
                    default:
                        audioManager.playStoneMove()
                    }
                }
            }

            // Small delay to ensure state has propagated
            try? await Task.sleep(nanoseconds: 150_000_000) // 0.15 seconds

            // Check for victory after AI move
            if gameController.state.isGameOver && !showVictoryBanner {
                playVictorySound()
                postLadderGameEndedNotification()
                withAnimation(RubiconAnimations.slow) {
                    showVictoryBanner = true
                }
            }
        }
    }

    /// Track the player's last move type for mirror play (Twins specialty)
    func recordPlayerMoveType(_ moveType: MoveType) {
        lastPlayerMoveType = moveType
    }

    // MARK: - Cell Tap Handler

    func handleCellTap(_ position: Position) {
        // Don't allow interaction during AI turn
        if case .vsAI = state.gameMode, state.currentPlayer == .dark {
            return
        }

        let hadSelection = selectedPosition != nil
        let moveCountBefore = state.moveHistory.count

        gameController.selectPosition(position)

        // Determine what happened and play appropriate sound
        let moveCountAfter = state.moveHistory.count
        if moveCountAfter > moveCountBefore {
            // A move was made (drop or shift)
            audioManager.playStoneMove()
        } else if selectedPosition != nil && !hadSelection {
            // A stone was selected
            audioManager.playSelect()
        } else if selectedPosition == nil && hadSelection {
            // Selection was cleared (clicked elsewhere)
            // No sound needed
        }

        // Check for victory after move
        if isGameOver && !showVictoryBanner {
            playVictorySound()
            postLadderGameEndedNotification()
            withAnimation(RubiconAnimations.slow) {
                showVictoryBanner = true
            }
        }

        // Small delay then check AI turn to ensure state propagated
        Task {
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            if !isGameOver {
                checkForAITurn()
            }
        }
    }

    // MARK: - Audio Helpers

    private func playVictorySound() {
        // Small delay so it plays after any other sounds
        Task {
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
            audioManager.playVictory()
        }
    }

    // MARK: - Ladder Notification

    private func postLadderGameEndedNotification() {
        // Post notification for ladder mode tracking
        let playerWon = state.winner == .light
        NotificationCenter.default.post(
            name: .ladderGameEnded,
            object: nil,
            userInfo: ["playerWon": playerWon]
        )

        // Record achievement for game end
        recordGameEndAchievements()
    }

    // MARK: - Achievement Recording

    private func recordGameEndAchievements() {
        guard state.isGameOver else { return }

        let playerWon = state.winner == .light
        let moveCount = state.moveHistory.count

        // Determine difficulty
        var difficulty = 0
        if case .vsAI(let aiDiff) = state.gameMode {
            difficulty = aiDiff.rawValue
        }

        // Determine victory type
        var victoryType: String? = nil
        if let winCondition = state.winCondition {
            switch winCondition {
            case .theStar: victoryType = "The Star"
            case .theLongRoad: victoryType = "The Long Road"
            case .theFortress: victoryType = "The Fortress"
            case .twinRivers: victoryType = "Twin Rivers"
            case .gateAndPath: victoryType = "Gate & Path"
            case .threeBends: victoryType = "Three Bends"
            case .thePhalanx: victoryType = "The Phalanx"
            case .thePincer: victoryType = "The Pincer"
            case .theSerpent: victoryType = "The Serpent"
            case .theConstellation: victoryType = "The Constellation"
            }
        } else if state.winner != nil {
            // Winner exists but no winCondition means elimination
            victoryType = "Elimination"
        }

        // Record to achievement manager
        achievementManager.recordGameEnd(
            won: playerWon,
            difficulty: difficulty,
            stonesLost: stonesLostByPlayer,
            moveCount: moveCount,
            wasDown5Stones: wasPlayerDown5Stones,
            victoryType: playerWon ? victoryType : nil
        )
    }

    /// Track player stone loss for achievements
    func trackPlayerStoneLoss(count: Int = 1) {
        stonesLostByPlayer += count

        // Check if player is down 5+ stones (for comeback achievement)
        let playerStones = state.board.allPositions(for: .light).count + state.lightStonesInHand
        let opponentStones = state.board.allPositions(for: .dark).count + state.darkStonesInHand
        if opponentStones - playerStones >= 5 {
            wasPlayerDown5Stones = true
        }
    }

    /// Track captures by player for achievements
    func trackPlayerCapture(count: Int = 1) {
        achievementManager.recordCapture(count: count)
    }
}
