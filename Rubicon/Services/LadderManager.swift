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

    public var tierNumber: Int {
        switch self {
        case .bronze1, .silver1, .gold1, .platinum1, .diamond1: return 1
        case .bronze2, .silver2, .gold2, .platinum2, .diamond2: return 2
        case .bronze3, .silver3, .gold3, .platinum3, .diamond3: return 3
        case .master, .grandmaster: return 0
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

    public var glowColor: Color {
        switch self {
        case .bronze1, .bronze2, .bronze3:
            return Color(red: 0.9, green: 0.6, blue: 0.3)
        case .silver1, .silver2, .silver3:
            return Color.white
        case .gold1, .gold2, .gold3:
            return Color(red: 1.0, green: 0.9, blue: 0.4)
        case .platinum1, .platinum2, .platinum3:
            return Color(red: 0.5, green: 0.9, blue: 0.9)
        case .diamond1, .diamond2, .diamond3:
            return Color(red: 0.7, green: 0.9, blue: 1.0)
        case .master:
            return Color(red: 0.9, green: 0.6, blue: 1.0)
        case .grandmaster:
            return Color(red: 1.0, green: 0.5, blue: 0.5)
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

    /// Base LP gain for a win at this rank
    public var baseLPGain: Int {
        switch self {
        case .bronze1, .bronze2, .bronze3: return 28
        case .silver1, .silver2, .silver3: return 25
        case .gold1, .gold2, .gold3: return 22
        case .platinum1, .platinum2, .platinum3: return 20
        case .diamond1, .diamond2, .diamond3: return 18
        case .master: return 15
        case .grandmaster: return 12
        }
    }

    /// Base LP loss for a loss at this rank
    public var baseLPLoss: Int {
        switch self {
        case .bronze1, .bronze2, .bronze3: return 12
        case .silver1, .silver2, .silver3: return 15
        case .gold1, .gold2, .gold3: return 18
        case .platinum1, .platinum2, .platinum3: return 20
        case .diamond1, .diamond2, .diamond3: return 22
        case .master: return 25
        case .grandmaster: return 20
        }
    }

    /// Is this the top rank in a tier (requires promo series)
    public var requiresPromoSeries: Bool {
        switch self {
        case .bronze3, .silver3, .gold3, .platinum3, .diamond3, .master:
            return true
        default:
            return false
        }
    }

    /// Can demote from this rank
    public var canDemote: Bool {
        switch self {
        case .bronze1: return false // Can't go lower
        case .silver1, .gold1, .platinum1, .diamond1: return false // Protected at tier floor
        case .master: return false // Can demote from Master but protected at 0 LP for a few games
        default: return true
        }
    }

    /// Demotion shield games (protection at 0 LP)
    public var demotionShieldGames: Int {
        switch self {
        case .bronze1: return 999 // Never demotes
        case .silver1, .gold1, .platinum1, .diamond1: return 999 // Tier protected
        case .master: return 3 // 3 losses at 0 LP before demotion
        case .grandmaster: return 5 // 5 losses at 0 LP before demotion
        default: return 1 // 1 loss at 0 LP = immediate demotion
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

    /// Title unlocked at this rank
    public var unlockedTitle: String? {
        switch self {
        case .silver1: return "Apprentice"
        case .gold1: return "Strategist"
        case .platinum1: return "Tactician"
        case .diamond1: return "Champion"
        case .master: return "Master"
        case .grandmaster: return "Grandmaster"
        default: return nil
        }
    }

    /// Stone theme unlocked at this rank
    public var unlockedStoneTheme: String? {
        switch self {
        case .silver3: return "Marble"
        case .gold3: return "Jade"
        case .platinum3: return "Obsidian"
        case .diamond3: return "Crystal"
        case .master: return "Royal"
        case .grandmaster: return "Celestial"
        default: return nil
        }
    }

    /// Board theme unlocked at this rank
    public var unlockedBoardTheme: String? {
        switch self {
        case .gold1: return "Walnut"
        case .platinum1: return "Slate"
        case .diamond1: return "Midnight"
        case .master: return "Tournament"
        case .grandmaster: return "Ethereal"
        default: return nil
        }
    }
}

// MARK: - Promotion Series

public struct PromotionSeries: Codable, Equatable {
    public var targetRank: LadderRank
    public var wins: Int = 0
    public var losses: Int = 0
    public var gamesRequired: Int = 3  // Best of 3 (need 2 wins)

    public var winsNeeded: Int { (gamesRequired / 2) + 1 }
    public var isWon: Bool { wins >= winsNeeded }
    public var isLost: Bool { losses > gamesRequired - winsNeeded }
    public var isComplete: Bool { isWon || isLost }
    public var gamesPlayed: Int { wins + losses }

    public var statusText: String {
        if isWon { return "PROMOTION!" }
        if isLost { return "Series Failed" }
        return "\(wins)W - \(losses)L"
    }
}

// MARK: - Ladder Stats

public struct LadderStats: Codable {
    public var totalWins: Int = 0
    public var totalLosses: Int = 0
    public var currentStreak: Int = 0 // Positive = win streak, negative = loss streak
    public var bestStreak: Int = 0
    public var highestRank: LadderRank = .bronze1
    public var currentLP: Int = 0  // 0-100 LP per rank
    public var demotionShieldRemaining: Int = 0
    public var promoSeries: PromotionSeries? = nil
    public var seasonGamesPlayed: Int = 0
    public var seasonNumber: Int = 1

    // Performance tracking for LP adjustments
    public var recentWins: Int = 0  // Wins in last 10 games
    public var recentLosses: Int = 0  // Losses in last 10 games

    // Victory type stats
    public var eliminationWins: Int = 0
    public var patternWins: Int = 0
    public var dominatingWins: Int = 0  // Won without losing any stones
    public var comebackWins: Int = 0    // Won after being down 5+ stones

    public var winRate: Double {
        let total = totalWins + totalLosses
        guard total > 0 else { return 0 }
        return Double(totalWins) / Double(total) * 100.0
    }

    public var recentWinRate: Double {
        let recent = recentWins + recentLosses
        guard recent > 0 else { return 50.0 }
        return Double(recentWins) / Double(recent) * 100.0
    }
}

// MARK: - Rank Change Result

public struct RankChangeResult {
    public var previousRank: LadderRank
    public var newRank: LadderRank
    public var lpChange: Int
    public var newLP: Int
    public var didPromote: Bool
    public var didDemote: Bool
    public var startedPromoSeries: Bool
    public var promoSeriesUpdate: PromotionSeries?
    public var unlockedRewards: [LadderReward]

    public init(previousRank: LadderRank, newRank: LadderRank, lpChange: Int = 0, newLP: Int = 0,
                didPromote: Bool = false, didDemote: Bool = false, startedPromoSeries: Bool = false,
                promoSeriesUpdate: PromotionSeries? = nil, unlockedRewards: [LadderReward] = []) {
        self.previousRank = previousRank
        self.newRank = newRank
        self.lpChange = lpChange
        self.newLP = newLP
        self.didPromote = didPromote
        self.didDemote = didDemote
        self.startedPromoSeries = startedPromoSeries
        self.promoSeriesUpdate = promoSeriesUpdate
        self.unlockedRewards = unlockedRewards
    }
}

// MARK: - Ladder Reward

public struct LadderReward: Identifiable {
    public let id = UUID()
    public let type: RewardType
    public let name: String
    public let rank: LadderRank

    public enum RewardType {
        case title
        case stoneTheme
        case boardTheme
        case border
    }

    public var icon: String {
        switch type {
        case .title: return "text.quote"
        case .stoneTheme: return "circle.fill"
        case .boardTheme: return "square.grid.3x3"
        case .border: return "square.on.square"
        }
    }
}

// MARK: - Ladder Manager

@MainActor
public class LadderManager: ObservableObject {
    public static let shared = LadderManager()

    @AppStorage("ladderRank") private var rankValue: Int = 0
    @Published public private(set) var stats: LadderStats
    @Published public private(set) var unlockedRewards: Set<String> = []

    private let statsKey = "ladderStats"
    private let rewardsKey = "ladderRewards"

    public var currentRank: LadderRank {
        get { LadderRank(rawValue: rankValue) ?? .bronze1 }
        set {
            rankValue = newValue.rawValue
            checkAndUnlockRewards(for: newValue)
        }
    }

    private init() {
        // Load stats from UserDefaults
        if let data = UserDefaults.standard.data(forKey: statsKey),
           let decoded = try? JSONDecoder().decode(LadderStats.self, from: data) {
            self.stats = decoded
        } else {
            self.stats = LadderStats()
        }

        // Load unlocked rewards
        if let rewards = UserDefaults.standard.array(forKey: rewardsKey) as? [String] {
            self.unlockedRewards = Set(rewards)
        }

        // Check rewards for current rank on init
        checkAndUnlockRewards(for: currentRank)
    }

    private func saveStats() {
        if let encoded = try? JSONEncoder().encode(stats) {
            UserDefaults.standard.set(encoded, forKey: statsKey)
        }
    }

    private func saveRewards() {
        UserDefaults.standard.set(Array(unlockedRewards), forKey: rewardsKey)
    }

    // MARK: - Match Results

    public func recordWin(wasElimination: Bool = false, wasDominating: Bool = false, wasComeback: Bool = false) -> RankChangeResult {
        stats.totalWins += 1
        stats.seasonGamesPlayed += 1

        // Update recent performance
        updateRecentPerformance(won: true)

        // Update streak
        if stats.currentStreak >= 0 {
            stats.currentStreak += 1
        } else {
            stats.currentStreak = 1
        }
        stats.bestStreak = max(stats.bestStreak, stats.currentStreak)

        // Track victory types
        if wasElimination { stats.eliminationWins += 1 }
        else { stats.patternWins += 1 }
        if wasDominating { stats.dominatingWins += 1 }
        if wasComeback { stats.comebackWins += 1 }

        var result = RankChangeResult(previousRank: currentRank, newRank: currentRank)

        // Handle promotion series
        if var series = stats.promoSeries {
            series.wins += 1
            stats.promoSeries = series
            result.promoSeriesUpdate = series

            if series.isWon {
                // Promotion successful!
                if let nextRank = currentRank.next {
                    result.previousRank = currentRank
                    currentRank = nextRank
                    result.newRank = nextRank
                    result.didPromote = true
                    stats.currentLP = 25  // Start new rank with some LP
                    stats.promoSeries = nil
                    stats.demotionShieldRemaining = nextRank.demotionShieldGames

                    // Update highest rank
                    if nextRank.rawValue > stats.highestRank.rawValue {
                        stats.highestRank = nextRank
                    }

                    // Check for new rewards
                    result.unlockedRewards = getNewRewards(for: nextRank)
                }
            } else if series.isLost {
                // Failed promo series
                stats.promoSeries = nil
                stats.currentLP = 60  // Keep some LP after failed series
            }
        } else {
            // Normal LP gain
            let lpGain = calculateLPGain()
            result.lpChange = lpGain
            stats.currentLP += lpGain

            // Check for promotion
            if stats.currentLP >= 100 {
                if currentRank.requiresPromoSeries {
                    // Start promotion series
                    if let nextRank = currentRank.next {
                        stats.promoSeries = PromotionSeries(targetRank: nextRank)
                        stats.currentLP = 100
                        result.startedPromoSeries = true
                        result.promoSeriesUpdate = stats.promoSeries
                    }
                } else {
                    // Direct promotion (within same tier)
                    if let nextRank = currentRank.next {
                        let overflow = stats.currentLP - 100
                        result.previousRank = currentRank
                        currentRank = nextRank
                        result.newRank = nextRank
                        result.didPromote = true
                        stats.currentLP = min(overflow, 25)  // Carry over some LP
                        stats.demotionShieldRemaining = nextRank.demotionShieldGames

                        if nextRank.rawValue > stats.highestRank.rawValue {
                            stats.highestRank = nextRank
                        }
                        result.unlockedRewards = getNewRewards(for: nextRank)
                    }
                }
            }
            result.newLP = stats.currentLP
        }

        saveStats()
        objectWillChange.send()
        return result
    }

    public func recordLoss() -> RankChangeResult {
        stats.totalLosses += 1
        stats.seasonGamesPlayed += 1

        // Update recent performance
        updateRecentPerformance(won: false)

        // Update streak
        if stats.currentStreak <= 0 {
            stats.currentStreak -= 1
        } else {
            stats.currentStreak = -1
        }

        var result = RankChangeResult(previousRank: currentRank, newRank: currentRank)

        // Handle promotion series
        if var series = stats.promoSeries {
            series.losses += 1
            stats.promoSeries = series
            result.promoSeriesUpdate = series

            if series.isLost {
                // Failed series
                stats.promoSeries = nil
                stats.currentLP = 60  // Keep some LP
            }
        } else {
            // Normal LP loss
            let lpLoss = calculateLPLoss()
            result.lpChange = -lpLoss
            stats.currentLP = max(0, stats.currentLP - lpLoss)

            // Check for demotion
            if stats.currentLP == 0 {
                if stats.demotionShieldRemaining > 0 {
                    stats.demotionShieldRemaining -= 1
                } else if currentRank.canDemote {
                    if let prevRank = currentRank.previous {
                        result.previousRank = currentRank
                        currentRank = prevRank
                        result.newRank = prevRank
                        result.didDemote = true
                        stats.currentLP = 50  // Start with 50 LP in lower rank
                        stats.demotionShieldRemaining = 0
                    }
                }
            }
            result.newLP = stats.currentLP
        }

        saveStats()
        objectWillChange.send()
        return result
    }

    // MARK: - LP Calculation

    private func calculateLPGain() -> Int {
        var lp = currentRank.baseLPGain

        // Win streak bonus
        if stats.currentStreak >= 3 {
            lp += min(stats.currentStreak - 2, 5) * 2  // +2 LP per streak game (max +10)
        }

        // Hot hand bonus (high recent win rate)
        if stats.recentWinRate > 70 {
            lp += 3
        }

        // First win bonus (helps new players climb)
        if stats.totalWins <= 10 {
            lp += 5
        }

        return min(lp, 40)  // Cap at 40 LP
    }

    private func calculateLPLoss() -> Int {
        var lp = currentRank.baseLPLoss

        // Loss streak penalty
        if stats.currentStreak <= -3 {
            lp += min(abs(stats.currentStreak) - 2, 5) * 2  // +2 LP loss per streak (max +10)
        }

        // Tilt protection (losing a lot = smaller losses to prevent frustration)
        if stats.recentWinRate < 30 {
            lp = max(lp - 5, 10)
        }

        // New player protection
        if stats.totalWins + stats.totalLosses <= 20 {
            lp = max(lp - 5, 8)
        }

        return min(lp, 30)  // Cap losses at 30 LP
    }

    private func updateRecentPerformance(won: Bool) {
        if won {
            stats.recentWins = min(stats.recentWins + 1, 10)
            if stats.recentLosses > 0 { stats.recentLosses -= 1 }
        } else {
            stats.recentLosses = min(stats.recentLosses + 1, 10)
            if stats.recentWins > 0 { stats.recentWins -= 1 }
        }
    }

    // MARK: - Rewards

    private func checkAndUnlockRewards(for rank: LadderRank) {
        var newRewards: [String] = []

        // Check all ranks up to current for rewards
        for r in LadderRank.allCases where r.rawValue <= rank.rawValue {
            if let title = r.unlockedTitle, !unlockedRewards.contains("title_\(title)") {
                unlockedRewards.insert("title_\(title)")
                newRewards.append("title_\(title)")
            }
            if let stone = r.unlockedStoneTheme, !unlockedRewards.contains("stone_\(stone)") {
                unlockedRewards.insert("stone_\(stone)")
                newRewards.append("stone_\(stone)")
            }
            if let board = r.unlockedBoardTheme, !unlockedRewards.contains("board_\(board)") {
                unlockedRewards.insert("board_\(board)")
                newRewards.append("board_\(board)")
            }
        }

        if !newRewards.isEmpty {
            saveRewards()
        }
    }

    private func getNewRewards(for rank: LadderRank) -> [LadderReward] {
        var rewards: [LadderReward] = []

        if let title = rank.unlockedTitle {
            rewards.append(LadderReward(type: .title, name: title, rank: rank))
        }
        if let stone = rank.unlockedStoneTheme {
            rewards.append(LadderReward(type: .stoneTheme, name: stone, rank: rank))
        }
        if let board = rank.unlockedBoardTheme {
            rewards.append(LadderReward(type: .boardTheme, name: board, rank: rank))
        }

        return rewards
    }

    public func isRewardUnlocked(_ rewardID: String) -> Bool {
        unlockedRewards.contains(rewardID)
    }

    public func getAllAvailableRewards() -> [LadderReward] {
        var rewards: [LadderReward] = []
        for rank in LadderRank.allCases {
            rewards.append(contentsOf: getNewRewards(for: rank))
        }
        return rewards
    }

    // MARK: - Progress Info

    public var progressToNextRank: Double {
        if stats.promoSeries != nil {
            return 1.0  // Full bar during promo
        }
        return Double(stats.currentLP) / 100.0
    }

    public var lpDisplay: String {
        if let series = stats.promoSeries {
            return series.statusText
        }
        return "\(stats.currentLP) LP"
    }

    public var isInPromoSeries: Bool {
        stats.promoSeries != nil
    }

    // MARK: - Reset

    public func resetLadder() {
        currentRank = .bronze1
        stats = LadderStats()
        saveStats()
        objectWillChange.send()
    }

    public func resetSeason() {
        // Soft reset: Drop players down but keep some progress
        let currentTier = currentRank.tier
        var newRank: LadderRank = .bronze1

        switch currentTier {
        case "Bronze": newRank = .bronze1
        case "Silver": newRank = .bronze3
        case "Gold": newRank = .silver2
        case "Platinum": newRank = .gold2
        case "Diamond": newRank = .platinum2
        case "Master": newRank = .diamond2
        case "Grandmaster": newRank = .diamond3
        default: newRank = .bronze1
        }

        currentRank = newRank
        stats.currentLP = 50
        stats.promoSeries = nil
        stats.seasonGamesPlayed = 0
        stats.seasonNumber += 1
        stats.recentWins = 0
        stats.recentLosses = 0
        stats.demotionShieldRemaining = newRank.demotionShieldGames

        saveStats()
        objectWillChange.send()
    }
}
