import SwiftUI
import RubiconEngine

// MARK: - Ladder Rank

public enum LadderRank: Int, CaseIterable, Codable {
    case bronze1 = 0
    case bronze2 = 1
    case bronze3 = 2
    case silver1 = 3
    case silver2 = 4
    case silver3 = 5
    case gold1 = 6
    case gold2 = 7
    case gold3 = 8
    case platinum1 = 9
    case platinum2 = 10
    case platinum3 = 11
    case diamond1 = 12
    case diamond2 = 13
    case diamond3 = 14
    case master = 15
    case grandmaster = 16

    public var displayName: String {
        switch self {
        case .bronze1: return "Bronze I"
        case .bronze2: return "Bronze II"
        case .bronze3: return "Bronze III"
        case .silver1: return "Silver I"
        case .silver2: return "Silver II"
        case .silver3: return "Silver III"
        case .gold1: return "Gold I"
        case .gold2: return "Gold II"
        case .gold3: return "Gold III"
        case .platinum1: return "Platinum I"
        case .platinum2: return "Platinum II"
        case .platinum3: return "Platinum III"
        case .diamond1: return "Diamond I"
        case .diamond2: return "Diamond II"
        case .diamond3: return "Diamond III"
        case .master: return "Master"
        case .grandmaster: return "Grandmaster"
        }
    }

    public var tier: String {
        switch self {
        case .bronze1, .bronze2, .bronze3: return "Bronze"
        case .silver1, .silver2, .silver3: return "Silver"
        case .gold1, .gold2, .gold3: return "Gold"
        case .platinum1, .platinum2, .platinum3: return "Platinum"
        case .diamond1, .diamond2, .diamond3: return "Diamond"
        case .master: return "Master"
        case .grandmaster: return "Grandmaster"
        }
    }

    public var color: Color {
        switch self {
        case .bronze1, .bronze2, .bronze3:
            return Color(red: 0.8, green: 0.5, blue: 0.2)
        case .silver1, .silver2, .silver3:
            return Color(red: 0.75, green: 0.75, blue: 0.8)
        case .gold1, .gold2, .gold3:
            return Color(red: 1.0, green: 0.84, blue: 0.0)
        case .platinum1, .platinum2, .platinum3:
            return Color(red: 0.4, green: 0.8, blue: 0.8)
        case .diamond1, .diamond2, .diamond3:
            return Color(red: 0.6, green: 0.8, blue: 1.0)
        case .master:
            return Color(red: 0.8, green: 0.5, blue: 0.9)
        case .grandmaster:
            return Color(red: 1.0, green: 0.3, blue: 0.3)
        }
    }

    public var icon: String {
        switch self {
        case .bronze1, .bronze2, .bronze3: return "shield.fill"
        case .silver1, .silver2, .silver3: return "shield.lefthalf.filled"
        case .gold1, .gold2, .gold3: return "star.fill"
        case .platinum1, .platinum2, .platinum3: return "sparkles"
        case .diamond1, .diamond2, .diamond3: return "diamond.fill"
        case .master: return "crown.fill"
        case .grandmaster: return "flame.fill"
        }
    }

    /// The AI difficulty for this rank
    public var aiDifficulty: AIDifficulty {
        switch self {
        case .bronze1, .bronze2, .bronze3:
            return .beginner
        case .silver1, .silver2, .silver3:
            return .easy
        case .gold1, .gold2, .gold3:
            return .medium
        case .platinum1, .platinum2, .platinum3:
            return .hard
        case .diamond1, .diamond2, .diamond3:
            return .expert
        case .master, .grandmaster:
            return .master
        }
    }

    /// Wins needed to rank up
    public var winsToRankUp: Int {
        switch self {
        case .bronze1, .bronze2: return 2
        case .bronze3: return 3
        case .silver1, .silver2: return 2
        case .silver3: return 3
        case .gold1, .gold2: return 3
        case .gold3: return 4
        case .platinum1, .platinum2: return 3
        case .platinum3: return 4
        case .diamond1, .diamond2: return 4
        case .diamond3: return 5
        case .master: return 5
        case .grandmaster: return 999 // Can't rank up from GM
        }
    }

    /// Can demote from this rank
    public var canDemote: Bool {
        switch self {
        case .bronze1: return false // Can't go lower
        case .silver1, .gold1, .platinum1, .diamond1: return false // Protected at tier start
        default: return true
        }
    }

    public var next: LadderRank? {
        let allCases = LadderRank.allCases
        guard let currentIndex = allCases.firstIndex(of: self),
              currentIndex + 1 < allCases.count else { return nil }
        return allCases[currentIndex + 1]
    }

