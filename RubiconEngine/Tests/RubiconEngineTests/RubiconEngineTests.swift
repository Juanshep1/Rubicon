import Testing
@testable import RubiconEngine

@Test func testBoardInitialization() async throws {
    let board = Board()
    #expect(board.isEmpty(at: Position(column: 0, row: 0)))
    #expect(board.stoneCount(for: .light) == 0)
    #expect(board.stoneCount(for: .dark) == 0)
}

@Test func testPositionNotation() async throws {
    let position = Position(column: 0, row: 0)
    #expect(position.notation == "a1")

    let position2 = Position(column: 5, row: 5)
    #expect(position2.notation == "f6")
}

@Test func testStonePlacement() async throws {
    var board = Board()
    let position = Position(column: 2, row: 3)
    let stone = Stone(owner: .light)

    board.place(stone, at: position)

    #expect(!board.isEmpty(at: position))
    #expect(board.stone(at: position)?.owner == .light)
    #expect(board.stoneCount(for: .light) == 1)
}

@Test func testGameStateInitialization() async throws {
    let state = GameState()

    #expect(state.lightStonesInHand == 12)
    #expect(state.darkStonesInHand == 12)
    #expect(state.currentPlayer == .light)
    #expect(!state.isGameOver)
}

@Test func testMoveValidation() async throws {
    let state = GameState()
    let validator = MoveValidator()

    // Valid drop on empty board
    let validDrop = validator.validateDrop(at: Position(column: 2, row: 2), state: state)
    #expect(validDrop.isValid)

    // Invalid drop on occupied position after placing a stone
    var stateWithStone = state
    stateWithStone.board.place(Stone(owner: .light), at: Position(column: 2, row: 2))
    let invalidDrop = validator.validateDrop(at: Position(column: 2, row: 2), state: stateWithStone)
    #expect(!invalidDrop.isValid)
}

@Test func testPatternDetection() async throws {
    var board = Board()
    let detector = PatternDetector()

    // Place a horizontal line of 3
    board.place(Stone(owner: .light), at: Position(column: 0, row: 0))
    board.place(Stone(owner: .light), at: Position(column: 1, row: 0))
    board.place(Stone(owner: .light), at: Position(column: 2, row: 0))

    let patterns = detector.detectPatterns(on: board, for: .light, unlockedOnly: true)
    let lines = patterns.filter { $0.type == .line }

    #expect(!lines.isEmpty)
    #expect(lines.first?.positions.count == 3)
}

@Test func testRulesEngineExecution() async throws {
    let state = GameState()
    let engine = RulesEngine()

    let move = Move(player: .light, type: .drop(position: Position(column: 2, row: 2)))
    let result = engine.executeMove(move, on: state)

    #expect(result.success)
    #expect(!result.newState.board.isEmpty(at: Position(column: 2, row: 2)))
    #expect(result.newState.lightStonesInHand == 11)
    #expect(result.newState.currentPlayer == .dark)
}
