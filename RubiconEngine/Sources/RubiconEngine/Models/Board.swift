import Foundation

public struct Board: Codable, Sendable, Equatable {
    private var grid: [[Stone?]]

    public init() {
        grid = Array(repeating: Array(repeating: nil, count: 6), count: 6)
    }

    public func stone(at pos: Position) -> Stone? {
        guard pos.isValid else { return nil }
        return grid[pos.row][pos.column]
    }

    public func isEmpty(at pos: Position) -> Bool { stone(at: pos) == nil }
    public func isOccupied(at pos: Position) -> Bool { stone(at: pos) != nil }

    public mutating func place(_ stone: Stone, at pos: Position) {
        guard pos.isValid else { return }
        grid[pos.row][pos.column] = stone
    }

    @discardableResult
    public mutating func remove(at pos: Position) -> Stone? {
        guard pos.isValid else { return nil }
        let s = grid[pos.row][pos.column]
        grid[pos.row][pos.column] = nil
        return s
    }

    @discardableResult
    public mutating func move(from: Position, to: Position) -> Stone? {
        guard let s = remove(at: from) else { return nil }
        let captured = remove(at: to)
        place(s, at: to)
        return captured
    }

    public func allPositions(for player: Player) -> [Position] {
        Position.allPositions.filter { stone(at: $0)?.owner == player }
    }

    public func allEmptyPositions() -> [Position] {
        Position.allPositions.filter { isEmpty(at: $0) }
    }

    public func stoneCount(for player: Player) -> Int {
        allPositions(for: player).count
    }

    public func lockedStoneCount(for player: Player) -> Int {
        allPositions(for: player).filter { stone(at: $0)?.isLocked == true }.count
    }

    public mutating func lockStone(at pos: Position, patternID: UUID) {
        guard pos.isValid, var s = grid[pos.row][pos.column] else { return }
        s.isLocked = true
        s.lockedInPatternID = patternID
        grid[pos.row][pos.column] = s
    }

    public mutating func unlockStone(at pos: Position) {
        guard pos.isValid, var s = grid[pos.row][pos.column] else { return }
        s.isLocked = false
        s.lockedInPatternID = nil
        grid[pos.row][pos.column] = s
    }
}
