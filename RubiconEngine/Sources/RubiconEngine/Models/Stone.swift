import Foundation

public struct Stone: Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    public let owner: Player
    public var isLocked: Bool
    public var lockedInPatternID: UUID?

    public init(id: UUID = UUID(), owner: Player, isLocked: Bool = false, lockedInPatternID: UUID? = nil) {
        self.id = id
        self.owner = owner
        self.isLocked = isLocked
        self.lockedInPatternID = lockedInPatternID
    }
}
