import Foundation

public struct Position: Hashable, Codable, Sendable, Comparable, CustomStringConvertible {
    public let column: Int  // 0-5 (a-f)
    public let row: Int     // 0-5 (1-6)

    public static let boardSize = 6

    public init(column: Int, row: Int) {
        self.column = column
        self.row = row
    }

    public static func from(notation: String) -> Position? {
        let s = notation.lowercased().trimmingCharacters(in: .whitespaces)
        guard s.count == 2, let col = "abcdef".firstIndex(of: s.first!),
              let rowNum = Int(String(s.last!)), rowNum >= 1, rowNum <= 6 else { return nil }
        return Position(column: "abcdef".distance(from: "abcdef".startIndex, to: col), row: rowNum - 1)
    }

    public var notation: String {
        "\(Character(UnicodeScalar(97 + column)!))\(row + 1)"
    }

    public var description: String { notation }
    public var isValid: Bool { column >= 0 && column < 6 && row >= 0 && row < 6 }
    public var isCenter: Bool { column >= 2 && column <= 3 && row >= 2 && row <= 3 }
    public var isEdge: Bool { column == 0 || column == 5 || row == 0 || row == 5 }
    public var isCorner: Bool { (column == 0 || column == 5) && (row == 0 || row == 5) }

    public var orthogonalNeighbors: [Position] {
        [(0,1), (0,-1), (1,0), (-1,0)].map {
            Position(column: column + $0.0, row: row + $0.1)
        }
    }

    public static func < (lhs: Position, rhs: Position) -> Bool {
        lhs.row != rhs.row ? lhs.row < rhs.row : lhs.column < rhs.column
    }

    public static var allPositions: [Position] {
        (0..<6).flatMap { r in (0..<6).map { Position(column: $0, row: r) } }
    }
}
