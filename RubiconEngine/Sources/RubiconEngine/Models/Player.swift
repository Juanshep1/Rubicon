import Foundation

public enum Player: String, Codable, CaseIterable, Sendable {
    case light, dark

    public var opponent: Player {
        self == .light ? .dark : .light
    }

    public var displayName: String {
        self == .light ? "Light" : "Dark"
    }
}
