import Foundation

public enum MoveType: Codable, Sendable, Equatable {
    case drop(position: Position)
    case shift(from: Position, to: Position)
    case lock(patternID: UUID, positions: Set<Position>)
    case drawFromRiver
    case breakLock(sacrificePositions: [Position], targetPosition: Position)
    case pass
}

public struct Move: Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    public let player: Player
    public let type: MoveType
    public let timestamp: Date
    public var capturedPositions: [Position]
    public var surroundedPositions: [Position]

    public init(id: UUID = UUID(), player: Player, type: MoveType, timestamp: Date = Date(),
                capturedPositions: [Position] = [], surroundedPositions: [Position] = []) {
        self.id = id
        self.player = player
        self.type = type
        self.timestamp = timestamp
        self.capturedPositions = capturedPositions
        self.surroundedPositions = surroundedPositions
    }

    public var notation: String {
        switch type {
        case .drop(let pos): return pos.notation
        case .shift(let from, let to): return "\(from.notation)-\(to.notation)\(capturedPositions.isEmpty ? "" : "x")"
        case .lock(_, let positions): return "L:\(positions.sorted().map { $0.notation }.joined(separator: "-"))"
        case .drawFromRiver: return "R"
        case .breakLock(let sacrifice, let target): return "B:\(sacrifice.map { $0.notation }.joined(separator: ","))>\(target.notation)"
        case .pass: return "pass"
        }
    }
}
