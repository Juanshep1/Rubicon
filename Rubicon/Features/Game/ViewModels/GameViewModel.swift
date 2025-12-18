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

    private var cancellables = Set<AnyCancellable>()
    private var previousMoveCount = 0

    init(gameMode: GameMode = .localPassAndPlay) {
        self.gameController = GameController(gameMode: gameMode)
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
        gameController.performDrawFromRiver()

        // Play move sound
        audioManager.playStoneMove()

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
        gameController.performBreak(sacrificePositions: sacrificePositions, targetPosition: targetPosition)
        isInBreakMode = false
        breakSacrificePositions = []

        // Play lock sound for breaking
        audioManager.playLock()

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
            await gameController.executeAIMove()

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
    }
}
