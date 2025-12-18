import Foundation

public enum GameEvent: Sendable, Equatable {
    case gameStarted(GameState)
    case moveExecuted(Move, MoveResult)
    case patternLocked(Pattern)
    case captureOccurred([Position])
    case turnChanged(Player)
    case gameEnded(Player, VictorySetType?)
    case invalidMove(String)
}

public protocol GameControllerDelegate: AnyObject, Sendable {
    func gameController(_ controller: GameController, didReceiveEvent event: GameEvent)
}

@MainActor
public final class GameController: ObservableObject, Sendable {
    @Published public private(set) var state: GameState
    @Published public private(set) var selectedPosition: Position?
    @Published public private(set) var validDestinations: [Position] = []
    @Published public private(set) var availablePatterns: [Pattern] = []
    @Published public private(set) var lastMoveResult: MoveResult?

    private let rulesEngine = RulesEngine()
    public weak var delegate: GameControllerDelegate?

    public init(gameMode: GameMode = .localPassAndPlay, startingPlayer: Player = .light) {
        self.state = GameState(gameMode: gameMode, startingPlayer: startingPlayer)
    }

    public init(state: GameState) {
        self.state = state
    }

    // MARK: - Game Flow

    public func startNewGame(gameMode: GameMode = .localPassAndPlay, startingPlayer: Player = .light) {
        state = GameState(gameMode: gameMode, startingPlayer: startingPlayer)
        selectedPosition = nil
        validDestinations = []
        availablePatterns = []
        lastMoveResult = nil
        delegate?.gameController(self, didReceiveEvent: .gameStarted(state))
    }

    public func loadGame(from savedState: GameState) {
        state = savedState
        clearSelection()
        updateAvailablePatterns()
    }

    // MARK: - Selection

    public func selectPosition(_ position: Position) {
        guard !state.isGameOver else { return }

        // If clicking on own unlocked stone, select it for shift
        if let stone = state.board.stone(at: position),
           stone.owner == state.currentPlayer,
           !stone.isLocked {
            selectedPosition = position
            validDestinations = calculateValidDestinations(from: position)
        } else if selectedPosition != nil {
            // If we have a selection and clicked elsewhere, try to move
            if validDestinations.contains(position) {
                performShift(from: selectedPosition!, to: position)
            } else {
                clearSelection()
            }
        } else if state.board.isEmpty(at: position) && state.currentPlayerStonesInHand > 0 {
            // Empty position with stones in hand - perform drop
            performDrop(at: position)
        }
    }

    public func clearSelection() {
        selectedPosition = nil
        validDestinations = []
    }

    // MARK: - Actions

    public func performDrop(at position: Position) {
        let move = Move(player: state.currentPlayer, type: .drop(position: position))
        executeMove(move)
    }

    public func performShift(from: Position, to: Position) {
        let move = Move(player: state.currentPlayer, type: .shift(from: from, to: to))
        executeMove(move)
    }

    public func performLock(pattern: Pattern) {
        let move = Move(player: state.currentPlayer, type: .lock(patternID: pattern.id, positions: pattern.positions))
        executeMove(move)
    }

    public func performDrawFromRiver() {
        let move = Move(player: state.currentPlayer, type: .drawFromRiver)
        executeMove(move)
    }

    public func performBreak(sacrificePositions: [Position], targetPosition: Position) {
        let move = Move(player: state.currentPlayer, type: .breakLock(sacrificePositions: sacrificePositions, targetPosition: targetPosition))
        executeMove(move)
    }

    public func performPass() {
        let move = Move(player: state.currentPlayer, type: .pass)
        executeMove(move)
    }

    // MARK: - Move Execution

    private func executeMove(_ move: Move) {
        let result = rulesEngine.executeMove(move, on: state)

        if result.success {
            state = result.newState
            lastMoveResult = result
            clearSelection()
            updateAvailablePatterns()

            delegate?.gameController(self, didReceiveEvent: .moveExecuted(move, result))

            if let pattern = result.lockedPattern {
                delegate?.gameController(self, didReceiveEvent: .patternLocked(pattern))
            }

            if result.captureResult.hasCaptured {
                delegate?.gameController(self, didReceiveEvent: .captureOccurred(result.captureResult.capturedPositions))
            }

            if result.victoryResult.hasWinner {
                delegate?.gameController(self, didReceiveEvent: .gameEnded(result.victoryResult.winner!, result.victoryResult.victorySet))
            } else {
                delegate?.gameController(self, didReceiveEvent: .turnChanged(state.currentPlayer))
            }
        } else {
            delegate?.gameController(self, didReceiveEvent: .invalidMove(result.errorMessage ?? "Invalid move"))
        }
    }

    // MARK: - Queries

    public func validMoves() -> [Move] {
        rulesEngine.validMoves(for: state)
    }

    public func canDrop(at position: Position) -> Bool {
        guard state.board.isEmpty(at: position) else { return false }
        guard state.currentPlayerStonesInHand > 0 else { return false }
        return true
    }

    public func canShift(from: Position, to: Position) -> Bool {
        let validation = rulesEngine.moveValidator.validateShift(from: from, to: to, player: state.currentPlayer, state: state)
        return validation.isValid
    }

    public func canDrawFromRiver() -> Bool {
        state.canDrawFromRiver(player: state.currentPlayer)
    }

    public func canUseBreak() -> Bool {
        state.canUseBreak(player: state.currentPlayer)
    }

    public func potentialCaptures(at position: Position) -> [Position] {
        rulesEngine.potentialCaptures(at: position, for: state.currentPlayer, state: state)
    }

    // MARK: - Helpers

    private func calculateValidDestinations(from position: Position) -> [Position] {
        var destinations: [Position] = []
        let directions = [(0, 1), (0, -1), (1, 0), (-1, 0)]

        for (dc, dr) in directions {
            // Check 1 square away
            let pos1 = Position(column: position.column + dc, row: position.row + dr)
            if pos1.isValid {
                if state.board.isEmpty(at: pos1) {
                    destinations.append(pos1)

                    // Check 2 squares away (only if 1 away is empty)
                    let pos2 = Position(column: position.column + dc * 2, row: position.row + dr * 2)
                    if pos2.isValid {
                        if state.board.isEmpty(at: pos2) {
                            destinations.append(pos2)
                        } else if let stone = state.board.stone(at: pos2),
                                  stone.owner != state.currentPlayer,
                                  !stone.isLocked {
                            destinations.append(pos2) // Can strike
                        }
                    }
                } else if let stone = state.board.stone(at: pos1),
                          stone.owner != state.currentPlayer,
                          !stone.isLocked {
                    destinations.append(pos1) // Can strike at 1 away
                }
            }
        }

        return destinations
    }

    private func updateAvailablePatterns() {
        availablePatterns = rulesEngine.lockablePatterns(for: state.currentPlayer, on: state)
    }

    // MARK: - Serialization

    public func saveState() throws -> Data {
        try state.toJSON()
    }

    public func restoreState(from data: Data) throws {
        state = try GameState.fromJSON(data)
        clearSelection()
        updateAvailablePatterns()
    }
}
