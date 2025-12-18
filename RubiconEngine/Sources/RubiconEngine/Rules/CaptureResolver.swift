import Foundation

public struct CaptureResult: Sendable, Equatable {
    public let capturedPositions: [Position]
    public let surroundedPositions: [Position]

    public init(capturedPositions: [Position] = [], surroundedPositions: [Position] = []) {
        self.capturedPositions = capturedPositions
        self.surroundedPositions = surroundedPositions
    }

    public var hasCaptured: Bool { !capturedPositions.isEmpty }
    public var hasSurrounded: Bool { !surroundedPositions.isEmpty }
}

public struct CaptureResolver: Sendable {
    public init() {}

    /// Check if a stone at position is surrounded (all orthogonal neighbors occupied or off-board)
    public func isSurrounded(at position: Position, on board: Board) -> Bool {
        let neighbors = position.orthogonalNeighbors

        for neighbor in neighbors {
            if neighbor.isValid && board.isEmpty(at: neighbor) {
                return false
            }
        }
        return true
    }

    /// Find all surrounded stones for a given player
    public func findSurroundedStones(for player: Player, on board: Board) -> [Position] {
        var surrounded: [Position] = []

        for position in board.allPositions(for: player) {
            if isSurrounded(at: position, on: board) {
                surrounded.append(position)
            }
        }

        return surrounded
    }

    /// Find all surrounded stones on the board
    public func findAllSurroundedStones(on board: Board) -> [Position] {
        var surrounded: [Position] = []

        for row in 0..<6 {
            for col in 0..<6 {
                let pos = Position(column: col, row: row)
                if board.isOccupied(at: pos) && isSurrounded(at: pos, on: board) {
                    surrounded.append(pos)
                }
            }
        }

        return surrounded
    }

    /// Resolve captures after a move, returning which stones were captured
    /// Captured stones are those that became surrounded as a result of the move
    public func resolveCaptures(after move: Move, on board: Board, previousBoard: Board) -> CaptureResult {
        var capturedPositions: [Position] = []
        var surroundedPositions: [Position] = []

        // Find all currently surrounded stones
        let allSurrounded = findAllSurroundedStones(on: board)

        for pos in allSurrounded {
            // Check if this stone was NOT surrounded before the move
            let wasSurroundedBefore = previousBoard.isOccupied(at: pos) && isSurrounded(at: pos, on: previousBoard)

            if !wasSurroundedBefore {
                // Newly surrounded stone
                if let stone = board.stone(at: pos) {
                    // Track as captured (opponent's stones) or surrounded (own stones)
                    if stone.owner != move.player {
                        capturedPositions.append(pos)
                    } else {
                        surroundedPositions.append(pos)
                    }
                }
            }
        }

        return CaptureResult(capturedPositions: capturedPositions, surroundedPositions: surroundedPositions)
    }

    /// Check positions that could become surrounded after placing/moving a stone
    public func positionsAtRisk(when stoneMovedTo: Position, on board: Board) -> [Position] {
        let target = stoneMovedTo
        var atRisk: [Position] = []

        // Check all neighbors of the target position
        for neighbor in target.orthogonalNeighbors where neighbor.isValid {
            if board.isOccupied(at: neighbor) {
                // Simulate the placement and check if this neighbor would be surrounded
                var testBoard = board
                // Place a temporary stone
                testBoard.place(Stone(owner: .light), at: target)
                if isSurrounded(at: neighbor, on: testBoard) {
                    atRisk.append(neighbor)
                }
            }
        }

        return atRisk
    }

    /// Get positions that would capture opponent stones if a stone is placed there
    public func captureOpportunities(for player: Player, on board: Board) -> [(position: Position, captures: [Position])] {
        var opportunities: [(Position, [Position])] = []

        for emptyPos in board.allEmptyPositions() {
            var captures: [Position] = []

            for neighbor in emptyPos.orthogonalNeighbors where neighbor.isValid {
                if let stone = board.stone(at: neighbor), stone.owner == player.opponent {
                    // Check if placing here would surround this opponent stone
                    var testBoard = board
                    testBoard.place(Stone(owner: player), at: emptyPos)
                    if isSurrounded(at: neighbor, on: testBoard) {
                        captures.append(neighbor)
                    }
                }
            }

            if !captures.isEmpty {
                opportunities.append((emptyPos, captures))
            }
        }

        return opportunities
    }
}
