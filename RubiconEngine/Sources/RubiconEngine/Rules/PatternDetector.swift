import Foundation

public struct PatternDetector: Sendable {
    public init() {}

    public func detectPatterns(on board: Board, for player: Player, unlockedOnly: Bool = true) -> [Pattern] {
        var patterns: [Pattern] = []
        patterns.append(contentsOf: detectLines(on: board, for: player, unlockedOnly: unlockedOnly))
        patterns.append(contentsOf: detectBends(on: board, for: player, unlockedOnly: unlockedOnly))
        patterns.append(contentsOf: detectGates(on: board, for: player, unlockedOnly: unlockedOnly))
        if let cross = detectCross(on: board, for: player, unlockedOnly: unlockedOnly) { patterns.append(cross) }
        patterns.append(contentsOf: detectPods(on: board, for: player, unlockedOnly: unlockedOnly))
        patterns.append(contentsOf: detectHooks(on: board, for: player, unlockedOnly: unlockedOnly))
        return patterns
    }

    public func detectLines(on board: Board, for player: Player, unlockedOnly: Bool = true) -> [Pattern] {
        var lines: [Pattern] = []

        // Horizontal
        for row in 0..<6 {
            var streak: [Position] = []
            for col in 0..<6 {
                let pos = Position(column: col, row: row)
                if isValid(pos, for: player, on: board, unlockedOnly: unlockedOnly) {
                    streak.append(pos)
                } else {
                    if streak.count >= 3 { lines.append(Pattern(type: .line, positions: Set(streak), owner: player)) }
                    streak = []
                }
            }
            if streak.count >= 3 { lines.append(Pattern(type: .line, positions: Set(streak), owner: player)) }
        }

        // Vertical
        for col in 0..<6 {
            var streak: [Position] = []
            for row in 0..<6 {
                let pos = Position(column: col, row: row)
                if isValid(pos, for: player, on: board, unlockedOnly: unlockedOnly) {
                    streak.append(pos)
                } else {
                    if streak.count >= 3 { lines.append(Pattern(type: .line, positions: Set(streak), owner: player)) }
                    streak = []
                }
            }
            if streak.count >= 3 { lines.append(Pattern(type: .line, positions: Set(streak), owner: player)) }
        }
        return lines
    }

    public func detectBends(on board: Board, for player: Player, unlockedOnly: Bool = true) -> [Pattern] {
        var bends: [Pattern] = []
        var seen: Set<Set<Position>> = []

        for row in 0..<6 {
            for col in 0..<6 {
                let corner = Position(column: col, row: row)
                guard isValid(corner, for: player, on: board, unlockedOnly: unlockedOnly) else { continue }

                for dirs in [[(0,1),(1,0)], [(0,1),(-1,0)], [(0,-1),(1,0)], [(0,-1),(-1,0)]] {
                    let arm1 = Position(column: col + dirs[0].0, row: row + dirs[0].1)
                    let arm2 = Position(column: col + dirs[1].0, row: row + dirs[1].1)
                    guard arm1.isValid, arm2.isValid else { continue }
                    if isValid(arm1, for: player, on: board, unlockedOnly: unlockedOnly) &&
                       isValid(arm2, for: player, on: board, unlockedOnly: unlockedOnly) {
                        let positions: Set<Position> = [corner, arm1, arm2]
                        if !seen.contains(positions) {
                            seen.insert(positions)
                            bends.append(Pattern(type: .bend, positions: positions, owner: player))
                        }
                    }
                }
            }
        }
        return bends
    }

    public func detectGates(on board: Board, for player: Player, unlockedOnly: Bool = true) -> [Pattern] {
        var gates: [Pattern] = []
        for row in 0..<5 {
            for col in 0..<5 {
                let positions = [Position(column: col, row: row), Position(column: col+1, row: row),
                                Position(column: col, row: row+1), Position(column: col+1, row: row+1)]
                if positions.allSatisfy({ isValid($0, for: player, on: board, unlockedOnly: unlockedOnly) }) {
                    gates.append(Pattern(type: .gate, positions: Set(positions), owner: player))
                }
            }
        }
        return gates
    }

    public func detectCross(on board: Board, for player: Player, unlockedOnly: Bool = true) -> Pattern? {
        for row in 1..<5 {
            for col in 1..<5 {
                let center = Position(column: col, row: row)
                guard isValid(center, for: player, on: board, unlockedOnly: unlockedOnly) else { continue }
                let arms = [Position(column: col-1, row: row), Position(column: col+1, row: row),
                           Position(column: col, row: row-1), Position(column: col, row: row+1)]
                if arms.allSatisfy({ isValid($0, for: player, on: board, unlockedOnly: unlockedOnly) }) {
                    return Pattern(type: .cross, positions: Set([center] + arms), owner: player)
                }
            }
        }
        return nil
    }