    public var previous: LadderRank? {
        let allCases = LadderRank.allCases
        guard let currentIndex = allCases.firstIndex(of: self),
              currentIndex > 0 else { return nil }
        return allCases[currentIndex - 1]
    }
}

// MARK: - Ladder Stats

public struct LadderStats: Codable {
    public var totalWins: Int = 0
    public var totalLosses: Int = 0
    public var currentStreak: Int = 0 // Positive = win streak, negative = loss streak
    public var bestStreak: Int = 0
    public var highestRank: LadderRank = .bronze1
    public var gamesAtCurrentRank: Int = 0
    public var rankUpProgress: Int = 0 // Wins toward next rank
    public var seasonGamesPlayed: Int = 0

    public var winRate: Double {
        let total = totalWins + totalLosses
        guard total > 0 else { return 0 }
        return Double(totalWins) / Double(total) * 100.0
    }
}

// MARK: - Ladder Manager

@MainActor
public class LadderManager: ObservableObject {
    public static let shared = LadderManager()

    @AppStorage("ladderRank") private var rankValue: Int = 0
    @Published public private(set) var stats: LadderStats

    private let statsKey = "ladderStats"

    public var currentRank: LadderRank {
        get { LadderRank(rawValue: rankValue) ?? .bronze1 }
        set { rankValue = newValue.rawValue }
    }

    private init() {
        // Load stats from UserDefaults
        if let data = UserDefaults.standard.data(forKey: statsKey),
           let decoded = try? JSONDecoder().decode(LadderStats.self, from: data) {
            self.stats = decoded
        } else {
            self.stats = LadderStats()
        }
    }

    private func saveStats() {
        if let encoded = try? JSONEncoder().encode(stats) {
            UserDefaults.standard.set(encoded, forKey: statsKey)
        }
    }

    // MARK: - Match Results

    public func recordWin() -> RankChangeResult {
        stats.totalWins += 1
        stats.seasonGamesPlayed += 1
        stats.gamesAtCurrentRank += 1

        // Update streak
        if stats.currentStreak >= 0 {
            stats.currentStreak += 1
        } else {
            stats.currentStreak = 1
        }
        stats.bestStreak = max(stats.bestStreak, stats.currentStreak)

        // Progress toward rank up
        stats.rankUpProgress += 1

        var result = RankChangeResult(previousRank: currentRank, newRank: currentRank, didPromote: false, didDemote: false)

        // Check for rank up
        if stats.rankUpProgress >= currentRank.winsToRankUp {
            if let nextRank = currentRank.next {
                result.previousRank = currentRank
                currentRank = nextRank
                result.newRank = nextRank
                result.didPromote = true
                stats.rankUpProgress = 0
                stats.gamesAtCurrentRank = 0

                // Update highest rank
                if nextRank.rawValue > stats.highestRank.rawValue {
                    stats.highestRank = nextRank
                }
            }
        }

        saveStats()
        objectWillChange.send()
        return result
    }

    public func recordLoss() -> RankChangeResult {
        stats.totalLosses += 1
        stats.seasonGamesPlayed += 1
        stats.gamesAtCurrentRank += 1

        // Update streak
        if stats.currentStreak <= 0 {
            stats.currentStreak -= 1
        } else {
            stats.currentStreak = -1
        }

        var result = RankChangeResult(previousRank: currentRank, newRank: currentRank, didPromote: false, didDemote: false)

        // Lose progress on loss
        if stats.rankUpProgress > 0 {
            stats.rankUpProgress -= 1
        } else if currentRank.canDemote {
            // Demote if at 0 progress and lose again
            if let prevRank = currentRank.previous {
                result.previousRank = currentRank
                currentRank = prevRank
                result.newRank = prevRank
                result.didDemote = true
                stats.rankUpProgress = prevRank.winsToRankUp / 2 // Start halfway
                stats.gamesAtCurrentRank = 0
            }
        }

        saveStats()
        objectWillChange.send()
        return result
    }

    // MARK: - Progress Info

    public var progressToNextRank: Double {
        let required = currentRank.winsToRankUp
        guard required > 0 else { return 1.0 }
        return Double(stats.rankUpProgress) / Double(required)
    }

    public var winsNeededForRankUp: Int {
        currentRank.winsToRankUp - stats.rankUpProgress
    }

    // MARK: - Reset

    public func resetLadder() {
        currentRank = .bronze1
        stats = LadderStats()
        saveStats()
        objectWillChange.send()
    }
}

// MARK: - Rank Change Result

public struct RankChangeResult {
    public var previousRank: LadderRank
    public var newRank: LadderRank
    public var didPromote: Bool
    public var didDemote: Bool
}
