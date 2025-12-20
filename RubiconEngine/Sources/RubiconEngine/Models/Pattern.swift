import Foundation

public enum PatternType: String, Codable, CaseIterable, Sendable {
    case line, bend, gate, cross, pod, hook

    public var displayName: String {
        switch self {
        case .line: return "Line"
        case .bend: return "Bend"
        case .gate: return "Gate"
        case .cross: return "Cross"
        case .pod: return "Pod"
        case .hook: return "Hook"
        }
    }

    public var minimumStones: Int {
        switch self {
        case .line, .bend, .pod: return 3
        case .gate, .hook: return 4
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
    case thePhalanx, thePincer, theSerpent, theConstellation  // New in Third Edition

    public var displayName: String {
        switch self {
        case .twinRivers: return "Twin Rivers"
        case .gateAndPath: return "Gate & Path"
        case .threeBends: return "Three Bends"
        case .theFortress: return "The Fortress"
        case .theLongRoad: return "The Long Road"
        case .theStar: return "The Star"
        case .thePhalanx: return "The Phalanx"
        case .thePincer: return "The Pincer"
        case .theSerpent: return "The Serpent"
        case .theConstellation: return "The Constellation"
        }
    }

    public var isInstantWin: Bool { self == .theLongRoad || self == .theStar }

    public var description: String {
        switch self {
        case .twinRivers: return "Two Lines"
        case .gateAndPath: return "Gate + Line"
        case .threeBends: return "Three Bends"
        case .theFortress: return "Two Gates"
        case .theLongRoad: return "5+ Line (Instant)"
        case .theStar: return "Cross (Instant)"
        case .thePhalanx: return "Gate + Cross"
        case .thePincer: return "Two Hooks"
        case .theSerpent: return "Two Bends + Line"
        case .theConstellation: return "Three Gates"
        }
    }
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