    public func isValidPattern(positions: Set<Position>, type: PatternType, owner: Player, on board: Board, unlockedOnly: Bool = true) -> Bool {
        for pos in positions {
            guard isValid(pos, for: owner, on: board, unlockedOnly: unlockedOnly) else { return false }
        }
        return true
    }

    private func isValid(_ pos: Position, for player: Player, on board: Board, unlockedOnly: Bool) -> Bool {
        guard let stone = board.stone(at: pos), stone.owner == player else { return false }
        if unlockedOnly && stone.isLocked { return false }
        return true
    }

    // POD: T-shape with 3 stones (2x1 rectangle + 1 adjacent stone perpendicular)
    // Like a small T: two horizontal stones with one vertical extension
    public func detectPods(on board: Board, for player: Player, unlockedOnly: Bool = true) -> [Pattern] {
        var pods: [Pattern] = []
        var seen: Set<Set<Position>> = []

        for row in 0..<6 {
            for col in 0..<6 {
                let center = Position(column: col, row: row)
                guard isValid(center, for: player, on: board, unlockedOnly: unlockedOnly) else { continue }

                // Check all 4 T-orientations:
                // 1. Horizontal bar with vertical stem down
                // 2. Horizontal bar with vertical stem up
                // 3. Vertical bar with horizontal stem left
                // 4. Vertical bar with horizontal stem right

                let tShapes: [[(Int, Int)]] = [
                    // Horizontal bar (center + right) with stem down from center
                    [(0, 0), (1, 0), (0, -1)],
                    // Horizontal bar (center + right) with stem up from center
                    [(0, 0), (1, 0), (0, 1)],
                    // Horizontal bar (center + left) with stem down from center
                    [(0, 0), (-1, 0), (0, -1)],
                    // Horizontal bar (center + left) with stem up from center
                    [(0, 0), (-1, 0), (0, 1)],
                    // Vertical bar (center + up) with stem right from center
                    [(0, 0), (0, 1), (1, 0)],
                    // Vertical bar (center + up) with stem left from center
                    [(0, 0), (0, 1), (-1, 0)],
                    // Vertical bar (center + down) with stem right from center
                    [(0, 0), (0, -1), (1, 0)],
                    // Vertical bar (center + down) with stem left from center
                    [(0, 0), (0, -1), (-1, 0)],
                ]

                for shape in tShapes {
                    let positions = shape.map { Position(column: col + $0.0, row: row + $0.1) }
                    guard positions.allSatisfy({ $0.isValid && isValid($0, for: player, on: board, unlockedOnly: unlockedOnly) }) else { continue }

                    let posSet = Set(positions)
                    if !seen.contains(posSet) {
                        seen.insert(posSet)
                        pods.append(Pattern(type: .pod, positions: posSet, owner: player))
                    }
                }
            }
        }
        return pods
    }

    // HOOK: L-tetromino (line of 3 + 1 stone attached to end)
    // Like an L: three stones in a row with one perpendicular at one end
    public func detectHooks(on board: Board, for player: Player, unlockedOnly: Bool = true) -> [Pattern] {
        var hooks: [Pattern] = []
        var seen: Set<Set<Position>> = []

        for row in 0..<6 {
            for col in 0..<6 {
                let corner = Position(column: col, row: row)
                guard isValid(corner, for: player, on: board, unlockedOnly: unlockedOnly) else { continue }

                // Hook shapes: line of 3 + 1 perpendicular at one end (L-tetromino)
                // 8 orientations
                let hookShapes: [[(Int, Int)]] = [
                    // Vertical line going up, horizontal extension to right
                    [(0, 0), (0, 1), (0, 2), (1, 0)],
                    // Vertical line going up, horizontal extension to left
                    [(0, 0), (0, 1), (0, 2), (-1, 0)],
                    // Vertical line going up, horizontal extension to right at top
                    [(0, 0), (0, 1), (0, 2), (1, 2)],
                    // Vertical line going up, horizontal extension to left at top
                    [(0, 0), (0, 1), (0, 2), (-1, 2)],
                    // Horizontal line going right, vertical extension up
                    [(0, 0), (1, 0), (2, 0), (0, 1)],
                    // Horizontal line going right, vertical extension down
                    [(0, 0), (1, 0), (2, 0), (0, -1)],
                    // Horizontal line going right, vertical extension up at end
                    [(0, 0), (1, 0), (2, 0), (2, 1)],
                    // Horizontal line going right, vertical extension down at end
                    [(0, 0), (1, 0), (2, 0), (2, -1)],
                ]

                for shape in hookShapes {
                    let positions = shape.map { Position(column: col + $0.0, row: row + $0.1) }
                    guard positions.allSatisfy({ $0.isValid && isValid($0, for: player, on: board, unlockedOnly: unlockedOnly) }) else { continue }

                    let posSet = Set(positions)
                    if !seen.contains(posSet) {
                        seen.insert(posSet)
                        hooks.append(Pattern(type: .hook, positions: posSet, owner: player))
                    }
                }
            }
        }
        return hooks
    }
}
