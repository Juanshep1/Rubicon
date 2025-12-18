import Foundation

public enum PatternType: String, Codable, CaseIterable, Sendable {
    case line, bend, gate, cross

    public var displayName: String {
        switch self {
        case .line: return "Line"
        case .bend: return "Bend"
        case .gate: return "Gate"
        case .cross: return "Cross"
        }
    }

    public var minimumStones: Int {
        switch self {
        case .line, .bend: return 3
        case .gate: return 4
        case .cross: return 5
        }
    }
}

public struct Pattern: Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    public let type: PatternType
    public let positions: Set<Position>
    public let owner: Player
    public var isLocked: Bool

    public init(id: UUID = UUID(), type: PatternType, positions: Set<Position>, owner: Player, isLocked: Bool = false) {
        self.id = id
        self.type = type
        self.positions = positions
        self.owner = owner
        self.isLocked = isLocked
    }

    public var stoneCount: Int { positions.count }
    public var isInstantWin: Bool { (type == .line && positions.count >= 5) || type == .cross }
}

public enum VictorySetType: String, Codable, CaseIterable, Sendable {
    case twinRivers, gateAndPath, threeBends, theFortress, theLongRoad, theStar

    public var displayName: String {
        switch self {
        case .twinRivers: return "Twin Rivers"
        case .gateAndPath: return "Gate & Path"
        case .threeBends: return "Three Bends"
        case .theFortress: return "The Fortress"
        case .theLongRoad: return "The Long Road"
        case .theStar: return "The Star"
        }
    }

    public var isInstantWin: Bool { self == .theLongRoad || self == .theStar }
}

public struct VictorySet: Codable, Sendable, Equatable {
    public let type: VictorySetType
    public let patterns: [Pattern]
    public let winner: Player

    public init(type: VictorySetType, patterns: [Pattern], winner: Player) {
        self.type = type
        self.patterns = patterns
        self.winner = winner
    }
}
